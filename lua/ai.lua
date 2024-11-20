-- <<

-- This code is executed as part of an event at turn end.
-- It places units and reduces in return the gold of the ai side.


function simulate_combat(x1, y1, x2, y2)
	---wesnoth.interface.add_chat_message('harm unit')
	---wesnoth.interface.delay(1000)
	wml.fire('do_command',{{'attack',{ weapon=0, defender_weapon=0, {'source', { x=x1, y=y1 } }, {'destination', { x=x2, y=y2 } } }}})
	---wml.fire('harm_unit',{ delay=0, { 'filter', { x=x1, y=y1 } }, { 'filter_second',{ x=x2, y=y2 } } })
	---wesnoth.interface.delay(2000)
	---[harm_unit]
	---[animate_unit] copy from ranged maybe.. looks like..
	---    [filter]: StandardUnitFilter all matching units will be harmed (required).
	---    [filter_second]: StandardUnitFilter if present, the first matching unit will attack all the units matching the filter above.
	---fire_event: (default no) if yes, when a unit is killed by harming, the corresponding events are fired. If yes, also the corresponding advance and post advance events are fired.
end

function attack_adjacent_enemies(unit_x, unit_y)
	local recruited_unit = wesnoth.units.get(unit_x, unit_y)
	local max_enemy_x = 0
	local max_enemy_y = 0
	local max_enemy_hitpoints = 0
	for x, y in wesnoth.current.map:iter_adjacent(unit_x, unit_y) do
		local enemy_unit = wesnoth.units.get(x, y)
		if enemy_unit then
			if wesnoth.sides.is_enemy(wesnoth.current.side, enemy_unit.side) then
				if recruited_unit.hitpoints > enemy_unit.hitpoints then
					if max_enemy_hitpoints < enemy_unit.hitpoints then
						max_enemy_hitpoints = enemy_unit.hitpoints
						max_enemy_x = enemy_unit.x
						max_enemy_y = enemy_unit.y
					end
					-- attack unit
					-- simulate_combat(unit_x, unit_y, x, y)
					-- wesnoth.interface.add_chat_message('There is enemy at '..x..','..y..' with lower or same hitpoints ('..unit_x..','..unit_y..')')
				else
					local enemy_defense = wesnoth.units.defense_on(enemy_unit, wesnoth.current.map[enemy_unit])
					local recruited_unit_defense = wesnoth.units.defense_on(recruited_unit, wesnoth.current.map[recruited_unit])

					if recruited_unit.hitpoints == enemy_unit.hitpoints then
							if enemy_defense <= recruited_unit_defense then
								-- attack unit
								if max_enemy_hitpoints < enemy_unit.hitpoints then
									max_enemy_hitpoints = enemy_unit.hitpoints
									max_enemy_x = enemy_unit.x
									max_enemy_y = enemy_unit.y
								end
								-- simulate_combat(unit_x, unit_y, x, y)
							else
								-- do nothing
							end
					else
						-- do nothing
					end
				end
			end
		end
	end
	if max_enemy_hitpoints > 0 then
		-- attack strongest killable enemy
		simulate_combat(unit_x, unit_y, max_enemy_x, max_enemy_y)
	end
end

function convert_recruit_into_ship(price)
	local ship_spawn = 'ce_spawn_3g_boat'
	if price == 3 then
		ship_spawn = 'ce_spawn_3g_boat'
	elseif price == 5 then
		ship_spawn = 'ce_spawn_5g_dhow'
	elseif price == 10 then
		ship_spawn = 'ce_spawn_10g_caravel'
	elseif price == 15 then
		ship_spawn = 'ce_spawn_15g_galleon'
	elseif price == 25 then
		ship_spawn = 'ce_spawn_25g_warship'
	end
	return ship_spawn
end

