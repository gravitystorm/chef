#
# Cookbook Name:: donate
# Recipe:: default
#
# Copyright 2016, OpenStreetMap Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.default[:ssl][:certificates] = node[:ssl][:certificates] | ["openstreetmap"]

include_recipe "apache::ssl"
include_recipe "mysql"
include_recipe "git"

if node[:lsb][:release].to_f >= 16.04
  package "php"
  package "php-cli"
  package "php-curl"
  package "php-mysql"
  package "php-gd"

  apache_module "php7.0"
else
  package "php5"
  package "php5-cli"
  package "php5-curl"
  package "php5-mysql"
  package "php5-gd"

  apache_module "php5"
end

apache_module "headers"

passwords = data_bag_item("donate", "passwords")

database_password = passwords["database"]

mysql_user "donate@localhost" do
  password database_password
end

mysql_database "donate" do
  permissions "donate@localhost" => :all
end

directory "/srv/donate.openstreetmap.org" do
  owner "donate"
  group "donate"
  mode 0o755
end

git "/srv/donate.openstreetmap.org" do
  action :sync
  repository "git://github.com/osmfoundation/donation-drive.git"
  user "donate"
  group "donate"
end

directory "/srv/donate.openstreetmap.org/data" do
  owner "donate"
  group "donate"
  mode 0o755
end

template "/srv/donate.openstreetmap.org/scripts/db-connect.inc.php" do
  source "db-connect.inc.php.erb"
  owner "root"
  group "donate"
  mode 0o644
  variables :passwords => passwords
end

apache_site "donate.openstreetmap.org" do
  template "apache.erb"
end

template "/etc/cron.d/osmf-donate" do
  source "cron.erb"
  owner "root"
  group "root"
  mode 0o600
  variables :passwords => passwords
end

template "/etc/cron.daily/osmf-donate-backup" do
  source "backup.cron.erb"
  owner "root"
  group "root"
  mode 0o750
  variables :passwords => passwords
end
