#!/usr/bin/env ruby

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
    
    package_root = "/chimera/packages/#{package_name}/#{package_version}/"
    if not File.exist?(package_root)  
      puts "package #{package_name} not found in chimera package cache" 
      exit 1
    end
    Find.find(package_root) do |f|
      local = f.sub(package_root, "")
      if (File.directory?(f)) 
        FileUtils.mkpath("#{new_env}#{local}")
      elsif (File.symlink?(f))
        File.unlink("#{new_env}#{local}") if File.exist?("#{new_env}#{local}")
        File.symlink(File.readlink(f), "#{new_env}#{local}")
      else
        File.symlink(f, "#{new_env}#{local}")
      end
    end
  end
end

#delete the old symlink
env = "/chimera/env/#{environment_name}" 
File.delete(env) if File.symlink?(env)
FileUtils.mkpath("/chimera/env/") if not File.exist?("/chimera/env/")
File.symlink(new_env, env) 
