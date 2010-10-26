require 'rubygems'
require 'spec'
require 'timeout'

require 'eventmachine'

def start_reactor
  t = Thread.current
  reactor = Thread.new do
    EM.run do
      t.wakeup
    end
  end
  sleep(4)
  reactor
end

def stop_reactor(reactor)
  EM::schedule {EM.stop}
  reactor.join
end

def wait_for
  Timeout::timeout(5) do
    while !yield
      Thread.pass
    end
  end
rescue Timeout::Error => e
  fail("timeout waiting ...")
end

#$DEBUG = true
