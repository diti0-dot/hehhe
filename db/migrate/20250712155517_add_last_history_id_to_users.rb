class AddLastHistoryIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_history_id, :bigint
  end
end
