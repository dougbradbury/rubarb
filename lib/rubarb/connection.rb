require "rubarb/connection_id"
require "rubarb/fast_message_protocol"
require "rubarb/remote_call"
require 'rubarb/outgoing_connection'
require 'rubarb/incoming_connection'
require 'rubarb/connection_error'
require 'rubarb/default'

module Rubarb
  module IncomingHandler
    include ConnectionId

    attr_accessor :id
    attr_accessor :on_connection
    attr_accessor :api
    attr_accessor :insecure_methods
    attr_accessor :parent

    def post_init
      @buffer = ""
    end

    def connection_completed
      Rubarb::FastMessageProtocol.install(self)
      send_data("5")
      send_data(@id)
      @parent.connection_completed(self) if @parent
    end

    def receive_message message
      if (message == @id)
        self.extend(Rubarb::IncomingConnection)
        @on_connection.call if @on_connection
      else
        call_errbacks(ConnectionError.new("Handshake Failure"))
      end
    end

    def unbind
      @parent.connection_closed(self)
    end

    def call_errbacks(message)
      @parent.call_errbacks(message)
    end

  end

  module OutgoingHandler
    include ConnectionId
    include OutgoingConnection
    attr_accessor :host
    attr_accessor :port
    attr_accessor :on_connection
    attr_accessor :api
    attr_accessor :callback
    attr_accessor :msg_id_generator
    attr_accessor :insecure_methods
    attr_accessor :parent
    attr_accessor :keep_alive_time

    def post_init
      @buffer = ""
    end

    def connection_completed
      send_data("4")
      @parent.connection_completed(self) if @parent
    end

    def receive_data data
      @buffer << data
      if @id.nil?
        handshake(@buffer)
      end
    end

    def unbind
      cancel_keep_alive
      @parent.connection_closed(self)
    end

    def call_errbacks(message)
      @parent.call_errbacks(message)
    end

    private

    def handshake(buffer)
      if complete_id?(buffer)
        Rubarb::FastMessageProtocol.install(self)
        EventMachine::connect(@host, @port, IncomingHandler) do |incoming_connection|
          @id = extract_id(buffer)
          incoming_connection.id = @id
          incoming_connection.on_connection = @on_connection
          incoming_connection.api = @api
          incoming_connection.insecure_methods = @insecure_methods
          incoming_connection.parent = @parent
        end
      end
    end
  end

  class Connection

    attr_reader :msg_id_generator

    def remote_connection
      @outgoing_connection
    end

    def initialize(host, port, api, insecure_methods=Default::INSECURE_METHODS, keep_alive_time = 0)
      @host = host
      @port = port
      @api = api
      @msg_id_generator = Id.new
      @errbacks = []
      @insecure_methods = insecure_methods
      @connections = []
      @keep_alive_time = keep_alive_time
    end

    def close_connections
      EM.next_tick do
        @connections.each {|conn| conn.close_connection_after_writing}
      end
    end

    def connection_closed(connection)
      @connections.delete(connection)
      if !@connections.empty?
        close_connections
      else
        call_errbacks(ConnectionError.new)
      end
    end

    def connection_completed(connection)
      @connections << connection
    end

    def call_errbacks(message)
      @errbacks.each do |e|
        e.call(message)
      end
    end

    def errback & block
      @errbacks << block if block
    end

    def start & block
      EventMachine::schedule do
        begin
          EventMachine::connect(@host, @port, OutgoingHandler) do |connection|
            connection.host = @host
            connection.port = @port
            connection.on_connection = block
            connection.api = @api
            connection.msg_id_generator = @msg_id_generator
            connection.insecure_methods = @insecure_methods
            connection.parent = self
            connection.keep_alive_time = @keep_alive_time
            @outgoing_connection = connection
          end
        rescue Exception => e
          @errbacks.each do |errback|
            errback.call(e)
          end
        end
      end
    end

    def method_missing(method, * args, & block)
      EventMachine::schedule do
        begin
          @outgoing_connection.remote_call(method, args, & block)
        rescue Exception => e
          call_errbacks(e)
        end
      end
    end

    def stop(& callback)
      EventMachine::schedule do
        if @outgoing_connection
          EventMachine::next_tick do
            @outgoing_connection.close_connection_after_writing
            callback.call(true) if callback
          end
        else
          callback.call(false) if callback
        end
      end
    end
  end
end
