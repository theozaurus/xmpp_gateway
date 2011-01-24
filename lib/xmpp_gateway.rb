require 'eventmachine'

require_relative 'xmpp_gateway/http_interface'
require_relative 'xmpp_gateway/logger'

trap(:INT)  { EventMachine.stop }
trap(:TERM) { EventMachine.stop }

EventMachine.run do
  include XmppGateway

  HttpInterface.start
end

XmppGateway.logger.info("Stopped server")