local S = digilines.S

local pipeworks_enabled = minetest.get_modpath("pipeworks") ~= nil

-- Sends a message onto the Digilines network.
-- pos: the position of the Digilines chest node.
-- action: the action string indicating what happened.
-- stack: the ItemStack that the action acted on (optional).
-- from_slot: the slot number that is taken from (optional).
-- to_slot: the slot number that is put into (optional).
-- side: which side of the chest the action occurred (optional).
local function send_message(pos, action, stack, from_slot, to_slot, side)
	local channel = minetest.get_meta(pos):get_string("channel")
	local msg = {
		action = action,
		stack = stack and stack:to_table(),
		from_slot = from_slot,
		to_slot = to_slot,
		-- Duplicate the vector in case the caller expects it not to change.
		side = side and vector.new(side)
	}
	digilines.receptor_send(pos, digilines.rules.default, channel, msg)
end

-- Checks if the inventory has become empty and, if so, sends an empty message.
local function check_empty(pos)
	if minetest.get_meta(pos):get_inventory():is_empty("main") then
		send_message(pos, "empty")
	end
end

-- Checks if the inventory has become full for a particular type of item and,
-- if so, sends a full message.
local function check_full(pos, stack)
	local one_item_stack = ItemStack(stack)
	one_item_stack:set_count(1)
	if not minetest.get_meta(pos):get_inventory():room_for_item("main", one_item_stack) then
		send_message(pos, "full", one_item_stack)
	end
end

local tubeconn = pipeworks_enabled and "^pipeworks_tube_connection_wooden.png" or ""
local tubescan = pipeworks_enabled and function(pos) pipeworks.scan_for_tube_objects(pos) end or nil

-- A place to remember things from allow_metadata_inventory_put to
-- on_metadata_inventory_put. This is a hack due to issue
-- minetest/minetest#6534 that should be removed once that’s fixed.
local last_inventory_put_index
local last_inventory_put_stack

-- A place to remember things from allow_metadata_inventory_take to
-- tube.remove_items. This is a hack due to issue minetest-mods/pipeworks#205
-- that should be removed once that’s fixed.
local last_inventory_take_index

local tube_can_insert = function(pos, _, stack, direction)
	local ret = minetest.get_meta(pos):get_inventory():room_for_item("main", stack)
	if not ret then
		-- The stack cannot be accepted. It will never be passed to
		-- insert_object, but it should be reported as a toverflow.
		-- Here, direction = direction item is moving, which is into
		-- side.
		local side = vector.multiply(direction, -1)
		send_message(pos, "toverflow", stack, nil, nil, side)
	end
	return ret
end

local tube_insert_object = function(pos, _, original_stack, direction)
	-- Here, direction = direction item is moving, which is into side.
	local side = vector.multiply(direction, -1)
	local inv = minetest.get_meta(pos):get_inventory()
	local inv_contents = inv:get_list("main")
	local any_put = false
	local stack = original_stack
	local stack_name = stack:get_name()
	local stack_count = stack:get_count()
	-- Walk the inventory, adding items to existing stacks of the same
	-- type.
	for i = 1, #inv_contents do
		local existing_stack = inv_contents[i]
		if not existing_stack:is_empty() and existing_stack:get_name() == stack_name then
			local leftover = existing_stack:add_item(stack)
			local leftover_count = leftover:get_count()
			if leftover_count ~= stack_count then
				-- We put some items into the slot. Update the slot in
				-- the inventory, tell Digilines listeners about it,
				-- and keep looking for the a place to put the
				-- leftovers if any.
				any_put = true
				inv:set_stack("main", i, existing_stack)
				local stack_that_was_put
				if leftover_count == 0 then
					stack_that_was_put = stack
				else
					stack_that_was_put = ItemStack(stack)
					stack_that_was_put:set_count(stack_count - leftover_count)
				end
				send_message(pos, "tput", stack_that_was_put, nil, i, side)
				stack = leftover
				stack_count = leftover_count
				if stack_count == 0 then
					break
				end
			end
		end
	end
	if stack_count ~= 0 then
		-- Walk the inventory, adding items to empty slots.
		for i = 1, #inv_contents do
			local existing_stack = inv_contents[i]
			if existing_stack:is_empty() then
				local leftover = existing_stack:add_item(stack)
				local leftover_count = leftover:get_count()
				if leftover_count ~= stack_count then
					-- We put some items into the slot. Update the slot in
					-- the inventory, tell Digilines listeners about it,
					-- and keep looking for the a place to put the
					-- leftovers if any.
					any_put = true
					inv:set_stack("main", i, existing_stack)
					local stack_that_was_put
					if leftover_count == 0 then
						stack_that_was_put = stack
					else
						stack_that_was_put = ItemStack(stack)
						stack_that_was_put:set_count(stack_count - leftover_count)
					end
					send_message(pos, "tput", stack_that_was_put, nil, i, side)
					stack = leftover
					stack_count = leftover_count
					if stack_count == 0 then
						break
					end
				end
			end
		end
	end
	if any_put then
		check_full(pos, original_stack)
	end
	if stack_count ~= 0 then
		-- Some items could not be added and bounced back. Report them.
		send_message(pos, "toverflow", stack, nil, nil, side)
	end
	return stack
