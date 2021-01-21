
local function check_and_update(pos, node)
	if digilines.getspec(node) then
		digilines.update_autoconnect(pos)
	end
end

minetest.register_on_placenode(check_and_update)
minetest.register_on_dignode(check_and_update)

function digilines.update_autoconnect(pos, secondcall)
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
		digilines.update_autoconnect(xppos, true)
		digilines.update_autoconnect(zppos, true)
		digilines.update_autoconnect(xmpos, true)
		digilines.update_autoconnect(zmpos, true)

		digilines.update_autoconnect(xpypos, true)
		digilines.update_autoconnect(zpypos, true)
		digilines.update_autoconnect(xmypos, true)
		digilines.update_autoconnect(zmypos, true)

		digilines.update_autoconnect(xpympos, true)
		digilines.update_autoconnect(zpympos, true)
		digilines.update_autoconnect(xmympos, true)
		digilines.update_autoconnect(zmympos, true)
	end

	local digilinespec = digilines.getspec(minetest.get_node(pos))
	if not (digilinespec and digilinespec.wire and
			digilinespec.wire.use_autoconnect) then
		return nil
	end

	local zmg = 	digilines.rules_link_anydir(pos, zmpos)
	local zmymg = 	digilines.rules_link_anydir(pos, zmympos)
	local xmg = 	digilines.rules_link_anydir(pos, xmpos)
	local xmymg = 	digilines.rules_link_anydir(pos, xmympos)
	local zpg = 	digilines.rules_link_anydir(pos, zppos)
	local zpymg = 	digilines.rules_link_anydir(pos, zpympos)
	local xpg = 	digilines.rules_link_anydir(pos, xppos)
	local xpymg = 	digilines.rules_link_anydir(pos, xpympos)


	local xpyg = digilines.rules_link_anydir(pos, xpypos)
	local zpyg = digilines.rules_link_anydir(pos, zpypos)
	local xmyg = digilines.rules_link_anydir(pos, xmypos)
	local zmyg = digilines.rules_link_anydir(pos, zmypos)

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
