$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
#$DEBUG = true
require 'rubygems'
require 'dkbrpc'


class ServerApi
  def time(responder)
    puts "Server received time request"
    responder.reply(Time.now)
  end
end

EM.run do
  server = Dkbrpc::Server.new("127.0.0.1", 9441, ServerApi.new)

  connections = {}

  server.start do |client|
    puts "Connection Made:  #{client}"
    client.name do |name|
      connections[name] = client
      client.errback do
        puts "Connection Lost:  #{name}"
        connections.delete(name)
      end

    end

  end

  EventMachine.add_periodic_timer(1) { puts "Connections:  #{connections.keys.inspect}" }

end