end

local formspec_header = ""

if minetest.get_modpath("mcl_formspec") then
	formspec_header = mcl_formspec.get_itemslot_bg(0,1,8,4)..
		mcl_formspec.get_itemslot_bg(0,6,8,4)
end

minetest.register_alias("digilines_inventory:chest", "digilines:chest")

minetest.register_node("digilines:chest", {
	description = S("Digiline Chest"),
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
	groups = {choppy=2, oddly_breakable_by_hand=2, tubedevice=1, tubedevice_receiver=1, axey=1, handy=1},
	is_ground_content = false,
	sounds = digilines.sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Digiline Chest"))
		meta:set_string("formspec", "size[8,10]"..
			formspec_header..
			"label[0,0;" .. S("Digiline Chest") .. "]" ..
			"list[current_name;main;0,1;8,4;]"..
			"field[2,5.5;5,1;channel;" .. S("Channel") .. ";${channel}]"..
			((default and default.get_hotbar_bg) and default.get_hotbar_bg(0,6) or "")..
			"list[current_player;main;0,6;8,4;]"..
			"listring[]")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	after_place_node = tubescan,
	after_dig_node = tubescan,
	can_dig = function(pos)
		return minetest.get_meta(pos):get_inventory():is_empty("main")
	end,
	on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			return
		end
		if fields.channel ~= nil then
			minetest.get_meta(pos):set_string("channel",fields.channel)
		end
	end,
	digilines = {
		receptor = {},
		effector = {
			action = function() end
		}
	},
	tube = {
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1},
		connects = function(i,param2)
			return not pipeworks.connects.facingFront(i,param2)
		end,
		input_inventory = "main",
		can_insert = tube_can_insert,
		insert_object = tube_insert_object,
		remove_items = function(pos, _, stack, dir, count)
			-- Here, stack is the ItemStack in our own inventory that is being
			-- pulled from, NOT the stack that is actually pulled out.
			-- Combining it with count gives the stack that is pulled out.
			-- Also, note that Pipeworks doesn’t pass the index to this
			-- function, so we use the one recorded in
			-- allow_metadata_inventory_take; because we don’t implement
			-- tube.can_remove, Pipeworks will call
			-- allow_metadata_inventory_take instead and will pass it the
			-- index.
			local taken = stack:take_item(count)
			minetest.get_meta(pos):get_inventory():set_stack("main", last_inventory_take_index, stack)
			send_message(pos, "ttake", taken, last_inventory_take_index, nil, dir)
			check_empty(pos)
			return taken
		end,
	},
	allow_metadata_inventory_put = function(pos, _, index, stack)
		-- Remember what was in the target slot before the put; see
		-- on_metadata_inventory_put for why we care.
		last_inventory_put_index = index
		last_inventory_put_stack = minetest.get_meta(pos):get_inventory():get_stack("main", index)
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(_, _, index, stack)
		-- Remember the index value; see tube.remove_items for why we care.
		last_inventory_take_index = index
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, _, from_index, _, to_index, count, player)
		-- See what would happen if we were to move the items back from in the
		-- opposite direction. In the event of a normal move, this must
		-- succeed, because a normal move subtracts some items from the from
		-- stack and adds them to the to stack; the two stacks naturally must
		-- be compatible and so the reverse operation must succeed. However, if
		-- the user *swaps* the two stacks instead, then due to issue
		-- minetest/minetest#6534, this function is only called once; however,
		-- when it is called, the stack that used to be in the to stack has
		-- already been moved to the from stack, so we can detect the situation
		-- by the fact that the reverse move will fail due to the from stack
		-- being incompatible with its former contents.
		local inv = minetest.get_meta(pos):get_inventory()
		local from_stack = inv:get_stack("main", from_index)
		local to_stack = inv:get_stack("main", to_index)
		local reverse_move_stack = ItemStack(to_stack)
		reverse_move_stack:set_count(count)
		local swapped = from_stack:add_item(reverse_move_stack):get_count() == count
		if swapped then
			local channel = minetest.get_meta(pos):get_string("channel")
			to_stack:set_count(count)
			local msg = {
				action = "uswap",
				-- The slot and stack do not match because this function is
				-- called after the action has taken place, but the Digilines
				-- message is from the perspective of a viewer who hasn’t
				-- observed the movement yet.
				x_stack = to_stack:to_table(),
				x_slot = from_index,
				y_stack = from_stack:to_table(),
				y_slot = to_index,
			}
			digilines.receptor_send(pos, digilines.rules.default, channel, msg)
		else
			to_stack:set_count(count)
			send_message(pos, "umove", to_stack, from_index, to_index)
		end
		minetest.log("action", player:get_player_name().." moves stuff in chest at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, _, index, stack, player)
		-- Get what was in the target slot before the put; it has disappeared
		-- by now (been replaced by the result of the put action) but we saved
		-- it in allow_metadata_inventory_put. This should always work
		-- (allow_metadata_inventory_put should AFAICT always be called
		-- immediately before on_metadata_inventory_put), but in case of
		-- something weird happening, just fall back to using an empty
		-- ItemStack rather than crashing.
		local old_stack
		if last_inventory_put_index == index then
			old_stack = last_inventory_put_stack
			last_inventory_put_index = nil
			last_inventory_put_stack = nil
		else
			old_stack = ItemStack(nil)
		end
		-- If the player tries to place a stack into an inventory, there’s
		-- already a stack there, and the existing stack is either of a
		-- different item type or full, then obviously the stacks can’t be
		-- merged; instead the stacks are swapped. This information is not
		-- reported to mods (Minetest core neither tells us that a particular
		-- action was a swap, nor tells us a take followed by a put). In core,
		-- the condition for swapping is that you try to add the new stack to
		-- the existing stack and the leftovers are as big as the original
		-- stack to put. Replicate that logic here using the old stack saved in
		-- allow_metadata_inventory_put. If a swap happened, report it to the
		-- Digilines network as a utake followed by a uput.
		local leftovers = old_stack:add_item(stack)
		if leftovers:get_count() == stack:get_count() then
			send_message(pos, "utake", old_stack, index)
		end
		send_message(pos, "uput", stack, nil, index)
		check_full(pos, stack)
		minetest.log("action", player:get_player_name().." puts stuff into chest at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, _, index, stack, player)
		send_message(pos, "utake", stack, index)
		check_empty(pos)
		minetest.log("action", player:get_player_name().." takes stuff from chest at "..minetest.pos_to_string(pos))
	end
})

