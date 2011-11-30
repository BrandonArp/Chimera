#!/usr/bin/env ruby

$:.push(File.expand_path(File.dirname(__FILE__)) + '/gen-rb')
require 'rubygems'
require 'chimera.rb'
require 'pp'

def get_chimera_client() 
  transport = Thrift::BufferedTransport.new(Thrift::Socket.new('localhost', 6882))
  protocol = Thrift::BinaryProtocol.new(transport)
  client = Chimera::Client.new(protocol)
  client.open()
  return client
end


def start_package_deployment(deployment_id, packages, environment, client = nil)
  client = get_chimera_client() if client == nil
  client.deployTargets(deployment_id, packages, environment)
end

def get_deployment_status(deployment_id, client = nil)
  client = get_chimera_client() if client == nil
  return client.getDeploymentStatus(deployment_id)
end

def set_deployment_status(deployment_id, status, client = nil)
  client = get_chimera_client() if client == nil
  return client.getDeploymentStatus(deployment_id)
end

def set_deployment_status(deployment_id, status, client = nil)
  client = get_chimera_client() if client == nil
  client.reportStatus(deployment_id, status)
end

def map_status(status)
  return DeployStatus::VALUE_MAP[status]
end

def get_deployments(client = nil)
  client = get_chimera_client() if client == nil
  return client.getDeployments()
end

