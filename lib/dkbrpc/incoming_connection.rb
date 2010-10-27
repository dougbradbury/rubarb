require "dkbrpc/remote_call"

module Dkbrpc

  module IncomingConnection
    include RemoteCall

    def receive_message(message)
      id, method, args = unmarshal_call(message)
      @message_id = id
      begin
        api.send(method, *[self, *args]);
      rescue Exception => e
        reply(e)
      end
    end

    def reply(*args)
      send_message(marshal_call(args.unshift(@message_id)))
    end

  end
end
