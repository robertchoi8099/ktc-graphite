#
# Cookbook Name:: ktc-graphite
# Recipe:: master
# Author:: Robert Choi
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

include_recipe 'services'
include_recipe 'ktc-utils'
include_recipe 'ktc-graphite::_member'

::KTC::Network.node = node
ip = ::KTC::Network.address 'management'
port = node['graphite']['carbon']['relay']['line_receiver_port']

graphite_service =  Services::Service.new 'graphite'
graphite_service.members.map do |m|
  unless m.ip == ip || m.name == node['fqdn']
    Chef::Log.info("Found a member: #{m.name}. Loading it from etcd..")
    # Update carbon-relay destinations
    node.default['graphite']['carbon']['relay']['destinations'] <<
      "#{m.ip}:#{m.port}"
    # Update webapp cluster_servers
    node.default['graphite']['web']['cluster_servers'] << "#{m.ip}:80"
  end
end

include_recipe 'ktc-graphite::_install'

ruby_block 'register graphite endpoint' do
  block do
    ep = Services::Endpoint.new 'graphite',
                                ip: ip,
                                port: port
    ep.save
  end
end
