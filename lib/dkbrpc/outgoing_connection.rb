require "dkbrpc/remote_call"

module Dkbrpc
  module OutgoingConnection
    include RemoteCall
    def receive_message(message)
      id, *marshaled_message = *unmarshal_call(message)
      if marshaled_message.first.is_a?(Exception)
        @errback.call(*marshaled_message) if @errback
      else
        @callback[id].call(*marshaled_message) if @callback
      end
    end

    def remote_call(method, *args, &block)
      id = @msg_id_generator.next
      @callback[id] = block
      send_message(marshal_call(id, method, *args))
    end
  end
end
