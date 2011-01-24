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
      if record = connections[@jid.to_s]
        # Connection exists
        @connection = record[:connection]
        @connected  = record[:password] == password
      else
        # Create connection
        @connection = XmppInterface.new(user, password)
        @connected  = @connection.connected
        @connection.client.register_handler(:disconnected) do
          @connected = false
          connections.delete(@jid)
        end
        
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
    
    def connections
      self.class.connections
    end
    
  end
end
