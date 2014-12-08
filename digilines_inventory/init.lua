local function sendMessage(pos, msg, channel)
	if channel == nil then
		channel = minetest.get_meta(pos):get_string("channel")
	end
	digiline:receptor_send(pos,digiline.rules.default,channel,msg)
end

local function maybeString(stack)
	if type(stack)=='string' then return stack
	elseif type(stack)=='table' then return dump(stack)
	else return stack:to_string()
	end
end

local function can_insert(pos, stack)
	local can = minetest.get_meta(pos):get_inventory():room_for_item("main", stack)
	if can then
		sendMessage(pos,"put "..maybeString(stack))
	else
		-- overflow and lost means that items are gonna be out as entities :/
		sendMessage(pos,"lost "..maybeString(stack))
	end
	return can
end

local tubeconn = minetest.get_modpath("pipeworks") and "^pipeworks_tube_connection_wooden.png" or ""
local tubescan = minetest.get_modpath("pipeworks") and function(pos) pipeworks.scan_for_tube_objects(pos) end or nil

minetest.register_node("digilines_inventory:chest", {
	description = "Digiline Chest",
	tiles = {
		"default_chest_top.png"..tubeconn,
		"default_chest_top.png"..tubeconn,
		"default_chest_side.png"..tubeconn,
		"default_chest_side.png"..tubeconn,
		"default_chest_side.png"..tubeconn,
		"default_chest_front.png",
	},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	groups = {choppy=2, oddly_breakable_by_hand=2, tubedevice=1, tubedevice_receiver=1},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Digiline Chest")
		meta:set_string("formspec", "size[8,10]"..
			((default and default.gui_bg) or "")..
			((default and default.gui_bg_img) or "")..
			((default and default.gui_slots) or "")..
			"label[0,0;Digiline Chest]"..
			"list[current_name;main;0,1;8,4;]"..
			"field[2,5.5;5,1;channel;Channel;${channel}]"..
			((default and default.get_hotbar_bg) and default.get_hotbar_bg(0,6) or "")..
			"list[current_player;main;0,6;8,4;]")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	after_place_node = tubescan,
	after_dig_node = tubescan,
	can_dig = function(pos, player)
		return minetest.get_meta(pos):get_inventory():is_empty("main")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.channel ~= nil then
			minetest.get_meta(pos):set_string("channel",fields.channel)
		end
	end,
	digiline = {
		receptor = {},
		effector = {
			action = function(pos,node,channel,msg) end
		}
	},
	tube = {
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1},
		connects = function(i,param2)
			return not pipeworks.connects.facingFront(i,param2)
		end,
		input_inventory = "main",
		can_insert = function(pos, node, stack, direction)
			return can_insert(pos, stack)
		end,
		insert_object = function(pos, node, stack, direction)
			local inv = minetest.get_meta(pos):get_inventory()
			local leftover = inv:add_item("main", stack)
			local count = leftover:get_count()
			if count == 0 then
				local derpstack = stack:get_name()..' 1'
				if not inv:room_for_item("main", derpstack) then
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
	},
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not can_insert(pos, stack) then
			sendMessage(pos,"uoverflow "..maybeString(stack))
		end
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, fromlistname, fromindex, tolistname, toindex, count, player)
		minetest.log("action", player:get_player_name().." moves stuff in chest at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local channel = minetest.get_meta(pos):get_string("channel")
		local send = function(msg)
			sendMessage(pos,msg,channel)
		end
		-- direction is only for furnaces
		-- as the item has already been put, can_insert should return false if the chest is now full.
		local derpstack = stack:get_name()..' 1'
		if can_insert(pos,derpstack) then
			send("uput "..maybeString(stack))
		else
			send("ufull "..maybeString(stack))
		end
		minetest.log("action", player:get_player_name().." puts stuff into chest at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local inv = minetest.get_meta(pos):get_inventory()
		if inv:is_empty(listname) then
			sendMessage(pos, "empty", channel)
		end
		sendMessage(pos,"utake "..maybeString(stack))
		minetest.log("action", player:get_player_name().." takes stuff from chest at "..minetest.pos_to_string(pos))
	end
})
