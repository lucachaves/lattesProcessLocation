# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150130192020) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "degrees", force: :cascade do |t|
    t.string   "name"
    t.integer  "year"
    t.integer  "university_id"
    t.integer  "person_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "degrees", ["person_id"], name: "index_degrees_on_person_id", using: :btree
  add_index "degrees", ["university_id"], name: "index_degrees_on_university_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "city"
    t.string   "city_ascii"
    t.string   "uf"
    t.string   "country"
    t.string   "country_ascii"
    t.string   "country_abbr"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "people", force: :cascade do |t|
    t.string   "id16"
    t.integer  "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "people", ["location_id"], name: "index_people_on_location_id", using: :btree

  create_table "universities", force: :cascade do |t|
    t.string   "name"
    t.string   "abbr"
    t.integer  "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "universities", ["location_id"], name: "index_universities_on_location_id", using: :btree

  add_foreign_key "degrees", "people"
  add_foreign_key "degrees", "universities"
  add_foreign_key "people", "locations"
  add_foreign_key "universities", "locations"
end
