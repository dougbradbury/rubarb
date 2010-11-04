module Rubarb
  class Id
    def initialize
      @id ||= 1
    end

    def next
      id = "%08d" % @id
      @id = @id == 99999999 ? 1 : @id + 1
      id
    end
  end
end
