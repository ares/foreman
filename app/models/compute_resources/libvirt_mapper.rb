module ComputeResources
  module LibvirtMapper
    class HypervisorMapper
      attr_accessor :compute_resource
      attr_writer :raw_data

      def initialize(compute_resource)
        @compute_resource = compute_resource
      end

      def raw_data
        @raw_data ||= @compute_resource.hypervisor
      end

      def hypervisor
        @hypervisor ||= raw_data
      end

      def uuid
        hypervisor.uuid
      end

      def type
        hypervisor.type
      end

      def version
        hypervisor.version
      end

      def sockets
        hypervisor.sockets
      end

      def name
        hypervisor.hostname
      end

      # TODO otazka jestli patri do hypervisoru, u ovirtu bude treba nejaka selekce - asi ano, stejne jako guest ma hypervisor
      def guests
        @compute_resource.vms.map { |vm| ComputeResources::Guest.build_by_raw_data(@compute_resource, vm, :hypervisor => self) }
      end
    end

    class GuestMapper
      attr_accessor :compute_resource
      attr_writer :raw_data

      def initialize(compute_resource)
        @compute_resource = compute_resource
      end

      def raw_data
        @raw_data ||= client.servers.new
      end

      def hypervisor
        @hypervisor ||= @compute_resource.hypervisor
      end

      def uuid
        raw_data.uuid
      end

      def state
        raw_data.state
      end

      def active?
        raw_data.active
      end
    end
  end
end
