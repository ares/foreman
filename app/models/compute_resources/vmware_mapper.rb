module ComputeResources
  module VmwareMapper
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
        hypervisor.summary.hardware.uuid # or hypervisor.hardware.systemInfo.uuid
      end

      def type
        hypervisor.summary.config.product.name
      end

      def version
        hypervisor.summary.config.product.version
      end

      def sockets
        hypervisor.summary.hardware.numCpuPkgs
      end

      def name
        hypervisor.name
      end

      # TODO otazka jestli patri do hypervisoru, u ovirtu bude treba nejaka selekce - asi ano, stejne jako guest ma hypervisor
      def guests
        hypervisor.vm.map do |vm|
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
        @raw_data ||= raise('guest build unsupported by mapper')
      end

      def hypervisor
        # @hypervisor ||= @compute_resource.send(:rbovirt_client).hosts(:search => "vms.id=#{uuid}")
        # TODO
        raise 'not sure how to find host of guest atm'
      end

      def uuid
        # some vmware vms can have uuid missing, seems like some issue in vmware
        if raw_data.summary.config.uuid.nil?
          Rails.logger.debug "vmware guest #{raw_data.name} has empty UUID"
        end
        raw_data.summary.config.uuid || ''
      end

      def state
        raw_data.guest.guestState
      end

      def active?
        state.strip == 'running'
      end
    end
  end
end
