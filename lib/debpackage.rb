require 'package'

=begin rdoc
    represents a single version of a package.
=end
class DebPackage < Package
  include Comparable
  attr_accessor :name
  
  #--
  # should probally contain the intstall method.... etc
  #++
  
  def initialize(package_name, version)
    super(package_name, version)
  end

  def set_from_info_block(block)
    block.each_line do |line| 
      if (line =~ /^\s*(\S+): (.*)$/)
        addProperty($1.underscore, $2)
      end
    end
    #handle version being unset...
    @version = Version_String.new(@version)
    @name = @package
    @provides = if @provides
        @provices.split(', ')
      else
        []
      end
  end
      
  def self.from_deb_file(deb_file)
    if not File.exist?(deb_file)
      raise "deb file not found: #{deb_file}"
    end
    package_info = `dpkg-deb --info #{deb_file}`
    new(package_info)
  end
  
  def get_cache_file(dl_if_not_found = false) 
    if ($ARCHITECTURE == nil)
      $ARCHITECTURE = `dpkg --print-architecture`.chomp
    end
    attempt_chain = [@architecture]
    deb_name = "#{@name}_#{@version}_#{@architecture}.deb"
    deb_name = deb_name.gsub(":", "%3a")
    deb_pkg_orig = "/var/cache/apt/archives/#{deb_name}" 
    if (@architecture == "all")
      attempt_chain.push($ARCHITECTURE)
    end
    if ($ARCHITECTURE == "amd64")
      attempt_chain.push("i386")
    end
    tried_download = false
    do_download = false
    failed = false
    failures = []
    root_cache = "/var/cache/apt/archives"
    until tried_download
      if do_download
        puts "trying to download package that's not in the cache"
        root_cache = "/tmp"
        Dir.chdir("/tmp")
        system("apt-get download #{@name}")
        tried_download = true
      end
      attempt_chain.each do |arch|
        deb_name = "#{@name}_#{@version}_#{arch}.deb"
        deb_name = deb_name.gsub(":", "%3a")
        deb_pkg = "#{root_cache}/#{deb_name}" 
        if File.exist?(deb_pkg) 
          return deb_pkg
        end
        failures.push(deb_pkg)
        failed = true
      end
      do_download = true
      if not dl_if_not_found
        tried_download = true
      end
    end
    return deb_pkg_orig
  end
  
  def <=> (left, right)
    left.version <=> right.version
  end

end

