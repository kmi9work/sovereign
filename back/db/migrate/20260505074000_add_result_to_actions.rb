class AddResultToActions < ActiveRecord::Migration[7.0]
  def change
    add_column :actions, :result, :boolean, default: false, null: false
  end
end
