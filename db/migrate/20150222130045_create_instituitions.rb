class CreateInstituitions < ActiveRecord::Migration
  def change
    create_table :instituitions do |t|
      t.string :name
      t.string :abbr
      t.references :location, index: true

      t.timestamps null: false
    end
    add_foreign_key :instituitions, :locations
  end
end
