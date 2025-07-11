class AddUidToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :uid, :string
  end
end
