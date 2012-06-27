# Add RVM's lib directory to the load path.
#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

set :stages, %w(acceptation production)
set :default_stage, "acceptation"

# Load RVM's capistrano plugin.
require 'rvm/capistrano'

require 'capistrano/ext/multistage'
#require 'bundler/capistrano'

# Let Capistrano take care of assets precompilation
load "deploy/assets"

# Set it to the ruby + gemset of your app, e.g:
set :rvm_ruby_string, 'ruby-1.9.3-p125@spreedemo'
set :rvm_type, :system

set :application, "SpreeDemo"

# Use Git source control
set :scm, :git 
set :scm_verbose, true
set :scm_username, "pietercg"
set :repository, "git@github.com:Pietercg/SpreeDemo.git"
set :git_enable_submodules, 1
set :copy_exclude, ["spec"]

# Deploy from master branch by default
set :branch, "master"
set :deploy_via, :remote_cache

# Settings for passenger environment
set :passenger_port, 3009
set :passenger_cmd, "passenger"

# SSH options to host
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

# bug: `gsub': invalid byte sequence in US-ASCII 1.9.2
# fix: https://github.com/capistrano/capistrano/issues/70
set :default_environment, {'LANG' => 'en_US.UTF-8'}

# bug: capistrano probeert oude public mappen te linken die niet bestaan
# fix: https://github.com/capistrano/capistrano/issues/79
set :normalize_asset_timestamps, false

# ----------------------------------------------------------------------------------------------------------------------------
# Deploy procedure
# ----------------------------------------------------------------------------------------------------------------------------
namespace :deploy do
  
  # Setup database.yml file
  desc "Setup database.yml in the #{deploy_to} directory."
  task :setup_database_config, :roles => [:app] do
    db_pw = Capistrano::CLI.ui.ask "Database password: "
    db = database_config.update(:password => db_pw)
    put ERB.new(DatabaseYml).result(binding), "#{deploy_to}/database.yml"
  end
  
  #  Push database.yml to application configuration location 
  desc "Push database.yml to configuration location."
  task :copy_database_config_to_current, :roles => [:app] do
    run "cp #{deploy_to}/database.yml #{release_path}/#{application}/config/database.yml"
  end
 
  # Restarting application
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
#  # Create gemset
#  desc "Create the gemset"
#  task :create_gemset do
#    run "rvm #{rvm_ruby_string} --create"
#  end
  
  # Create RVM wrapper
  desc "Create the RVM wrapper"
  task :create_wrapper do
    run "rvm wrapper #{rvm_ruby_string} #{application.downcase}"
  end
  
  # Starting / stoping Passenger  
  [:start, :stop].each do |t|
     desc "#{t} task isn't needed for Passenger"
     task t, :roles => :app do
       # nothing
     end
  end
  
  # Database migration
  desc "Execute database migrations"
  task :migrate, :roles => [:db] do
    run "bundle exec rake db:migrate"
  end 
  
end

namespace :bundler do
  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(release_path, '.bundle')
    run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
  end

  task :install, :roles => :app do
    run "cd #{release_path}/#{application} && bundle install"

    on_rollback do
      if previous_release
        run "cd #{previous_release} && bundle install"
      else
        logger.important "no previous release to rollback to, rollback of bundler:install skipped"
      end
    end
  end

  task :bundle_new_release, :roles => :db do
    bundler.create_symlink
    bundler.install
  end
end

namespace :rvmrc do
  desc 'Trust rvmrc file'
  task :trust_rvmrc do
    run "rvm rvmrc trust #{current_release}/#{application}"
  end
  desc 'Create rvmrc file'
  task :create_rvmrc do
    run "echo 'rvm use #{rvm_ruby_string} --create' > #{current_release}/#{application}/.rvmrc"
  end
end

# Before and Afters
before "deploy:setup", "rvm:install_rvm"
before "deploy:setup", "rvm:install_ruby"
before "deploy:setup", "deploy:create_wrapper"

after "deploy:setup", "deploy:setup_database_config"
after "deploy:update_code", "deploy:copy_database_config_to_current"
after "deploy", "deploy:cleanup"
after "deploy:rollback:revision", "bundler:install"
after "deploy:update_code", "rvmrc:create_rvmrc"
after "deploy:update_code", "rvmrc:trust_rvmrc"
after "deploy:update_code", "bundler:bundle_new_release"

# ----------------------------------------------------------------------------------------------------------------------------
# Creating Database.yml file
# ----------------------------------------------------------------------------------------------------------------------------
DatabaseYml = <<EOS
# MySQL (default setup).  Versions 4.1 and 5.0 are recommended.

db: &db
  adapter: mysql2
  encoding: utf8
  reconnect: falserails
  username: <%= db[:username] %>
  password: <%= db[:password] %>
  host: <%= db[:host] %>
  
development:
  <<: *db
  database: <%= db[:development] %>
  	
test:
  <<: *db
  database: core_test
  
acceptation:
  <<: *db
  database: <%= db[:acceptation] %>

production:
  <<: *db
  database: <%= db[:production] %>
EOS