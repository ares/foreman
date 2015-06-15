module HostStatus
  class Global
    OK = 0
    WARN = 1
    ERROR = 2

    def self.build(statuses)
      status_codes = statuses.map do |status|
        status.to_global
      end.max
    end
  end
end
