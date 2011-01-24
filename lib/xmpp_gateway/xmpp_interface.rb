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
      jid = Blather::JID.new(user)
      
      f = Fiber.current
      
      @client = Blather::Client.setup jid, password  
      @client.register_handler(:ready) do
        @connected = true
        f.resume( @connected ) if f.alive?
      end
      @client.register_handler(:disconnected) do
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
      
      XmppGateway.logger.debug "XMPP connection #{jid} #{@connected ? '' : 'not '}connected"
    end
    
    def write(stanza)
      XmppGateway.logger.debug "Sending stanza #{stanza.to_s}"
      
      f = Fiber.current

      @client.write_with_handler( stanza ){|result|
        f.resume(result) if f.alive?
      }
      
      if reply_expected stanza
        reply = Fiber.yield
        XmppGateway.logger.debug "Received #{reply}"
        return reply
      end
    end
    
  private    

    def reply_expected(stanza)
      stanza.is_a? Blather::Stanza::Iq
    end
  
  end
  
end