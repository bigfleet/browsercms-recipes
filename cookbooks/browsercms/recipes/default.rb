#
# Cookbook Name:: browsercms
# Recipe:: default
#
# Copyright 2009, Kane Reid Securities Group, Inc.
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

include_recipe 'mysql'
include_recipe 'apache2'
include_recipe 'passenger'
include_recipe 'gems'

browsercms = node[:browsercms]
user = node[:user]

execute "download-browsercms" do
  command "cd /home/#{user}; git clone git://github.com/browsermedia/browsercms.git"
  creates "/home/#{user}/browsercms"
  action :run
end

execute "install-browsercms" do
  command "cd /home/#{user}/browsercms; rake cms:install"
  creates "/usr/lib/ruby/gems/1.8/gems/browser_cms_blog_module-3.0.0"
  action :run  
end


directory "/var/log/browsercms" do
  action :create
  owner "root"
  group "admin"
  mode 0775
end

directory "/var/www/browsercms" do
  action :create
  owner user
  group "www-data"
  mode 0775  
end

directory "/var/www/browsercms/site" do
  action :create
  owner user
  group "www-data"
  mode 0775  
end

template "/var/www/browsercms/database.yml" do
  owner node[:user]
  mode 0644
  source "database.yml.erb"
  variables({
    :name => "browsercms",
    :passwd => "J4LZE1XYTX30QYL"
  })
end

execute "setup-browsercms" do
  command "umask 002 && rails site -d mysql -m /var/chef/cookbooks/browsercms/files/default/#{browsercms["style"]}_rails_template.rb > results.txt"
  creates "/var/www/browsercms/site/public/"
  group   "www-data"
  cwd     "/var/www/browsercms"
  user    "www-data"
  action :run  
end

passenger_app "public-site" do
  conf( {:env => "production", 
         :server_name => browsercms["server_name"],
         :template => "public.conf.erb",          
         :docroot => browsercms["docroot"],
         :enable => true
         } )
end

passenger_app "admin-site" do
  conf( {:env => "production", 
         :server_name => browsercms["server_name"],
         :template => "admin.conf.erb",
         :docroot => browsercms["docroot"],
         :enable => true
         } )
end