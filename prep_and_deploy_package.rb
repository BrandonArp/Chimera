#!/usr/bin/env ruby
$: << File.dirname( __FILE__) 

require 'lib/chimera_svc.rb'
require 'optparse'
require 'tempfile'


opts = OptionParser.new
args = {}

opts.on("-e", "--environment ENVIRONMENT", "environment to deploy") do |environment|
  args[:environment] = environment
end

opts.on("-d", "--deployment DEPLOYMENT", "deployment id of the deployment") do |deployment|
  args[:deployment_id] = deployment
end

opts.on("-h", "--help", "this help dialog") do 
  puts opts
  exit 0
end 

opts.parse!()

local_dir = File.expand_path(File.dirname(__FILE__))
deployment_id = args[:deployment_id]
environment = args[:environment] 

package_arg = ""
ARGV.each do |package|
  package_arg = package_arg + " " + package
end

puts "prep_and_deploy_package with deployment id #{deployment_id}, environment #{environment}, packages [#{package_arg}]" 

report_status = true

begin
  client = get_chimera_client()
rescue => e
  puts "not reporting status to chimera server: #{e}"
  report_status = false
end

temp = Tempfile.new(deployment_id)
manifest_output = temp.path
temp.close()
set_deployment_status(deployment_id, DeployStatus::STARTED, client) if report_status
system 'apt-get update'
set_deployment_status(deployment_id, DeployStatus::PULL, client) if report_status
system "#{local_dir}/prep_package.rb #{manifest_output}#{package_arg}"
set_deployment_status(deployment_id, DeployStatus::EXTRACT, client) if report_status
system "#{local_dir}/deploy_environment.rb #{environment} #{manifest_output}"
set_deployment_status(deployment_id, DeployStatus::COMPLETE, client) if report_status
