class CreateLanguageRank < ActiveRecord::Migration
  def change
    create_table :language_ranks do |t|
      t.integer   :user_id,           null: false
      t.string    :language,          null: false
      t.float     :score,             null: false
      t.integer   :rank,              null: false
      t.integer   :top,               null: false
      t.string    :city
      t.string    :country
      t.integer   :repository_count,  null: false, default: 0
      t.integer   :stars_count,       null: false, default: 0
    end
    
    add_index :language_ranks, [:user_id, :language, :score, :city], name: 'rank_by_city_index'
    add_index :language_ranks, [:user_id, :language, :score, :country], name: 'rank_by_country_index'
  end
end
