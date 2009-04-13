set :scm, :git
set :project, 'browsercms-recipes'

task :ec2 do
  set :user,  'ubuntu'
  set :password, '12dc3d02'
  role :app,  'ec2-67-202-61-35.compute-1.amazonaws.com'
end

namespace :bootstrap do
  desc <<-DESC
  Install all packages required to get rolling, depending on Chef for majority of setup
  DESC
  task :prereqs, :roles => :app do
    sudo 'apt-get update'
    sudo 'apt-get install -y git-core ruby ruby1.8-dev rubygems libopenssl-ruby1.8 libshadow-ruby1.8 build-essential wget'
  end
  
  task :replace_rubygems, :roles => :app do
    run <<-CMD
      cd /tmp &&
      wget http://rubyforge.org/frs/download.php/45904/rubygems-update-1.3.1.gem &&
      sudo gem install rubygems-update-1.3.1.gem &&
      sudo /var/lib/gems/1.8/bin/update_rubygems &&
      sudo rm /usr/bin/gem &&
      sudo ln -s /usr/bin/gem1.8 /usr/bin/gem    
    CMD
  end
  
  task :add_opscode_gem_source, :roles => :app do
    sudo "gem sources -a http://gems.opscode.com"
  end
  
  task :install_chef, :roles => :app do
    sudo "gem install chef ohai"
  end
    
  task :all do
    transaction do
      prereqs
      replace_rubygems
      add_opscode_gem_source
      install_chef
    end
  end
  
end

namespace :deploy do
    
  task :prep_cookbook, :roles => :app do
    sudo "mkdir -p /var/chef"
    sudo "ln -s /home/#{user}/#{project}/cookbooks /var/chef/cookbooks"
  end
  
  task :run_cookbook, :roles => :app do
    sudo "chef-solo -l debug -j /home/#{user}/#{project}/config/dna.json -c /home/#{user}/#{project}/config/solo.rb"
  end
  
end