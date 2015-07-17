class CreateHostStatus < ActiveRecord::Migration
  def self.up
    create_table :host_status do |t|
      t.string :type
      t.integer :status, :default => 0, :null => false
      t.references :host, :null => false
      t.datetime :reported_at, :null => false
    end
    add_column :hosts, :global_status, :integer, :default => 0, :null => false

    Host.all.each do |host|
      host.refresh_statuses
    end

    remove_column :hosts, :puppet_status
  end

  def self.down
    add_column :hosts, :puppet_status, :integer,  :null => false, :default => 0
    remove_column :hosts, :global_status

    Host.all.each do |host|
      config_status = host.host_statuses.find_by_type("HostStatus::ConfigurationStatus")
      unless config_status.nil?
        host.puppet_status = config_status.status
        host.save
      end
    end

    drop_table :host_status
  end
end
