#!/usr/bin/env ruby
$: << File.dirname( __FILE__) 
require 'optparse'
require 'lib/aptutils'
require 'lib/deploy'
require 'pp'

opts = OptionParser.new

args = {}

opts.on("-p", "--package p1,p2,p3", Array, "package to override") do |package|
  args[:package] = package
end

opts.on("-e", "--environment ENV", "environment to override in") do |environment|
  args[:environment] = environment
end

opts.on("-h", "--help", "show this help dialog") do
  puts opts
  exit 0
end

opts.parse!

error = false

if not args[:environment]
  puts "missing required argument environment"
  error = true
end

if not args[:package]
  puts "missing required argument package"
  error = true
end

if error
  exit 1
end



args[:package].each do |package|
  if not File.exist?(package)
    puts "file does not exist: #{package}"
    exit 1
  end
  info = get_deb_info(package)
  puts "caching #{package}"
  install_deb(package)
  puts "building links for #{package}"
  build_sym_links(get_package_name(info), get_package_version(info), "/chimera/env/#{args[:environment]}")
end


