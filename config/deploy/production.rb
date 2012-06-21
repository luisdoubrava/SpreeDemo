set :database_config, {
  :username => "root", 
  :password => "", 
  :host => "127.0.0.1",
  :production => "spreedemo"}

set :deploy_to, "/applications/#{application}/production"
set :deploy_via, :remote_cache

set :user, "admin"
set :runner, "admin"
set :use_sudo, false

role :app, "server.cg.nl", :primary => true  
role :db, "server.cg.nl", :primary => true