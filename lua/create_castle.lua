--<<

-- Helper function for capitol.lua

-- Take center, turn into castle terrain.
-- Around it, turn into keep (or castle).

function create_castle(...)
	-- arg1 to arg2: location (might be one or two arguments)
	-- arg2 or arg3: size
	-- arg3 or arg4: delay_redraw
	local location, n = wesnoth.map.read_location(...)
	location = wesnoth.map.get(location) or wml.error('requires a location such as {x=10,y=20}')
	local size = select(n+1, ...) or 10
	local delay_redraw = select(n+2, ...)
	

	local function choose_tile(hex)
		if hex:matches{ terrain = 'Wwf' } then
			-- This gives water only castles at least one keep.
			return 'Ker'
		elseif hex:matches{ terrain = 'W*^*' } then
			return 'Cme'
		elseif hex:matches{ terrain = 'A*,Ha,Ms,Rra' } then
			return 'Kea'
		elseif hex:matches{ terrain = 'A*^*,*^Fma,*^Fda,*^Fpa,*^Feta,*^Esa' } then
			return 'Cea'
		elseif hex:matches{ terrain = 'S*' } then
			return 'Chs'
		elseif hex.overlay_terrain then
			return 'Ce'
		else
			return 'Ke'
		end
	end
	
	local replacement = choose_tile(location)
	wesnoth.current.map[location] = wesnoth.map.replace_base(replacement)

	local castles = 1
	local r = 1
	local z
	local terrain_filter = {
		wml.tag.filter_adjacent_location{
			x = location.x,
			y = location.y
		},
		wml.tag['not'] {
			terrain = 'X*^*,*^X*,*^_fme'
		},
		include_borders = false,
	}

	repeat
		r = r + 1
		z = wesnoth.map.find(terrain_filter)
		if (#z + castles) > size then
			mathx.shuffle(z)
		end
		for i,h in ipairs(z) do
			if not h:matches{ terrain = 'K*^*,C*^*' } then
				replacement = choose_tile(h)
				wesnoth.current.map[h] = wesnoth.map.replace_base(replacement)
			end
			castles = castles + 1
			if castles == size then break end
		end
		terrain_filter = {
			wml.tag['and'] {
				x = location.x,
				y = location.y,
				radius = r,
				include_borders = false,
				wml.tag.filter_radius { 
					wml.tag['not'] { terrain = '!,Wwf,!,W*^*,X*^*,*^X*,*^_fme' },
				},
			},
			wml.tag['not'] {
				terrain = 'C*^*,K*^*,*^Bs*'
			}
		}
	until castles >= size or r > 4

	-- This is for testing, normally redraw happens after all castles are placed.
	if not delay_redraw then
		wesnoth.wml_actions.redraw{ clear_shroud = true }
	end
end

-->>
