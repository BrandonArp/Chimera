def parse_version(version_string)
  version = []
  re = /([^0-9]*([0-9])+([a-zA-Z]?))/
  to_match = version_string
  while to_match != "" do
    match = re.match(to_match)
    version.push(Integer(match.captures[1]))
    if (match.captures[2])
      version.push(match.captures[2][0])
    end
    to_match = match.post_match
  end
  return version
end

def get_package_info(package_name)
  package_info = `apt-cache show #{package_name}`
  puts "error looking up package '#{package_name}'" unless $? == 0
  blocks = package_info.split("\n\n")
#  pp blocks
  info = {} 
  for block in blocks do
    block_info = {}
    block.each_line do |line| 
      if (line =~ /(\w+): (.*)$/)
        block_info[$1] = $2
      end
    end
    #check for a higher version, only return the highest version
    if info.empty?
      info = block_info
    end
    
    if (block_info["Version"])
      i_version = parse_version(info["Version"])
      b_version = parse_version(block_info["Version"])
      higher = higher_version(i_version, b_version)
      if higher == b_version
        info = block_info
      end
    else
      puts "no version found in block"
    end
  end
  return info
end

def higher_version(version_a, version_b)
  max_compare = [version_a.size, version_b.size].min
  i = 0
  while i < max_compare do
    if (Integer(version_a[i]) > Integer(version_b[i]))
      return version_a
    elsif Integer(version_b[i]) > Integer(version_a[i])
      return version_b
    end
    i = i + 1
  end
  if version_a.size == version_b.size
    return version_a
  elsif version_a.size > version_b.size
    return version_a
  elsif version_b.size > version_a.size
    return version_b
  end
  
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
  deb_name = "#{package_name}_#{package_version}_#{package_architecture}.deb"
  deb_name = deb_name.gsub(":", "%3a")
  deb_pkg_orig = "/var/cache/apt/archives/#{deb_name}" 
  if (package_architecture == "all")
    attempt_chain.push($ARCHITECTURE)
  end
  if ($ARCHITECTURE == "amd64")
    attempt_chain.push("i386")
  end
  failed = false
  failures = []
  for arch in attempt_chain do
    deb_name = "#{package_name}_#{package_version}_#{arch}.deb"
    deb_name = deb_name.gsub(":", "%3a")
    deb_pkg = "/var/cache/apt/archives/#{deb_name}" 
    if File.exist?(deb_pkg) 
      return deb_pkg
    end
    failures.push(deb_pkg)
    failed = true
  end
  puts "ERROR: could not find package #{package_name}.  Looked for #{failures}"
  return deb_pkg_orig
end

