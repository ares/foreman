module ComputeResources
  class Hypervisor
    include ActiveModel::Model

    attr_accessor :compute_resource, :mapper

    def initialize(params = {})
      super
      @mapper = self.compute_resource.mapper(self.class.to_s.split('::').last)
    end

    def self.build_by_raw_data(compute_resource, raw_data, params = {})
      hypervisor = new({ :compute_resource => compute_resource }.merge(params))
      hypervisor.mapper.raw_data = raw_data
      hypervisor
    end

    # Public API of this object
    delegate :uuid, :type, :version, :sockets, :to => :mapper

    def guests
      @guests ||= @mapper.guests
    rescue => e
      Foreman::Logging.exception("Failed to load guests", e)
      return []
    end
    # End of public API

    # TODO virt-who specific view layer, should not be defined here
    # TODO ovirt type neni uplne jak zjistit, hypervisor api ho nevraci, default to QEMU nebo se podivat jak to dela virt-who
    def vw_attributes
      {
        :uuid => uuid.downcase, # TODO must be also able to use hostname or "hwuuid"
        :guests => guests.map(&:vw_attributes),
        :facts => {
          :"hypervisor.type" => type, # qemu nebo VMware ESXi, definovat by se mel hypervisor sam
          :"cpu.cpu_socket(s)" => sockets,
          :"hypervisor.version" => version
        }
      }
    end
  end
end
