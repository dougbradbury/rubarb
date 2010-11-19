# rubaRb
### A Bidirectional Event Machine Based Remote Procedure Call Library for Ruby

This library uses two socket connections between a client and a server.
One is used for request / replies from the client to the server.
The other is used for remote calls made from the server to the client.

Each end publishes a single object on which methods can be called by the remote end.
All calls to the remote objects are asyncronous.  Do not make any blocking calls in
the published object.  Responses are return by calling the "reply" method on the responder object.

Server and Connection object may be created and started outside of EM::run,
but the Eventmachine reactor must be started somewhere in your application

## Installation

    gem install rubarb

## Server Example

    class ServerApi
      def time(responder)
        puts "Server received time request"
        responder.reply(Time.now)
      end
    end

    EM.run do
      server = Rubarb::Server.new("127.0.0.1", 9441, ServerApi.new)

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

## Client Example

    class ClientApi
      def initialize(name)
        @name = name
      end
      def name(responder)
        responder.reply(@name)
      end
    end

    EM::run do
      connection = Rubarb::Connection.new("127.0.0.1", 9441, ClientApi.new(ARGV[0]))
      connection.errback do |error|
        puts ("Connection Error:  #{error}")
      end

      connection.start do
        connection.time do |response|
          puts "Server Said it is:  #{response.strftime("%D")}"
        end

        EventMachine.add_timer(20) do
          puts "stopping"
          connection.stop
          EM::stop
        end
      end

    end
