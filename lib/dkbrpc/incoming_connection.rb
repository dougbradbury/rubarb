require "dkbrpc/remote_call"

module Dkbrpc

  module IncomingConnection
    include RemoteCall
    
    def receive_message msg
      method, args = unmarshal_call(msg)
      api.send(method, * [self, * args]);
    end

    def reply(* args)
      send_message(marshal_call(args))
    end

  end
end