=begin rdoc
Plugin container for registering and keeping track of package locator classes
=end
class PackageLocator
  def initialize
    Dir[File.dirname(__FILE__) + '/packagelocators/*.rb'].each { |file| 
			l = "packagelocators/#{File.basename(file)}"
      puts "trying to load #{l}"
      load l
    }
  end 

end
