#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: Apache License, Version 2.0
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

require File.join(File.dirname(__FILE__), 'config', 'rake')

require 'tempfile'

$vcs = :svn
if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end


desc "Update your repository from source control"
task :update do
  puts "** Updating your repository"

  case $vcs
  when :svn
    sh %{svn up}
  when :git
    pull = false
    pull = true if File.join(TOPDIR, ".git", "remotes", "origin")
    IO.foreach(File.join(TOPDIR, ".git", "config")) do |line|
      pull = true if line =~ /\[remote "origin"\]/
    end
    if pull
      sh %{git pull} 
    else
      puts "* Skipping git pull, no origin specified"
    end
  end
end

desc "Test your cookbooks for syntax errors"
task :test do
  puts "** Testing your cookbooks for syntax errors"
  Dir[ File.join(TOPDIR, "cookbooks", "**", "*.rb") ].each do |recipe|
    sh %{ruby -c #{recipe}} do |ok, res|
      if ! ok
        raise "Syntax error in #{recipe}"
      end
    end
  end
end


desc "Install the latest copy of the repository on this Chef Server"
task :install => [ :update, :test ] do
  puts "** Installing your cookbooks"  
  directories = [ 
    COOKBOOK_PATH,
    SITE_COOKBOOK_PATH,
    CHEF_CONFIG_PATH
  ]
  puts "* Creating Directories"
  directories.each do |dir|
    sh "sudo mkdir -p #{dir}"
    sh "sudo chown root:root #{dir}"
  end
  puts "* Installing new Cookbooks"
  sh "sudo rsync -rlP --delete --exclude '.svn' cookbooks/ #{COOKBOOK_PATH}"
  puts "* Installing new Site Cookbooks"
  sh "sudo rsync -rlP --delete --exclude '.svn' cookbooks/ #{COOKBOOK_PATH}"
  puts "* Installing new Chef Server Config"
  sh "sudo cp config/server.rb #{CHEF_SERVER_CONFIG}"
  puts "* Installing new Chef Client Config"
  sh "sudo cp config/client.rb #{CHEF_CLIENT_CONFIG}"
end

desc "By default, run rake test"
task :default => [ :test ]

desc "Create a new cookbook (with COOKBOOK=name)"
task :new_cookbook do
  create_cookbook(File.join(TOPDIR, "cookbooks"))
end

def create_cookbook(dir)
  raise "Must provide a COOKBOOK=" unless ENV["COOKBOOK"]
  puts "** Creating cookbook #{ENV["COOKBOOK"]}"
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "attributes")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "recipes")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "definitions")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "libraries")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "files", "default")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "templates", "default")}" 
  unless File.exists?(File.join(dir, ENV["COOKBOOK"], "recipes", "default.rb"))
    open(File.join(dir, ENV["COOKBOOK"], "recipes", "default.rb"), "w") do |file|
      file.puts <<-EOH
#
# Cookbook Name:: #{ENV["COOKBOOK"]}
# Recipe:: default
#
# Copyright #{Time.now.year}, #{COMPANY_NAME}
#
EOH
      case NEW_COOKBOOK_LICENSE
      when :apachev2
        file.puts <<-EOH
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
EOH
      when :none
        file.puts <<-EOH
# All rights reserved - Do Not Redistribute
#
EOH
      end
    end
  end
end

desc "Create a new self-signed SSL certificate for FQDN=foo.example.com"
task :ssl_cert do
  $expect_verbose = true
  fqdn = ENV["FQDN"]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  raise "Must provide FQDN!" unless fqdn && hostname && domain
  puts "** Creating self signed SSL Certificate for #{fqdn}"
  sh("(cd #{CADIR} && openssl genrsa 2048 > #{fqdn}.key)")
  sh("(cd #{CADIR} && chmod 644 #{fqdn}.key)")
  puts "* Generating Self Signed Certificate Request"
  tf = Tempfile.new("#{fqdn}.ssl-conf")
  ssl_config = <<EOH
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C                      = #{SSL_COUNTRY_NAME}
ST                     = #{SSL_STATE_NAME}
L                      = #{SSL_LOCALITY_NAME}
O                      = #{COMPANY_NAME}
OU                     = #{SSL_ORGANIZATIONAL_UNIT_NAME}
CN                     = #{fqdn}
emailAddress           = #{SSL_EMAIL_ADDRESS}
EOH
  tf.puts(ssl_config)
  tf.close
  sh("(cd #{CADIR} && openssl req -config '#{tf.path}' -new -x509 -nodes -sha1 -days 3650 -key #{fqdn}.key > #{fqdn}.crt)")
  sh("(cd #{CADIR} && openssl x509 -noout -fingerprint -text < #{fqdn}.crt > #{fqdn}.info)")
  sh("(cd #{CADIR} && cat #{fqdn}.crt #{fqdn}.key > #{fqdn}.pem)")
  sh("(cd #{CADIR} && chmod 644 #{fqdn}.pem)")
end