if minetest.global_exists("tubelib") then
	local speculative_pull = nil
	local pull_succeeded = function(passed_speculative_pull)
		if passed_speculative_pull.canceled then return end

		send_message(passed_speculative_pull.pos, "ttake", passed_speculative_pull.taken,
				passed_speculative_pull.index, nil, vector.multiply(passed_speculative_pull.dir, -1))
		check_empty(passed_speculative_pull.pos)
	end
	local function tube_side(pos, side)
		if side == "U" then return {x=0,y=-1,z=0}
		elseif side == "D" then return {x=0,y=1,z=0}
		end
		local param2 = minetest.get_node(pos).param2
		return vector.multiply(
			minetest.facedir_to_dir(
				tubelib2.side_to_dir(side, param2) - 1),
			-1)
	end
	tubelib.register_node("digilines:chest", {}, {
		on_pull_stack = function(pos, side, _)
			local inv = minetest.get_meta(pos):get_inventory()
			for i, stack in pairs(inv:get_list("main")) do
				if not stack:is_empty() then
					speculative_pull = {
						canceled = false,
						pos = pos,
						taken = stack,
						index = i,
						dir = tube_side(pos, side)
					}
					minetest.after(0, pull_succeeded, speculative_pull)
					inv:set_stack("main", i, nil)
					return stack
				end
			end
			return nil
		end,
		on_pull_item = function(pos, side, _)
			local inv = minetest.get_meta(pos):get_inventory()
			for i, stack in pairs(inv:get_list("main")) do
				if not stack:is_empty() then
					local taken = stack:take_item(1)
					speculative_pull = {
						canceled = false,
						pos = pos,
						taken = taken,
						index = i,
						dir = tube_side(pos, side)
					}
					minetest.after(0, pull_succeeded, speculative_pull)
					inv:set_stack("main", i, stack)
					return taken
				end
			end
			return nil
		end,
		on_push_item = function(pos, side, item, _)
			local dir_vec = tube_side(pos, side)
			if not tube_can_insert(pos, nil, item, dir_vec) then
				return false
			end
			tube_insert_object(pos, nil, item, dir_vec)
			return true
		end,
		on_unpull_item = function(pos, _, item, _)
			local inv = minetest.get_meta(pos):get_inventory()
			if not inv:room_for_item("main", item) then
				return false
			end

			local existing_stack = inv:get_stack("main", speculative_pull.index)
			local leftover = existing_stack:add_item(item)
			if not leftover:is_empty() then
				return false
			end

			inv:set_stack("main", speculative_pull.index, existing_stack)

			-- Cancel speculative pull
			-- this on_unpull_item callback should be called
			-- immediately after on_pull_item if it fails
			-- so this should be procedural
			speculative_pull.canceled = true
			speculative_pull = nil
			return true
		end,
	})
end

local chest = "default:chest"

if minetest.get_modpath("mcl_chests") then
	chest = "mcl_chests:chest"
end

minetest.register_craft({
	type = "shapeless",
	output = "digilines:chest",
	recipe = {chest, "digilines:wire_std_00000000"}
})
