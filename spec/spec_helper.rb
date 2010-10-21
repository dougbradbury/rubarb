require 'rubygems'
require 'spec'


require 'eventmachine'
def start_reactor
  t = Thread.current
  reactor = Thread.new do
    EM.run do
      t.wakeup
    end
  end
  sleep(3)
  reactor
end

def stop_reactor(reactor)
  EM.stop
  reactor.join
end

$DEBUG = true