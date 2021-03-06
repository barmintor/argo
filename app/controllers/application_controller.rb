class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  before_filter :authorize!
  before_filter :fedora_setup

  helper_method :current_or_guest_user
  
  include Rack::Webauth::Helpers

  attr_reader :help
  
  def initialize(*args)
    super
    
    klass_chain = self.class.name.sub(/Controller$/,'Helper').split(/::/)
    klass = nil
    begin
      klass = Module.const_get(klass_chain.shift)
      while klass_chain.length > 0
        klass = klass.const_get(klass_chain.shift)
      end
    rescue NameError
      klass = nil
    end
    @help = Class.new {
      include klass unless klass.nil?
      include ApplicationHelper
    }.new
    self
  end
  
  def current_user
    if webauth and webauth.logged_in?
      User.find_or_create_by_webauth(webauth)
    elsif request.env['REMOTE_USER']
      User.find_or_create_by_remoteuser(request.env['REMOTE_USER'])
    else
      nil
    end
  end

  def current_or_guest_user
    current_user
  end
  
  def user_session
    session
  end

  def default_html_head
    stylesheet_links << ['argo']
  end
  
  protected
  def munge_parameters
    case request.content_type
    when 'application/xml','text/xml'
      help.merge_params(Hash.from_xml(request.body.read))
    when 'application/json','text/json'
      help.merge_params(JSON.parse(request.body.read))
    end
  end

  def fedora_setup
    Dor::Config.fedora.post_config
  end

  def development_only!
    if Rails.env.development? or ENV['DOR_SERVICES_DEBUG_MODE']
      yield
    else
      render :text => 'Not Found', :status => :not_found
    end
  end
  
  def authorize!
    unless current_user
      redirect_to "#{auth_login_url}?return=#{request.fullpath.sub(/reset_webauth=true&?/,'')}" 
      return false
    end
    return true
  end

end
