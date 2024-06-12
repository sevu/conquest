-- <<

local spawns_theme = wml.variables['CE_SYSTEM.spawns_theme']

if not spawns_theme or (spawns_theme == 11) then
	-- Randomly choosing a spawns theme.
	if wml.variables['CE_SYSTEM.regions'] then
		spawns_theme = mathx.random_choice{ 1, 2, 3, 6, 7, 8, 9, 10 }
	else
		spawns_theme = mathx.random_choice{ 1, 2, 7, 8, 9, 10 }
	end
end

---------------------------------------------------------------
if (spawns_theme == 1) or (spawns_theme == 2) or (spawns_theme == 7) or (spawns_theme == 8) or (spawns_theme == 9) or (spawns_theme == 10) then
-- Random Spawns and Classic 1g
-- Unbiased, Only Humans, Easy, Medium, Hard
---------------------------------------------------------------
	local villages = wesnoth.map.find{ owner_side = 0, gives_income = true }

	for i,v in ipairs(villages) do
		wml.variables.ce_spawn = { side = 7, x = v.x, y = v.y }

		if spawns_theme == 2 then
			-- Classic 1g in each city
			wesnoth.game_events.fire('ce_spawn_1g_militia')

		elseif spawns_theme == 1 then
			-- Conquest Minus
			wesnoth.game_events.fire(mathx.random_choice('ce_spawn_5g_Cavalry,ce_spawn_4g_Dwarvishstalwart,ce_spawn_3g_Sergeant,ce_spawn_2g_Dwarvishguardsman,ce_spawn_1g_militia'))

		elseif spawns_theme == 7 then
			-- Conquest Minus with only Human Spawns
			wesnoth.game_events.fire(mathx.random_choice('ce_spawn_5g_Cavalry,ce_spawn_3g_Sergeant,ce_spawn_1g_militia'))

		elseif spawns_theme == 8 then
			-- Conquest Minus Easy
			wesnoth.game_events.fire(mathx.random_choice('ce_spawn_5g_Cavalry,ce_spawn_4g_Dwarvishstalwart,ce_spawn_3g_Sergeant,ce_spawn_3g_Sergeant,ce_spawn_3g_Sergeant,ce_spawn_2g_Dwarvishguardsman,ce_spawn_2g_Dwarvishguardsman,ce_spawn_2g_Dwarvishguardsman,ce_spawn_2g_Dwarvishguardsman,ce_spawn_1g_militia,ce_spawn_1g_militia,ce_spawn_1g_militia'))

		elseif spawns_theme == 9 then
			-- Conquest Minus Medium
			wesnoth.game_events.fire(mathx.random_choice('ce_spawn_5g_Cavalry,ce_spawn_4g_Dwarvishstalwart,ce_spawn_4g_Dwarvishstalwart,ce_spawn_3g_Sergeant,ce_spawn_3g_Sergeant,ce_spawn_3g_Sergeant,ce_spawn_3g_Sergeant,ce_spawn_2g_Dwarvishguardsman,ce_spawn_2g_Dwarvishguardsman,ce_spawn_1g_militia'))

		elseif spawns_theme == 10 then
			-- Conquest Minus Hard
			wesnoth.game_events.fire(mathx.random_choice('ce_spawn_5g_Cavalry,ce_spawn_5g_Cavalry,ce_spawn_5g_Cavalry,ce_spawn_4g_Dwarvishstalwart,ce_spawn_4g_Dwarvishstalwart,ce_spawn_4g_Dwarvishstalwart,ce_spawn_3g_Sergeant,ce_spawn_3g_Sergeant,ce_spawn_2g_Dwarvishguardsman,ce_spawn_1g_militia'))

		end
		wml.variables.ce_spawn = nil
	end

