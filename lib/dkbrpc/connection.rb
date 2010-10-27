require "dkbrpc/connection_id"
require "dkbrpc/fast_message_protocol"
require "dkbrpc/remote_call"
require 'dkbrpc/outgoing_connection'
require 'dkbrpc/incoming_connection'
require 'dkbrpc/connection_error'

module Dkbrpc
  module IncomingHandler
    include Dkbrpc::IncomingConnection
    attr_accessor :id, :on_connection, :api, :errback

    def post_init
      @buffer = ""
    end
    
    def connection_completed
      Dkbrpc::FastMessageProtocol.install(self)
      send_data("5")
      send_data(@id)
      @on_connection.call if @on_connection
    end

    def unbind
      @errback.call(ConnectionError.new) if @errback
    end
  end

  module OutgoingHandler
    include ConnectionId
    include OutgoingConnection
    attr_accessor :host, :port
    attr_accessor :on_connection
    attr_accessor :api
    attr_accessor :errback, :callback
    attr_accessor :msg_id_generator

    def post_init
      @buffer = ""
    end

    def connection_completed
      send_data("4")
    end

    def receive_data data
      @buffer << data
      if @id.nil?
        handshake(@buffer)
      end
    end

    def unbind
      if @incoming_connection
        EM.next_tick { @incoming_connection.close_connection }
      else
        @errback.call(Dkbrpc::ConnectionError.new) if @errback
      end
    end

    private

    def handshake(buffer)
      if complete_id?(buffer)
        Dkbrpc::FastMessageProtocol.install(self)
        EventMachine::connect(@host, @port, IncomingHandler) do |incoming_connection|
          @id = extract_id(buffer)
          incoming_connection.id = @id
          incoming_connection.on_connection = @on_connection
          incoming_connection.api = @api
          incoming_connection.errback = @errback
          @incoming_connection = incoming_connection
        end
      end
    end
  end

  class Connection
    attr_reader :remote_connection
    attr_reader :msg_id_generator

    def initialize(host, port, api)
      @host = host
      @port = port
      @api = api
      @msg_id_generator = Id.new
    end

    def errback &block
      @errback = block
    end

    def start &block
      EventMachine::schedule do
        EventMachine::connect(@host, @port, OutgoingHandler) do |connection|
          connection.host = @host
          connection.port = @port
          connection.on_connection = block
          connection.api = @api
          connection.errback = @errback
          connection.callback = {}
          connection.msg_id_generator = @msg_id_generator
          @remote_connection = connection
        end
      end
    end

    def method_missing(method, *args, &block)
      EventMachine::schedule do
        @remote_connection.remote_call(method, args, &block)
      end
    end

    def stop
      EventMachine::schedule do
        @remote_connection.close_connection
      end
    end
  end
end
