-- <<

function create_total_bonus_message()
	local _ = wesnoth.textdomain 'wesnoth-Conquest'
	-- po: visible when you move the mouse over the flag icon in the top bar of the game
	local lua_message = _'Total Bonus:'
	local all_sides = wesnoth.sides.find{ wml.tag.has_unit { canrecruit = true } }

	for i,v in ipairs(all_sides) do
		local color = v.variables.colorname or wesnoth.colors[v.color].pango_color
		local spancolor = "<span color='"..color.."'>"
		local spancolor_end = '</span>'
		lua_message = lua_message.."\n"..spancolor.. _'Base income:'..' '..v.base_income..spancolor_end
	end
	wml.variables['CE_SYSTEM.total_bonus_message'] = lua_message
end

function calculate_region_bonus(lua_current_side)
	local lua_total_regions = wml.variables['CE_SYSTEM.regions.length']
	local lua_income_bonus = 0
	for i=0,lua_total_regions-1,1 do
		local lua_region_name_id = wml.variables['CE_SYSTEM.regions['..i..'].id']
		local lua_all_villages_belong_to_this_player = true
		local lua_total_villages_in_region = wml.variables['CE_SYSTEM.regions_'..lua_region_name_id..'.length']

		for j=0,lua_total_villages_in_region-1,1 do
			local lua_villa_owner_x = wml.variables['CE_SYSTEM.regions_'..lua_region_name_id..'['..j..'].x']
			local lua_villa_owner_y = wml.variables['CE_SYSTEM.regions_'..lua_region_name_id..'['..j..'].y']
			local lua_villa_owner_side = wesnoth.map.get_owner{ lua_villa_owner_x, lua_villa_owner_y }
			if lua_current_side ~= lua_villa_owner_side then
				lua_all_villages_belong_to_this_player = false
				break
			end
		end

		if lua_all_villages_belong_to_this_player == true then
			lua_income_bonus = lua_income_bonus + wml.variables['CE_SYSTEM.regions['..i..'].bonus']
		end
	end
	wml.fire('modify_side', { side = lua_current_side, income = lua_income_bonus })
end

-- >>
