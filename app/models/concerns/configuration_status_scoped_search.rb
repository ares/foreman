module ConfigurationStatusScopedSearch
  extend ActiveSupport::Concern

  module ClassMethods
    def scoped_search_status(status, options)
      options.merge({
        :offset => HostStatus::ConfigurationStatus::METRIC.index(status.to_s),
        :word_size => HostStatus::ConfigurationStatus::BIT_NUM
      })
      scoped_search options
    end
  end

end
