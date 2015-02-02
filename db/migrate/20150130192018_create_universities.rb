class CreateUniversities < ActiveRecord::Migration
  def change
    create_table :universities do |t|
      t.string :name
      t.string :abbr
      t.references :location, index: true

      t.timestamps null: false
    end
    add_foreign_key :universities, :locations
  end
end
