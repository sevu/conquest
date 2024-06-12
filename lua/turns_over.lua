-- << Magic marker. For Lua it's a comment, for the WML preprocessor an opening quotation sign.

-- Trimmed down version of mainline data/multiplayer/eras.lua

local res = {}

function res.turns_over_advantage()
	local winning_sides, side_results = res.calc_turns_over_advantage()
	wml.variables['won'] = table.concat(winning_sides, ',')

	local _ = wesnoth.textdomain 'wesnoth-Conquest'
	-- po: Turn limit reached (if one was used)
	res.show_turns_over_advantage(winning_sides, side_results, _'End of Game')
end

function res.calc_turns_over_advantage()
	local function all_sides()
		local function f(s, i)
			i = i + 1
			local t = wesnoth.sides[i]
			return t and i, t
		end
		return f, nil, 0
	end

	local winning_sides = {}
	local best_score = -1
	local side_outcomes = {}

	for side, team in all_sides() do
		if not team.__cfg.hidden then
			if # wesnoth.units.find_on_map( { side = side } ) == 0 then
				side_outcomes[side] = false
			else
				local income = team.total_income
				side_outcomes[side] = {income = income}

				if income > best_score then
					winning_sides = {side}
					best_score = income
				elseif income == best_score then
					table.insert(winning_sides, side)
				end
			end
		end
	end

	return winning_sides, side_outcomes
end

---Show the turns over advantage popup.
function res.show_turns_over_advantage(winning_sides, side_results, title)
	local _
	local side_comparison = ''
	for side = 1, #wesnoth.sides do
		local outcome = side_results[side]
		local side_color = wesnoth.colors[wesnoth.sides[side].color].pango_color

		if outcome == false then
			_ = wesnoth.textdomain 'wesnoth-multiplayer'
			local side_text = _ "<span strikethrough='true' foreground='$side_color'>Side $side_number</span>:  Has lost all units"
			side_comparison = side_comparison .. side_text:vformat{side_color = side_color, side_number = side} .. "\n"
		elseif outcome ~= nil then
			_ = wesnoth.textdomain 'wesnoth-Conquest'
			-- po: This is a shortened string from the mainline textdomain wesnoth-multiplayer. You can copy the text from there and delete a part of it: https://gettext.wesnoth.org/?package=wesnoth-multiplayer
			local side_text = _ "<span foreground='$side_color'>Side $side_number</span>:  Income = $income"
			side_comparison = side_comparison .. side_text:vformat{side_color = side_color, side_number = side, income = outcome.income} .. "\n"
		end
	end

	_ = wesnoth.textdomain 'wesnoth-multiplayer'
	if #winning_sides == 1 then
		local side = winning_sides[1]
		local side_color = wesnoth.colors[wesnoth.sides[side].color].pango_color
		local comparison_text = _ "<span foreground='$side_color'>Side $side_number</span> has the advantage."
		side_comparison = side_comparison .. "\n" .. comparison_text:vformat{side_number = winning_sides[1], side_color = side_color}
	elseif #winning_sides == 2 then
		local comparison_text = _ "Sides $side_number and $other_side_number are tied."
		side_comparison = side_comparison .. "\n" .. comparison_text:vformat{side_number = winning_sides[1], other_side_number = winning_sides[2]}
	elseif #winning_sides ~= 0 then
		local winners = stringx.format_conjunct_list('', winning_sides)
		local comparison_text = _ "Sides $winners are tied."
		side_comparison = side_comparison .. "\n" .. comparison_text:vformat{winners = winners}
	end

	title = title or _ 'dialog^Turns Over'
	gui.show_popup(title, side_comparison)
end

res.turns_over_advantage()

return res
-- Magic marker. For Lua it's a comment, for the WML preprocessor a closing quotation sign. >>
