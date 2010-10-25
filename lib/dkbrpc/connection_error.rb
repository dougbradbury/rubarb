module Dkbrpc
  class ConnectionError < StandardError
    def message
      "Connection Failure"
    end
  end
end
