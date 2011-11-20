def get_package_info(package_name)
  package_info = `apt-cache show #{package_name}`
  puts "error looking up package '#{package_name}'" unless $? == 0
  info = {}
  package_info.each_line { |line| 
    if (line =~ /(\w+): (.*)$/)
      info[$1] = $2
    end
  }
  return info
end

def get_package_provides(package_info)
  return package_info["Provides"].split(', ') if package_info["Provides"]
  return []
end

def get_package_filename(package_info)
  return package_info["Filename"]
end

def get_package_version(package_info)
  return package_info["Version"]
end

def get_package_architecture(package_info)
  return package_info["Architecture"]
end

def get_package_name(package_info)
  return package_info["Package"]
end

def get_cache_deb(package_info) 
  if ($ARCHITECTURE == nil)
    $ARCHITECTURE = `dpkg --print-architecture`.chomp
  end
  package_name = get_package_name(package_info)
  package_version = get_package_version(package_info)
  package_architecture = get_package_architecture(package_info)
  attempt_chain = [package_architecture]
  if (package_architecture == "all")
    attempt_chain.push($ARCHITECTURE)
  end
  if ($ARCHITECTURE == "amd64")
    attempt_chain.push("i386")
  end
  failed = false
  for arch in attempt_chain do
    deb_name = "#{package_name}_#{package_version}_#{arch}.deb"
    deb_name = deb_name.gsub(":", "%3a")
    deb_pkg = "/var/cache/apt/archives/#{deb_name}" 
    if File.exist?(deb_pkg) 
      puts "Found file at #{deb_pkg}" if failed
      return deb_pkg
    end
    puts "WARNING: Could not find package at #{deb_pkg}"
    failed = true
  end
end
