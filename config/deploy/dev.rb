set :rails_env, "development"
set :deployment_host, "lyberapps-dev.stanford.edu"
set :branch, "develop"
set :bundle_without, [:deployment,:production]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true