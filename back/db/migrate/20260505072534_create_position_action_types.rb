class CreatePositionActionTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :position_action_types do |t|
      t.references :position, null: false, foreign_key: true
      t.references :action_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :position_action_types, %i[position_id action_type_id], unique: true
  end
end
