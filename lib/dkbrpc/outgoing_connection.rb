require "dkbrpc/remote_call"

module Dkbrpc
  module OutgoingConnection
    include RemoteCall
    def receive_message(message)
      id, *marshaled_message = *unmarshal_call(message)
      if marshaled_message.first.is_a?(Exception)
        @errback.call(*marshaled_message) if @errback
      else
        if @callback
          @callback[id].call(*marshaled_message)
          @callback.delete(id)
        end
      end
    end

    def remote_call(method, *args, &block)
      id = @msg_id_generator.next
      @callback ||= {}
      @callback[id] = block
      send_message(marshal_call(id, method, *args))
    end
  end
end
