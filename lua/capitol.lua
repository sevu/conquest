-- << Magic marker. For Lua it's a comment, for the WML preprocessor an opening quotation sign.

local _ = wesnoth.textdomain 'wesnoth-Conquest'
local all_villages = wesnoth.map.find{ gives_income = true }
local total_villages = #all_villages
local friendly_distance = wml.variables['CE_SYSTEM.max_distance'] or 8
local enemy_distance = wml.variables['CE_SYSTEM.min_distance'] or 12
local number_of_attempts = wml.variables['CE_SYSTEM.number_of_attempts'] or 1

local function tunnel_distance_check(tunnel_exit, other_exit, distance_setting, taken_vils)
	-- This function is used to take the teleport tunnels into account
	-- for the minimum distance between two player spawns
	--
	-- If a taken village is close to a tunnel, it returns a filter
	-- to exclude fields near the other tunnel exit.

	local filter_addition  = nil
	local distance_reduced = distance_setting

	for k,vil in ipairs(taken_vils) do
		local distance_tunnel = wesnoth.map.distance_between(vil, tunnel_exit)
		distance_reduced = math.min(distance_tunnel, distance_reduced)
	end

	-- If there is a player close to the tunnel, add an exlusion for the other tunnel exit.
	-- (One for this side is not needed, as it is already excluded by the presence of that player.)
	if distance_reduced < distance_setting then
		filter_addition = { 'not', { x = other_exit.x, y = other_exit.y, radius = distance_setting - distance_reduced } }
	end

	return filter_addition, distance_reduced
end

-- Saftey check, in case map generation went wrong and there are no villages.
if total_villages == 0 then return end

