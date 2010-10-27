module Dkbrpc
  class Id
    def initialize
      @id ||= 1
    end

    def next
      id = "%08d" % @id
      @id += 1
      id
    end
  end
end
