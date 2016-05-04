minetest.register_on_placenode(function(pos, node)
	if minetest.registered_nodes[node.name].digiline then
		digiline:update_autoconnect(pos)
	end
end)

minetest.register_on_dignode(function(pos, node)
	if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].digiline then
-- need to make sure that node exists (unknown nodes!)
		digiline:update_autoconnect(pos)
	end
end)

function digiline:update_autoconnect(pos, secondcall)
	local xppos = {x=pos.x+1, y=pos.y, z=pos.z}
	local zppos = {x=pos.x, y=pos.y, z=pos.z+1}
	local xmpos = {x=pos.x-1, y=pos.y, z=pos.z}
	local zmpos = {x=pos.x, y=pos.y, z=pos.z-1}
	local xpympos = {x=pos.x+1, y=pos.y-1, z=pos.z}
	local zpympos = {x=pos.x, y=pos.y-1, z=pos.z+1}
	local xmympos = {x=pos.x-1, y=pos.y-1, z=pos.z}
	local zmympos = {x=pos.x, y=pos.y-1, z=pos.z-1}
	local xpypos = {x=pos.x+1, y=pos.y+1, z=pos.z}
	local zpypos = {x=pos.x, y=pos.y+1, z=pos.z+1}
	local xmypos = {x=pos.x-1, y=pos.y+1, z=pos.z}
	local zmypos = {x=pos.x, y=pos.y+1, z=pos.z-1}

	if secondcall == nil then
		digiline:update_autoconnect(xppos, true)
		digiline:update_autoconnect(zppos, true)
		digiline:update_autoconnect(xmpos, true)
		digiline:update_autoconnect(zmpos, true)

		digiline:update_autoconnect(xpypos, true)
		digiline:update_autoconnect(zpypos, true)
		digiline:update_autoconnect(xmypos, true)
		digiline:update_autoconnect(zmypos, true)

		digiline:update_autoconnect(xpympos, true)
		digiline:update_autoconnect(zpympos, true)
		digiline:update_autoconnect(xmympos, true)
		digiline:update_autoconnect(zmympos, true)
	end

	local def = minetest.registered_nodes[minetest.get_node(pos).name]
	local digilinespec = def and def.digiline
	if not (digilinespec and digilinespec.wire and
			digilinespec.wire.use_autoconnect) then
		return nil
	end

	local zmg = 	digiline:rules_link_anydir(pos, zmpos)
	local zmymg = 	digiline:rules_link_anydir(pos, zmympos)
	local xmg = 	digiline:rules_link_anydir(pos, xmpos)
	local xmymg = 	digiline:rules_link_anydir(pos, xmympos)
	local zpg = 	digiline:rules_link_anydir(pos, zppos)
	local zpymg = 	digiline:rules_link_anydir(pos, zpympos)
	local xpg = 	digiline:rules_link_anydir(pos, xppos)
	local xpymg = 	digiline:rules_link_anydir(pos, xpympos)


	local xpyg = digiline:rules_link_anydir(pos, xpypos)
	local zpyg = digiline:rules_link_anydir(pos, zpypos)
	local xmyg = digiline:rules_link_anydir(pos, xmypos)
	local zmyg = digiline:rules_link_anydir(pos, zmypos)

	local zm, xm, zp, xp, xpy, zpy, xmy, zmy
	if zmg or zmymg then zm = 1 else zm = 0 end
	if xmg or xmymg then xm = 1 else xm = 0 end
	if zpg or zpymg then zp = 1 else zp = 0 end
	if xpg or xpymg then xp = 1 else xp = 0 end

	if xpyg then xpy = 1 else xpy = 0 end
	if zpyg then zpy = 1 else zpy = 0 end
	if xmyg then xmy = 1 else xmy = 0 end
	if zmyg then zmy = 1 else zmy = 0 end

	if xpy == 1 then xp = 1 end
	if zpy == 1 then zp = 1 end
	if xmy == 1 then xm = 1 end
	if zmy == 1 then zm = 1 end

	local nodeid = 	tostring(xp )..tostring(zp )..tostring(xm )..tostring(zm )..
				tostring(xpy)..tostring(zpy)..tostring(xmy)..tostring(zmy)


	minetest.set_node(pos, {name = digilinespec.wire.basename..nodeid})
end
