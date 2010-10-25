require "dkbrpc/remote_call"

module Dkbrpc
  module OutgoingConnection
    include RemoteCall
    def receive_message(message)
      marshaled_message = *unmarshal_call(message)
      if marshaled_message.is_a?(Exception)
        @errback.call(marshaled_message) if @errback
      else
        @callback.call(marshaled_message) if @callback
      end
    end

    def remote_call(method, *args, &block)
      @callback = block
      send_message(marshal_call(method, *args))
    end
  end
end
