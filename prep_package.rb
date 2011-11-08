#!/usr/bin/env ruby
def get_package_info(package_name)
  package_info = `apt-cache show #{package_name}`
  puts "error looking up package '#{package_name}'" unless $? == 0
  return package_info
end

def get_package_provides(package_info)
  package_info.each_line { |line|
    if (line =~ /Provides: (.*)/)
      return $1.split(', ')
    end
  }
end

def get_package_version(package_info)
  package_info.each_line { |line|
    if (line =~ /Version: (.*)/)
      return $1
    end
  }
end

def recurse_prep(package_name, recurse_hash = Hash.new(), provides = Hash.new())
  package_depends = `apt-cache depends #{package_name}`
  in_or_block = false
  package_depends.each_line { |line|
    if (line =~ /Depends:\s<?([^>]+)\s*/)
      dependency = $1.chomp
#      dependency = $1
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
        puts "#{dependency}=>#{version}  (provides #{provides.length} packages)"
        recurse_prep(dependency, recurse_hash, provides)
      end 
    end
  }
end

package_name = ARGV[0]
puts "package: #{package_name}"
output = `apt-get install -y -d #{package_name}` 
puts "error getting package. are you running as root?\n#{output}" unless $? == 0
recurse_prep(package_name)

