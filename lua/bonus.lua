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
	if lua_current_side == 0 then return end

	local total_regions = wml.variables['CE_SYSTEM.regions.length']
	local income_bonus = 0
	for i=0,total_regions-1,1 do
		local region_name_id = wml.variables['CE_SYSTEM.regions['..i..'].id']
		local all_villages_belong_to_this_player = true
		local total_villages_in_region = wml.variables['CE_SYSTEM.regions_'..region_name_id..'.length']

		for j=0,total_villages_in_region-1,1 do
			local villa_owner_x = wml.variables['CE_SYSTEM.regions_'..region_name_id..'['..j..'].x']
			local villa_owner_y = wml.variables['CE_SYSTEM.regions_'..region_name_id..'['..j..'].y']
			local villa_owner_side = wesnoth.map.get_owner{ villa_owner_x, villa_owner_y }
			if lua_current_side ~= villa_owner_side then
				all_villages_belong_to_this_player = false
				break
			end
		end

		if all_villages_belong_to_this_player == true then
			income_bonus = income_bonus + wml.variables['CE_SYSTEM.regions['..i..'].bonus']
		end
	end

	local initial_income = wesnoth.sides[lua_current_side].variables.initial_income or 2
	local ai_extra_income = wml.variables['CE_SYSTEM.Experimental_AI_Extra_Gold_perturn'] or 0

	if ai_extra_income == 0 then
		wesnoth.sides[lua_current_side].base_income = initial_income + income_bonus
	else

		local p = wesnoth.sync.evaluate_single( function() return { controller = wesnoth.sides[lua_current_side].controller } end )

		if p.controller == 'ai' then
			wesnoth.sides[lua_current_side].base_income = initial_income + income_bonus + ai_extra_income
		else
			wesnoth.sides[lua_current_side].base_income = initial_income + income_bonus
		end
	end
end

-- >>
