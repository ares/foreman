class FakeNic < ActiveRecord::Base
  self.table_name = 'nics'

  attr_accessible :host_id, :name, :mac, :ip, :subnet_id, :domain_id, :identifier,
                  :virtual, :primary, :managed

  def type
    Nic::Managed
  end
end

class FakeHost < ActiveRecord::Base
  self.table_name = 'hosts'

  attr_accessible :mac, :ip, :subnet_id, :domain_id, :primary_interface

  def type
    Host::Managed
  end
end

class MoveHostNicsToInterfaces < ActiveRecord::Migration
  def up
    add_column :nics, :primary, :boolean, :default => false

    say "Migrating Host interfaces to Nic primaries"
    Host::Managed.all.each do |host|
      next unless host.managed?
      nic = FakeNic.new
      nic.host_id = host.id
      nic.name = host.name
      nic.mac = host.mac
      nic.ip = host.ip
      nic.subnet_id = host.subnet.id
      nic.domain_id = host.domain.id
      nic.virtual = false
      nic.identifier = host.primary_interface || "eth0"
      nic.managed = true
      nic.primary = true
      nic.save(:validate => false)
      say "  Migrated #{nic.name}-#{nic.identifier} to nics"
    end

    remove_column :hosts, :ip
    remove_column :hosts, :mac
    remove_column :hosts, :primary_interface
    remove_column :hosts, :subnet_id
    remove_column :hosts, :domain_id
  end

  def down
    add_column :hosts, :ip, :string
    add_column :hosts, :mac, :string, :default => ''
    add_column :hosts, :primary_interface, :string
    add_column :hosts, :subnet_id, :integer
    add_column :hosts, :domain_id, :integer

    say "Migrating Nic primaries to Host interfaces"
    FakeHost.all.each do |host|
      next unless host.managed?
      nic = FakeNic.where(:host_id => host.id).where(:primary => true).first
      host.mac = nic.mac
      host.ip = nic.ip
      host.subnet_id = nic.subnet_id
      host.domain_id = nic.domain_id
      host.primary_interface = nic.identifier
      host.save(:validate => false)
      nic.destroy!
    end

    remove_column :nics, :primary
  end
end
