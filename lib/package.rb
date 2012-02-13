require 'pp'
class String
    def underscore
        self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
end

=begin rdoc
    A class that represents all versions of a named package
=end
class Package_versions
 
  def initialize(control_blob)
    blocks = control_blob.split("\n\n")
    @versions = blocks.map do |block|
      Version.new(block)
    end
    @versions.sort!
  end
  
  def self.new(package_name)
    package_info = `apt-cache show #{package_name}`
    puts "error looking up package '#{package_name}'" unless $? == 0
    super.new(package_info)
  end
 
  def extract_files
 
  end
  
  def versions
    @versions.map do |package_version|
      package_version
    end
  end
  
  def [](version)
    @versions.find {|i| i.version == version }
  end
 
end

class DependencyResolver
  def get_default_dependencies(dependency_set)
		sets = dependency_set.get_dependency_sets()
		needed = []
		sets.each{ |set| needed << set.package() }
		needed
	end 
end

class DependencySet
  attr_reader :top_levels
	def initialize(dependencies)
		@top_levels = []
		dependencies.each { |dep|
			add_dependency(dep)
		}
	end

	def add_dependency(dependency)
		@top_levels << dependency
	end

	def get_dependency_sets()
	  @top_levels
	end

	def to_s()
		pp @top_levels
	end
end

class OrDependency
	attr_reader :packages
  def initialize(packages)
		@packages = packages
	end

	def package()
		@packages[0]
	end
end

class Dependency
	attr_reader :package
	def initialize(package)
		@package = package
	end
end

=begin rdoc
    represents a single version of a package.
=end
class Package
  include Comparable
  attr_accessor :name, :version, :depends
  
  #--
  # should probally contain the intstall method.... etc
  #++
  
  def initialize(package_name, version)
    @name = package_name
    @version = version
  end
      
  def self.from_deb_file(deb_file)
    if not File.exist?(deb_file)
      raise "deb file not found: #{deb_file}"
    end
    package_info = `dpkg-deb --info #{deb_file}`
    new(package_info)
  end

	def to_s()
		"#{@name} @ #{@version}"
	end
  
  def <=> (right)
    right.version <=> @version
  end
end

=begin rdoc
This class represents a version string with compairison logic.
For all other purposes, it behaves as a string.

Note: calling ! methods on it will not have any affect on the underlying values.
=end
class PackageVersionString
  include Comparable
  attr_reader :version_array
  
  def initialize(the_string)
    the_string = the_string.strip
    @version_array = []
    re = /(^([0-9]+)|(^[a-zA-Z]+)|(^.))/
    to_match = the_string
    until to_match.empty?
      match = re.match(to_match)
      @version_array << do_convert(match.to_s)
      to_match = match.post_match
    end
  end
  
  def do_convert(aString)
    if aString =~ /\d+/
      #we need to do something about leading 0s, they shouldn't go away....
      aString.to_i
    else
      aString
    end
  end
  
  def <=>(right)
    length = [@version_array.length, right.version_array.length].min
    res = @version_array.first(length) <=> right.version_array.first(length)
    if res != 0
      res
   else
      @version_array.length <=> right.version_array.length
    end
  end
  
  def to_s
    @version_array.join
  end
  
  def to_str
    to_s
  end
  
  def method_missing(name, *args, &block)
    to_s.send(name, *args, &block)
  end

end
