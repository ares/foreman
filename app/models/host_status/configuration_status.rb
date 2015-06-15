module HostStatus
  class ConfigurationStatus < Base
    METRIC = %w[applied restarted failed failed_restarts skipped pending]
    BIT_NUM = 6
    MAX = (1 << BIT_NUM) -1 # maximum value per metric

    #TODO: refactor all the methods for getting the metrics

    # generate dynamically methods for all metrics
    # e.g. Report.last.applied
    METRIC.each do |method|
      define_method method do
        get_metric method
      end
    end

    # returns true if total error metrics are > 0
    def error?
      %w[failed failed_restarts].sum {|f| get_metric f} > 0
    end

    # returns true if total action metrics are > 0
    def changes?
      %w[applied restarted].sum {|f| get_metric f} > 0
    end

    # returns true if there are any changes pending
    def pending?
      pending > 0
    end

    def out_of_sync?
      if host && !host.enabled?
        false
      else
        !reported_at.nil? and reported_at < Time.now - (Setting[:puppet_interval] + Setting[:outofsync_interval]).minutes
      end
    end

    def refresh!
      #TODO: get metrics from latest configuration report for a host, use it for status calculation and save it
      #status = ReportStatusCalculator.new(:counters => metrics).calculate
      super
    end

    def to_global
      if error?
        # error
        return HostStatus::Global::ERROR
      elsif out_of_sync?
        # out of sync
        return HostStatus::Global::WARN
      else
        # active, pending, no changes
        return HostStatus::Global::OK
      end
    end

    def name
      N_("Configuration")
    end

    def to_label
      if host && !host.enabled
        N_("Alerts disabled")
      elsif reported_at.nil?
        N_("No reports")
      elsif out_of_sync?
        N_("Out of sync")
      elsif error?
        N_("Error")
      elsif changes?
        N_("Active")
      elsif pending?
        N_("Pending")
      else
        N_("No changes")
      end
    end

    def get_metric(metric)
      @calc ||= ReportStatusCalculator.new(:bit_field => status)
      @calc.status(metric)
    end


    def self.is(config_status)
      "((host_status.status >> #{bit_mask(config_status)}) != 0)"
    end

    def self.is_not(config_status)
      "((host_status.status >> #{bit_mask(config_status)}) == 0)"
    end

    def self.bit_mask(config_status)
      "#{BIT_NUM*METRIC.index(config_status)} & #{MAX}"
    end

  end
end

HostStatus.status_registry.add(HostStatus::ConfigurationStatus)
