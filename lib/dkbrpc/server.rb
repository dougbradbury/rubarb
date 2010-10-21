require 'eventmachine'
require 'dkbrpc/connection_id'
require "dkbrpc/fast_message_protocol"
require 'dkbrpc/outgoing_connection'
require 'dkbrpc/incoming_connection'

module Dkbrpc

  class Id
    def self.next
      @id ||= 1
      id = "%08d" % @id
      @id += 1
      id
    end
  end

  class RemoteClient
    attr_accessor :outgoing, :incomming

    def self.acquire_client(id)
      @@clients ||= {}
      @@clients[id] ||= RemoteClient.new
      @@clients[id]
    end

    def self.add_incomming(id, incomming)
      acquire_client(id).incomming = incomming
    end

    def self.add_outgoing(id, outgoing)
      acquire_client(id).outgoing = outgoing
    end

    def self.find(id)
      return acquire_client(id)
    end
  end

  module Listener
    attr_accessor :api
    attr_accessor :new_connection_callback
    include ConnectionId

    def post_init
      @buffer = ""
    end

    def receive_data data
      @buffer << data
      if @id.nil?
        handshake(@buffer)
      end

    end

    def unbind

    end

    private

    def handle_incoming
      @id = Id.next
      send_data(@id)
      RemoteClient.add_incomming(@id, self)
    end

    def handle_outgoing(buffer)
      if complete_id?(buffer[1..-1])
        @id = extract_id(buffer[1..-1])
        RemoteClient.add_outgoing(@id, self)
        self.extend(OutgoingConnection)
        switch_protocol        
      end
    end

    def handshake(buffer)
      if buffer[0] == "4"[0]
        handle_incoming
        self.extend(IncomingConnection)
        switch_protocol
      elsif buffer[0] == "5"[0]
        handle_outgoing(buffer)
        @new_connection_callback.call(ClientProxy.new(self)) if @new_connection_callback
      end
    end

    def switch_protocol
      Dkbrpc::FastMessageProtocol.install(self)
    end

  end

  class ClientProxy
    def initialize(outgoing_connection)
      @remote_connection = outgoing_connection
    end

    def method_missing(method, * args, & block)
      EventMachine::schedule do
        @remote_connection.remote_call(method, args, &block)
      end
    end
  end


  class Server
    def initialize(host, port, api)
      @host = host
      @port = port
      @api = api
    end

    def start & block
      EventMachine::schedule do
        EventMachine::start_server(@host, @port, Listener) do |server|
          server.api = @api
          server.new_connection_callback = block
        end
      end


    end

  end


end