class AddGoogleFieldsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :access_token, :text
    add_column :users, :refresh_token, :text
    add_column :users, :expire_at, :datetime
  end
end
