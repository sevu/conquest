-- <<

-- This function defines a new WML tag [region].
-- Unused data is commented with --

function wesnoth.wml_actions.region(cfg)
	local region_name = cfg.name or wml.error '[region] expects a name= attribute.'
	local region_bonus = cfg.bonus or wml.error '[region] expects a bonus= attribute.'
	local village_list = cfg.village_list or wml.error '[region] expects a village_list= attribute.'
	local region_color = cfg.color or '200,200,200'

	local region_codename = region_name
	-- may be bug with double empty spaces or double '-' signs in same region name etc
	if string.find(region_codename,' ') then region_codename = string.gsub(region_codename,' ','_') end
	if string.find(region_codename,"'") then region_codename = string.gsub(region_codename,"'",'' ) end
	if string.find(region_codename,'’') then region_codename = string.gsub(region_codename,'’','' ) end
	if string.find(region_codename,'/') then region_codename = string.gsub(region_codename,'/','_') end
	if string.find(region_codename,'-') then region_codename = string.gsub(region_codename,'-','_') end


	-- Special mode for Pasarganta maps.
	-- Will recolor existing labels with the region_color from this tag.
	if wml.variables.mapsection and (wml.variables.mapvariant ~= 'pasarganta_new') then
		-- Recolor-mode on, recolor existing region:
		for j=0,wml.variables['CE_SYSTEM.regions_' ..  region_codename ..'.length']-1,1 do
			local village_label = wesnoth.map.get_label{
				wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].x'],
				wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].y'],
			}

			-- Overwrite label in a new color.
			village_label.color = region_color
			wesnoth.map.add_label(village_label)
		end
		return
	end


	-- Check if region doesn't already exist (in that case only add villages to the region)
	if wml.variables['CE_SYSTEM.regions_'..region_codename] == nil then

		local lua_regions_length = wml.variables['CE_SYSTEM.regions.length'] or 0

		-- wml.variables['CE_SYSTEM.regions_'..region_codename..'_bonus'] = region_bonus
		-- wml.variables['CE_SYSTEM.regions_'..region_codename..'array_num'] = lua_regions_length

		wml.variables['CE_SYSTEM.regions['..lua_regions_length..'].id'] = region_codename
		wml.variables['CE_SYSTEM.regions['..lua_regions_length..'].bonus'] = region_bonus
		-- wml.variables['CE_SYSTEM.regions['..lua_regions_length..'].name'] = region_name
	end


	local lua_previous = 'y'
	local lua_village_x = -1
	local lua_village_y = -1
	local lua_village_name
	local lua_offset_x = wml.variables['CE_SYSTEM.offset_x'] or 0
	local lua_offset_y = wml.variables['CE_SYSTEM.offset_y'] or 0

	for eachword in string.gmatch(village_list, '([^,]+)') do
		if tonumber(eachword) ~= nil then
			if lua_previous == 'string' then
				lua_previous = 'x'
				lua_village_x = eachword + lua_offset_x
			else
				lua_previous = 'y'
				lua_village_y = eachword + lua_offset_y
			end
		else
			lua_previous = 'string'
			lua_village_name = eachword
		end


		if lua_previous == 'y' then

			local lua_villages_length = wml.variables['CE_SYSTEM.regions_'..region_codename..'.length'] or 0

			-- wml.variables['CE_SYSTEM.regions_'..region_codename..'['..lua_villages_length..'].name'] = lua_village_name
			wml.variables['CE_SYSTEM.regions_'..region_codename..'['..lua_villages_length..'].x'] = lua_village_x
			wml.variables['CE_SYSTEM.regions_'..region_codename..'['..lua_villages_length..'].y'] = lua_village_y

			-- wml.variables['CE_SYSTEM.regions_city_'..lua_village_x..'_'..lua_village_y..'.name'] = lua_village_name
			-- wml.variables['CE_SYSTEM.regions_city_'..lua_village_x..'_'..lua_village_y..'.region_id'] = region_codename
			-- wml.variables['CE_SYSTEM.regions_city_'..lua_village_x..'_'..lua_village_y..'.array_num'] = lua_villages_length

			wesnoth.map.add_label {
				text = lua_village_name..' ('..region_name..' +'..region_bonus..')',
				color = region_color,
				x = lua_village_x,
				y = lua_village_y,
				visible_in_fog = wml.variables['CE_SYSTEM.show_village_labels_in_fog']
			}
		end
	end
end

-- >>
