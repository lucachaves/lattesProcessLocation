class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :id16
      t.references :location, index: true
      t.references :instituition, index: true

      t.timestamps null: false
    end
    add_foreign_key :people, :locations
    add_foreign_key :people, :instituitions
  end
end
