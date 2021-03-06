# encoding: utf-8

# puppet namespace
module Puppet
  #NetDev namespace
  module NetDev
	#CE namespace
	module CE
        
	  class CarApi < ApiBase
		def initialize()
		  super()
		end

		def get_car()			  
		  car_array = []
		  session = Puppet::NetDev::CE::Device.session
		  
		  get_car_xml ='<rpc><get><filter type="subtree"><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfCarTmpls><qosIfCarTmpl><CarTmplName></CarTmplName><cir></cir><pir></pir><cbs></cbs><pbs></pbs></qosIfCarTmpl></qosIfCarTmpls></qos></filter></get></rpc>'
		  car_all = session.rpc.do_config(get_car_xml)
		  
          if car_all.element_children.count != 0
		  car_element = car_all.first_element_child.first_element_child
		  car_element.element_children.each do |car_elem|
		  car_doc_speed = Nokogiri::XML(car_elem.to_s)
		  car_name = car_doc_speed.xpath("/qosIfCarTmpl/CarTmplName").text	
          car_speed = car_doc_speed.xpath("/qosIfCarTmpl/cir").text
		  
		  property_hash = {:ensure => :present}
		  property_hash[:name] = car_name
		  property_hash[:speed] = car_speed
		  
		  get_car_apply_xml = '<rpc><get><filter type="subtree"><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfQoss><qosIfCars><qosIfCar><ifName></ifName><direction>inbound</direction><CarTmplName></CarTmplName></qosIfCar></qosIfCars></qosIfQoss></qos></filter></get></rpc>'
		  
		  car_apply_all = session.rpc.do_config(get_car_apply_xml)

		  if car_apply_all.element_children.count != 0		  
		     car_apply_elements = car_apply_all.first_element_child.first_element_child.first_element_child
		     car_apply_elements.element_children.each do |car_apply_elem|
		        car_doc = Nokogiri::XML(car_apply_elem.to_s)
		        car_name_get = car_doc.xpath("/qosIfCar/CarTmplName").text
                if car_name_get == car_name
			 
			       car_interface = car_doc.xpath("/qosIfCar/ifName").text
				   property_hash[:interface_name] = car_interface
			    end
		      end
          end

		  	 car_array << property_hash
		  end
			
		 end 		
		  return car_array
			
	    end
        
	
		def set_car(resource)	
		   session = Puppet::NetDev::CE::Device.session
		   create_car_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfCarTmpls><qosIfCarTmpl operation="create"><CarTmplName>' + "#{resource[:name]}" + '</CarTmplName><cir>' + "#{resource[:speed]}" + '</cir><pir></pir><cbs></cbs><pbs></pbs></qosIfCarTmpl></qosIfCarTmpls></qos></config></edit-config></rpc>'
		   session.rpc.do_config(create_car_xml)
		   
		   if resource[:interface_name] != nil && !resource[:interface_name].empty?
		    set_car_apply_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfQoss><qosIfCars><qosIfCar operation="create"><ifName>' + "#{resource[:interface_name]}" + '</ifName><direction>inbound</direction><CarTmplName>' + "#{resource[:name]}" + '</CarTmplName></qosIfCar></qosIfCars></qosIfQoss></qos></config></edit-config></rpc>'
		    session.rpc.do_config(set_car_apply_xml)
		   end
			
			
		   if resource[:interface_name] != nil && resource[:interface_name].empty?
			   car_interface = nil
		       get_car_apply_xml = '<rpc><get><filter type="subtree"><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfQoss><qosIfCars><qosIfCar><ifName></ifName><direction>inbound</direction><CarTmplName></CarTmplName></qosIfCar></qosIfCars></qosIfQoss></qos></filter></get></rpc>'
		       car_apply_all = session.rpc.do_config(get_car_apply_xml)
		       if car_apply_all.element_children.count != 0		  
		          car_apply_elements = car_apply_all.first_element_child.first_element_child.first_element_child
		          car_apply_elements.element_children.each do |car_apply_elem|
		             car_doc = Nokogiri::XML(car_apply_elem.to_s)
		             car_name_get = car_doc.xpath("/qosIfCar/CarTmplName").text
                     if car_name_get == resource[:name]
			           car_interface = car_doc.xpath("/qosIfCar/ifName").text
			         end
		          end
               end
		    

		      if car_interface != nil
		         delete_car_apply_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfQoss><qosIfCars><qosIfCar operation="delete"><ifName>' + "#{car_interface}" + '</ifName><direction>inbound</direction></qosIfCar></qosIfCars></qosIfQoss></qos></config></edit-config></rpc>'
                 session.rpc.do_config(delete_car_apply_xml)
		      end
		  end    			
		end

		
        def create_car(resource)
		   session = Puppet::NetDev::CE::Device.session
		   create_car_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfCarTmpls><qosIfCarTmpl operation="create"><CarTmplName>' + "#{resource[:name]}" + '</CarTmplName><cir>' + "#{resource[:speed]}" + '</cir><pir></pir><cbs></cbs><pbs></pbs></qosIfCarTmpl></qosIfCarTmpls></qos></config></edit-config></rpc>'
		   session.rpc.do_config(create_car_xml) 
		end
		
		def delete_car(resource)
		   session = Puppet::NetDev::CE::Device.session
		   car_interface = nil
		   get_car_apply_xml = '<rpc><get><filter type="subtree"><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfQoss><qosIfCars><qosIfCar><ifName></ifName><direction>inbound</direction><CarTmplName></CarTmplName></qosIfCar></qosIfCars></qosIfQoss></qos></filter></get></rpc>'
		   car_apply_all = session.rpc.do_config(get_car_apply_xml)

		   if car_apply_all.element_children.count != 0		  
		     car_apply_elements = car_apply_all.first_element_child.first_element_child.first_element_child
		     car_apply_elements.element_children.each do |car_apply_elem|
		       car_doc = Nokogiri::XML(car_apply_elem.to_s)
		       car_name_get = car_doc.xpath("/qosIfCar/CarTmplName").text
                if car_name_get == resource[:name]
			      car_interface = car_doc.xpath("/qosIfCar/ifName").text
			    end
		      end
           end
		    

		   if car_interface != nil
		     delete_car_apply_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfQoss><qosIfCars><qosIfCar operation="delete"><ifName>' + "#{car_interface}" + '</ifName><direction>inbound</direction></qosIfCar></qosIfCars></qosIfQoss></qos></config></edit-config></rpc>'
             session.rpc.do_config(delete_car_apply_xml) 
		   end
		   
		  delete_car_xml = '<rpc><edit-config><target><running/></target><default-operation>merge</default-operation><error-option>rollback-on-error</error-option><config><qos xmlns="http://www.huawei.com/netconf/vrp" content-version="1.0" format-version="1.0"><qosIfCarTmpls><qosIfCarTmpl operation="delete"><CarTmplName>' + "#{resource[:name]}" + '</CarTmplName></qosIfCarTmpl></qosIfCarTmpls></qos></config></edit-config></rpc>'
		  session.rpc.do_config(delete_car_xml) 		
	    end
	  end
	
	end
  end
end    

