run "rm public/index.html"
gem "browser_cms"
run "cp /var/www/browsercms/database.yml config/database.yml"
rake("db:create RAILS_ENV=production")
route "map.routes_for_browser_cms"
generate(:browser_cms)
rake("db:migrate RAILS_ENV=production")