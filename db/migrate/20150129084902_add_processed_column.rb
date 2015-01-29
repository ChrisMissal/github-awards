class AddProcessedColumn < ActiveRecord::Migration
  def change
    add_column :repositories, :forked, :boolean, null: false, default: false
  end
end
