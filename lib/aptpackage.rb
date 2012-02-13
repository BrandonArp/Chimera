require 'package'

class AptPackage < Package
  def initialize(control_blob)
    lines = control_blob.split("\n")
    hash = {}
    lines.each { |line|
    next if !line
      pair = line.split(":")
      key = pair[0].strip 
      val = pair[1].strip if pair[1]
      hash[key] = val
    }
    super(hash["Package"], PackageVersionString.new(hash["Version"]))

    dependency_string = hash["Depends"]
    top_levels = []
    top_levels_strs = dependency_string.split(",")
    top_levels_strs.each { |elem|
      elem.strip!
      ors = elem.split("|")
      if ors.size > 1 
        deps = ors.map { |a| parse_dependency(a) }
        top_levels << OrDependency.new(deps)
      else
        top_levels << Dependency.new(parse_dependency(ors[0]))
      end
    }
    @depends = DependencySet.new(top_levels)
  end

  def parse_dependency(dep_string)
    dep_string.strip!
    re = /(.*)\([><=]*\s*(.*)\)/
    match = re.match(dep_string)
    package_name = match.captures[0].strip
    version = match.captures[1].strip
    Package.new(package_name, PackageVersionString.new(version))
  end
end
