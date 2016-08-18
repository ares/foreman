class AddInheritingFlagToFilter < ActiveRecord::Migration
  class FakeFilter < ActiveRecord::Base
    self.table_name = 'filters'
  end

  def up
    add_column :filters, :inheriting, :boolean, :default => true, :null => false

    FakeFilter.where.not(:taxonomy_search => nil).update_all(:inheriting => false)
  end

  def down
    remove_column :filters, :inheriting
  end
end
