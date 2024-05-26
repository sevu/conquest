-- <<
local _ = wesnoth.textdomain 'wesnoth-Conquest'
local lua_all_villages = wesnoth.map.find{ gives_income = true }
local lua_total_villages = #lua_all_villages - 1
local lua_number_of_attempts = (wml.variables['CE_SYSTEM.number_of_attempts'] or 1) - 1
local lua_friendly_distance = wml.variables['CE_SYSTEM.max_distance'] or 8
local lua_enemy_distance = wml.variables['CE_SYSTEM.min_distance'] or 10
----------------------------------------------------------------------
for d=lua_enemy_distance,5,-1 do
		wesnoth.interface.delay(1)
		wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Distance $d', {d=d}))

		for k=0,lua_number_of_attempts,1 do
				local break_sides_cycle = false
				local text = _'Attempt $number out of $max'
				wesnoth.interface.delay(1)
				wesnoth.interface.add_chat_message('Conquest',text:vformat({ number=k+1, max=lua_number_of_attempts+1 }))
				---------------------------------------------------------------

				local random_first_villa = mathx.random(0, lua_total_villages)
				--
				local sides_counter = 1
				local all_sides = wesnoth.sides.find{ wml.tag.has_unit { canrecruit = true } }

				for j,v in ipairs(all_sides) do
					if break_sides_cycle == false then
						local break_random_villa_cycle = false
						local current_side = v.side
						--------------------------
						--- for first side, spawn 1 militia in a random village on map
						if sides_counter == 1 then
							local counter = 0

							for i, pairs_xy in ipairs(lua_all_villages) do
								if random_first_villa == counter then
									wml.variables.ce_spawn = { side = current_side, x = pairs_xy.x, y = pairs_xy.y }
									wesnoth.game_events.fire('ce_spawn_1g_militia')
									wml.variables.ce_spawn = nil
								end
								counter = counter + 1
							end

							--- for first side store nearby villages in settings radius
							--- and place 2 militia in randomly shuffled 2 of them
							local all_friendly_villages = wesnoth.map.find{ owner_side = 0, gives_income = true, {'and',
								{ owner_side=current_side, gives_income = true, radius=lua_friendly_distance }}}

							if #all_friendly_villages > 1 then
								mathx.shuffle(all_friendly_villages)
								local secondary_village_counter = 0

								for f, pairss_xy in ipairs(all_friendly_villages) do
									if secondary_village_counter < 2 then
										wml.variables.ce_spawn = { side = current_side, x = pairss_xy.x, y = pairss_xy.y }
										wesnoth.game_events.fire('ce_spawn_1g_militia')
										wml.variables.ce_spawn = nil
									end
									secondary_village_counter = secondary_village_counter + 1
								end

							else
								break_sides_cycle = true
							end

						else
							---try if you can put next side with specified distances..
							local lua_all_villages_left = wesnoth.map.find{ owner_side=0, gives_income = true, {'and',
								{{'not', { gives_income = true, radius=d, {'not', { owner_side=0 }} }} }} }
							--wesnoth.message(#lua_all_villages_left)
							--------------------------------
							local lua_total_villages_left = #lua_all_villages_left - 1

							for n=1,10,1 do
								if break_random_villa_cycle == false then

									-- safety check for random function
									if lua_total_villages_left >= 0 then
										local random_villa = mathx.random(0, lua_total_villages_left)
										local counter = 0

										for i, pairs_xy in ipairs(lua_all_villages_left) do
											if random_villa == counter then
												wml.variables.ce_spawn = { side = current_side, x = pairs_xy.x, y = pairs_xy.y }
												wesnoth.game_events.fire('ce_spawn_1g_militia')
												wml.variables.ce_spawn = nil
											end
											counter = counter + 1
										end
									end

									--- for first side store nearby villages in settings radius
									--- and place 2 militia in randomly shuffled 2 of them
									local all_friendly_villages = wesnoth.map.find{ gives_income = true, owner_side=0, {'and',
										{{'not', { gives_income = true, radius=d, {'not',{ owner_side=0 }},
										{'and', {{'not', { owner_side=current_side}} }} }} }},
										{'and', { gives_income = true, radius=lua_friendly_distance, owner_side=current_side }} }

									if #all_friendly_villages > 1 then
										break_random_villa_cycle = true
										mathx.shuffle(all_friendly_villages)
										local secondary_village_counter = 0
										for f, pairss_xy in ipairs(all_friendly_villages) do
											if secondary_village_counter < 2 then
												wml.variables.ce_spawn = { side = current_side, x = pairss_xy.x, y = pairss_xy.y }
												wesnoth.game_events.fire('ce_spawn_1g_militia')
												wml.variables.ce_spawn = nil
											end
											secondary_village_counter = secondary_village_counter + 1
										end

										if sides_counter == #all_sides then
											wesnoth.interface.delay(1)
											wesnoth.interface.add_chat_message('Conquest',_'All sides placed successfully')
											return
										end

									else
										wesnoth.interface.delay(1)
										wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Retrying side $n placement',{n=current_side}))

										local all_non_king_units_of_current_side = wesnoth.units.find_on_map{ side=current_side, canrecruit = false }
										if #all_non_king_units_of_current_side > 0 then
											wesnoth.map.set_owner({ all_non_king_units_of_current_side[1].x, all_non_king_units_of_current_side[1].y }, 0)
											wesnoth.units.erase(all_non_king_units_of_current_side[1].x, all_non_king_units_of_current_side[1].y)
										end
										--break_sides_cycle = true
										--break_random_villa_cycle = true
									end
									--------------------------------
									--break_sides_cycle = true
								end
							end

							if break_random_villa_cycle == false then
								wesnoth.interface.delay(1)
								wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Placing side $n failed', {n=current_side}))

								local all_non_king_units = wesnoth.units.find_on_map{ canrecruit = false }
								for u=1,#all_non_king_units,1 do
									wesnoth.map.set_owner({ all_non_king_units[u].x, all_non_king_units[u].y }, 0)
									wesnoth.units.erase(all_non_king_units[u].x, all_non_king_units[u].y)
								end
								break_sides_cycle = true
							end	
						end
						sides_counter = sides_counter + 1
						-------------------------------------------
					end
				end
		----------------------------------------------------------
		end
end
-------------------------------------------------------------------
-- >>
