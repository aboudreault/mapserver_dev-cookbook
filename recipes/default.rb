#
# Cookbook Name:: mapserver-dev
# Recipe:: default
#
# Copyright (C) 2013 Alan Boudreault
# 
# All rights reserved - Do Not Redistribute
#

user = node['mapserver-dev']['user']
user_home = "/home/#{user}/"
source_dir = File.join(user_home, node['mapserver-dev']['source_dir'])
script_dir = File.join(user_home, node['mapserver-dev']['script_dir'])
install_dir = node['mapserver-dev']['install_dir']

mapserver_dir = File.join(source_dir, 'mapserver')
msdoc_dir = File.join(source_dir, 'mapserver-docs')
msautotest_dir = File.join(source_dir, 'msautotest')
mapserver_install_dir = File.join(install_dir, 'mapserver')
patch_dir = File.join(source_dir, 'patches')

#locale
include_recipe 'locale'

# Setup postgres
node['postgresql']['password']['postgres'] = 'postgres'
node['postgresql']['pg_hba'].push(
                                {:type => 'local', 
                                  :db => 'msautotest', 
                                  :user => user, 
                                  :addr => nil, 
                                  :method => 'ident'} )

include_recipe 'postgresql::server'

packages = %w{git emacs vim gdal-bin bison imagemagick postgresql-9.1-postgis python-sphinx libsvg libsvg-cairo}
directories = [source_dir, script_dir, msdoc_dir, msautotest_dir, 
               mapserver_install_dir, patch_dir]

# add the UbuntuGIS Unstable PPA; grab key from keyserver
apt_repository "ubuntugis-unstable" do
  uri "http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "314DF160"
end

execute "apt-get update"

packages.each do |p|
  package p
end

include_recipe 'apache2'
include_recipe 'apache2::mod_fastcgi'

# create templates
create_template_utf8_command = begin
      "sudo -u postgres createdb -E UTF8 -O postgres " +
      "--lc_ctype en_US.UTF-8 -T template0 template_utf8;"
    end

configure_template_utf8_command =  begin
"sudo -u postgres psql -d template_utf8 -c \""+
  "update pg_database set datistemplate = TRUE where datname = 'template_utf8'; " + " \";"
end

bash "create_template_utf8" do
  user "root"
  code <<-EOH
#{create_template_utf8_command}
#{configure_template_utf8_command}
EOH
  not_if "sudo -u postgres psql -l | grep template_utf8"
end

create_template_postgis_command = begin
      "sudo -u postgres createdb -O postgres " +
      "-T template_utf8 template_postgis;"
    end

configure_template_postgis_command =  begin
"sudo -u postgres psql -d template_postgis -c \"create extension postgis; " +
  "grant ALL on geometry_columns to PUBLIC; " +
  "grant ALL on geography_columns to PUBLIC; " +
  "grant ALL on spatial_ref_sys to PUBLIC; " +
  "grant ALL on raster_columns to PUBLIC; " +
  "grant ALL on raster_overviews to PUBLIC; " +
  "update pg_database set datistemplate = TRUE where datname = 'template_postgis'; " + " \";"
end

bash "create_template_postgis" do
  user "root"
  code <<-EOH
#{create_template_postgis_command}
#{configure_template_postgis_command}
EOH
  not_if "sudo -u postgres psql -l | grep template_postgis"
end

bash "create_user_role" do 
  user "postgres"
  code <<-EOH
createuser -S -R -d #{user}
EOH
  not_if "sudo -u postgres psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='#{user}'\" | grep 1"
end

bash "create_user_database" do 
  user user
  code <<-EOH
createdb -O #{user} #{user}
EOH
  not_if "sudo -u postgres psql -l | grep #{user}"
end

##################### end create db

directories.each do |dir|
  directory dir do
    action :create
    owner user
    group user
    recursive true
  end
end

############ Mapserver

execute "apt-get build-dep -y cgi-mapserver"

git mapserver_dir do
  repository "https://github.com/mapserver/mapserver.git"
  reference "master"
  action :sync
  user user
  group user
end

# patches
cookbook_file "branch-6-0.patch" do
  backup false
  mode 00644
  path "#{patch_dir}/branch-6-0.patch"
  action :create_if_missing
  owner user
  group user
end

