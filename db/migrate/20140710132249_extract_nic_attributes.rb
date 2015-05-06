class FakeBMCNic < ActiveRecord::Base
  self.table_name = 'nics'
  serialize :attrs, Hash

  ATTRIBUTES = [:username, :password, :provider]
  attr_accessible :updated_at, *ATTRIBUTES

  PROVIDERS = %w(IPMI)
  validates :provider, :inclusion => {:in => PROVIDERS}

  ATTRIBUTES.each do |method|
    define_method method do
      self.attrs ||= { }
      self.attrs[method]
    end

    define_method "#{method}=" do |value|
      self.attrs         ||= { }
      old_value = attrs[method]
      self.attrs[method] = value
      # attrs_will_change! makes the record dirty. Otherwise, rails has a bug that it won't save if no other field is changed.
      self.attrs_will_change! if (old_value != value)
    end
  end

  def type
    Nic::BMC
  end
end

class ExtractNicAttributes < ActiveRecord::Migration
  def up
    add_column :nics, :provider, :string
    add_column :nics, :username, :string
    add_column :nics, :password, :string

    say "Extracting serialized attributes"
    Nic::BMC.all.each do |nic|
      nic = nic.becomes(FakeBMCNic)
      if nic.attrs.present?
        nic.attrs.each_pair do |attribute, value|
          if nic.respond_to?(attribute)
            nic.send("#{attribute}=", value)
          else
            raise Foreman::Exception, "can not extract attribute '#{attribute}', delete custom interface and rerun migration"
          end
        end
        nic.type = 'Nic::BMC'
        nic.save(:validate => false)
      end
    end
  end

  def down
    Nic::BMC.all.each do |nic|
      nic = nic.becomes(FakeBMCNic)
      nic.attrs['provider'] = nic.provider unless nic.provider.nil?
      nic.attrs['username'] = nic.username unless nic.username.nil?
      nic.attrs['password'] = nic.password unless nic.password.nil?
      nic.type = 'Nic::BMC'
      nic.save(:validate => false)
    end

    remove_column :nics, :password
    remove_column :nics, :username
    remove_column :nics, :provider
  end
end
