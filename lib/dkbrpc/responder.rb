module Dkbrpc
  class Responder
    attr_reader :message_id
    attr_reader :incoming_connection
    def initialize(incoming_connection, message_id)
      @incoming_connection = incoming_connection
      @message_id = message_id
    end

    def reply(*args)
      @incoming_connection.reply(@message_id, *args)
    end
  end
end
