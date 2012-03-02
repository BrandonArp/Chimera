#!/usr/bin/env ruby

$:.push(File.expand_path(File.dirname(__FILE__)) + '/lib/gen-rb')
$:.push(File.expand_path(File.dirname(__FILE__)) + '/lib')
require 'rubygems'
require 'chimera.rb'
require 'chimera_svc.rb'
require 'pp'

begin
  client = get_chimera_client()
  chimera_ping(client)
  puts "getting deployments"
  deployments = get_deployments(client)
  pp deployments
#  puts "starting deployment foo"
#  foo.deployTargets('foo', ["examcreator"], 'ec')
  puts "getting deployment status"
  status = get_deployment_status('foo', client)
  puts "deployment status: #{DeployStatus::VALUE_MAP[status]}"
  puts "setting deployment status to pull"
  set_deployment_status('foo', DeployStatus::PULL, client)
  puts "getting deployment status"
  status = get_deployment_status('foo', client)
  puts "deployment status: #{DeployStatus::VALUE_MAP[status]}"
rescue InternalError => err
  puts "Caught internal error:"
  pp err
end
