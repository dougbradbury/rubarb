require "dkbrpc/remote_call"

module Dkbrpc

  module IncomingConnection
    include RemoteCall

    def receive_message msg
      method, args = unmarshal_call(msg)
      begin
        api.send(method, *[self, *args]);
      rescue Exception => e
        reply(e)
      end
    end

    def reply(*args)
      send_message(marshal_call(args))
    end

  end
end
