module Dkbrpc
  class Id

    def self.next
      @id ||= 1
      id = "%08d" % @id
      @id += 1
      id
    end

  end
end
