class CreatePreferredEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :preferred_emails do |t|
      t.string :email
      t.string :subject
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
