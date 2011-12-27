#!/usr/bin/env ruby
$: << File.dirname( __FILE__) 

require 'lib/deploy'

require 'find'
require 'digest'
require 'fileutils'
require 'optparse'

opts = OptionParser.new

environment_name = ""
manifest = ""

opts.on("-e", "--environment ENVIRONMENT", "environment to build") do |env|
  environment_name = env
end

opts.on("-m", "--manifest MANIFEST", "manifest input file") do |mani|
  manifest = mani
end

opts.on("-h", "--help", "display this help dialog") do
  puts opts
  exit 0
end

opts.parse!

error = false
if environment_name == ""
  puts "required argument evironment not found"
  error = true
end

if manifest == ""
  puts "required argument manifest not found"
  error = true
end

if error == true
  puts opts
  exit 1
end

hash = Digest::SHA256.hexdigest(File.read(manifest))

manifest_file = File.new(manifest, "r")
new_env = "/chimera/_env/#{environment_name}/#{hash}/"
FileUtils.rm_rf(new_env)
while (line = manifest_file.gets) do
  if (line =~ /(.*)=>(.*)/) 
    package_name = $1
    package_version = $2
    build_sym_links(package_name, package_version, new_env)   
  end
end

#delete the old symlink
env = "/chimera/env/#{environment_name}" 
File.delete(env) if File.symlink?(env)
FileUtils.mkpath("/chimera/env/") if not File.exist?("/chimera/env/")
File.symlink(new_env, env) 
