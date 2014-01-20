# mapserver-dev cookbook

This cookbook provides a complete MapServer development environment. It has been
updated on 2014-0-120 to work with latest mapserver, virtualbox (4.3) and
vagrant (1.4.3).

After the provisioning, you'll get:

* All MapServer dependencies and build tools installed.
* MapServer (Branch master, 6.4, 6.2, 6.0) source downloaded and installed.
* MapServer CGI/FCGI setup for all executables:
   * http://localhost:8002/cgi-bin/mapserv (add .fcgi for fastCGI)
   * http://localhost:8002/cgi-bin/mapserv-branch-6-0
   * http://localhost:8002/cgi-bin/mapserv-branch-6-2
   * http://localhost:8002/cgi-bin/mapserv-branch-6-4
* PostgreSQL+Postgis setup with the testsuite data loaded.
* MapServer test suite available in ~/src/msautotest
* MapServer docs available in ~/src/docs
* MapServer documentation available through: http://localhost:8002/

# Installation

Install the following softwares:

* Virtualbox: https://www.virtualbox.org/
* Vagrant: http://www.vagrantup.com/

Install the following vagrant plugins:

* vbguest: vagrant plugin install vagrant-vbguest
* berkshelf: vagrant plugin install vagrant-berkshelf

Checkout the environment:

$ git checkout https://github.com/aboudreault/mapserver_dev-cookbook.git
$ cd mapserver_dev-cookbook

# Usage

## Configuration

* Vagrant config: *Vagrantfile*.
* You might want to change some setting in *attributes/default.rb*. (ie locale,
default to en_US-utf8)

## Initial Setup

$ vagrant up

This might take some time.

## Commands

Stop the vm: vagrant halt
Start the vm: vagrant up (provisioning is only done the first time)
Reprovision the vm: vagrant provision or vagrant up --provision

# Author

Author:: Alan Boudreault (boudreault.alan@gmail.com)
