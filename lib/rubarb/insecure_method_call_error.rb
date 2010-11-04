module Rubarb
  class InsecureMethodCallError < StandardError
    def initialize(method="")
      @method = method
    end

    def message
      "Remote client attempts to call method #{@method}, but was denied."
    end
  end
end
