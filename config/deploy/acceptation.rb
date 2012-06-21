set :database_config, {
  :username => "root", 
  :password => "", 
  :host => "sqlacc1",
  :acceptation => "acc_spreedemo" }

set :rails_env, "acceptation"

set :deploy_to, "/mnt/data_web/#{application}"
set :deploy_via, :remote_cache

set :user, "deployer"
set :runner, "deployer"
set :group, "www-data"
set :use_sudo, false
set :rvm_install_with_sudo, true

server "10.0.0.217", :app, :web, :db, :primary => true
