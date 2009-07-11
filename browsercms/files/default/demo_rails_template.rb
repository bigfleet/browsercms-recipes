run "rm public/index.html"
gem "browser_cms"
run "cp /var/www/browsercms/database.yml config/database.yml"
rake("db:create")
route "map.routes_for_browser_cms"
generate(:browser_cms)
generate(:browser_cms_demo_site)
rake("db:migrate")