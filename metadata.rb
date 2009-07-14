name    "broswercms"
description 'Run a browsercms instance on this node'
depends "apache2::mod_rails"
depends "apt"
depends "gems"
depends "git"
depends "passenger"
maintainer 'Jim Van Fleet'
maintainer_email 'jvanfleet@tradeking.com'