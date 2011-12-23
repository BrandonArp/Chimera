#!/usr/bin/env ruby
$: << File.dirname( __FILE__) 

require 'lib/chimera_svc.rb'
require 'optparse'


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

if args[:manifest] and args[:package]
  puts "must only specify package list or manifest file, not both"
  puts opts
  exit 1
end

if not args[:environment]
  puts "must specify an environment to deploy to"
  puts opts
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
  package_arg = package_arg[1..-0]
  puts "prep_and_deploy_package with packages#{package_arg}, environment #{environment}"
end

if manifest
  puts "prep_and_deploy_package with manifest #{manifest}, environment #{environment}" 
end

system 'apt-get update'
if packages
  #TODO need to generate a manifest file name
  system "#{local_dir}/prep_package.rb -m #{output_manifest} -p #{package_arg}"
end
if manifest
  system "#{local_dir}/prep_manifest.rb -m #{manifest}"
end
system "#{local_dir}/deploy_environment.rb #{environment} #{manifest}"
