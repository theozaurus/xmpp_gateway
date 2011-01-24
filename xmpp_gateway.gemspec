Gem::Specification.new do |s|
  s.name        = "xmpp_gateway"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.author      = "Theo Cushion"
  s.email       = "theo.c@zepler.net"
  s.homepage    = "http://github.com/theozaurus/xmpp_gateway"
  s.summary     = "A server for sending and receiving XMPP stanzas via a HTTP interface"
  s.description = "XmppGateway is a server that allows XMPP stanzas to be posted via HTTP POST requests, it provides a synchronous API for IQ messages so that a reply is included in the body of the response"
 
  s.required_ruby_version     = '>= 1.9.2'
  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_dependency  'blather'
  s.add_dependency  'eventmachine_httpserver'
  
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.mdown)
  s.executables  = ['xmpp_gateway']
  s.require_path = 'lib'
end