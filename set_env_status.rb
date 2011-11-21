#!/usr/bin/env ruby
require 'optparse'
require 'etc'

def execute_scripts(admin_dir, standard_dir)
  if (File.exist?(admin_dir))
    admin_scripts = Dir.entries(admin_dir)
    admin_scripts.delete(".")
    admin_scripts.delete("..")
  else 
    puts "no admin scripts found"
  end

  if (File.exist?(standard_dir))
    reg_scripts = Dir.entries(standard_dir)
    reg_scripts.delete(".")
    reg_scripts.delete("..")
  else 
    puts "no standard scripts found"
  end
  all_scripts = []
  all_scripts = admin_scripts.map{|item| [admin_dir + "/" + item, true]} if admin_scripts != nil
  all_script = all_scripts + reg_scripts.map{|item| [standard_dir + "/" + item, false]} if reg_scripts != nil
  all_scripts.sort!{|a,b| a[0]<=>b[0]}
  for script_entry in all_scripts do
    script = script_entry[0]
    as_admin = script_entry[1]
    other = fork()
    if (other != nil)
      puts "Waiting for script #{script} to complete"
      Process.waitpid(other)
    else
      cmd = "/chimera/bin/env -e #{$ENV_NAME} #{script}"
      puts "would be execing #{cmd} as admin" if as_admin
      puts "would be execing #{cmd}" if as_admin == false
      if as_admin == false
        uid = Etc.getpwnam("nobody").uid
        Process::Sys.setuid(uid)
      end
      Kernel.exec(cmd)
      exit!
    end
  end
end

env_name = ENV["ENV_NAME"]

options = {}

opts = OptionParser.new 
  
opts.banner = "usage: set_env_status.rb [options]"
opts.on("-e", "--environment [ENV]", "chimera environment") do |env|
  options[:environment] = env
end

opts.on("-a", "--action ACTION", [:activate, :deactivate], "status to set environment to") do |action|
  options[:action] = action
end

opts.parse!
if options[:environment] != nil
  env_name = options[:environment]
end

action = options[:action]

if (action == nil)
  print opts
  puts "no action to take specified"
  exit!
end

if (env_name == nil)
  print opts
  puts "no environment to act on"
  exit!
end
$ENV_NAME = env_name
command_root = "/chimera/env/" + env_name + "/usr/lib/chimera/command"
preactivate_admin = command_root + "/preactivateadmin"
preactivate = command_root + "/preactivate"
activate_admin = command_root + "/activateadmin"
activate = command_root + "/activate"
postactivate_admin = command_root + "/postactivateadmin"
postactivate = command_root + "/postactivate"
predeactivate_admin = command_root + "/predeactivateadmin"
predeactivate = command_root + "/predeactivate"
deactivate_admin = command_root + "/deactivateadmin"
deactivate = command_root + "/deactivate"
postdeactivate_admin = command_root + "/postdeactivateadmin"
postdeactivate = command_root + "/postdeactivate"

if (action == :activate)
  puts "executing pre-activate scripts"
  execute_scripts(preactivate_admin, preactivate)
  puts "done."
  puts "executing activate scripts"
  execute_scripts(activate_admin, activate)
  puts "done."
  puts "executing post-activate scripts"
  execute_scripts(postactivate_admin, postactivate)
  puts "done."
elsif (action == :deactivate)
  puts "executing pre-deactivate scripts"
  execute_scripts(predeactivate_admin, predeactivate)
  puts "done."
  puts "executing deactivate scripts"
  execute_scripts(deactivate_admin, deactivate)
  puts "done."
  puts "executing post-deactivate scripts"
  execute_scripts(postdeactivate_admin, postdeactivate)
  puts "done"
else
  puts "ERROR: unknown action"
  exit
end

