module Rubarb
  class ConnectionError < StandardError
    def initialize(message = "Connection Failure")
      @message = message
    end
    
    def message
      @message
    end
  end
end