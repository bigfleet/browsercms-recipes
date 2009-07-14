#
# Cookbook Name:: browsercms
# Recipe:: default
#
# Copyright 2009, Jim Van Fleet
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "passenger_apache2::mod_rails"
include_recipe "mysql::client"

application_user = node[:railsapps][:browsercms][:user]

%w{browsercms mysql}.each do |gem_dep|
  gem_package gem_dep
end

["#{node[:railsapps][:browsercms][:app][:log_dir]}",
 "#{node[:railsapps][:browsercms][:app][:path]}",
 "#{node[:railsapps][:browsercms][:app][:path]}/#{node[:railsapps][:browsercms][:app][:sitename]}",
 "#{node[:railsapps][:browsercms][:app][:path]}/#{node[:railsapps][:browsercms][:app][:sitename]}/config"].each do |dir_name|
   directory dir_name do
     owner application_user
     group node[:railsapps][:browsercms][:app][:group]
     mode 0775
   end
end

# Setting a database host in the style of bigfleet/kitchen
database_nodes = search(:node, "railsapps_database:*")
Chef::Log.info "Inspecting #{database_nodes.size} nodes for database host information"
hashes = database_nodes.collect{ |rslt| rslt[:railsapps][:database] }
results = hashes.uniq.reject{ |r| r.empty? }
Chef::Log.info "Found #{results.inspect}"
db_host = results.first


template "#{node[:railsapps][:browsercms][:app][:path]}/#{node[:railsapps][:browsercms][:app][:sitename]}/config/database.yml" do
  source "database.yml.erb"
  owner    application_user
  group    node[:railsapps][:browsercms][:app][:group]
  variables :database => node[:railsapps][:browsercms][:db][:database], 
            :passwd => node[:railsapps][:browsercms][:db][:password],
            :user   => node[:railsapps][:browsercms][:db][:user],
            :host   => db_host || "localhost"
  mode "0664"
end

current_path = "#{node[:railsapps][:browsercms][:app][:path]}/#{node[:railsapps][:browsercms][:app][:sitename]}/public/"

execute "setup-browsercms" do
  command "rails #{node[:railsapps][:browsercms][:app][:sitename]} -d mysql -m http://browsercms.org/templates/#{node[:railsapps][:browsercms][:app][:style]}.rb"
  creates current_path
  group   "#{node[:railsapps][:browsercms][:app][:group]}"
  cwd     "#{node[:railsapps][:browsercms][:app][:path]}"
  user    application_user
  action :run
  umask   002
end

web_app "public-site" do
  docroot current_path
  server_name node[:railsapps][:browsercms][:host]
  log_dir node[:railsapps][:browsercms][:app][:log_dir]
  max_pool_size node[:railsapps][:browsercms][:app][:pool_size]
  rails_env "production"
  template "public.conf.erb"
end

web_app "admin-site" do
  docroot current_path
  server_name node[:railsapps][:browsercms][:host]
  log_dir node[:railsapps][:browsercms][:app][:log_dir]
  max_pool_size node[:railsapps][:browsercms][:app][:pool_size]  
  rails_env "production"
  template "admin.conf.erb"
end

apache_site "default" do
  enable false
end

# append config.action_controller.page_cache_directory = RAILS_ROOT + "/public/cache/" to config/environments/production.rb