# additionnal mapserver; copy mapserver working directory
node['mapserver-dev']['versions'].each do |version|

  version_dir =  "#{source_dir}/mapserver-#{version}"
  if not File.exist?(version_dir)
 
    patch_file = ::File.expand_path("#{patch_dir}/#{version}.patch")
    log("File: #{patch_file} ; Exists? : #{::File.exists?(patch_file)}")

    execute "copy_mapserver_#{version}" do
      user user
      command "cp -r #{mapserver_dir} #{version_dir}"
    end

    execute "checkout_branch_#{version}" do
      user user
      cwd version_dir
      command "git checkout #{version}"
    end

    execute "apply_patch_#{version}" do
      user user
      cwd version_dir
      command "patch -p1 < #{patch_dir}/#{version}.patch && autoconf"
      only_if { ::File.exists?("#{patch_dir}/#{version}.patch") }
    end

    # in case of re-provisionning
    execute "rm -f #{version_dir}/chef"
    
  end
end

template "#{script_dir}/mapserver-build.sh" do
  source "mapserver-build.sh.erb"
  mode 00744
  owner user
  group user
  action :create_if_missing
  variables({
    :install_dir => install_dir,
  })
end

bash "install_mapserver" do
  user user
  cwd mapserver_dir
  code <<-EOH
  #{script_dir}/mapserver-build.sh && touch chef
  EOH
  not_if { ::File.exists?("#{mapserver_dir}/chef") }
end

bash "bash_mapserver_path" do 
  user user
  code <<-EOH
  echo "export PATH=#{mapserver_install_dir}/bin:$PATH" >> #{user_home}/.bashrc
  EOH
end

execute "mapserver_cgi" do 
  command "ln -sf #{mapserver_install_dir}/bin/mapserv /usr/lib/cgi-bin/mapserv"
  creates "/usr/lib/cgi-bin/mapserv"
end

execute "mapserver_fcgi" do 
  command "ln -sf #{mapserver_install_dir}/bin/mapserv /usr/lib/cgi-bin/mapserv.fcgi"
  creates "/usr/lib/cgi-bin/mapserv.fcgi"
end

# additionnal mapserver; install and setup
node['mapserver-dev']['versions'].each do |version|

  version_dir = "#{source_dir}/mapserver-#{version}"
  version_install_dir = File.join(install_dir, "mapserver-#{version}")

  directory version_install_dir do
    action :create
    owner user
    group user
    recursive true
  end

  bash "install_mapserver_#{version}" do
    user user
    cwd version_dir
    code <<-EOH
  #{script_dir}/mapserver-build.sh
  EOH
    not_if { ::File.exists?("#{version_dir}/chef") }
  end

  execute "mapserver_cgi_#{version}" do 
    command "ln -sf #{version_install_dir}/bin/mapserv /usr/lib/cgi-bin/mapserv-#{version}"
  end
  
  execute "mapserver_fcgi_#{version}" do 
    command "ln -sf #{version_install_dir}/bin/mapserv /usr/lib/cgi-bin/mapserv-#{version}.fcgi"
  end

end

############ end mapserver

############# MSAUTOTEST 
git msautotest_dir do
  repository "https://github.com/mapserver/msautotest.git"
  reference "master"
  action :sync
  user user
  group user
end

cookbook_file "populate_msautotest_database.sh" do
  backup false
  mode 00744
  path "#{script_dir}/populate_msautotest_database.sh"
  action :create_if_missing
  owner user
  group user
end

bash "create_msautotest_database" do 
  cwd msautotest_dir
  code <<-EOH
sudo -u postgres createdb -T template_postgis -O #{user} msautotest
sudo -u vagrant #{script_dir}/populate_msautotest_database.sh;
EOH
  not_if "sudo -u postgres psql -l | grep msautotest"
end

cookbook_file "fix_msautotest_pg_connection.sh" do
  backup false
  mode 00744
  path "#{script_dir}/fix_msautotest_pg_connection.sh"
  action :create_if_missing
  owner user
  group user
end

bash "fix_msautotest_pg_connection" do 
  user user
  cwd msautotest_dir
  code <<-EOH
#{script_dir}/fix_msautotest_pg_connection.sh
EOH
end

############### END MSAUTOTEST

############### DOCS
git msdoc_dir do
  repository "https://github.com/mapserver/docs.git"
  reference "master"
  action :sync
  user user
  group user
end

bash "build_mapserver_docs" do 
  user user
  cwd msdoc_dir
  code "make html"
end

template "/etc/apache2/sites-available/mapserver" do
  source "mapserver-virtualhost.erb"
  mode 00744
  action :create_if_missing
  variables({
    :msdoc_dir => msdoc_dir,
  })
end

execute "a2ensite mapserver"
execute "service apache2 reload"

#################### END DOCS
