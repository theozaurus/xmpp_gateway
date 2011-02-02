require "fiber"
require "blather/client/client"

module XmppGateway
  class XmppInterface
    
    attr_reader :client
    attr_reader :connected
    
    def self.stanza(stanza)
      noko = Nokogiri::XML::Document.parse( stanza ).root
      return nil unless noko
      blather = Blather::XMPPNode.import( noko )
      return nil if blather.class == Blather::XMPPNode # This means it isn't a valid presence, iq or message stanza
      return blather
    end
    
    def initialize(user,password)
      @jid = Blather::JID.new(user)
      
      f = Fiber.current
      
      @client = Blather::Client.setup @jid, password  
      @client.register_handler(:ready) do
        @connected = true
        f.resume( @connected ) if f.alive?
      end
      @client.register_handler(:disconnected) do
        XmppGateway.logger.debug "XMPP connection #{@jid} disconnected"
        @connected = false
        f.resume( @connected ) if f.alive?
        # Prevent EventMachine from stopping by returning true on disconnected
        true
      end
      @client.clear_handlers(:error)
      @client.register_handler(:error){ f.resume( false ) if f.alive? }
       
      begin
        @client.run
      rescue
        @connected = false
      end
      
      # Waits until it has connected unless an error was thrown
      @connected = Fiber.yield if @connected.nil?
      
      schedule_activity_monitor
      
      XmppGateway.logger.debug "XMPP connection #{@jid} #{@connected ? '' : 'not '}connected"
    end
    
    def write(stanza)
      XmppGateway.logger.debug "Sending stanza #{stanza.to_s}"
      
      f = Fiber.current

      @client.write_with_handler( stanza ){|result|
        f.resume(result) if f.alive?
      }
      
      if reply_expected stanza
        # Remove timer while we wait for response
        cancel_timer
        reply = Fiber.yield
        XmppGateway.logger.debug "Received #{reply}"
        # Schedule new timer
        schedule_activity_monitor
        return reply
      end
      
      schedule_activity_monitor
    end
    
  private    

    def schedule_activity_monitor
      cancel_timer
      @timer = EventMachine::Timer.new(60) do
        XmppGateway.logger.debug "XMPP connection #{@jid} inactive for over 60 seconds"
        @client.close if @connected
      end if @connected
    end
    
    def cancel_timer
      @timer.cancel if @timer
    end

    def reply_expected(stanza)
      stanza.is_a? Blather::Stanza::Iq
    end
  
  end
  
end