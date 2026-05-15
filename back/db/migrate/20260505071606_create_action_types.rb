class CreateActionTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :action_types do |t|
      t.string :action_type
      t.string :name
      t.string :display_params
      t.string :success_result
      t.string :failure_result

      t.timestamps
    end
  end
end
