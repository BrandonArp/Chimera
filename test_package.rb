#!/usr/bin/env ruby
$: << "lib"
require 'package'
require 'packagelocator'
require 'pp'

loc = PackageLocator.new()
a = AptPackageLocator.new()
packages = a.get_package_versions("apache2")
puts packages
puts "************"
puts a.has_package?("apache2")
puts "************"
puts a.get_package_versions("foopackage128")
puts "************"
puts a.has_package?("foopackage128")
p = packages[0]
puts "loading dependencies for #{p}"
puts p.depends
puts "------"
resolver = DependencyResolver.new()
pp resolver.get_default_dependencies(p.depends)

