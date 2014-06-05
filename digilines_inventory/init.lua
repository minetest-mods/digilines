if not minetest.get_modpath("pipeworks") then
	print("[Digilines] Install pipeworks if you want to use the digilines chest")
	return
end

local defaultChest = minetest.registered_nodes['default:chest']

local sendMessage = function (pos, msg, channel)
	if channel == nil then
		channel = minetest.get_meta(pos):get_string("channel")
	end
	digiline:receptor_send(pos,digiline.rules.default,channel,msg)
end

tableMerge =  function(first_table,second_table)
	if second_table == nil then return end
	for k,v in pairs(second_table) do first_table[k] = v end
end

tableMergeImmutable = function(first_table, second_table)
	if first_table == nil then return second_table end
	if second_table == nil then return first_table end
	copy = digiline:tablecopy(first_table)
	for k,v in pairs(second_table) do copy[k] = v end
	return copy
end

local mychest = digiline:tablecopy(defaultChest)

function defer(what,...)
	if what then
		return what(...)
	end
end

function maybeString(stack)
	if type(stack)=='string' then return stack
	elseif type(stack)=='table' then return dump(stack)
	else return stack:to_string()
	end
end

mychest = tableMergeImmutable(defaultChest,{
	description = "Digiline Chest",
	digiline = {
		receptor = {},
		effector = {
			action = function(pos,node,channel,msg) end
		}
	},
	on_construct = function(pos)
		defaultChest.on_construct(pos)
		local meta = minetest.get_meta(pos)
		-- we'll  sneak into row 4 thanks
		meta:set_string("formspec",meta:get_string("formspec").."\nfield[2,4.5;5,1;channel;Channel;${channel}]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.channel ~= nil then
			minetest.get_meta(pos):set_string("channel",fields.channel)
			return defer(defaultChest.on_receive_fields, pos, formname, fields, sender)
		end
	end,
	tube = tableMergeImmutable(defaultChest.tube, {
		-- note: mese filters cannot put part of a stack in the destination.
		-- space for 50 coal with 99 added will pop out 99, not 49.
		connects = function(i,param2)
			return not pipeworks.connects.facingFront(i,param2)
		end,
		insert_object = function(pos, node, stack, direction)
			local leftover = defaultChest.tube.insert_object(pos,node,stack,direction)
			local count = leftover:get_count()
			if count == 0 then
				local derpstack = stack:get_name()..' 1'
				if not defaultChest.tube.can_insert(pos, node, derpstack, direction) then
					-- when you can't put a single more of whatever you just put,
					-- you'll get a put for it, then a full
					sendMessage(pos,"full "..maybeString(stack)..' '..tostring(count))
				end
			else
				-- this happens when the chest has received two stacks in a row and
				-- filled up exactly with the first one.
				-- You get a put for the first stack, a put for the second
				-- and then a overflow with the first in stack and the second in leftover
				-- and NO full?
				sendMessage(pos,"overflow "..maybeString(stack)..' '..tostring(count))
			end
			return leftover
		end,
		can_insert = function(pos, node, stack, direction)
			local can = defaultChest.tube.can_insert(pos, node, stack, direction)
			if can then
				sendMessage(pos,"put "..maybeString(stack))
			else
				-- overflow and lost means that items are gonna be out as entities :/
				sendMessage(pos,"lost "..maybeString(stack))
			end
			return can
		end,
	}),
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not mychest.tube.can_insert(pos,nil,stack,nil) then
			sendMessage(pos,"uoverflow "..maybeString(stack))
		end
		local ret = defer(defaultChest.allow_metadata_inventory_put, pos, listname, index, stack, player)
		if ret then return ret end
		return stack:get_count()
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local channel = minetest.get_meta(pos):get_string("channel")
		local send = function(msg)
			sendMessage(pos,msg,channel)
		end
		-- direction is only for furnaces
		-- as the item has already been put, can_insert should return false if the chest is now full.
		local derpstack = stack:get_name()..' 1'
		if mychest.tube.can_insert(pos,nil,derpstack,nil) then
			send("uput "..maybeString(stack))
		else
			send("ufull "..maybeString(stack))
		end
		return defer(defaultChest.on_metadata_inventory_put, pos, listname, index, stack, player)
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		sendMessage(pos,"utake "..maybeString(stack))
		return defaultChest.on_metadata_inventory_take(pos, listname, index, stack, player)
	end
})

if mychest.tube.can_insert == nil then
	-- we can use the can_insert function from pipeworks, but will duplicate if not found.
	mychest.tube.can_insert = function(pos,node,stack,direction)
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		return inv:room_for_item("main",stack)
	end
end

-- minetest.register_node(":default:chest", mychest)
minetest.register_node("digilines_inventory:chest", mychest)
