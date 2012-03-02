=begin rdoc
Plugin container for registering and keeping track of package locator classes
=end
class PackageLocator
  def initialize
    Dir[File.dirname(__FILE__) + '/packagelocators/*.rb'].each { |file| 
			l = "packagelocators/#{File.basename(file)}"
      require l
    }
  end
  def PackageLocator.inherited(subclass)
    puts "#{subclass} inherits from PackageLocator."
  end 
  def subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

end
