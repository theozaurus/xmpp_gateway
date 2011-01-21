require 'eventmachine'

require_relative 'xmpp_gateway/http_interface'

trap(:INT)  { EventMachine.stop }
trap(:TERM) { EventMachine.stop }

EventMachine.run do
  include XmppGateway

  HttpInterface.start
end