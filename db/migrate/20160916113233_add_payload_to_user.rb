class AddPayloadToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :payload, :json
  end
end
