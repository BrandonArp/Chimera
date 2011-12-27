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

opts.on("-p", "--package p1,p2,p3", Array, "packages to deploy") do |package|
  args[:package] = package
end

opts.on("-m", "--manifest MANIFEST", "manifest to deploy") do |manifest|
  args[:manifest] = manifest
end

opts.on("-h", "--help", "this help dialog") do 
  puts opts
  exit 0
end 

opts.parse!

if not (args[:manifest].nil? ^ args[:package].nil?)
  puts "must only specify package list or manifest file, but not both"
  puts "manifest: #{args[:manifest]}"
  puts "packages: #{args[:package]}"
  puts opts
  exit 1
end

if not args[:environment]
  puts "must specify an environment to deploy to"
  puts opts
  exit 1
end

local_dir = File.expand_path(File.dirname(__FILE__))
packages = nil
manifest = nil
if args[:package]
  packages = args[:package]
end

if args[:manifest]
  manifest = args[:manifest]
end

environment = args[:environment]

if packages
  package_arg = ""
  packages.each do |package|
    package_arg = package_arg + "," + package
  end
  package_arg = package_arg[1..-1]
  puts "prep_and_deploy_package with packages#{package_arg}, environment #{environment}"
end

if manifest
  puts "prep_and_deploy_package with manifest #{manifest}, environment #{environment}" 
end

report_status = false
temp = Tempfile.new(deployment_id)
manifest_output = temp.path
temp.close()
set_deployment_status(deployment_id, DeployStatus::STARTED, client) if report_status
system 'apt-get update'
if packages
  temp_file = Tempfile.new("deploy")
  temp_file.close
  #make sure we define the manifest for deploying it
  manifest = temp_file.path
  set_deployment_status(deployment_id, DeployStatus::PULL, client) if report_status
  system "#{local_dir}/prep_package.rb -m #{manifest} -p #{package_arg}"
elsif manifest
  system "#{local_dir}/prep_manifest.rb -m #{manifest}"
end
set_deployment_status(deployment_id, DeployStatus::EXTRACT, client) if report_status
system "#{local_dir}/deploy_environment.rb -e #{environment} -m #{manifest}"
system "#{local_dir}/set_env_status.rb -a activate -e #{environment}"
set_deployment_status(deployment_id, DeployStatus::COMPLETE, client) if report_status
