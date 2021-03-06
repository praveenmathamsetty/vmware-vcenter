# Copyright (C) 2015 VMware, Inc.
require 'pathname'
module_lib = Pathname.new(__FILE__).parent.parent.parent

require File.join module_lib, 'puppet_x/vmware/mapper'
require File.join module_lib, 'puppet_x/vmware/vmware_lib/puppet_x/vmware/util'
require File.join module_lib, 'puppet_x/vmware/vmware_lib/puppet/property/vmware'

Puppet::Type.newtype(:vc_ip_pool) do
  @doc = "Manage vCenter IpPools. http://pubs.vmware.com/vsphere-55/index.jsp#com.vmware.wssdk.apiref.doc/vim.vApp.IpPool.html"

  ensurable do
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:label, :namevar => true) do
    desc 'Pool name. The pool name must be unique within the datacenter.'
  end

  newparam(:datacenter) do 
    desc 'The datacenter target for the IpPool'
  end

  newparam(:force_destroy) do
    desc 'If true, the pool will be destroyed even if it is in use'
    newvalues(:true,:false)
    defaultto :false
  end

  map = PuppetX::VMware::Mapper.new_map('IpPoolMap')
  map.leaf_list.each do |leaf|
    option = {}
    if type_hash = leaf.olio[t = Puppet::Property::VMware_Array]
      option.update(
        :array_matching => :all,
        :parent => t
      )
    elsif type_hash = leaf.olio[t = Puppet::Property::VMware_Array_Hash]
      option.update(
        # :array_matching => :all,
        :parent => t
      )
    elsif type_hash = leaf.olio[t = Puppet::Property::VMware_Array_VIM_Object]
      option.update(
        # :array_matching => :all,
        :parent => t
      )
    end
    option.update(type_hash[:property_option]) if
      type_hash && type_hash[:property_option]

    newproperty(leaf.prop_name, option) do
      desc(leaf.desc) if leaf.desc
      newvalues(*leaf.valid_enum) if leaf.valid_enum
      munge {|val| leaf.munge.call(val)} if leaf.munge
      validate {|val| leaf.validate.call(val)} if leaf.validate
      eval <<-EOS
        def change_to_s(is, should)
          "[#{leaf.full_name}] changed \#{is_to_s(is).inspect} to \#{should_to_s(should).inspect}"
        end
      EOS
    end
  end
end
