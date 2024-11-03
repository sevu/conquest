-- << Magic marker. For Lua it's a comment, for the WML preprocessor an opening quotation sign.

local _ = wesnoth.textdomain 'wesnoth-Conquest'
local all_villages = wesnoth.map.find{ gives_income = true }
local total_villages = #all_villages - 1
local friendly_distance = wml.variables['CE_SYSTEM.max_distance'] or 8
local enemy_distance = wml.variables['CE_SYSTEM.min_distance'] or 12
local number_of_attempts = wml.variables['CE_SYSTEM.number_of_attempts'] or 1


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

		local random_first_villa = mathx.random(0, total_villages)
		local all_sides = wesnoth.sides.find{ wml.tag.has_unit { canrecruit = true } }

		for sides_counter,s in ipairs(all_sides) do
			local break_random_villa_cycle = false
			local current_side = s.side

			-- Special handling for first side.
			--- for first side, spawn 1 militia in a random village on map
			if sides_counter == 1 then

				-- Determine a random village.
				local counter = 0
				for i, villa in ipairs(all_villages) do
					if random_first_villa == counter then
						wml.variables.ce_spawn = { side = current_side, x = villa.x, y = villa.y }
						wesnoth.game_events.fire('ce_spawn_1g_militia')
						wml.variables.ce_spawn = nil
						break
					end
					counter = counter + 1
				end

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

			-- If it is not the first side.
			else
				---try if you can put next side with specified distances..
				local all_villages_left = wesnoth.map.find{ owner_side=0, gives_income = true, {'and',
					{{'not', { gives_income = true, radius=d, {'not', { owner_side=0 }} }} }} }

				local total_villages_left = #all_villages_left - 1

				-- Loop with up to 10 tries.
				for n=1,10,1 do
					if break_random_villa_cycle == false then

						-- Safety check for random function.
						if total_villages_left >= 0 then
							local random_villa = mathx.random(0, total_villages_left)
							local counter = 0

							-- Spawn 1 village.
							for i, villa in ipairs(all_villages_left) do
								if random_villa == counter then
									wml.variables.ce_spawn = { side = current_side, x = villa.x, y = villa.y }
									wesnoth.game_events.fire('ce_spawn_1g_militia')
									wml.variables.ce_spawn = nil
									break
								end
								counter = counter + 1
							end

							--- for first side store nearby villages in settings radius
							--- and place 2 militia in randomly shuffled 2 of them
							local all_friendly_villages = wesnoth.map.find{ gives_income = true, owner_side=0, {'and',
								{{'not', { gives_income = true, radius=d, {'not',{ owner_side=0 }},
								{'and', {{'not', { owner_side=current_side}} }} }} }},
								{'and', { gives_income = true, radius=friendly_distance, owner_side=current_side }} }

							-- Place next 2 villages for the same side.
							if #all_friendly_villages > 1 then
								break_random_villa_cycle = true
								mathx.shuffle(all_friendly_villages)
								local secondary_village_counter = 0
								for f, villa in ipairs(all_friendly_villages) do
									if secondary_village_counter < 2 then
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
									return
								end

							else
								-- There are not 2 villages left fullfilling the two distance conditions.
								if n < 10 then
									wesnoth.interface.delay(1)
									wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Retrying side $n placement'..' ($x/10)',{n=current_side, x=n+1}))
								end

								-- Remove the already placed 1st village. Re-enter the loop afterwards.
								local first_unit = wesnoth.units.find_on_map{ side=current_side, canrecruit = false }[1]
								wesnoth.map.set_owner({ first_unit.x, first_unit.y }, 0)
								first_unit:erase()
							end

						else
							-- Did not find a first village. Re-enter the loop.
							if n < 10 then
								wesnoth.interface.delay(1)
								wesnoth.interface.add_chat_message('Conquest',stringx.vformat(_'Retrying side $n placement'..' ($x/10)',{n=current_side, x=n+1}))
							end
						end

					end
				end

				if break_random_villa_cycle == false then
					-- Failed all 10 tries to place this side. Abort.
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

local old_message = _'Retrying side $n placement'

-- Magic marker. For Lua it's a comment, for the WML preprocessor a closing quotation sign. >>
