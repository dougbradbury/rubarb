require "rubarb/remote_call"

module Rubarb
  module OutgoingConnection
    include RemoteCall

    def receive_message(message)
      id, *unmarshaled_message = *unmarshal_call(message)
      if unmarshaled_message.first.is_a?(Exception)
        call_errbacks(*unmarshaled_message)
      else
        if @callback[id]
          @callback[id].call(*unmarshaled_message)
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
