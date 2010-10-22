require "dkbrpc/connection_id"
require "dkbrpc/fast_message_protocol"
require "dkbrpc/remote_call"
require 'dkbrpc/outgoing_connection'
require 'dkbrpc/incoming_connection'


module Dkbrpc

  module IncommingHandler
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
      @errback.call("Connection Failure") if @errback
    end
  end


  module OutgoingHandler
    include ConnectionId
    include OutgoingConnection
    attr_accessor :host, :port, :on_connection, :api, :errback

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
        @incoming_connection.close_connection
      else
        @errback.call("Connection Failure") if @errback
      end
    end

    private


    def handshake(buffer)
      if complete_id?(buffer)
        Dkbrpc::FastMessageProtocol.install(self)
        EventMachine::connect(@host, @port, IncommingHandler) do |incoming_connection|
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
    def initialize(host, port, api)
      @host = host
      @port = port
      @api = api
    end

    def errback & block
      @errback = block
    end

    def start & block
      EventMachine::schedule do
        EventMachine::connect(@host, @port, OutgoingHandler) do |handler|
          @remote_connection = handler
          handler.host = @host
          handler.port = @port
          handler.on_connection = block
          handler.api = @api
          handler.errback = @errback
        end
      end
    end

    def method_missing(method, * args, & block)
      EventMachine::schedule do
        @remote_connection.remote_call(method, args, & block)
      end
    end

    def stop
      EventMachine::schedule do
        @remote_connection.close_connection
      end
    end

  end
end