-- Loop to retry with lower distance to other players.
for d=enemy_distance,4,-1 do

	-- Set number_of_attempts depending on current distance.
	-- When the currently used distance is high, it is fine do use a smaller distance on the next try.
	-- If the distance is small, a retry with the same distance might be nice.
	-- On very low distance, we use many retries, to handle randomly generated maps with very many villages on small space.
	if d <= 5 then
		number_of_attempts = 10
	elseif d <= 6 then
		number_of_attempts = 3
	elseif d <= 10 then
		number_of_attempts = 2
	end

	-- Loop to retry with same settings.
	for k=1,number_of_attempts,1 do
		wesnoth.interface.delay(1)
		if k == 1 then
			wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Distance $d', {d=d}))
		else
			wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Distance $d, Attempt $k', {d=d, k=k}))
		end


		local all_sides = wesnoth.sides.find{ wml.tag.has_unit { canrecruit = true } }

		-- Only tracking the taken villages to use this variables if this map has tunnels.
		local taken_villages

		for sides_counter,s in ipairs(all_sides) do
			local break_random_villa_cycle = false
			local current_side = s.side

			-- Special handling for first side.
			--- for first side, spawn 1 militia in a random village on map
			if sides_counter == 1 then

				-- Initializing only for first player.
				taken_villages = {}

				-- Determine a random village.
				local random_first_villa = mathx.random(1, total_villages)
				local villa = all_villages[random_first_villa]
				table.insert(taken_villages, { x = villa.x, y = villa.y })
				wml.variables.ce_spawn = { side = current_side, x = villa.x, y = villa.y }
				wesnoth.game_events.fire('ce_spawn_1g_militia')
				wml.variables.ce_spawn = nil

				--- for first side store nearby villages in settings radius
				--- and place 2 militia in randomly shuffled 2 of them
				local all_friendly_villages = wesnoth.map.find{ owner_side = 0, gives_income = true, {'and',
					{ owner_side=current_side, gives_income = true, radius=friendly_distance }}}

				-- Choose 2nd and 3rd village village.
				if #all_friendly_villages > 1 then
					mathx.shuffle(all_friendly_villages)
					local secondary_village_counter = 0

					for f, villa in ipairs(all_friendly_villages) do
						if secondary_village_counter < 2 then
							table.insert(taken_villages, { x = villa.x, y = villa.y })
							wml.variables.ce_spawn = { side = current_side, x = villa.x, y = villa.y }
							wesnoth.game_events.fire('ce_spawn_1g_militia')
							wml.variables.ce_spawn = nil
						else
							break
						end
						secondary_village_counter = secondary_village_counter + 1
					end

				else
					-- No other two villages are within max distance to first village. Abort.
					local first_unit = wesnoth.units.find_on_map{ side=current_side, canrecruit = false }[1]
					wesnoth.map.set_owner({ first_unit.x, first_unit.y }, 0)
					first_unit:erase()
					break
				end

			-- If it is not the first side. Same code in a loop, extra check for teleport maps.
			else
				---try if you can put next side with specified distances..

				-- This filter gets all villages, except the ones being in a radius around player villages.
				local addition
				local filter = { gives_income = true, owner_side = 0,
					{'not', { gives_income = true,
						{'not', { owner_side = 0 }},
						radius = d
					}}
				}

				-- If option is activated and the Lua variable tunnels was defined by the scenario.
				if wml.variables.teleports and rawget(_G, 'tunnels') then

					for k,tunnel_end in ipairs(tunnels) do
						local t

						-- Look if a player is close to the tunnel.
						addition, t = tunnel_distance_check( tunnel_end[1], tunnel_end[2], d, taken_villages)
						if addition then
							table.insert(filter, addition)
						end

						-- Same for the other exit, but with reduced distance.
						addition, t = tunnel_distance_check( tunnel_end[2], tunnel_end[1], t, taken_villages)
						if addition then
							table.insert(filter, addition)
						end
					end

				end

				-- Get the candidates for first village by using the filter.
				local all_villages_left = wesnoth.map.find(filter)
				local total_villages_left = #all_villages_left


				-- Remove first condition, add new ones below.
				table.remove(filter, 1)

				-- Like the removed condition, but not excluding current side.
				addition = { 'not', { gives_income = true, { 'not' , {owner_side = current_side }}, { 'not' , {owner_side = 0 }}, radius = d } }
				table.insert(filter, addition)

				-- Villages should be next to first one given to this side.
				addition = { 'and', { gives_income = true, owner_side = current_side, radius = friendly_distance } }
				table.insert(filter, addition)

				-- Loop with up to 5 tries.
				for n=1,5,1 do
					if break_random_villa_cycle == false then

						-- This variable is for tunnels and reset always.
						local took_villages = {}

						-- Safety check for random function.
						if total_villages_left >= 1 then
							-- Spawn 1 village.
							local random_villa = mathx.random(1, total_villages_left)
							local villa = all_villages_left[random_villa]
							table.insert(took_villages, { x = villa.x, y = villa.y })
							wml.variables.ce_spawn = { side = current_side, x = villa.x, y = villa.y }
							wesnoth.game_events.fire('ce_spawn_1g_militia')
							wml.variables.ce_spawn = nil

							-- Next two villages next to current side.
							all_friendly_villages = wesnoth.map.find(filter)

							-- Place next 2 villages for the same side.
							if #all_friendly_villages > 1 then
								break_random_villa_cycle = true
								mathx.shuffle(all_friendly_villages)
								local secondary_village_counter = 0
								for f, villa in ipairs(all_friendly_villages) do
									if secondary_village_counter < 2 then
										table.insert(took_villages, { x = villa.x, y = villa.y })
										wml.variables.ce_spawn = { side = current_side, x = villa.x, y = villa.y }
										wesnoth.game_events.fire('ce_spawn_1g_militia')
										wml.variables.ce_spawn = nil
									else
										break
									end
									secondary_village_counter = secondary_village_counter + 1
								end

								if sides_counter == #all_sides then
									wesnoth.interface.add_chat_message('Conquest',_'All sides placed successfully')

									local viewer, vision = wesnoth.interface.get_viewing_side()
									local p = wesnoth.units.find_on_map{ side = viewer, canrecruit = false }

									local bounding_box_x = (math.min(p[1].x, p[2].x, p[3].x) + math.max(p[1].x, p[2].x, p[3].x)) / 2
									local bounding_box_y = (math.min(p[1].y, p[2].y, p[3].y) + math.max(p[1].y, p[2].y, p[3].y)) / 2

									local viewer_x = math.ceil(bounding_box_x)
									local viewer_y = math.ceil(bounding_box_y)

									-- Updates vision of own units for side who didn't start their turn already now.
									wesnoth.wml_actions.redraw{ clear_shroud = true }

									-- Scroll to the units of the first side which you control.
									wesnoth.interface.scroll_to_hex(viewer_x, viewer_y)

									return
								end

								table.insert(taken_villages, took_villages[1])
								table.insert(taken_villages, took_villages[2])
								table.insert(taken_villages, took_villages[3])

							else
								-- There are not 2 villages left fullfilling the two distance conditions.
								if n < 5 then
									wesnoth.interface.delay(1)
									wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Retrying side $n placement'..' ($x/5)',{n=current_side, x=n+1}))
								end

								-- Remove the already placed 1st village. Re-enter the loop afterwards.
								local first_unit = wesnoth.units.find_on_map{ side=current_side, canrecruit = false }[1]
								wesnoth.map.set_owner({ first_unit.x, first_unit.y }, 0)
								first_unit:erase()
							end

						else
							-- Did not find a first village. Re-enter the loop.
							if n < 5 then
								wesnoth.interface.delay(1)
								wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Retrying side $n placement'..' ($x/5)',{n=current_side, x=n+1}))
							end
						end

					end
				end

				if break_random_villa_cycle == false then
					-- Failed all 5 tries to place this side. Abort.
					wesnoth.interface.delay(1)
					wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Placing side $n failed', {n=current_side}))

					-- Remove all units and start from scratch.
					for l, u in ipairs(wesnoth.units.find_on_map{ canrecruit = false }) do
						wesnoth.map.set_owner({ u.x, u.y }, 0)
						u:erase()
					end
					break
				end
			end

		end

	end
end


wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Failed to alocate starting postions for all sides! Restart the game. For random maps, it helps to use a bigger map. Distance to own villages was set to $max|.', { max = friendly_distance } ))

-- Magic marker. For Lua it's a comment, for the WML preprocessor a closing quotation sign. >>
