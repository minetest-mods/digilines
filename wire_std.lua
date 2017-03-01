-- naming scheme: wire:(xp)(zp)(xm)(zm)_on/off
-- The conditions in brackets define whether there is a digiline at that place or not
-- 1 = there is one; 0 = there is none
-- y always means y+

local box_center = {-1/16, -.5, -1/16, 1/16, -.5+1/16, 1/16}
local box_bump1 =  { -2/16, -8/16,  -2/16, 2/16, -13/32, 2/16 }
local box_bump2 =  { -3/32, -13/32, -3/32, 3/32, -12/32, 3/32 }

local box_xp = {1/16, -.5, -1/16, 8/16, -.5+1/16, 1/16}
local box_zp = {-1/16, -.5, 1/16, 1/16, -.5+1/16, 8/16}
local box_xm = {-8/16, -.5, -1/16, -1/16, -.5+1/16, 1/16}
local box_zm = {-1/16, -.5, -8/16, 1/16, -.5+1/16, -1/16}

local box_xpy = {.5-1/16, -.5+1/16, -1/16, .5, .4999+1/16, 1/16}
local box_zpy = {-1/16, -.5+1/16, .5-1/16, 1/16, .4999+1/16, .5}
local box_xmy = {-.5, -.5+1/16, -1/16, -.5+1/16, .4999+1/16, 1/16}
local box_zmy = {-1/16, -.5+1/16, -.5, 1/16, .4999+1/16, -.5+1/16}

for xp=0, 1 do
for zp=0, 1 do
for xm=0, 1 do
for zm=0, 1 do
for xpy=0, 1 do
for zpy=0, 1 do
for xmy=0, 1 do
for zmy=0, 1 do
	if (xpy == 1 and xp == 0) or (zpy == 1 and zp == 0)
	or (xmy == 1 and xm == 0) or (zmy == 1 and zm == 0) then break end

	local groups
	local nodeid = 	tostring(xp )..tostring(zp )..tostring(xm )..tostring(zm )..
			tostring(xpy)..tostring(zpy)..tostring(xmy)..tostring(zmy)

	local wiredesc

	if nodeid == "00000000" then
		groups = {dig_immediate = 3}
		wiredesc = "Digiline"
	else
		groups = {dig_immediate = 3, not_in_creative_inventory = 1}
	end

	local nodebox = {}
	local adjx = false
	local adjz = false
	if xp == 1 then table.insert(nodebox, box_xp) adjx = true end
	if zp == 1 then table.insert(nodebox, box_zp) adjz = true end
	if xm == 1 then table.insert(nodebox, box_xm) adjx = true end
	if zm == 1 then table.insert(nodebox, box_zm) adjz = true end
	if xpy == 1 then table.insert(nodebox, box_xpy) end
	if zpy == 1 then table.insert(nodebox, box_zpy) end
	if xmy == 1 then table.insert(nodebox, box_xmy) end
	if zmy == 1 then table.insert(nodebox, box_zmy) end

	local tiles
	if adjx and adjz and (xp + zp + xm + zm > 2) then
		table.insert(nodebox, box_bump1)
		table.insert(nodebox, box_bump2)
		tiles = {
			"digiline_std_bump.png",
			"digiline_std_bump.png",
			"digiline_std_vertical.png",
			"digiline_std_vertical.png",
			"digiline_std_vertical.png",
			"digiline_std_vertical.png"
		}
	else
		table.insert(nodebox, box_center)
		tiles = {
			"digiline_std.png",
			"digiline_std.png",
			"digiline_std_vertical.png",
			"digiline_std_vertical.png",
			"digiline_std_vertical.png",
			"digiline_std_vertical.png"
		}
	end

	if nodeid == "00000000" then
		nodebox = {-8/16, -.5, -1/16, 8/16, -.5+1/16, 1/16}
	end

	minetest.register_node("digilines:wire_std_"..nodeid, {
		description = wiredesc,
		drawtype = "nodebox",
		tiles = tiles,
		inventory_image = "digiline_std_inv.png",
		wield_image = "digiline_std_inv.png",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		digiline =
		{
			wire =
			{
				basename = "digilines:wire_std_",
				use_autoconnect = true
			}
		},
		selection_box = {
			type = "fixed",
			fixed = {-.5, -.5, -.5, .5, -.5+1/16, .5}
		},
		node_box = {
			type = "fixed",
			fixed = nodebox
		},
		groups = groups,
		walkable = false,
		stack_max = 99,
		drop = "digilines:wire_std_00000000"
	})
end
end
end
end
end
end
end
end
