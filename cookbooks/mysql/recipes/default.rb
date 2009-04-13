#
# Cookbook Name:: mysql
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

package "mysql-server" do
  action :install
end

service "mysql" do
  supports :restart => true
  action :enable
end

execute "change-mysql-root-passwd" do
  passwd = random_string(15)
  command "mysqladmin password -u root #{passwd} && echo #{passwd} > /usr/mysql.pass"
  creates "/usr/mysql.pass"
  action :run
end
