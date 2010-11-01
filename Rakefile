require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dkbrpc"
    gem.summary = %Q{A Bidirectional Event Machine Based Remote Procedure Call Library for Ruby}
    gem.description = %Q{This library uses two socket connections between a client and a server. One is used for request / replies from the
client to the server.  The other is used for remote calls made from the server to the client.

Each end publishes a single object on which
methods can be called by the remote end.  All calls to the remote objects are asyncronous.  Do not make any blocking
calls in the published object.  Responses are return by calling the "reply method on the responder object.}
    
    gem.email = "doug@8thlight.com"
    gem.homepage = "http://github.com/dougbradbury/dkbrpc"
    gem.authors = ["doug"]
    gem.add_development_dependency "rspec", ">= 1.3.0"
    gem.add_dependency "eventmachine", ">= 0.12.11"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "dkbrpc-gem #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
