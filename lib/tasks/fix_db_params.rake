#class ConfigReport < Report
#  def metrics
#    self[:metrics]
#  end
#end
#
#class ForemanOpenscap::ArfReport < Report
#  def metrics
#    self[:metrics]
#  end
#end
#
#desc 'fix wrong typed serialized data'
#task :fix_serialized_data do
#  User.as_anonymous_admin do
#    ConfigReport.all.each do |report|
#      new_metrics = YAML.load(report.metrics.gsub('!ruby/hash:ActionController::Parameters', '!ruby/hash:ActiveSupport::HashWithIndifferentAccess'))
#      new_metrics.permit! if new_metrics.respond_to? :permit!
#      report.metrics = new_metrics
#      report.save!
#    end
#
#    ForemanOpenscap::ArfReport.all.each do |report|
#      new_metrics = YAML.load(report.metrics.gsub('!ruby/hash:ActionController::Parameters', '!ruby/hash:ActiveSupport::HashWithIndifferentAccess'))
#      new_metrics.permit! if new_metrics.respond_to? :permit!
#      report.metrics = new_metrics
#      report.save!
#    end
#  end
#end
