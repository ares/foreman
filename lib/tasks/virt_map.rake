namespace :virt_map do
  desc <<-END_DESC
Synchronize all guests on all supported compute-resource to candlepin

Examples:
  # foreman-rake virt_map:sync_all
END_DESC

  task :sync_all => :environment do
    #ComputeResource.all.each do |compute_resource|
    Foreman::Model::Vmware.all.each do |compute_resource|
      unless compute_resource.supports_hypervisors_reporting?
        puts "ignoring CR #{compute_resource.name} since it's type #{compute_resource.type} is not supported"
        next
      end

      puts generate_json(compute_resource)
    end
  end

  def generate_json(compute_resource)
    pp generate_hash(compute_resource)
    #generate_hash(compute_resource).to_json
  end

  def generate_hash(compute_resource)
    {
      :hypervisors => compute_resource.hypervisors.map(&:vw_attributes)
    }
  end
end
