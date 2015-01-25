class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :github_id,     null: false
      t.string  :login,         null: false
      t.string  :gravatar_url,  null: false
      t.string  :country
      t.string  :city
      t.timestamps              null: false
    end
    
    add_index :users, :login
    add_index :users, :country
    add_index :users, :city
  end
end
