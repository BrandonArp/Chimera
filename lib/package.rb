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
        $versions = blocks.map do |block|
            Version.new(block)
        end
    end
    
    def self.new(package_name)
        package_info = `apt-cache show #{package_name}`
        puts "error looking up package '#{package_name}'" unless $? == 0
        super.new(package_info)
    end
    
    def self.from_deb_file(deb_file)
        if not File.exist?(deb_file)
            raise "deb file not found: #{deb_file}"
        end
        package_info = `dpkg-deb --info #{deb_file}`
        super.new(package_info)
    end
    
    #--
    # needs things like versions, get(version), 
    #++

end

=begin rdoc
    represents a single version of a package.
=end
class Package
    attr_accessor :name
    
    #--
    # should probally contain the intstall method.... etc
    #++
    
    def addProperty(name, value)
        define_method("#{name}") do 
            instance_variable_get("@#{name}")
        end
        define_method("#{name}=" do |val|
            instance_variable_set("@#{name}", val); 
        end
        instance_variable_set("@#{name}", value); 
    end
    
    def initialize()
        block.each_line do |line| 
            if (line =~ /^\s*(\S+): (.*)$/)
                addProperty($1.underscore.to_symbol, $2)
            end
        end
        #handle version being unset...
        @parsed_version = parse_version(@version)
        @name = @package
        @provides = if @provides
                @provices.split(', ')
            else
                []
            end
    end
    
    def parse_version(version_string)
        version = []
        re = /([^0-9]*([0-9]+)([a-zA-Z]?))/
        to_match = version_string
        while to_match != "" do
            match = re.match(to_match)
            version.push(Integer(match.captures[1]))
            if (match.captures[2][0] != nil)
                version.push(match.captures[2].bytes.first)
            end
            to_match = match.post_match
        end
        return version
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
        left_v = left.version
        right_v = right.version
        max_compare = [left_v.size, right_v.size].min
        0.upto(max_compare) do |i|
            if (Integer(left_v[i]) > Integer(right_v[i]))
                return -1
            elsif Integer(right_v[i]) > Integer(left_v[i])
                return 1
            end
        end
        if left_v.size == right_v.size
            return 0
        elsif left_v.size > right_v.size
            return -1
        elsif right_v.size > left_v.size
            return 1
        end
    end

end
