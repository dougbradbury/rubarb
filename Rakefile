require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rubarb"
    gem.summary = %Q{A Bidirectional Event Machine Based Remote Procedure Call Library for Ruby}
    gem.description = %Q{This library uses two socket connections between a client and a server. One is used for request / replies from the
client to the server.  The other is used for remote calls made from the server to the client.

Each end publishes a single object on which
methods can be called by the remote end.  All calls to the remote objects are asyncronous.  Do not make any blocking
calls in the published object.  Responses are return by calling the "reply method on the responder object.}

    gem.email = "doug@8thlight.com"
    gem.homepage = "http://github.com/dougbradbury/rubarb"
    gem.authors = ["doug bradbury"]
    gem.add_dependency "eventmachine", ">= 1.0.0.rc.4"
	gem.files = Dir['lib/**/*.rb']
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts << "--timeout" << "8"
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.spec_opts << "--timeout" << "8"
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rubarb-gem #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
