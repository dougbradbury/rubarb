module Rubarb
  module RemoteCall
    def marshal_call(*args)
      Marshal::dump(args)
    end

    def unmarshal_call(data)
      return *Marshal::load(data)
    end

  end
end
