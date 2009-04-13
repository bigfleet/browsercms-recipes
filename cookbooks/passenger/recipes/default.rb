require_recipe "apache2"

# Required to compile passenger
package "apache2-prefork-dev"

gem_package "passenger" do
  version node[:passenger_version]
end

execute "passenger_module" do
  command 'echo -en "\n\n\n\n" | passenger-install-apache2-module'
  creates node[:passenger][:module_path]
end

template node[:passenger][:apache_load_path] do
  source "passenger.load.erb"
  owner "root"
  group "root"
  mode 0755
end

template node[:passenger][:apache_conf_path] do
  source "passenger.conf.erb"
  owner "root"
  group "root"
  mode 0755
end

apache_module "passenger"
include_recipe "apache2::mod_deflate"
include_recipe "apache2::mod_rewrite"