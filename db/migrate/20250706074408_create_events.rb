class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.datetime :start_time
      t.datetime :end_time
      t.references :preferred_email, null: false, foreign_key: true

      t.timestamps
    end
  end
end
