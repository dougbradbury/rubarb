$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
#$DEBUG = true
require 'rubygems'
require 'rubarb'


class ServerApi
  def time(responder)
    puts "Server received time request"
    responder.reply(Time.now)
  end
end

EM.run do
  server = Rubarb::Server.new("127.0.0.1", 9447, ServerApi.new, Rubarb::Default::INSECURE_METHODS, 2)

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
