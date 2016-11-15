module ComputeResources
  class Guest
    include ActiveModel::Model
    attr_accessor :compute_resource, :mapper
    attr_writer :hypervisor

    def initialize(params = {})
      super
      @mapper = self.compute_resource.mapper(self.class.to_s.split('::').last)
    end

    def self.build_by_raw_data(compute_resource, raw_data, params = {})
      guest = new({ :compute_resource => compute_resource }.merge(params))
      guest.mapper.raw_data = raw_data
      guest
    end

    # Public API of this object
    delegate :uuid, :state, :active?, :to => :mapper

    def hypervisor
      @hypervisor || @mapper.hypervisor
    rescue => e
      Foreman::Logging.exception("Failed to load hypervisor", e)
      nil
    end
    # End of public API


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
    def vw_attributes
      {
        :guestId => uuid.downcase,
        :state => VIRTWHO_MAPPING[state.upcase], # TODO zjistim jak virt_who tohle dela
        :attributes => {
          :virtWhoType => @compute_resource.provider.downcase, # needs mapping to --libvirt|--vdsm|--esx|--rhevm|--hyperv
          :active => active? ? '1' : '0'
        }
      }
    end
  end
end
