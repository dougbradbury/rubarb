require 'eventmachine'
require 'dkbrpc/connection_id'
require "dkbrpc/fast_message_protocol"
require 'dkbrpc/remote_call'
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
    include ConnectionId
    include RemoteCall

    def post_init
      @buffer = ""
    end

    def receive_data data
      @buffer << data
      if @id.nil?
        handshake(@buffer)
      end

    end

    def receive_message msg
      method, args = unmarshal_call(msg)
      api.send(method, *[self, *args]);
    end

    def reply(*args)
      send_message(marshal_call(args))
    end

    def unbind

    end

    private

    def handle_incomming
      @id = Id.next
      send_data(@id)
      RemoteClient.add_incomming(@id, self)
    end

    def handle_outgoing(buffer)
      if complete_id?(buffer[1..-1])
        @id = extract_id(buffer[1..-1])
        RemoteClient.add_outgoing(@id, self)
      end
    end

    def handshake(buffer)
      if buffer[0] == "4"[0]
        handle_incomming
        switch_protocol
      elsif buffer[0] == "5"[0]
        handle_outgoing(buffer)
      end
    end

    def switch_protocol
      Dkbrpc::FastMessageProtocol.install(self)
    end

  end


  class Server
    def initialize(host, port, api)
      @host = host
      @port = port
      @api = api
    end

    def start
      EventMachine::schedule do
        EventMachine::start_server(@host, @port, Listener) do |server|
          server.api = @api
        end
      end


    end

  end


end