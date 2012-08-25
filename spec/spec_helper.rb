require 'simplecov'

SimpleCov.start
require 'rubygems'
require 'timeout'

require 'eventmachine'

def start_reactor
  main_thread = Thread.current
  em_thread = Thread.new do
    EventMachine::run do
      main_thread.wakeup
    end
  end
  while !(em_thread.alive? && em_thread.status != "sleep")
    sleep(0.2)
  end
  return em_thread
end


def stop_reactor(reactor)
  return unless EM::reactor_running?
  EM.stop
  reactor.join
rescue Exception => e

end


def wait_for
  Timeout::timeout(5) do
    while !yield
      Thread.pass
    end
  end
  rescue Timeout::Error => e
end

def sync_stop(server)
  return unless server
  stopped = false
  server.stop { stopped = true }
  wait_for { stopped }
end


RSpec.configure do |config|
  config.before(:suite) {$reactor_thread = start_reactor}
  config.after(:suite) {stop_reactor($reactor_thread)}
end


#$DEBUG = true
