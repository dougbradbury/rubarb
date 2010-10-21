require "dkbrpc/remote_call"

module Dkbrpc
  module OutgoingConnection
    include RemoteCall
    def receive_message(message)
      @callback.call(* unmarshal_call(message))
    end

    def remote_call(method, * args, & block)
      @callback = block
      send_message(marshal_call(method, * args))
    end
  end
end
