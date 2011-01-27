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
      reset_keep_alive
      id = @msg_id_generator.next
      @callback ||= {}
      @callback[id] = block
      send_message(marshal_call(id, method, *args))
    end

    def cancel_keep_alive
      EventMachine::cancel_timer(@keep_alive_timer) if @keep_alive_timer
    end

    def reset_keep_alive
      cancel_keep_alive
      @keep_alive_timer = EventMachine::add_timer(@keep_alive_time) do
        send_message(marshal_call(""))
        puts "keep alive"
        reset_keep_alive
      end unless @keep_alive_time == 0 || @keep_alive_time.nil?
    end

  end
end
