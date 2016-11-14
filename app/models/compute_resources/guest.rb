module ComputeResources
  class Guest
    include ActiveModel::Model

    attr_accessor :vm, :hypervisor
    # TODO add mapper object, don't ask vm directly
    #   this instance should find out type based on compute resource, and create mapper accordingly
    #   similarly hypervisor should
    #   this way guest and hypervisor will have same API and share it
    # TODO also needs compute resource so it can create own hypervisor instance, in worst case by cr.hypervisors.select ... but it's CR type specific
    #   but hypervisor is only needed for type which we won't need when we have mapper from initializer. hypervisor might not be needed at all here or
    #   can be constructed through mapper if it's missing as it's specific to CR

    def provider
      hypervisor.provider
    end

    # STATE_UNKNOWN = 0      # unknown state
    # STATE_RUNNING = 1      # running
    # STATE_BLOCKED = 2      # blocked on resource
    # STATE_PAUSED = 3       # paused by user
    # STATE_SHUTINGDOWN = 4  # guest is being shut down
    # STATE_SHUTOFF = 5      # shut off
    # STATE_CRASHED = 6      # crashed
    # STATE_PMSUSPENDED = 7  # suspended by guest power management

    VIRTWHO_MAPPING = {
      "UNKNOWN" => 0,      # unknown state
      "RUNNING" => 1,      # running
      "BLOCKED" => 2,      # blocked on resource
      "PAUSED" => 3,       # paused by user
      "SHUTINGDOWN" => 4,  # guest is being shut down
      "SHUTOFF" => 5,      # shut off
      "CRASHED" => 6,      # crashed
      "PMSUSPENDED" => 7,  # suspended by guest power management
    }

    # TODO virt-who specific
    def attributes
      {
        :guestId => vm.uuid.downcase,
        :state => VIRTWHO_MAPPING[vm.state.upcase],
        :attributes => {
          :virtWhoType => provider.downcase,
          :active => vm.active ? '1' : '0'
        }
      }
    end
  end
end
