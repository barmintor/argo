RubyDorServices::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.middleware.use(Rack::Webauth)
  cert_dir = File.expand_path(File.join(File.dirname(__FILE__),"../certs"))

  Dor::Config.configure do
    fedora do
      url 'https://fedoraAdmin:1y83r73am@dor.stanford.edu/fedora'
      cert_file File.join(cert_dir,"argo-client.crt")
      key_file File.join(cert_dir,"argo-client.key")
      key_pass ''
    end

    workflow.url 'https://lyberservices-test.stanford.edu/workflow/'
    gsearch.url 'https://dor-test.stanford.edu/solr'

    suri do
      mint_ids true
      id_namespace 'druid'
      url 'https://lyberservices-test.stanford.edu:8080'
      user 'labware'
      pass 'lyberteam'
    end

    metadata do
      exist.url 'http://viewer:l3l%40nd@lyberapps-prod.stanford.edu/exist/rest'
      catalog.url 'http://lyberservices-prod.stanford.edu/catalog/mods'
    end
  end
end
