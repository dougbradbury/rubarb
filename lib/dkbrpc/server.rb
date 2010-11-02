require 'eventmachine'
require 'dkbrpc/connection_id'
require "dkbrpc/fast_message_protocol"
require 'dkbrpc/outgoing_connection'
require 'dkbrpc/incoming_connection'
require 'dkbrpc/id'
require 'dkbrpc/default'

module Dkbrpc
  class ClientProxy
    attr_reader :remote_connection
    
    def initialize(outgoing_connection)
      @remote_connection = outgoing_connection
    end

    def method_missing(method, * args, & block)
      EventMachine::schedule do
        begin
          @remote_connection.remote_call(method, args, & block)
        rescue Exception => e
          @remote_connection.call_errbacks(e)
        end
      end
    end

    def errback(& block)
      @remote_connection.errbacks << block if block
    end

    def conn_id
      @remote_connection.conn_id
    end

    def stop
      EventMachine::next_tick do
        @remote_connection.close_connection
      end
    end
  end

  class Server
    attr_reader :connections
    attr_reader :conn_id_generator
    attr_reader :msg_id_generator
    attr_reader :errback
    attr_reader :insecure_methods
    attr_accessor :external_protocol

    def initialize(host, port, api, insecure_methods=Default::INSECURE_METHODS)
      @host = host
      @port = port
      @api = api
      @connections = []
      @unbind_block = Proc.new do |connection|
        @connections.delete(connection)
      end
      @conn_id_generator = Id.new
      @msg_id_generator = Id.new
      @insecure_methods = insecure_methods
    end

    def start(& callback)
      EventMachine::schedule do
        begin
          @server_signature = EventMachine::start_server(@host, @port, Listener) do |connection|
            connection.conn_id_generator = @conn_id_generator
            connection.msg_id_generator = @msg_id_generator
            connection.api = @api
            connection.new_connection_callback = callback
            connection.errbacks = @errback.nil? ? [] : [@errback]
            connection.unbindback = @unbind_block
            connection.insecure_methods = @insecure_methods
            connection.external_protocol = @external_protocol
            @connections << connection
          end
        rescue Exception => e
          @errback.call(e) if @errback
        end
      end
    end


    def stop(& callback)
      EventMachine::schedule do
        EventMachine::next_tick do
          close_all_connections
          stop_server(callback)
        end
      end
    end

    def errback(& block)
      @errback = block
    end

    private #################################################################################
    def close_all_connections
      @connections.each do |connection|
        connection.close_connection
      end
    end

    def stop_server(callback)
      if @server_signature
        EventMachine::stop_server(@server_signature)
        @server_signature = nil
        callback.call(true) if callback
      else
        callback.call(false) if callback
      end
    end

  end

  module Listener
    INCOMING_CONNECTION = "4"[0]
    OUTGOING_CONNECTION = "5"[0]
    attr_accessor :conn_id_generator
    attr_reader :conn_id
    attr_accessor :msg_id_generator
    attr_accessor :api
    attr_accessor :new_connection_callback
    attr_accessor :callback
    attr_accessor :errbacks
    attr_accessor :unbindback
    attr_accessor :insecure_methods
    attr_accessor :external_protocol

    include ConnectionId

    def post_init
      @buffer = ""
    end

    def receive_data data
      @buffer << data
      handshake(@buffer) if @conn_id.nil?
    end

    def unbind
      call_errbacks(ConnectionError.new)
      @unbindback.call(self) if @unbindback
    end

    def call_errbacks(message)
      @errbacks.each do |e|
        e.call(message)
      end
    end

    private

    def handle_incoming
      @conn_id = @conn_id_generator.next
      self.extend(IncomingConnection)
      switch_protocol
      send_data(@conn_id)
    end

    def handle_outgoing(buffer)
      if complete_id?(buffer[1..-1])
        @conn_id = extract_id(buffer[1..-1])
        self.extend(OutgoingConnection)
        switch_protocol
        send_message(@conn_id)
        @new_connection_callback.call(ClientProxy.new(self)) if @new_connection_callback
      end
    end

    def handshake(buffer)
      if buffer[0] == INCOMING_CONNECTION
        handle_incoming
      elsif buffer[0] == OUTGOING_CONNECTION
        handle_outgoing(buffer)
      else
        @external_protocol.handle_connection(buffer, self) if @external_protocol
      end
    end

    def switch_protocol
      Dkbrpc::FastMessageProtocol.install(self)
    end
  end
end
