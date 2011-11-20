#!/usr/bin/env ruby
require 'fileutils'
require 'lib/aptutils.rb'

def prep_multiple(package_list, manifest_file)
  recurse_hash = Hash.new()
  provides = Hash.new()
  package_list.each do |package| 
    recurse_prep(package, manifest_file, recurse_hash, provides)
  end
end

def recurse_prep(package_name, manifest_file, recurse_hash = Hash.new(), provides = Hash.new())
  package_depends = `apt-cache depends #{package_name}`
  in_or_block = false
  my_info = get_package_info(package_name)
  my_version = get_package_version(my_info)
  manifest_file.write("#{package_name}=>#{my_version}\n")
  package_depends.each_line { |line|
    if (line =~ /Depends:\s?([^<> ]+)\s*/)
      dependency = $1.chomp
      store_dep = false
      if (!in_or_block)
        store_dep = true
      end
      if (line.strip!().start_with?("|"))
        in_or_block = true
      else
      end
      if !recurse_hash.has_key?(dependency) and store_dep and !provides.has_key?(dependency)
        recurse_hash[dependency] = true
        package_info = get_package_info(dependency)
        version = get_package_version(package_info)
	provides_list = get_package_provides(package_info)
        provides_list.each{|provide| provides[provide] = dependency}
        puts "#{dependency}=>#{version}  (provides #{provides_list.length} packages)"
        recurse_prep(dependency, manifest_file, recurse_hash, provides)
      end 
    end
  }
  #install me
  my_info = get_package_info(package_name)
  my_version = get_package_version(my_info)
  my_cache_deb = get_cache_deb(my_info)
  package_loc = "/chimera/packages/#{package_name}/#{my_version}"
  if not File.directory?(package_loc)
    FileUtils.mkpath(package_loc)
  end

  if not File.exist?(my_cache_deb)
    `apt-get install -y -d --reinstall #{package_name}`
  end
  `dpkg -x #{my_cache_deb} #{package_loc}`
  puts "error extracting package '#{package_name}'" unless $? == 0
end

packages = ARGV.slice(1..-1)
manifest_output = ARGV[0]
manifest_file = File.open(manifest_output, 'w')
output = `apt-get install -y -d #{packages.join(" ")}` 
puts "error getting package. are you running as root?\n#{output}" unless $? == 0
prep_multiple(packages, manifest_file)

