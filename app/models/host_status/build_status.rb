module HostStatus
  class BuildStatus < Base

    def name
      N_("Build")
    end

    def to_label
      if host && host.build
        N_("Pending Installation")
      else
        N_("Installed")
      end
    end

    def refresh!
      #TODO: save host.build into status
      super
    end

  end
end

HostStatus.status_registry.add(HostStatus::BuildStatus)
