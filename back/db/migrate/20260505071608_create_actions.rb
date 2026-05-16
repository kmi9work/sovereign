class CreateActions < ActiveRecord::Migration[7.0]
  def change
    create_table :actions do |t|
      t.references :position, null: false, foreign_key: true
      t.references :action_type, null: false, foreign_key: true
      t.references :country, null: true, foreign_key: true
      t.references :second_country, null: true, foreign_key: { to_table: :countries }
      t.references :province, null: true, foreign_key: true
      t.integer :cycle_number

      t.timestamps
    end
  end
end
