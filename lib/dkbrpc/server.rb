require 'eventmachine'
require 'dkbrpc/connection_id'
require "dkbrpc/fast_message_protocol"
require 'dkbrpc/outgoing_connection'
require 'dkbrpc/incoming_connection'
require 'dkbrpc/id'

module Dkbrpc

  class ClientProxy
    def initialize(outgoing_connection)
      @remote_connection = outgoing_connection
    end

    def method_missing(method, * args, & block)
      EventMachine::schedule do
        @remote_connection.remote_call(method, args, & block)
      end
    end

    def errback(& block)
      @remote_connection.errback = block
    end
  end


  class Server
    
    def initialize(host, port, api)
      @host = host
      @port = port
      @api = api
      @connections = []
    end

    def start(& callback)
      EventMachine::schedule do
        begin
          @server_signature = EventMachine::start_server(@host, @port, Listener) do |connection|
            connection.api = @api
            connection.new_connection_callback = callback
            @connections << connection
          end
        rescue Exception => e
          @errback.call(e) if @errback
        end
      end
    end

    def stop
      EventMachine::schedule do
        @connections.each do |connection|
          connection.close_connection
        end
        EventMachine::stop_server(@server_signature)
      end if @server_signature
    end
    
    def errback(&block)
      @errback = block
    end
  end

  module Listener
    attr_accessor :api
    attr_accessor :new_connection_callback
    attr_accessor :errback
    include ConnectionId

    def post_init
      @buffer = ""
    end

    def receive_data data
      @buffer << data
      handshake(@buffer) if @id.nil?
    end

    def unbind
      @errback.call if @errback
    end

    private

    def handle_incoming
      @id = Id.next
      send_data(@id)
      self.extend(IncomingConnection)
      switch_protocol
    end

    def handle_outgoing(buffer)
      if complete_id?(buffer[1..-1])
        @id = extract_id(buffer[1..-1])
        self.extend(OutgoingConnection)
        switch_protocol
        @new_connection_callback.call(ClientProxy.new(self)) if @new_connection_callback
      end
    end

    def handshake(buffer)
      if buffer[0] == "4"[0]
        handle_incoming
      elsif buffer[0] == "5"[0]
        handle_outgoing(buffer)
      end
    end

    def switch_protocol
      Dkbrpc::FastMessageProtocol.install(self)
    end

  end

end