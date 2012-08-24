# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'momomoto_helper'

class ApplicationController < ActionController::Base
  include MomomotoHelper
  session :off
  around_filter :transaction_wrapper
  before_filter :automatic_token_check

  rescue_from ActionController::RoutingError, :with => :not_found

  private

  def not_found( exception = nil )
    unless exception.nil?
      logger.info "Not found: #{exception.message}"
    end

    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

  protected

  def local( tag, arguments = {} )
    Localizer.lookup( tag.to_s, @current_language, arguments )
  end

  # ensure user has a current conference set and proper permissions for the current conference
  def check_current_conference
    if POPE.user.current_conference_id &&
       POPE.conference_permission?( 'pentabarf::login', POPE.user.current_conference_id )
      yield
    else
      redirect_to(:controller=>'conference',:action=>:select)
    end
  end

  def transaction_wrapper
    response.content_type ||= Mime::HTML
    Momomoto::Database.instance.transaction do
      if auth
        # if auth succeeds we continue
        yield
      elsif not performed? then
        # if auth failed and nothing has been rendered we return 401
        response.headers["Status"] = "Unauthorized"
        response.headers["WWW-Authenticate"] = "Basic realm=Pentabarf"
        render( :file=>'auth_failed.rxml',:status=>401,:content_type=>'text/html' )
      end
      POPE.deauth
    end
  end

  def rescue_action_in_public( exception )
    @meditation_message = exception.message
    render :file => File.join( RAILS_ROOT, '/app/views/meditation.rhtml' )
  end

  # extract authorization credentials from http header
  def http_auth_data
    ['X-HTTP_AUTHORIZATION','HTTP_AUTHORIZATION','REDIRECT_X_HTTP_AUTHORIZATION','Authorization'].each do | key |
      if request.env.has_key?( key )
        authdata = request.env[ key ].to_s.split
        if authdata[0] == 'Basic'
          user, pass = Base64.decode64(authdata[1]).split(':', 2)[0..1]
          user = Iconv.iconv( 'UTF-8', 'iso-8859-1', user.to_s ).first
          pass = Iconv.iconv( 'UTF-8', 'iso-8859-1', pass.to_s ).first
          return user, pass
        end
        break
      end
    end
    return '', ''
  end

  def auth
    user, pass = http_auth_data
    POPE.auth( user, pass )
    return check_permission
   rescue => e
    logger.warn( e.to_s ) unless e.class == Pope::NoUserData
    return false
  end

  # protect save,copy and delete functions with token
  def automatic_token_check
    if params[:action].match(/^(save|delete|copy)/)
      return check_token
    end
    true
  end

  # validate submitted token
  def check_token
    token = Token.generate( url_for(:only_path=>true) )
    if token != params[:token]
      logger.warn( "Wrong token for #{url_for({})} from #{request.remote_ip}" )
      return false
    else
      return true
    end
  end

  def log_error( exception, verbose = false )
    super( exception )

    message = ''
    message += "User: #{POPE.user.login_name}\n" if POPE.user
    message += "Time: #{Time.now.to_s}\n"
    message += "UA: #{request.env['HTTP_USER_AGENT']}\nIP: #{request.remote_ip}\n"
    message += "URL: https://#{request.host + request.request_uri}\n"
    message += "Exception: #{exception.message}\n"
    message += "Exception Class: #{exception.class}\n"
    if verbose
      message += "Backtrace:\n" + clean_backtrace(exception).join("\n") +
                 "Request: #{filter_parameters(params).inspect}\n"
    end

    begin
      JabberLogger.log( message )
    rescue => e
      logger.error(e)
    end

    # always include backtrace in exception mails
    if not verbose
      message += "Backtrace:\n" + clean_backtrace(exception).join("\n") +
                 "Request: #{filter_parameters(params).inspect}\n"
    end

    begin
      MailLogger.log( exception.message, message )
    rescue => e
      logger.error(e)
    end

  end

  def update_last_login
    yield
    POPE.user.last_login = 'now()'
    POPE.user.write
  end

end

