module ComputeResources
  module OvirtMapper
    class HypervisorMapper
      attr_accessor :compute_resource
      attr_writer :raw_data

      def initialize(compute_resource)
        @compute_resource = compute_resource
      end

      def raw_data
        @raw_data ||= raise('host build unsupported by mapper')
      end

      def hypervisor
        @hypervisor ||= raw_data
      end

      def uuid
        hypervisor.id
      end

      # oVirt hypervisor type is always QEMU
      def type
        'qemu'
      end

      def version
        hypervisor.version
      end

      def sockets
        hypervisor.cpu_sockets
      end

      def name
        hypervisor.name
      end

      # TODO otazka jestli patri do hypervisoru, u ovirtu bude treba nejaka selekce - asi ano, stejne jako guest ma hypervisor
      def guests
        @compute_resource.send(:rbovirt_client).vms(:search => "host=#{name}").map do |vm|
          ComputeResources::Guest.build_by_raw_data(@compute_resource, vm, :hypervisor => self)
        end
      end
    end

    class GuestMapper
      attr_accessor :compute_resource
      attr_writer :raw_data

      def initialize(compute_resource)
        @compute_resource = compute_resource
      end

      def raw_data
        @raw_data ||= @compute_resource.send(:client).servers.new
      end

      def hypervisor
        @hypervisor ||= @compute_resource.send(:rbovirt_client).hosts(:search => "vms.id=#{uuid}")
      end

      def uuid
        raw_data.id
      end

      def state
        raw_data.status
      end

      def active?
        state.strip == 'up'
      end
    end
  end
end
