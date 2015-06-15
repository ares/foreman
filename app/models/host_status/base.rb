module HostStatus
  class Base < ActiveRecord::Base
    include Foreman::STI

    self.table_name = 'host_status'

    belongs_to_host

    def to_global
      HostStatus::Global::OK
    end

    def to_label
      fail NotImplementedError, "Method 'to_label' method needs to be implemented"
    end

    def name
      fail NotImplementedError, "Method 'name' method needs to be implemented"
    end

    def refresh!
      reported_at = Time.now
      save!
    end

    def self.relevant_for_host?(host)
      true
    end

  end

  def self.status_registry
    @status_registry ||= Set.new
  end
end

require_dependency 'host_status/configuration_status'
require_dependency 'host_status/build_status'
