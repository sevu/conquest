-- <<

-- This function defines a new WML tag [region].
-- Unused data is commented with --

function wesnoth.wml_actions.region(cfg)
	local t = wesnoth.textdomain 'wesnoth-Conquest_Vilas'
	local village_list = tostring(cfg.village_list) or wml.error '[region] expects a village_list= attribute.'
	local region_name  = tostring(cfg.name) or wml.error '[region] expects a name= attribute.'
	local region_bonus = cfg.bonus or wml.error '[region] expects a bonus= attribute.'
	local region_color = cfg.color or '200,200,200'

	local region_codename = region_name
	-- Replace some signs [ /-'’] to allow using it as name for a WML variable.
	region_codename = string.gsub(region_codename, '[ /-]', '_')
	region_codename = string.gsub(region_codename, "['’]", '' )


	-- Special mode for Pasarganta maps.
	-- Will recolor existing labels with the region_color from this tag.
	if wml.variables.mapsection and (wml.variables.mapvariant ~= 'pasarganta_new') then

		-- Recolor-mode on, recolor existing region:
		for j=0,wml.variables['CE_SYSTEM.regions_' ..  region_codename ..'.length']-1,1 do

			local village_label = wesnoth.map.get_label {
				wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].x'],
				wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].y'],
			}

			-- Overwrite label in a new color.
			village_label.color = region_color
			wesnoth.map.add_label(village_label)
		end
		return
	end


	-- Create a variable to store the information about the region, the bonus will be saved there.
	--
	-- Check if region doesn't already exist (in that case only add villages to the region)
	if wml.variables['CE_SYSTEM.regions_'..region_codename] == nil then

		local array_num = wml.variables['CE_SYSTEM.regions.length'] or 0

		-- wml.variables['CE_SYSTEM.regions_'..region_codename..'_bonus'] = region_bonus
		-- wml.variables['CE_SYSTEM.regions_'..region_codename..'array_num'] = array_num

		wml.variables['CE_SYSTEM.regions['..array_num..'].id'] = region_codename
		wml.variables['CE_SYSTEM.regions['..array_num..'].bonus'] = region_bonus
		-- wml.variables['CE_SYSTEM.regions['..array_num..'].name'] = region_name



		-- Special mode for Poland map,
		-- print region name with a label somewhere on the map.
		if cfg.region_center then
			local center_x = stringx.split(cfg.region_center)[1]
			local center_y = stringx.split(cfg.region_center)[2]

			wesnoth.map.add_label { text = string.upper(tostring(t(region_name))..' +'..region_bonus),
									color = region_color, x = center_x, y = center_y }
		end



		-- Special mode for Dative, Jel’wan, Lotrando and Poland maps,
		-- place a table with an extra label describing the bonus of the region.
		if wml.variables['CE_SYSTEM.region_table'] then
			local tab_x = stringx.split(wml.variables['CE_SYSTEM.region_table'])[1] + (wml.variables['CE_SYSTEM.column'] or 0)
			local tab_y = stringx.split(wml.variables['CE_SYSTEM.region_table'])[2] + (wml.variables['CE_SYSTEM.row'] or 0)
			local bonus = region_bonus .. ' ' .. wesnoth.textdomain 'wesnoth' 'Gold'
			local n, ne, se, s, sw, nw = wesnoth.map.get_adjacent_hexes(tab_x, tab_y)

			wesnoth.map.add_label { text = t(region_name), color = region_color, x = tab_x, y = tab_y, visible_in_shroud = true }
			wesnoth.map.add_label { text = bonus, color = region_color, x = se.x, y = se.y, visible_in_shroud = true }

			-- Determine next coordinates.
			if ((wml.variables['CE_SYSTEM.row'] or 0 ) + 1 ) < (wml.variables['CE_SYSTEM.rows'] or 4) then
				wml.variables['CE_SYSTEM.row'] = (wml.variables['CE_SYSTEM.row'] or 0) + 1
			else
				wml.variables['CE_SYSTEM.row'] = 0
				wml.variables['CE_SYSTEM.column'] = (wml.variables['CE_SYSTEM.column'] or 0) + 4
			end
		end
	end



	-- Handle village list
	local previous, village_x, village_y, village_name, village_text
	local offset_x = wml.variables['CE_SYSTEM.offset_x'] or 0
	local offset_y = wml.variables['CE_SYSTEM.offset_y'] or 0
	local label_style = wml.variables['CE_SYSTEM.label_style']


	for eachword in string.gmatch(village_list, '([^,]+)') do
		if tonumber(eachword) ~= nil then
			if previous == 'string' then
				previous = 'x'
				village_x = eachword + offset_x
			else
				previous = 'y'
				village_y = eachword + offset_y
			end
		else
			previous = 'string'
			village_name = eachword
		end


		if previous == 'y' then

			local array_num = wml.variables['CE_SYSTEM.regions_'..region_codename..'.length'] or 0

			-- wml.variables['CE_SYSTEM.regions_'..region_codename..'['..array_num..'].name'] = village_name
			wml.variables['CE_SYSTEM.regions_'..region_codename..'['..array_num..'].x'] = village_x
			wml.variables['CE_SYSTEM.regions_'..region_codename..'['..array_num..'].y'] = village_y

			-- wml.variables['CE_SYSTEM.regions_city_'..village_x..'_'..village_y..'.name'] = village_name
			-- wml.variables['CE_SYSTEM.regions_city_'..village_x..'_'..village_y..'.region_id'] = region_codename
			-- wml.variables['CE_SYSTEM.regions_city_'..village_x..'_'..village_y..'.array_num'] = array_num


			if not label_style then
				village_text = t(village_name)..' ('..t(region_name)..' +'..region_bonus..')'

			elseif label_style == 'short' then
				village_text = t(village_name)..' ('..t(region_name)..')'

			elseif label_style == 'bonus' then
				village_text = t(village_name)..' ( +'..region_bonus..')'

			elseif label_style == 'region' then
				village_text = t(region_name) ..' +'..region_bonus

			elseif label_style == 'simple' then
				village_text = t(village_name)
			end

			wesnoth.map.add_label {
				text = village_text,
				color = region_color,
				x = village_x,
				y = village_y,
				visible_in_fog = wml.variables['CE_SYSTEM.show_village_labels_in_fog']
			}
		end
	end
end

-- >>
