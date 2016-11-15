require 'fog_extensions/vsphere/mini_server'

module FogExtensions
  module Vsphere
    class MiniServers
      def initialize(client, dc)
        @client = client
        @dc     = client.send(:find_datacenters, dc)[0]
      end

      def all(filters = { })
        allvmsbyfolder(dc.vmFolder, nil).map do |entry|
          MiniServer.new(entry[:vm], entry[:path], entry[:uuid])
        end
      end

      def all_hosts
        all_compute_resources_by_folder(@dc.hostFolder, nil).map do |entry|
          entry[:cr].host
        end.flatten
      end
      # host.hardware.systemInfo.uuid
      #     nebo to stejne pres host.summary.hardware.uuid
      # host.guest.guestState
      # host.vm.first.summary.config.uuid

      def all_compute_resources_by_folder(folder, path = nil)
        ret = []
        unless folder == @dc.hostFolder
          path = path.nil? ? folder.name : path + '/' + folder.name
        end
        folder.childEntity.each do |entity|
          if entity.is_a?(RbVmomi::VIM::Folder)
            ret.push(*all_compute_resources_by_folder(entity, path))
          elsif entity.is_a?(RbVmomi::VIM::ComputeResource)
            ret.push({ :cr => entity, :path => path})
          end
        end
        ret
      end

      def allvmsbyfolder(folder, path = nil)
        ret = []
        unless folder == @dc.vmFolder
          path = path.nil? ? folder.name : path + '/' + folder.name
        end
        folder.childEntity.each do |entity|
          if entity.is_a?(RbVmomi::VIM::Folder)
            ret.push(*allvmsbyfolder(entity, path))
          elsif entity.is_a?(RbVmomi::VIM::VirtualMachine)
            config = entity.config
            if (config && !config.template && (uuid = config.instanceUuid))
              ret.push({ :vm => entity, :path => path, :uuid => uuid})
            end
          end
        end
        ret
      end

      private

      attr_reader :client, :dc
    end
  end
end
