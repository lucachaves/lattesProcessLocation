class CreateDegrees < ActiveRecord::Migration
  def change
    create_table :degrees do |t|
      t.string :name
      t.integer :year
      t.references :university, index: true
      t.references :person, index: true

      t.timestamps null: false
    end
    add_foreign_key :degrees, :universities
    add_foreign_key :degrees, :people
  end
end
