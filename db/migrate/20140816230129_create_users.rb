class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :spotify_user_id
      t.string :refresh_token
    end
  end
end
