db_password = ""
chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
20.times { |i| db_password << chars[rand(chars.size-1)] }

db_apps Mash.new unless attribute?("db_apps")
railsapps Mash.new unless attribute?("railsapps")
(db_apps[:names]                              ||= []) << "browsercms"
railsapps[:browsercms]                        = Mash.new        unless railsapps.has_key?(:browsercms)
railsapps[:browsercms][:db]                   = Mash.new        unless railsapps[:browsercms].has_key?(:db)
railsapps[:browsercms][:db][:user]            = "browsercms_db" unless railsapps[:browsercms][:db].has_key?(:user)
railsapps[:browsercms][:db][:password]        = db_password unless railsapps[:browsercms][:db].has_key?(:password)
railsapps[:browsercms][:db][:database_stem]   = "browsercms" unless railsapps[:browsercms][:db].has_key?(:database_stem)
railsapps[:browsercms][:app]                  = Mash.new        unless railsapps[:browsercms].has_key?(:app)
railsapps[:browsercms][:app][:user]           = "www-data" unless railsapps[:browsercms][:app].has_key?(:user)
railsapps[:browsercms][:app][:group]          = "www-data" unless railsapps[:browsercms][:app].has_key?(:group)
railsapps[:browsercms][:app][:path]           = "/srv/browsercms" unless railsapps[:browsercms][:app].has_key?(:path)
railsapps[:browsercms][:app][:log_dir]        = "/var/log/browsercms" unless railsapps[:browsercms][:app].has_key?(:log_dir)
railsapps[:browsercms][:app][:style]          = "demo" unless railsapps[:browsercms][:app].has_key?(:style)
railsapps[:browsercms][:app][:sitename]       = "site" unless railsapps[:browsercms][:app].has_key?(:sitename)
railsapps[:browsercms][:app][:pool_size]      = "4" unless railsapps[:browsercms][:app].has_key?(:pool_size)
railsapps[:browsercms][:host]                 = `hostname -f`.downcase.strip unless railsapps[:browsercms].has_key?(:host)