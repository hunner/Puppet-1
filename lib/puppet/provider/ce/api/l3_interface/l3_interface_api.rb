# encoding: utf-8

# puppet namespace
module Puppet
  #NetDev namespace
  module NetDev
	#CE namespace
	module CE
        
	  class L3InterfaceApi < ApiBase
		def initialize()
		  super()
		end
		
		def get_l3_interface()	
		  l3_interface_array = []
		  session = Puppet::NetDev::CE::Device.session		
		  
		  get_l3_interface_xml = '<rpc><get><filter type="subtree"><ifm xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><interfaces><interface><ifName></ifName><ifDescr></ifDescr><ifAdminStatus></ifAdminStatus><isL2SwitchPort></isL2SwitchPort><ifmAm4></ifmAm4></interface></interfaces></ifm></filter></get></rpc>'
			
		  interface_all = session.rpc.do_config(get_l3_interface_xml)					
		  interface_elements = interface_all.first_element_child.first_element_child
		  
		  interface_elements.element_children.each do |interface_elem|
		    interface_doc = Nokogiri::XML(interface_elem.to_s)
			
			interface_mode = interface_doc.xpath("/interface/isL2SwitchPort").text
			if interface_mode == 'true'
			  next
			end
			
			interface_name = interface_doc.xpath("/interface/ifName").text
			interface_des = interface_doc.xpath("/interface/ifDescr").text
			interface_enable = interface_doc.xpath("/interface/ifAdminStatus").text
			interface_ipaddress = nil
			
			ip_info = interface_doc.xpath("/interface/ifmAm4/am4CfgAddrs/am4CfgAddr")		
			ip_info.each do |node|
			  ip_node = Nokogiri::XML(node.to_s)
			  add_type = ip_node.xpath("/am4CfgAddr/addrType").text
			  
			  if add_type == 'main'
				ipaddress = ip_node.xpath("/am4CfgAddr/ifIpAddr").text
				netmask = ip_node.xpath("/am4CfgAddr/subnetMask").text
				interface_ipaddress = ipaddress + ' ' + netmask
			    break
			  end
			              
			end
			
			property_hash = {:ensure => :present}
			property_hash[:name] = interface_name
			
			if interface_des
			  property_hash[:description] = interface_des
			end
			
			if interface_enable == 'up'
			  property_hash[:enable] = :true
			elsif interface_enable == 'down'
			  property_hash[:enable] = :false
			end	
			
			if interface_ipaddress != nil
			  property_hash[:ipaddress] = interface_ipaddress
			else
			  property_hash[:ipaddress] = 'null'
			end
			
			l3_interface_array << property_hash			
		  end
		  
		  return l3_interface_array
		  
		end

		
		def set_l3_interface(resource)		
		  session = Puppet::NetDev::CE::Device.session
			
		  set_interface_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><ifm xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><interfaces><interface operation="merge"><ifName>' + "#{resource[:name]}" + '</ifName>'
			
		  if resource[:description]
			set_interface_xml += '<ifDescr>' + "#{resource[:description]}" + '</ifDescr>'
		  end
			
		  if resource[:enable] == :true
			set_interface_xml += '<ifAdminStatus>up</ifAdminStatus>'
		  end
			
		  if resource[:enable] == :false
			set_interface_xml += '<ifAdminStatus>down</ifAdminStatus>'
		  end	

		  #e.g. '192.168.1.1 255.255.255.0'
		  if resource[:ipaddress] &&  resource[:ipaddress] != 'null'
		    ipadd_and_mask = resource[:ipaddress].split
			#ipadd_and_mask include IP address and netmask
			if ipadd_and_mask.count == 2
			  ip_address = ipadd_and_mask[0]
			  net_mask = ipadd_and_mask[1]
			  set_interface_xml += '<ifmAm4><am4CfgAddrs><am4CfgAddr operation="merge"><ifIpAddr>' + "#{ip_address}" + '</ifIpAddr><subnetMask>' + "#{net_mask}" + '</subnetMask><addrType>main</addrType></am4CfgAddr></am4CfgAddrs></ifmAm4>'
			end
		  end
		  
		  if resource[:ipaddress] == 'null'
			#check whether main IP address exists, if true, delete it.
			get_l3_interface_xml = '<rpc><get><filter type="subtree"><ifm xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><interfaces><interface><ifName>' + "#{resource[:name]}" + '</ifName><ifmAm4></ifmAm4></interface></interfaces></ifm></filter></get></rpc>'
			
		    main_ipaddress_exist = false
			main_ipaddress = '0.0.0.0'
			
			interface_all = session.rpc.do_config(get_l3_interface_xml)					
		    interface_elements = interface_all.first_element_child.first_element_child
			
		    interface_elements.element_children.each do |interface_elem|
		      interface_doc = Nokogiri::XML(interface_elem.to_s)
			
			  ip_info = interface_doc.xpath("/interface/ifmAm4/am4CfgAddrs/am4CfgAddr")		
			  ip_info.each do |node|
			    ip_node = Nokogiri::XML(node.to_s)
			    add_type = ip_node.xpath("/am4CfgAddr/addrType").text
			  
			    if add_type == 'main'
				  ipaddress = ip_node.xpath("/am4CfgAddr/ifIpAddr").text
				  netmask = ip_node.xpath("/am4CfgAddr/subnetMask").text
				  main_ipaddress_exist = true
				  main_ipaddress = ipaddress
			      break
			    end
			  end              
			end
			
			if main_ipaddress_exist == true
			  set_interface_xml += '<ifmAm4><am4CfgAddrs><am4CfgAddr operation="delete"><ifIpAddr>' + main_ipaddress + '</ifIpAddr></am4CfgAddr></am4CfgAddrs></ifmAm4>'
			end
			
		  end
			
		  set_interface_xml += '</interface></interfaces></ifm></config></edit-config></rpc>'
			
		  session.rpc.do_config(set_interface_xml)
		end
		
	  end
	
	end
  end
end    

