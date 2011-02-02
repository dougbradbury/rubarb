require "rubarb/remote_call"
require "rubarb/responder"
require "rubarb/insecure_method_call_error"

module Rubarb

  module IncomingConnection
    include RemoteCall

    def receive_message(message)
      id, method, args = unmarshal_call(message)
      return unless method
      responder = Responder.new(self, id)
      begin
        raise Rubarb::InsecureMethodCallError.new(method) if @insecure_methods.include?(method)
        api.send(method, *[responder, *args])
      rescue Exception => e
        reply("0", e)
      end
    end

    def reply(id, *args)
      send_message(marshal_call(args.unshift(id)))
    end

	def reset_keep_alive
	end

    def cancel_keep_alive

    end
  end
end
