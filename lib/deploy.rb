require 'find'
require 'fileutils'

def install_deb(deb_location)
  #install me
  my_info = get_deb_info(deb_location)
  my_name = get_package_name(my_info)
  my_version = get_package_version(my_info)
  install_package(my_name, my_version, deb_location)
end

def install_package(package_name, package_version = nil, deb_location = nil)
  package_info = nil
  if package_version == nil or deb_location == nil
    package_info = get_package_info(package_name)
    package_version = get_package_version(package_info) if package_version == nil
    deb_location = get_cache_deb(package_info) if deb_location == nil
  end

  package_loc = "/chimera/packages/#{package_name}/#{package_version}"
  if not File.directory?(package_loc)
    FileUtils.mkpath(package_loc)
  end

  `dpkg -x #{deb_location} #{package_loc}`
  raise "error extracting package '#{package_name}'" unless $? == 0
end

def build_sym_links(package_name, version, environment_root)
    if environment_root[-1] != '/'
      environment_root += '/'
    end
    package_root = "/chimera/packages/#{package_name}/#{version}/"
    if not File.exist?(package_root)  
      raise "package #{package_name} not found in chimera package cache" 
    end
    Find.find(package_root) do |f|
      local = f.sub(package_root, "")
      dest = "#{environment_root}#{local}"
      File.unlink("#{dest}") if File.exist?("#{dest}") and not File.directory?(dest)
      if (File.directory?(f)) 
        FileUtils.mkpath("#{environment_root}#{local}")
      elsif (File.symlink?(f))
        File.symlink(File.readlink(f), "#{dest}")
      else
        File.symlink(f, "#{dest}")
      end
    end
end
