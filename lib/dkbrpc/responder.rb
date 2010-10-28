module Dkbrpc
  class Responder
    attr_reader :message_id
    attr_reader :handler
    def initialize(handler, message_id)
      @handler = handler
      @message_id = message_id
    end

    def conn_id
      @handler.conn_id
    end

    def reply(*args)
      @handler.reply(@message_id, *args)
    end
  end
end
