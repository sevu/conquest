-- <<

-- This is used only for one region in the Archipelago map.

local villages = {
	{ x=33, y=42 },
	{ x=32, y=36 },
	{ x=34, y=45 },
	{ x=38, y=46 },
	{ x=41, y=45 },
	{ x=42, y=40 },
	{ x=44, y=43 },
	{ x=48, y=45 },
	{ x=52, y=48 },
	{ x=49, y=51 },
	{ x=43, y=51 },
	{ x=38, y=51 }
}

mathx.shuffle(villages)

local colors = {
	'255,99,71',    -- Tomatored
	'255,165,0',    -- Orange
	'0,191,255',    -- Deep Sky Blue
	'255,192,203',  -- Light Pink
	'221,160,221',  -- Very Light Purple
	'173,216,230',  -- Very Light Blue
	'240,230,140'   -- Khaki
}

local region_names = {
	'Metironien',
	'Merkada',
	'Dimoso',
	'Jetimeda',
	'Kanrampo',
	'Ethiwerda',
	'New Union',
	'Merry World',
	'Paradies'
}

mathx.shuffle(colors)
mathx.shuffle(region_names)

local cluster = {}

local function check_all_clusters(village)

	for c = 1, #cluster do
		for v = 1, #cluster[c] do

			if wesnoth.map.distance_between(village, cluster[c][v]) <= 6 then
				table.insert(cluster[c], village)
				return
			end

		end
	end

	-- Fits into no cluster, create a new cluster with this village.
	table.insert(cluster, { village } )
end

-- Assign each village into a cluster.
for i = 1, #villages do

	mathx.shuffle(cluster)
	check_all_clusters(villages[i])

end

-- Add bonus, color etc
for c = 1, #cluster do
	cluster[c].bonus = #cluster[c]

	cluster[c].color = table.remove(colors) or '200,200,200'

	cluster[c].name = table.remove(region_names) or 'Region' .. c

	for v = 1, #cluster[c] do
		-- Change to the format village_list=name,x,y used by the [region] tag.
		if cluster[c].village_list then
			cluster[c].village_list = cluster[c].village_list .. ','
		else
			cluster[c].village_list = ''
		end
		cluster[c].village_list = cluster[c].village_list .. (cluster[c][v].name or '') .. ',' .. cluster[c][v].x .. ',' .. cluster[c][v].y
	end

	-- Create region with the [region] tag.
	wesnoth.wml_actions.region(cluster[c])
end

-- >>
