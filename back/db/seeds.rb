require "csv"

puts "Seeding countries and provinces..."

csv_content = File.read("countries.csv")
csv_content = csv_content.force_encoding("UTF-8").sub("\xEF\xBB\xBF", "")
countries_data = CSV.parse(csv_content, col_sep: ";", headers: true)

country_map = {}

countries_data.each do |row|
  id = row["id"]&.strip
  next if id.blank?

  country_name = row["Страна"]&.strip
  province_name = row["Провинция"]&.strip

  next if country_name.blank? || province_name.blank?

  country_map[country_name] ||= Country.find_or_create_by!(name: country_name)
  Province.find_or_create_by!(name: province_name, country: country_map[country_name])
end

puts "Seeding positions and action types..."

target_country_names = ["Великое княжество Литовское", "Русь"]
target_countries = Country.where(name: target_country_names)

raise "Target countries not found! Available: #{Country.pluck(:name).inspect}" if target_countries.count != 2

position_names = ["Маршал", "Государь", "Управляющий", "Тайный советник", "Епископ", "Инженер", "Дипломат"]

roles_content = File.read("roles.csv")
roles_content = roles_content.force_encoding("UTF-8").sub("\xEF\xBB\xBF", "")
roles_data = CSV.parse(roles_content, col_sep: ",", headers: true)

# Track which action type names belong to which position for linking
position_action_map = {} # position_name => [action_type_names]

roles_data.each do |row|
  position_name = row["Должность"]&.strip
  action_type_label = row["Тип действия"]&.strip
  action_name = row["Название действия"]&.strip
  display_params = row["Параметры показа"]&.strip
  success_result = row["Результат при успехе"]&.strip
  failure_result = row["Результат при неудаче"]&.strip

  next unless position_names.include?(position_name)
  next if action_name.blank?

  type_value = case action_type_label
               when "Приказ вельможи" then "prince"
               when "Приказ Государя" then "noble"
               end

  at = ActionType.find_or_create_by!(action_type: type_value, name: action_name) do |at|
    at.display_params = display_params.presence
    at.success_result = success_result.presence
    at.failure_result = failure_result.presence
  end

  (position_action_map[position_name] ||= []) << at.id
end

# Create positions and link action types
target_countries.each do |country|
  position_names.each do |pname|
    position = Position.find_or_create_by!(name: pname, country: country)
    action_type_ids = position_action_map[pname] || []
    existing_ids = position.position_action_types.pluck(:action_type_id)
    new_ids = action_type_ids - existing_ids
    new_ids.each do |at_id|
      PositionActionType.find_or_create_by!(position: position, action_type_id: at_id)
    end
  end
end

# Create initial parameter record
Parameter.find_or_create_by!(id: 1) { |p| p.current_cycle = 1 }

puts "Seeding done!"
puts "Countries: #{Country.count}"
puts "Provinces: #{Province.count}"
puts "Positions: #{Position.count}"
puts "ActionTypes: #{ActionType.count}"
puts "PositionActionTypes: #{PositionActionType.count}"
puts "Parameter: #{Parameter.count}"
