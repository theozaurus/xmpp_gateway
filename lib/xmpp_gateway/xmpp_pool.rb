require_relative 'xmpp_interface'

module XmppGateway
  class XmppPool
    
    attr_reader :connected
    
    def self.stanza(s)
      XmppInterface.stanza s
    end
    
    def self.connections
      @@connections ||= {}
    end
    
    def initialize(user, password)
      @jid = Blather::JID.new(user)
      
      if stale?
        XmppGateway.logger.debug "Stale XMPP connection #{@jid}"
        connections.delete @jid.to_s
      end
      
      if record = connections[@jid.to_s]
        # Connection exists
        XmppGateway.logger.debug "Reusing XMPP connection #{@jid}"
        
        @connection = record[:connection]
        @connected  = record[:password] == password
      else
        # Create connection
        XmppGateway.logger.debug "Creating XMPP connection #{@jid}"
        
        @connection = XmppInterface.new(user, password)
        @connected  = @connection.connected
        
        if @connected
          # Cache the connection
          connections[@jid.to_s] = {:password => password, :connection => @connection}
        end
      end
    end
    
    def client
      @connection.client
    end
    
    def write(s)
      @connection.write(s)
    end
    
  private
  
    def stale?
      connections[@jid.to_s] && !connections[@jid.to_s][:connection].connected
    end
    
    def connections
      self.class.connections
    end
    
  end
end
