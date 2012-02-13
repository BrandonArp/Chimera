require 'packagelocatorbase'
require 'package'
require 'aptpackage'

class AptPackageLocator < PackageLocatorBase
  def get_package_versions(package)
    package_info = get_package_info(package)
    get_versions_from_apt_blob(package_info)
  end

  def get_package_info(package_name)
    `apt-cache show #{package_name} 2>/dev/null`
  end

  def has_package?(package, version = nil)
    package_info = get_package_info(package)
    versions = get_versions_from_apt_blob(package_info)
    if (version == nil) 
			return !versions.empty?
		end
		return versions.contains(version)
  end

  def get_versions_from_apt_blob(control_blob)
    blocks = control_blob.split("\n\n")
    packages = blocks.map do |block| 
      AptPackage.new(block) 
		end
		packages.sort!
		packages
  end
end
