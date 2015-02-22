class CreateDegrees < ActiveRecord::Migration
  def change
    create_table :degrees do |t|
      t.string :name
      t.integer :start_year
      t.integer :end_year
      t.references :instituition, index: true
      t.references :person, index: true

      t.timestamps null: false
    end
    add_foreign_key :degrees, :instituitions
    add_foreign_key :degrees, :people
  end
end
