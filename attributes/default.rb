# locale
default['locale']['lang'] = 'en_US.UTF-8'

# apache2, due to a bug: authz_default is not more available
override['apache']['default_modules'] = %w{alias authn_file authnz_ldap authz_groupfile authz_host authz_user autoindex cgi dav_fs dav_svn deflate dir env expires headers ldap log_config mime negotiation proxy proxy_ajp proxy_balancer proxy_connect proxy_http python rewrite setenvif status wsgi xsendfile}

# source directory for mapserver, docs and msautotest.
# This is a relative path of the user home directory
default['mapserver-dev']['source_dir'] = 'src'

# script directory 
default['mapserver-dev']['script_dir'] = 'scripts'

# install directory (prefix). The make install is not done with sudo, be sure
# chef can create the ms dir (/opt/mapserver...) and change the owner.
default['mapserver-dev']['install_dir'] = '/opt'

# user of the box. this doesn't create the user. vagrant is OK. don't change
# this is unless you know what you are doing
default['mapserver-dev']['user'] = 'vagrant'

# additional versions of mapserver to be installed. This can either be a tag or
# a branch. The 'master' is always installed.
default['mapserver-dev']['versions'] = %w{branch-6-4 branch-6-2 branch-6-0}
