# encoding: utf-8

require 'puppet/provider/ce/device/device.rb'
require 'puppet/provider/ce/api/apibase.rb'
require 'puppet/provider/ce/api/vlan/vlan_api.rb'
require 'puppet/provider/ce/session/session.rb'
require 'puppet/provider/ce/ce/ce.rb'

Puppet::Type.type(:network_vlan).provide(:ce, :parent => Puppet::Provider::CE) do
  
  has_feature :describable

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  def self.instances 
    array = []
	vlans = Puppet::NetDev::CE::Device.vlan_api.get_vlan()

    vlans.each { |property_hash|
	  array << new(property_hash)
    }
	
    return array
  end

  def flush()
	return if !exists?()
	
	Puppet::NetDev::CE::Device.vlan_api.set_vlan(resource)	
	vlans = Puppet::NetDev::CE::Device.vlan_api.get_vlan()
	update(vlans)
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
	Puppet::NetDev::CE::Device.vlan_api.create_vlan(resource)
	@property_hash = {:id => resource[:id], :ensure => :present}
  end

  def destroy()
	Puppet::NetDev::CE::Device.vlan_api.delete_vlan(resource)
	@property_hash = {:id => resource[:id], :ensure => :absent}
  end
  
end
