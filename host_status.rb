#!/usr/bin/env ruby
require 'optparse'

options = {}

opts = OptionParser.new

opts.banner = "usage: host_status [options]"

opts.on("-s", "--state STATE", [:active, :standby, :shutdown, :staydown], "state to put the host in") do |state|
  options[:state] = state
end

opts.on("-h", "--help", "this help screen") do
  puts opts
  exit
end

opts.parse!


#TODO: implement host status change behavior
