-- <<

-- This creates the WML tag [capture_region].
-- It places on each villages of a region a unit.
-- It uses the datastructure to find the villages belonging to a region.
-- Created for Realm mode.

function wesnoth.wml_actions.capture_region(cfg)
    local region_codename = tostring(cfg.region or wml.error '[capture_region] expects a region= attribute.')
    region_codename = string.gsub(region_codename, '[ /-]', '_')
    region_codename = string.gsub(region_codename, "['’]", '' )

    local max_x, max_y, min_x, min_y = 0, 0, wesnoth.current.map.playable_width, wesnoth.current.map.playable_height

    -- Place on each village of the region a unit.
    for j = 0, wml.variables['CE_SYSTEM.regions_' .. region_codename .. '.length']-1 do

        local vil_x = wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].x']
        local vil_y = wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].y']

        if not min_x then min_x = vil_x elseif min_x > vil_x then min_x = vil_x end
        if not min_y then min_y = vil_y elseif min_y > vil_y then min_y = vil_y end

        max_x = math.max(max_x, vil_x)
        max_y = math.max(max_y, vil_y)

        wml.variables.ce_spawn = { side = wesnoth.current.side, x = vil_x, y = vil_y }
        wesnoth.game_events.fire('ce_spawn_1g_militia')
        wml.variables.ce_spawn = nil
    end

    if cfg.scroll ~= false then
        local bounding_box_x = math.ceil( (min_x + max_x) /2 )
        local bounding_box_y = math.ceil( (min_y + max_y) /2 )

        wesnoth.interface.scroll_to_hex(bounding_box_x, bounding_box_y)
    end
end

-- >>
