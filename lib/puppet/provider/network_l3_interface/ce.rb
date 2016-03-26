# encoding: utf-8

require 'puppet/provider/ce/device/device.rb'
require 'puppet/provider/ce/api/apibase.rb'
require 'puppet/provider/ce/api/l3_interface/l3_interface_api.rb'
require 'puppet/provider/ce/session/session.rb'
require 'puppet/provider/ce/ce/ce.rb'

Puppet::Type.type(:network_l3_interface).provide(:ce, :parent => Puppet::Provider::CE) do

  mk_resource_methods

  def self.instances 
	array = []
	interfaces = Puppet::NetDev::CE::Device.l3_interface_api.get_l3_interface()

	interfaces.each { |property_hash|
		array << new(property_hash)
	}

	return array
  end

  def initialize(resources)

    super(resources)
  end
  
  def self.prefetch(resources)

    instances.each do |prov|
	  if resource = resources[prov.name]
	    resource.provider = prov
	  end
    end
  end
  
  def flush()

	return if !exists?()
	Puppet::NetDev::CE::Device.l3_interface_api.set_l3_interface(resource)
	channels = Puppet::NetDev::CE::Device.l3_interface_api.get_l3_interface()
	update(channels)
  end
    
  def update(propertys = [])
	propertys.each { |property_hash|
	  if resource[:name] == property_hash[:name]
		@property_hash = property_hash
		break
	  end
	}
  end
  
  def exists?()

    @property_hash[:ensure] == :present
  end 
  
  def create()

	Puppet::NetDev::CE::Device.l3_interface_api.create_l3_interface(resource)
	@property_hash = {:ensure => :present}
  end

  def destroy()

	Puppet::NetDev::CE::Device.l3_interface_api.delete_l3_interface(resource)
	@property_hash = {:ensure => :absent}
  end
  
end
