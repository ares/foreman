module ComputeResources
  class Hypervisor
    include ActiveModel::Model

    attr_accessor :uuid, :type, :version, :sockets, :compute_resource

    def guests
      compute_resource.vms.map { |vm| Guest.new(:vm => vm, :hypervisor => self) }
    end

    def provider
      compute_resource.provider
    end

    # TODO virt-who specific view layer, should not be defined here
    # TODO virtWhoType je vzdy jeden z --libvirt|--vdsm|--esx|--rhevm|--hyperv, bude treba mapping ale tam kde je to virt-who specific
    # TODO ovirt type neni uplne jak zjistit, hypervisor api ho nevraci, default to QEMU nebo se podivat jak to dela virt-who
    def attributes
      {
        :uuid => uuid.downcase, # TODO must be also able to use hostname or "hwuuid"
        :guests => guests.map(&:attributes),
        :facts => {
          :"hypervisor.type" => type,
          :"cpu.cpu_socket(s)" => sockets,
          :"hypervisor.version" => version
        }
      }
    end
  end
end