---------------------------------------------------------------
elseif spawns_theme == 3 then
-- Balanced Hard
-- Region aware code, places one strong unit into every region and many weaker ones.
---------------------------------------------------------------
	local lua_total_regions = wml.variables['CE_SYSTEM.regions.length']
	for i=0,lua_total_regions-1,1 do
		local lua_current_region = wml.variables['CE_SYSTEM.regions['..i..'].id']
		local lua_total_villages = wml.variables['CE_SYSTEM.regions_'..lua_current_region..'.length']
		local counter = lua_total_villages

		-- In difference to the previous, this algorithm is not random but deterministic.
		-- Loop over all villages, but in random order.
		-- That way the units placed in a region are deterministic, but their position in the region is random.
		local order = {}
		for j=0,lua_total_villages-1,1 do
			table.insert(order, j)
		end
		mathx.shuffle(order)

		for z,j in ipairs(order) do
			local spawn_x = wml.variables['CE_SYSTEM.regions_'..lua_current_region..'['..j..'].x']
			local spawn_y = wml.variables['CE_SYSTEM.regions_'..lua_current_region..'['..j..'].y']
			local neutral_village = #wesnoth.map.find{ owner_side = 0, gives_income = true, x = spawn_x, y = spawn_y } > 0

			if neutral_village then
				-- The counter and the different cases ensure that not if some villages are occupied by plyers,
				-- then the weak units are skipped and not the strong ones.
				counter = counter - 1

				wml.variables.ce_spawn = { side = 7, x = spawn_x, y = spawn_y }

				if lua_total_villages == 1 then
					wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
				end

				-- 2 villages regions have one L3 and L5
				if lua_total_villages == 2 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					else
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					end
				end

				-- 3 villages regions have one L1, L3 and L5
				if lua_total_villages == 3 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					else
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					end
				end

				-- 4 villages regions have one L1, two L3 and one L5
				-- This is a second L3 instead of a second L5 compared to Initial
				if lua_total_villages == 4 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					elseif counter == 2 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					else
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					end
				end

				-- 5 villages regions have two L1, two L3 and one L8
				-- Compared to Initial it has an L3 instead of an L5
				if lua_total_villages == 5 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 2 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					elseif counter == 3 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					else
						wesnoth.game_events.fire("ce_spawn_8g_Eliteinfantry")
					end
				end

				-- 6 villages regions have three L1, one L3, one L5 and one L8
				-- Initial has an L10 an and L5 instead of two L1
				if lua_total_villages == 6 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 2 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 3 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					elseif counter == 4 then
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					else
						wesnoth.game_events.fire("ce_spawn_8g_Eliteinfantry")
					end
				end

				-- 7 villages regions have five L1, one L3 and one L15
				-- Initial has an L10, L8, two L5 instead of four L1
				if lua_total_villages == 7 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 2 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 3 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 4 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 5 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					else
						wesnoth.game_events.fire("ce_spawn_15g_Lieutenant")
					end
				end

				-- Even bigger regions have five L1, one L3 and one L15 and for each additional village an L5
				-- Unlike on Initial, each additional village receives an L5 instead of L15
				if lua_total_villages > 7 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 2 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 3 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 4 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 5 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					elseif counter == 6 then
						wesnoth.game_events.fire("ce_spawn_15g_Lieutenant")
					else
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					end
				end

				wml.variables.ce_spawn = nil
			end
		end
	end

---------------------------------------------------------------
elseif spawns_theme == 6 then
-- Hard Initial
-- Region aware code, places in bigger regions stronger units.
---------------------------------------------------------------
-- For all regions.
	local lua_total_regions = wml.variables['CE_SYSTEM.regions.length']
	for i=0,lua_total_regions-1,1 do
		local lua_current_region = wml.variables['CE_SYSTEM.regions['..i..'].id']
		local lua_total_villages = wml.variables['CE_SYSTEM.regions_'..lua_current_region..'.length']
		local counter = lua_total_villages

		local order = {}
		-- For all villages of this region.
		for j=0,lua_total_villages-1,1 do
			table.insert(order, j)
		end
		mathx.shuffle(order)

		-- For all villages of this region, in a randomized order.
		for z,j in ipairs(order) do
			local spawn_x = wml.variables['CE_SYSTEM.regions_'..lua_current_region..'['..j..'].x']
			local spawn_y = wml.variables['CE_SYSTEM.regions_'..lua_current_region..'['..j..'].y']
			local neutral_village = #wesnoth.map.find{ owner_side = 0, gives_income = true, x = spawn_x, y = spawn_y } > 0

			if neutral_village then
				-- For regions where players have some units, placing of the weak units is skipped.
				counter = counter - 1

				wml.variables.ce_spawn = { side = 7, x = spawn_x, y = spawn_y }

				-- Custom for 1 village regions.
				if lua_total_villages == 1 then
					wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
				end

				-- Custom for 2 village regions.
				if lua_total_villages == 2 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					else
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					end
				end

				-- Algorithm for big regions.
				-- The 2 themes differ only in this point.
				-- 4 villages: L1, L3, two L5
				-- 5 villages: L1, L3, two L5, L8
				-- 6 villages: L1, L3, two L5, L8, L10
				-- 7 villages: L1, L3, two L5, L8, L10, L15 for each additional village

				if lua_total_villages > 2 then
					if counter == 0 then
						wesnoth.game_events.fire("ce_spawn_1g_militia")
					elseif counter == 1 then
						wesnoth.game_events.fire("ce_spawn_3g_Sergeant")
					elseif counter == 2 then
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					elseif counter == 3 then
						wesnoth.game_events.fire(mathx.random_choice("ce_spawn_5g_Pikeman,ce_spawn_5g_Cavalry"))
					elseif counter == 4 then
						wesnoth.game_events.fire("ce_spawn_8g_Eliteinfantry")
					elseif counter == 5 then
						wesnoth.game_events.fire("ce_spawn_10g_Lancer")
					elseif counter == 6 then
						wesnoth.game_events.fire("ce_spawn_15g_Lieutenant")
					else
						wesnoth.game_events.fire("ce_spawn_15g_Lieutenant")
					end
				end

				wml.variables.ce_spawn = nil
			end
		end
	end

end

-- >>
