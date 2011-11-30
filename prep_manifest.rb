#!/usr/bin/env ruby
require 'fileutils'
$: << File.dirname( __FILE__) 
require 'lib/aptutils.rb'

def install_package(package_name)
  #install me
  my_info = get_package_info(package_name)
  my_version = get_package_version(my_info)
  my_cache_deb = get_cache_deb(my_info)
  package_loc = "/chimera/packages/#{package_name}/#{my_version}"
  if not File.directory?(package_loc)
    FileUtils.mkpath(package_loc)
  end

  `dpkg -x #{my_cache_deb} #{package_loc}`
  puts "error extracting package '#{package_name}'" unless $? == 0
end

packages = []
manifest = ARGV[0]
manifest_file = File.open(manifest, 'r')
manifest_file.each_line do |line| 
  if (line =~ /(.*)=>(.*)/)
    package = $1
    packages.push(package)
  end
end 
puts "Getting packages with apt, please wait..."
output = `apt-get install -y -d #{packages.join(" ")}` 
puts "error getting package. are you running as root?\n#{output}" unless $? == 0
packages.each do |package|
  puts "Installing package #{package} into chimera cache"
  install_package(package)
end
