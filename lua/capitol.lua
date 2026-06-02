-- << Magic marker. For Lua it's a comment, for the WML preprocessor an opening quotation sign.

function capitol()
	local _ = wesnoth.textdomain 'wesnoth-Conquest'
	local all_villages = wesnoth.map.find{ gives_income = true }
	local all_sides = wesnoth.sides.find{ wml.tag.has_unit { canrecruit = true } }
	local friendly_distance = wml.variables['CE_SYSTEM.max_distance'] or 8
	local enemy_distance = wml.variables['CE_SYSTEM.min_distance'] or 12
	local number_of_attempts = wml.variables['CE_SYSTEM.number_of_attempts'] or 1
	local castle_mode = wml.variables.castle_mode


	local function tunnel_distance_check(tunnel_exit, other_exit, taken_vils, distance_long, distance_start)
		-- This function is used to take the teleport tunnels into account
		-- for the minimum distance between two player spawns.
		--
		-- If one of the villages taken by other players is close to a tunnel,
		-- it returns a filter to exclude fields near the other tunnel exit.
		distance_start = distance_start or distance_long
		local filter_addition = nil
		local distance_reduced = distance_start

		for i,vil in ipairs(taken_vils) do
			local distance_to_vil = wesnoth.map.distance_between(vil, tunnel_exit)
			distance_reduced = math.min(distance_to_vil, distance_reduced)
		end

		-- If there is a player close to the tunnel, add an exlusion for the other tunnel exit.
		-- (One for this side is not needed, as it is already excluded by the presence of that player.)
		if distance_reduced < distance_start then
			filter_addition = wml.tag['not'] { x = other_exit.x, y = other_exit.y, radius = distance_long - distance_reduced }
		end

		return filter_addition, distance_reduced
	end


	-- Saftey check, in case map generation went wrong and there are no villages.
	if #all_villages == 0 then return end

	-- Loop to retry with lower distance to other players.
	for d=enemy_distance,4,-1 do

		-- Set number_of_attempts depending on current distance.
		-- When the currently used distance is high, it is fine do use a smaller distance on the next try.
		-- If the distance is small, a retry with the same distance might be nice.
		-- On very low distance, we use many retries, to handle randomly generated maps with very many villages on small space.
		-- Using math.max to allow overriding number_of_attempts with higher numbers from scenario variable.
		if d <= 5 then
			number_of_attempts = math.max(number_of_attempts, 10)
		elseif d <= 6 then
			number_of_attempts = math.max(number_of_attempts, 3)
		elseif d <= 10 then
			number_of_attempts = math.max(number_of_attempts, 2)
		end

		-- Loop to retry with same settings.
		for attempt=1,number_of_attempts,1 do
			wesnoth.interface.delay(1)
			if attempt == 1 then
				wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Distance $d', {d=d}))
			else
				wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Distance $d, Attempt $k', {d=d, k=attempt}))
			end

			local taken_villages = {}

			for sides_counter,s in ipairs(all_sides) do
				local break_random_villa_cycle = false
				local current_side = s.side
				local all_villages_left, filter, addition

				if sides_counter == 1 then
					-- Already know the villages for first side.
					all_villages_left = all_villages
					filter = { gives_income = true, owner_side = 0 }
				else
					-- To get all_villages_left for other players, it uses a
					-- filter to take distance and teleports into account.
					-- And need to prepare a similar filter for the later villages too.

					-- This filter gets all villages, except the ones being in a radius around player villages.
					filter = {
						gives_income = true,
						owner_side = 0,
						wml.tag['not'] {
							gives_income = true,
							wml.tag['not'] { owner_side = 0 },
							radius = d
						}
					}

					-- If option is activated and the Lua variable tunnels was defined by the scenario.
					if wml.variables.teleports and rawget(_G, 'tunnels') then

						for i,tunnel_end in ipairs(tunnels) do
							local t

							-- Look if a player is close to the tunnel.
							addition, t = tunnel_distance_check( tunnel_end[1], tunnel_end[2], taken_villages, d)
							if addition then
								table.insert(filter, addition)
							end

							-- Same for the other exit, but with reduced distance.
							addition, t = tunnel_distance_check( tunnel_end[2], tunnel_end[1], taken_villages, d, t)
							if addition then
								table.insert(filter, addition)
							end
						end

					end

					-- Get the candidates for first village by using the filter.
					all_villages_left = wesnoth.map.find(filter)

					-- Replace first sub-tag with a similar condition, which ist not excluding current side.
					filter[1] = wml.tag['not'] {
						gives_income = true,
						wml.tag['not'] { owner_side = current_side },
						wml.tag['not'] { owner_side = 0 },
						radius = d
					}
				end

				-- Villages should be next to first one given to this side.
				addition = wml.tag['and'] {
					gives_income = true,
					owner_side = current_side,
					radius = friendly_distance
				}
				table.insert(filter, addition)



				-- Loop with up to 5 tries.
				local players_left = #all_sides-sides_counter+1
				if all_villages_left[3 * players_left] then
					local n = 0
					-- The condition for max n times could be removed.
					while all_villages_left[1 * players_left] and n < 5 do
						n = n + 1

						if n > 1 then
							wesnoth.interface.delay(1)
							wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Retrying side $n placement'..' – $x', { n=current_side, x=n }))
						end

						-- Spawn 1 village.
						local random_villa = mathx.random(1, #all_villages_left)
						local villa = all_villages_left[random_villa]
						if sides_counter ~= 1 then
							-- For the first side, this is pointing to the same object as all_villages.
							-- And we want to reuse all_villages.
							all_villages_left[random_villa] = all_villages_left[#all_villages_left]
							all_villages_left[#all_villages_left] = nil
						end
						wesnoth.map.set_owner(villa, current_side)

						-- Next two villages next to current side.
						local nearby_villages = wesnoth.map.find(filter)

						-- Place next 2 villages for the same side.
						if nearby_villages[2] then
							break_random_villa_cycle = true
							table.insert(taken_villages, villa)

							for f=1,2,1 do
								random_villa = mathx.random(1, #nearby_villages)
								villa = nearby_villages[random_villa]
								nearby_villages[random_villa] = nearby_villages[#nearby_villages]
								nearby_villages[#nearby_villages] = nil
								wesnoth.map.set_owner(villa, current_side)
								table.insert(taken_villages, villa)
							end

							if sides_counter == #all_sides then
								-- All sides placed successfully.

								local castle = {}
								local bonus = 0

								for i,loc in ipairs(taken_villages) do
									local owner = wesnoth.map.get_owner(loc)

									-- Place units.
									if not castle_mode then
										wml.variables.ce_spawn = { side = owner, x = loc.x, y = loc.y }
										wesnoth.game_events.fire('ce_spawn_1g_militia')
										wml.variables.ce_spawn = nil

									-- Place castle, leader, etc.
									elseif not castle[owner] then
										-- Only on first village.
										castle[owner] = true
										wesnoth.current.map.special_locations[owner] = loc

										if rawget(_G, 'create_castle') then
											create_castle(loc)
										end

										-- Move leader and remove leader object.
										local u = wesnoth.units.find_on_map{ canrecruit = true, side = owner }[1]
										u:remove_modifications()
										u.status.petrified = nil
										u.moves = 2
										u:to_map(loc)

										wesnoth.sides[owner].scroll_to_leader = true

										-- Give higher starting gold than usual.
										-- Each player a bit more.
										-- 75, 80, 85, 90, 95, 100
										-- Give a bonus if the player choose a lower level leader.
										local l = (u.level < 3) and 10 or 0
										wesnoth.sides[owner].gold = wesnoth.sides[owner].gold + 75 + bonus + l
										bonus = bonus + 5
									end
								end

								local viewer, vision = wesnoth.interface.get_viewing_side()
								local p = wesnoth.units.find_on_map{ side = viewer, canrecruit = false }
								local u = wesnoth.units.find_on_map{ side = viewer, canrecruit = true }[1]

								-- Updates vision of own units for side who didn't start their turn already now.
								wesnoth.wml_actions.redraw{ clear_shroud = true }

								if #p >= 3 then
									local bounding_box_x = (math.min(p[1].x, p[2].x, p[3].x) + math.max(p[1].x, p[2].x, p[3].x)) / 2
									local bounding_box_y = (math.min(p[1].y, p[2].y, p[3].y) + math.max(p[1].y, p[2].y, p[3].y)) / 2

									local viewer_x = math.ceil(bounding_box_x)
									local viewer_y = math.ceil(bounding_box_y)

									-- Scroll to the units of the first side which you control.
									wesnoth.interface.scroll_to_hex(viewer_x, viewer_y, false, false, true)
								else
									u:scroll_to(false, false, true)
								end

								return
							end

							-- Found all three villages.
							break

						else
							-- There are not 2 villages left fulfiling the two distance conditions.
							-- Remove the already placed 1st village. Re-enter the loop afterwards.
							-- wesnoth.interface.add_chat_message('Conquest', _'Not enough nearby villages')
							wesnoth.map.set_owner(villa, 0)
						end
					end

				-- else wesnoth.interface.add_chat_message('Conquest', _'Don’t even try')
				end

				if not break_random_villa_cycle then
					-- Failed to place this side several times. Abort.
					wesnoth.interface.delay(1)
					wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Placing side $n failed', {n=current_side}))

					-- Reset villages of previous sides and start from scratch.
					for l, v in ipairs(taken_villages) do
						wesnoth.map.set_owner(v, 0)
					end

					-- Abort placing the next side, retry with new attempt.
					break
				end

			end

		end
	end

	wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Failed to alocate starting postions for all sides! Restart the game. For random maps, it helps to use a bigger map. Distance to own villages was set to $max|.', { max = friendly_distance } ))
end

-- Magic marker. For Lua it's a comment, for the WML preprocessor a closing quotation sign. >>
