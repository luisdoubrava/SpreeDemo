set :database_config, {
   :username => "root", 
   :password => "", 
   :host => "localhost",
   :development => "dev_spreedemo" }

set :rails_env, "development"

#set :deploy_to, "/mnt/data_web/#{application}"
#set :deploy_via, :remote_cache

#set :user, "deployer"
#set :runner, "deployer"
#set :use_sudo, false

#role :app, "webacc1.cg.lan", :primary => true  
#role :db, "sqlacc1.cg.lan", :primary => true