require 'rubygems'
require 'spec'
require 'timeout'

require 'eventmachine'

def start_reactor
  t = Thread.current
  reactor = Thread.new do
    puts "Reactor Thread:  #{Thread.current}"
    EM.run do
      t.wakeup
    end
    puts "EM run finsihed #{Thread.current}"
  end
  sleep(4)
  reactor
end

def stop_reactor(reactor)
  EM::schedule {EM.stop}
  reactor.join
  puts "Reactor Thread closed:  #{Thread.current}"
end

def wait_for

  Timeout::timeout(5) do
    while !yield
      Thread.pass
    end
  end

end

$DEBUG = true