name             "mapserver-dev"
maintainer       "Alan Boudreault"
maintainer_email "aboudreault@mapgears.com"
license          "Apache 2.0"
description      "Setup a mapserver development environment"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

depends "apt", "1.8.0"
depends "postgresql", "2.2.2"
depends "locale", "0.0.2"
depends "apache2", "1.5.0"

supports "ubuntu"
