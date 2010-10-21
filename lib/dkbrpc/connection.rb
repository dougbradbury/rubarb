require "dkbrpc/connection_id"
require "dkbrpc/fast_message_protocol"
require "dkbrpc/remote_call"

module Dkbrpc

  module IncommingHandler
    attr_accessor :id, :on_connection

    def post_init

    end

    def connection_completed
      send_data("5")
      send_data(@id)
      @on_connection.call if @on_connection
    end

    def receive_data data

    end

    def unbind

    end
  end


  module OutgoingHandler
    include ConnectionId
    include RemoteCall
    attr_accessor :host, :port, :on_connection

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

    def receive_message(message)      
      @callback.call(*unmarshal_call(message))
    end

    def unbind

    end

    def remote_call(method, * args, &block)
      @callback = block
      send_message(marshal_call(method, *args))
    end

    private


    def handshake(buffer)
      if complete_id?(buffer)
        EventMachine::connect(@host, @port, IncommingHandler) do |handler|
          @id = extract_id(buffer)
          handler.id = @id
          handler.on_connection = @on_connection
        end
        Dkbrpc::FastMessageProtocol.install(self)
      end
    end
  end

  class Connection
    def initialize(host, port, api)
      @host = host
      @port = port
      @api = api
    end

    def start &block
      EventMachine::schedule do
        EventMachine::connect(@host, @port, OutgoingHandler) do |handler|
          @remote_connection = handler
          handler.host = @host
          handler.port = @port
          handler.on_connection = block
        end
      end
    end

    def method_missing(method, * args, &block)
      EventMachine::schedule do        
        @remote_connection.remote_call(method, args, &block)
      end
    end

  end
end