-- <<

-- This creates the WML tag [capture_region].
-- It places on each villages of a region a unit.
-- It uses the datastructure to find the villages belonging to a region.
-- Created for Realm mode.
-- Usage:
-- [capture_region]
--     region=region1,region2
--     scroll=no
-- [/capture_region]

function wesnoth.wml_actions.capture_region(cfg)
    local region_string = tostring(cfg.region or wml.error '[capture_region] expects a region= attribute.')
    local region_list = stringx.split(region_string)

    local max_x, max_y, min_x, min_y = 1, 1, wesnoth.current.map.playable_width, wesnoth.current.map.playable_height

    -- Allow multiple regions to be captured
    for i,region_codename in ipairs(region_list) do
        region_codename = string.gsub(region_codename, '[ /-]', '_')
        region_codename = string.gsub(region_codename, "['’]", '' )

        -- Place on each village of the region a unit.
        for j = 0, wml.variables['CE_SYSTEM.regions_' .. region_codename .. '.length']-1 do

            local vil_x = wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].x']
            local vil_y = wml.variables['CE_SYSTEM.regions_'..region_codename..'['..j..'].y']

            min_x = math.min(min_x, vil_x)
            min_y = math.min(min_y, vil_y)
            max_x = math.max(max_x, vil_x)
            max_y = math.max(max_y, vil_y)

            wml.variables.ce_spawn = { side = wesnoth.current.side, x = vil_x, y = vil_y }
            wesnoth.game_events.fire('ce_spawn_1g_militia')
            wml.variables.ce_spawn = nil
        end
    end

    if cfg.scroll ~= false then
        local bounding_box_x = math.ceil( (min_x + max_x) /2 )
        local bounding_box_y = math.ceil( (min_y + max_y) /2 )

        wesnoth.wml_actions.scroll_to{ x = bounding_box_x, y = bounding_box_y, side = wesnoth.current.side }
    end
end

-- >>
