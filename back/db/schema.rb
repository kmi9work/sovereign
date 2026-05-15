# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_05_05_074000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_types", force: :cascade do |t|
    t.string "action_type"
    t.string "name"
    t.string "display_params"
    t.string "success_result"
    t.string "failure_result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "actions", force: :cascade do |t|
    t.bigint "position_id", null: false
    t.bigint "action_type_id", null: false
    t.bigint "country_id", null: false
    t.bigint "second_country_id"
    t.bigint "province_id"
    t.integer "cycle_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "read", default: false, null: false
    t.boolean "result", default: false, null: false
    t.index ["action_type_id"], name: "index_actions_on_action_type_id"
    t.index ["country_id"], name: "index_actions_on_country_id"
    t.index ["position_id"], name: "index_actions_on_position_id"
    t.index ["province_id"], name: "index_actions_on_province_id"
    t.index ["second_country_id"], name: "index_actions_on_second_country_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parameters", force: :cascade do |t|
    t.integer "current_cycle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "position_action_types", force: :cascade do |t|
    t.bigint "position_id", null: false
    t.bigint "action_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type_id"], name: "index_position_action_types_on_action_type_id"
    t.index ["position_id", "action_type_id"], name: "index_position_action_types_on_position_id_and_action_type_id", unique: true
    t.index ["position_id"], name: "index_position_action_types_on_position_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "name"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_positions_on_country_id"
  end

  create_table "provinces", force: :cascade do |t|
    t.string "name"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_provinces_on_country_id"
  end

  add_foreign_key "actions", "action_types"
  add_foreign_key "actions", "countries"
  add_foreign_key "actions", "countries", column: "second_country_id"
  add_foreign_key "actions", "positions"
  add_foreign_key "actions", "provinces"
  add_foreign_key "position_action_types", "action_types"
  add_foreign_key "position_action_types", "positions"
  add_foreign_key "positions", "countries"
  add_foreign_key "provinces", "countries"
end
