require "dkbrpc/remote_call"
require "dkbrpc/responder"
require "dkbrpc/insecure_method_call_error"

module Dkbrpc

  module IncomingConnection
    include RemoteCall

    def receive_message(message)
      id, method, args = unmarshal_call(message)
      responder = Responder.new(self, id)
      begin
        raise Dkbrpc::InsecureMethodCallError.new(method) if @insecure_methods.include?(method)
        api.send(method, *[responder, *args]);
      rescue Exception => e
        reply("0", e)
      end
    end

    def reply(id, *args)
      send_message(marshal_call(args.unshift(id)))
    end
  end
end
