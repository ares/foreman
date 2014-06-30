class AddAncestryToNics < ActiveRecord::Migration
  def self.up
    add_column :nics, :ancestry, :string
    add_index :nics, :ancestry
  end

  def self.down
    remove_index :nics, :ancestry
    remove_column :nics, :ancestry
  end
end
