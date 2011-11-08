#!/usr/bin/env ruby
deb_file = ARGV[0]
location = ARGV[1]
puts "deb_file: #{deb_file}"
puts "prep location: #{location}"

package_info = `apt-cache show
