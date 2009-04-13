define :passenger_app do
  name = params[:name]
  
  template "/etc/apache2/sites-available/#{name}" do
    owner 'root'
    group 'root'
    mode 0644
    source params[:conf][:template]
    variables({
      :name => name,
      :docroot  => params[:conf][:docroot],
      :server_name  => params[:conf][:server_name],
      :max_pool_size    => params[:conf][:max_pool_size] || 4,
      :ssl => params[:conf][:ssl],
      :env => params[:conf][:env]
    })
    #only_if { File.exists?(docroot) }
  end
  
  enable_setting = params[:conf][:enable]
  
  apache_site name do
    enable enable_setting
    only_if { File.exists?("/etc/apache2/sites-available/#{name}") }
  end
end