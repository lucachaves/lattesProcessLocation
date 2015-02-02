class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :city
      t.string :city_ascii
      t.string :uf
      t.string :country
      t.string :country_ascii
      t.string :country_abbr
      t.float :latitude
      t.float :longitude

      t.timestamps null: false
    end
  end
end
