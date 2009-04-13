gems_path `gem env gemdir`.chomp!
ruby_path `which ruby`.chomp!

passenger Mash.new unless attribute?("passenger")
passenger[:version]          = '2.1.3'
passenger[:root_path]        = "#{gems_path}/gems/passenger-#{passenger[:version]}"
passenger[:module_path]      = "#{passenger[:root_path]}/ext/apache2/mod_passenger.so"
passenger[:apache_load_path] = '/etc/apache2/mods-available/passenger.load'
passenger[:apache_conf_path] = '/etc/apache2/mods-available/passenger.conf'
