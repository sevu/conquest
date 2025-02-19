-- <<

-- This is a modification of wesnoth.interface.move_unit_fake
-- It does submit a third parameter to the scrolling function,
-- which avoids scrolling to units under fog.

function move_unit(filter, to_x, to_y)
	local moving_unit = wesnoth.units.find_on_map(filter)[1]
	local from_x, from_y = moving_unit.x, moving_unit.y

	wesnoth.interface.scroll_to_hex(from_x, from_y, true)
	to_x, to_y = wesnoth.paths.find_vacant_hex(to_x, to_y, moving_unit)

	if to_x < from_x then
		moving_unit.facing = "sw"
	elseif to_x > from_x then
		moving_unit.facing = "se"
	end
	moving_unit:extract()

	wesnoth.wml_actions.move_unit_fake{
		type      = moving_unit.type,
		gender    = moving_unit.gender,
		variation = moving_unit.variation,
		side      = moving_unit.side,
		x         = from_x .. ',' .. to_x,
		y         = from_y .. ',' .. to_y
	}

	moving_unit:to_map(to_x, to_y)
	wesnoth.wml_actions.redraw{}
end

-- >>
