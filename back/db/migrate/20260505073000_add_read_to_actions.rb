class AddReadToActions < ActiveRecord::Migration[7.0]
  def change
    add_column :actions, :read, :boolean, default: false, null: false
  end
end