function spawn_units(amount_of_gold, primary_x, primary_y, secondary_x, secondary_y)
if amount_of_gold > 0 then
	local lua_side = wesnoth.current.side
	local free_spaces = wesnoth.map.find{ terrain='Gg,Gs,Re,Rd,W*', include_borders=false, { 'and', { x=primary_x, y=primary_y, radius=1 }},{'not', {{'filter', {} }} } }
	---local gold_per_hex = mathx.round(amount_of_gold / #free_spaces)
	local gold_per_hex = mathx.round(amount_of_gold / 1.5)
	local spawn_array = {}
	---local goto_array = {}
	local c = 0
	for ff, pos in ipairs(free_spaces) do
		local spawn = 'ce_spawn_25g_General'
		local spawn_cost = 25
		if primary_x == 0 then primary_x=secondary_x primary_y=secondary_y end

		if gold_per_hex >25 then
			spawn = 'ce_spawn_25g_General'
			spawn_cost = 25
		elseif gold_per_hex > 25 then
			spawn = 'ce_spawn_25g_General'
			spawn_cost = 25
		elseif gold_per_hex > 20 then
			spawn = 'ce_spawn_20g_Knight'
			spawn_cost = 20
		elseif gold_per_hex > 15 then
			spawn = 'ce_spawn_15g_Lieutenant'
			spawn_cost = 15
		elseif gold_per_hex > 10 then
			spawn = 'ce_spawn_10g_Lancer'
			spawn_cost = 10
		elseif gold_per_hex > 8 then
			spawn = 'ce_spawn_8g_Eliteinfantry'
			spawn_cost = 8
		elseif gold_per_hex > 5 then
			spawn = 'ce_spawn_5g_Cavalry'
			spawn_cost = 5
		elseif gold_per_hex > 3 then
			spawn = 'ce_spawn_3g_Sergeant'
			spawn_cost = 3
		else
			if #free_spaces > 2 then
				if amount_of_gold >= 10 then
					spawn = 'ce_spawn_10g_Lancer'
					spawn_cost = 10
				elseif amount_of_gold >= 8 then
					spawn = 'ce_spawn_8g_Eliteinfantry'
					spawn_cost = 8
				elseif amount_of_gold >= 5 then
					spawn = 'ce_spawn_5g_Cavalry'
					spawn_cost = 5
				elseif amount_of_gold >= 3 then
					spawn = 'ce_spawn_3g_Sergeant'
					spawn_cost = 3
				else
					spawn = 'ce_spawn_1g_militia'
					spawn_cost = 1
				end
			else
				if gold_per_hex > 0 then
					spawn = 'ce_spawn_1g_militia'
					spawn_cost = 1
				end
			end
		end

		if not wesnoth.units.get(primary_x, primary_y) then
			local bool water = wesnoth.map.matches(pos.x, pos.y, { terrain = 'W*^*' })
			-- wesnoth.interface.add_chat_message('water='..water..', bool='..bool)
			---{ 'not', terrain = 'Wwf^*' }
			if water == false then
				if amount_of_gold >= spawn_cost then
					amount_of_gold = amount_of_gold - spawn_cost

					-- MASSIVE AI IMPROVEMENTS WILL HAPPEN WHEN:

					-- 1 --
					-- AI to try to capture full bonus cities first.
					-- AI looks what regions he already has.
					-- AI includes 10 radius other regions
					-- AI calculates how many villages of regions missing
					-- AI selects less villages left to capture
					-- AI targets these villages.. including recruiting near

					-- 2 --
					-- priority recruit in villa where enemy is in 2 hex radius (try recruit health > health)
					-- move near enemies and attack enemies adjacent to recruit units if health >= health

					-- 3 --
					-- when weaker unit is inside vilage with stronger enemy adjacent and still has attacks left on end of turn
					-- make it suicide to be able to recruit units in that city [do command] [attack]

					-- 4 --
					-- load / unload ship events. so can use them easily with lua.
					-- perform the test for empty village near ship after every moveto event involving unit out of village
					-- load ships near village (if ship empty) (recruit 1g militia and board it)
					-- unload ships near empty enemy village (after attack event or something)

					-- 5 --
					-- AI to protect full bonus villages..
					-- try to make sure that city has same amount of units as enemies in radius 10
					-- or same gold value units.. maybe 1 super strong, depending how many villages are threatened vs how much gold AI has

					-- ai for all maps (elfs, orcs etc) (convert function to work, easy)

					-- should be able to droid properly a side that you control on your turn even without being host.

					-- heal units

					-- animate all players recruits (move all units to my system.. of events)

					c = c + 1
					-- wesnoth.interface.add_chat_message(c..','..pos.x..','..pos.y)
					spawn_array[c] = {}
					spawn_array[c][1] = spawn
					spawn_array[c][2] = pos.x
					spawn_array[c][3] = pos.y
					spawn_array[c][4] = 'flat'
					spawn_array[c][5] = spawn_cost
				end
			else
				if amount_of_gold >= spawn_cost then
					if spawn_cost >= 3 then
						amount_of_gold = amount_of_gold - spawn_cost
						c = c + 1
						spawn_array[c] = {}
						spawn_array[c][1] = spawn
						spawn_array[c][2] = pos.x
						spawn_array[c][3] = pos.y
						spawn_array[c][4] = 'water'
						spawn_array[c][5] = spawn_cost
					end
				end
			end
		end
	end
	for j=c,1,-1 do
		wml.variables.ce_spawn = { side = lua_side, x = primary_x, y = primary_y, animate = true }
		if j>1 then
			if spawn_array[j][4] == 'water' then
				wesnoth.game_events.fire(convert_recruit_into_ship(spawn_array[j][5]))
			else
				wesnoth.game_events.fire(spawn_array[j][1])
			end
			wesnoth.interface.move_unit_fake({ x=primary_x, y=primary_y }, spawn_array[j][2], spawn_array[j][3])
			attack_adjacent_enemies(spawn_array[j][2], spawn_array[j][3])
		else
			wesnoth.game_events.fire(spawn_array[j][1])
			attack_adjacent_enemies(primary_x, primary_y)
		end
		wml.variables.ce_spawn = nil
	end
end
return amount_of_gold
end

--------------- /end of spawn function procedure
---------------------------------------------

local lua_side = wesnoth.current.side
local side_gold = wesnoth.sides[lua_side].gold
local side_villages = wesnoth.map.find{ gives_income=true, owner_side=lua_side }
-- wesnoth.interface.add_chat_message('AI side has '..side_gold..' gold and '..#side_villages..' villages.')
-- local free_spaces = wesnoth.map.find{ terrain='Gg,Gs,Re,Rd,Wwf', owner_side=lua_side}
local total_free_spaces = 0
local each_village_enemies = 0
local max_enemies_x = 0
local max_enemies_y = 0
local max_enemies_num = 0
local min_enemies_x = 0
local min_enemies_y = 0
local min_enemies_num = 0
local max_random_villa_no_enemies_x = 0
local max_random_villa_no_enemies_y = 0
local min_random_villa_no_enemies_x = 0
local min_random_villa_no_enemies_y = 0
local region_counter = {}

if #side_villages > 1 then
	mathx.shuffle(side_villages)
	local rcounter = 0
	for f, pairs_xy in ipairs(side_villages) do
		-------------------------------------------------
	--		local total_villages_in_region = wml.variables['CE_SYSTEM.regions_'..wml.variables['CE_SYSTEM.regions_city_'..pairs_xy.x..'_'..pairs_xy.y..'.region_id']..'.length']
	--		local region_id = wml.variables['CE_SYSTEM.regions_city_'..pairs_xy.x..'_'..pairs_xy.y..'.region_id']
			-- wesnoth.interface.add_chat_message('Region '..region_id..' has '..total_villages_in_region..' villages')
	--		region_counter[rcounter] = {}
	--		region_counter[rcounter][1] = region_id
	--		if region_counter[rcounter][2] then
	--			region_counter[rcounter][2] = region_counter[rcounter][2] + 1
	--		else
	--			region_counter[rcounter][2] = 0
	--		end
	--		region_counter[rcounter][3] = total_villages_in_region
	--		rcounter = rcounter + 1
			-- {VARIABLE CE_SYSTEM.regions_city_{X}_{Y}.region_id
			-- {VARIABLE CE_SYSTEM.regions_{ID}_bonus
			-- {VARIABLE CE_SYSTEM.regions_{REGION}.length
			-- count each villa of same region
			-- count how many missing
			-- priority recruit before turn 5-7 near bonus

			-------------------------------------------------
		local lua_unit = wesnoth.units.get(pairs_xy.x, pairs_xy.y)
		if not lua_unit then
			if max_random_villa_no_enemies_x == 0 then
				max_random_villa_no_enemies_x = pairs_xy.x
				max_random_villa_no_enemies_y = pairs_xy.y
			else
				min_random_villa_no_enemies_x = pairs_xy.x
				min_random_villa_no_enemies_y = pairs_xy.y
			end
			local free_spaces = wesnoth.map.find{ terrain='Gg,Gs,Re,Rd,W*', include_borders=false, { 'and', { x=pairs_xy.x, y=pairs_xy.y, radius=1 }},{'not', {{'filter', {} }} } }
			local enemies_in_radius_locations = wesnoth.map.find{ terrain='*^*',  { 'and', { x=pairs_xy.x, y=pairs_xy.y, radius=10 }},{'filter', { canrecruit=false, {'filter_side', {{'enemy_of',{ side = lua_side} }} }} } }
						---+ #wesnoth.map.find{ terrain='*^*',  { 'and', { x=pairs_xy.x, y=pairs_xy.y, radius=10 }},{'filter', {{'filter_side', {{'enemy_of',{ side = lua_side} }} }} } }

			if enemies_in_radius_locations then
				local enemies_in_radius = #enemies_in_radius_locations
				-- wesnoth.map.add_label{ x=pairs_xy.x, y=pairs_xy.y, text=enemies_in_radius, color={255,255,255} }
				if enemies_in_radius > 0 then
					if enemies_in_radius > max_enemies_num then
						max_enemies_num = enemies_in_radius
						max_enemies_x =	pairs_xy.x
						max_enemies_y =	pairs_xy.y
					end
					if min_enemies_num == 0 then
						if enemies_in_radius > 0 then
							min_enemies_num = enemies_in_radius
							min_enemies_x =	pairs_xy.x
							min_enemies_y =	pairs_xy.y
						end
					else
						if enemies_in_radius < min_enemies_num then
							min_enemies_num = enemies_in_radius
							min_enemies_x =	pairs_xy.x
							min_enemies_y =	pairs_xy.y
						end
					end
				end
			end
			-- total_free_spaces = total_free_spaces + #free_spaces + 1
		end
	end
--	for i=0,#region_counter,1 do
--		wesnoth.interface.add_chat_message('AI has '..region_counter[i][2]..'/'..region_counter[i][3]..' villages of Region '..region_counter[i][1])
--	end
	----------------------------------
	local third_of_gold = mathx.round(side_gold / 3)
	local larger_gold = third_of_gold * 2
	third_of_gold = side_gold - larger_gold
	----------------------------------------------
	larger_gold = spawn_units(larger_gold, max_enemies_x, max_enemies_y, max_random_villa_no_enemies_x, max_random_villa_no_enemies_y)
	third_of_gold = spawn_units(third_of_gold, min_enemies_x, min_enemies_y, min_random_villa_no_enemies_x, min_random_villa_no_enemies_y)
	local remaining_gold = third_of_gold + larger_gold
	for f, pairss_xy in ipairs(side_villages) do
		local lua_unit = wesnoth.units.get(pairss_xy.x, pairss_xy.y)
		if not lua_unit then
			remaining_gold = spawn_units(remaining_gold, pairss_xy.x, pairss_xy.y, 0, 0)
		end
	end
	----------------------------------------------
	wesnoth.sides[lua_side].gold = remaining_gold
	-------------------------
else
	local remaining_gold = side_gold
	for f, pairss_xy in ipairs(side_villages) do
		local lua_unit = wesnoth.units.get(pairss_xy.x, pairss_xy.y)
		if not lua_unit then
			remaining_gold = spawn_units(remaining_gold, pairss_xy.x, pairss_xy.y, 0, 0)
		end
	end
	----------------------------------------------
	wesnoth.sides[lua_side].gold = remaining_gold
	-------------------------
end
-- wesnoth.interface.add_chat_message('AI side has '..side_gold..' gold and '..#side_villages..' villages with '..total_free_spaces..' free spaces.')
-- wesnoth.interface.add_chat_message('AI side has'..side_gold..'gold left')

-- >>
