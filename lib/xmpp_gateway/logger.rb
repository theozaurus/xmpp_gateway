module XmppGateway

  def self.logger
    @@logger ||= begin
      l = Logger.new($stdout)
      l.level = Logger::INFO
      l
    end
  end

  def self.logger=(logger)
    @@logger = logger
  end
  
end