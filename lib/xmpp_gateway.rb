require 'optparse'

options = {
  bind: '127.0.0.1',
  port: '8000'
}

optparse = OptionParser.new do |opts|
  opts.banner = "Run with #{$0}"

  opts.on('-b', '--bind', "What address to bind to, by default #{options[:bind]}") do |bind|
    options[:bind] = bind
  end
  
  opts.on('-p', '--port', "What port to bind to, by default #{options[:port]}") do |port|
    options[:port] = port
  end

  opts.on('-D', '--debug', 'Run in debug mode') do
    options[:debug] = true
  end

  opts.on('-d', '--daemonize', 'Daemonize the process') do |daemonize|
    options[:daemonize] = daemonize
  end

  opts.on('-p', '--pid', 'Write the PID to this file') do |pid|
    if !File.writable?(File.dirname(pid))
      $stderr.puts "Unable to write log file to #{pid}"
      exit 1
    end
    options[:pid] = pid
  end

  opts.on('-l', '--log', 'Write the Log to this file instead of stdout/stderr') do |log|
    if !File.writable?(File.dirname(log))
      $stderr.puts "Unable to write log file to #{log}"
      exit 1
    end
    options[:log] = log
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
  
end
optparse.parse!

at_exit do
    
  def run(options)
    require_relative 'xmpp_gateway/http_interface'
    require_relative 'xmpp_gateway/logger'
    
    $stdin.reopen "/dev/null"

    if options[:log]
      log = File.new(options[:log], 'a')
      log.sync = options[:debug]
      $stdout.reopen log
      $stderr.reopen $stdout
    end

    XmppGateway.logger.level = Logger::DEBUG if options[:debug]

    trap(:INT)  { EventMachine.stop }
    trap(:TERM) { EventMachine.stop }

    EventMachine.run do
      include XmppGateway

      HttpInterface.start(options[:bind],options[:port])
    end
    XmppGateway.logger.info("Stopped server")
  end

  if options[:daemonize]
    pid = fork do
      Process.setsid
      exit if fork
      File.open(options[:pid], 'w') { |f| f << Process.pid } if options[:pid]
      run options
      FileUtils.rm(options[:pid]) if options[:pid]
    end
    ::Process.detach pid
    exit
  else
    run options
  end
  
end