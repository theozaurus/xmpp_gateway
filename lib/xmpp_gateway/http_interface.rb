require 'evma_httpserver'
require 'base64'
require 'cgi'

require_relative 'xmpp_pool'

module XmppGateway
  class HttpInterface < EM::Connection

    include EM::HttpServer

    def self.start(host = '127.0.0.1', port = 8000)
      EM.start_server(host, port, self)
    end
    
    def acceptable_method?
      %w(GET POST).include? @http_request_method
    end

    def process_http_request
      # the http request details are available via the following instance variables:
      #   @http_protocol
      #   @http_request_method
      #   @http_cookie
      #   @http_if_none_match
      #   @http_content_type
      #   @http_path_info
      #   @http_request_uri
      #   @http_query_string
      #   @http_post_content
      #   @http_headers
      
      Fiber.new{        
        if acceptable_method?
          user, password = credentials
          @connection = XmppPool.new( user, password )
          if @connection.connected
            case @http_request_method
            when "GET"
              get.send_response
            when "POST"
              stanza = XmppPool.stanza(post_params['stanza'])
              if stanza
                result = @connection.write stanza
                response(result).send_response
              else
                bad_request.send_response
              end
            else
              # acceptable_method should have stopped us arriving here
              # battle on bravely
              method_not_allowed.send_response
            end
          else
            unauthorized.send_response
          end
        else
          method_not_allowed.send_response 
        end
      }.resume
    end
    
    def headers
      @headers ||= Hash[@http_headers.split("\000").map{|kv| kv.split(':',2).map{|v| v.strip} }]
    end
    
    def basic_auth
      @_basic_auth ||= ( headers['Authorization'] || '' ).match(/\ABasic +(.+)\Z/).to_a[1]
    end
    
    def post_params
      @_post_params ||= Hash[@http_post_content.split('&').map{|kv| kv.split('=',2).map{|v| CGI.unescape v } }]
    end
    
    def credentials
      if basic_auth
        Base64.decode64(basic_auth).split(':')
      end
    end
    
    def response(stanza)
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'application/xml'
      response.content = stanza
      return response
    end
    
    def unauthorized
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 401
      response.content_type 'text/html'
      response.headers = {"WWW-Authenticate" => 'Basic realm="Secure Area"'}
      response.content = "Unauthorised"
      return response
    end
    
    def method_not_allowed
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 405
      response.content_type 'text/html'
      response.content = "Method not allowed"
      return response
    end
    
    def bad_request
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 400
      response.content_type 'text/html'
      response.content = "Please send a valid stanza"
      return response
    end
    
    def get
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'      
      response.content = 
      "<h1>Enter Stanza</h1>" + 
      "<form method='post'>" +
        "<label for='stanza'>Stanza</label>" +
        "<textarea name='stanza' cols=50 rows=20>" +
          "<iq type='get'\n" +
          "    to='#{@connection.client.jid.domain}'\n" +
          "    id='info1'>\n" +
          "  <query xmlns='http://jabber.org/protocol/disco#info'/>\n" +
          "</iq>" +
        "</textarea>" +
        "<input type='submit' value='Submit'/>" +
      "</form>"
      return response
    end
  
  end
end