#!/usr/bin/env ruby
$: << File.dirname( __FILE__) 

require 'lib/chimera_svc.rb'
require 'optparse'


opts = OptionParser.new
args = {}

opts.on("-e", "--environment ENVIRONMENT", "environment to deploy") do |environment|
  args[:environment] = environment
end

opts.on("-h", "--help", "this help dialog") do 
  puts opts
  exit 0
end 

local_dir = File.expand_path(File.dirname(__FILE__))
packages = ARGV.slice(2..-1)
manifest_output = ARGV[0]
environment = ARGV[1]

package_arg = ""
packages.each do |package|
  package_arg = package_arg + " " + package
end

puts "prep_and_deploy_package with manifest #{manifest_output}, environment #{environment}, packages [#{package_arg}]" 

system 'apt-get update'
system "#{local_dir}/prep_package.rb #{manifest_output}#{package_arg}"
system "#{local_dir}/deploy_environment.rb #{environment} #{manifest_output}"
