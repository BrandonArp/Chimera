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
    
    def versions
        @versions.map do |package_version|
            package_version
        end
    end
    
    def [](version)
        @versions.find {|i| i.version == version }
    end

end

=begin rdoc
    represents a single version of a package.
=end
class Package
    include Comparable
    attr_accessor :name
    
    #--
    # should probally contain the intstall method.... etc
    #++
    
    def addProperty(name, value)
        define_method("#{name}") do 
            instance_variable_get("@#{name}")
        end
        instance_variable_set("@#{name}", value); 
    end
    
    def initialize()
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
    
    def get_cache_deb(dl_if_not_found = false) 
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

=begin rdoc
This class represents a version string with compairison logic.
For all other purposes, it behaves as a string.

Note: calling ! methods on it will not have any affect on the underlying values.
=end
class Version_String
    include Comparable
    
    def initialize(the_string)
        the_string = the_string.trim
        @version_array = []
        re = /(^([0-9]+)|(^[a-zA-Z]+)|^\.)/
        to_match = version_string
        until to_match.empty?
            match = re.match(to_match)
            @version_array << do_convert(match)
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
    
    def <=>(left, right)
        length = [left.length, right.length].min
        res = left.first(length) <=> right.first(length)
        if res != 0
            res
        else
            left.length <=> right.length
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
