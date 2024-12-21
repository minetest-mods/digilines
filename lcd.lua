local S = digilines.S
local FS = digilines.FS

--* parts are currently not possible because you cannot set the pitch of an entity from lua

-- Font: 04.jp.org

-- load characters map
local chars_file = io.open(minetest.get_modpath("digilines").."/characters", "r")
local charmap = {}
if not chars_file then
	print("[digilines] E: LCD: character map file not found")
else
	while true do
		local char = chars_file:read("*l")
		if char == nil then
			break
		end
		local img = chars_file:read("*l")
		chars_file:read("*l")
		charmap[char] = img
	end
end

-- CONSTANTS
local LCD_WIDTH = 100
local LCD_PADDING = 8

local LINE_LENGTH = 12
local NUMBER_OF_LINES = 5

local LINE_HEIGHT = 14
local CHAR_WIDTH = 5


assert((CHAR_WIDTH+1) * LINE_LENGTH <= LCD_WIDTH - LCD_PADDING*2, "LCD: Lines set too long!")
assert((LINE_HEIGHT+1) * NUMBER_OF_LINES <= LCD_WIDTH - LCD_PADDING*2, "LCD: Too many lines!")


local split = function(s, pat)
	-- adapted from https://stackoverflow.com/a/1647577/4067384
	-- simplified for our only usecase
	local st, g = 1, s:gmatch("()("..pat..")")
	local function getter()
		if st then
			local segs, seps, sep = st, g()
			st = sep and seps + #sep
			return s:sub(segs, (seps or 0) - 1)
		end
	end
	return getter
end

local create_lines = function(text)
	--[[
	  Typeset the lines according to these rules (in order of subjective significance):
	  - words that fit on the screen but would let the current line overflow are placed on a new line instead
	  - " | " always forces a linebreak
	  - spaces are included, except when there is a linebreak anyway
	  - words with more characters than fit on screen are just chopped up, filling the lines as full as possible
	  - don't bother typesetting more lines than fit on screen
	  - if we are on the last line that will fit on screen
	]]--
	local line = ""
	local line_num = 1
	local tab = {}
	local flush_line_and_check_for_return = function()
		table.insert(tab, line)
		line_num = line_num+1
		if line_num > NUMBER_OF_LINES then
			return true
		end
		line = ""
	end
	for par in split(text, " | ") do
		for word in split(par, "%s") do
			if string.len(word) <= LINE_LENGTH and line_num < NUMBER_OF_LINES then
				local line_len = string.len(line)
				if line_len > 0 then
					-- remember the space
					line_len = line_len + 1
				end
				if line_len + string.len(word) <= LINE_LENGTH then
					if line_len > 0 then
						line = line.." "..word
					else
						line = word
					end
				else
					-- don't add the space since we have a line break
					if word ~= " " then
						if line_len > 0 then
							-- ok, we need the new line
							if flush_line_and_check_for_return() then return tab end
						end
						line = word
					end
				end
			else
				-- chop up word to make it fit
				local remaining
				while true do
					remaining = LINE_LENGTH - string.len(line)
					if remaining < LINE_LENGTH then
						line = line .. " "
						remaining = remaining - 1
					end
					if remaining < string.len(word) then
						line = line .. string.sub(word, 1, remaining)
						word = string.sub(word, remaining+1)
						if flush_line_and_check_for_return() then return tab end
					else
						-- used up the word
						line = line .. word
						break
					end
				end
			end
		end
		-- end of paragraph
		if flush_line_and_check_for_return() then return tab end
		line = ""
	end
	return tab
end

local generate_line = function(s, ypos)
	local i = 1
	local parsed = {}
	local width = 0
	local chars = 0
	while chars < LINE_LENGTH and i <= #s do
		local file = nil
		if charmap[s:sub(i, i)] ~= nil then
			file = charmap[s:sub(i, i)]
			i = i + 1
		elseif i < #s and charmap[s:sub(i, i + 1)] ~= nil then
			file = charmap[s:sub(i, i + 1)]
			i = i + 2
		else
			print("[digilines] W: LCD: unknown symbol in '"..s.."' at "..i)
			if charmap[" "] ~= nil then
				file = charmap[" "]
			end
			i = i + 1
		end
		if file ~= nil then
			width = width + CHAR_WIDTH + 1
			table.insert(parsed, file)
			chars = chars + 1
		end
	end
	width = width - 1

	local texture = ""
	local xpos = math.floor((LCD_WIDTH - width) / 2)
	for ii = 1, #parsed do
		texture = texture..":"..xpos..","..ypos.."="..parsed[ii]..".png"
		xpos = xpos + CHAR_WIDTH + 1
	end
	return texture
end

local generate_texture = function(lines)
	local texture = "[combine:"..LCD_WIDTH.."x"..LCD_WIDTH
	local ypos = math.floor((LCD_WIDTH - LINE_HEIGHT*NUMBER_OF_LINES) / 2)
	for i = 1, #lines do
		texture = texture..generate_line(lines[i], ypos)
		ypos = ypos + LINE_HEIGHT
	end
	return texture
end

local lcds = {
	-- on ceiling
	--* [0] = {delta = {x = 0, y = 0.4, z = 0}, pitch = math.pi / -2},
	-- on ground
	--* [1] = {delta = {x = 0, y =-0.4, z = 0}, pitch = math.pi /  2},
	-- sides

	-- Note: 0.437 is on the surface but we need some space to avoid
	--       z-fighting in distant places (e.g. 30000,10,0)
	[2] = {delta = {x =  0.43, y = 0, z = 0}, yaw = math.pi / -2},
	[3] = {delta = {x = -0.43, y = 0, z = 0}, yaw = math.pi /  2},
	[4] = {delta = {x = 0, y = 0, z =  0.43}, yaw = 0},
	[5] = {delta = {x = 0, y = 0, z = -0.43}, yaw = math.pi},
}

local reset_meta = function(pos)
	minetest.get_meta(pos):set_string("formspec", "field[channel;"..FS("Channel")..";${channel}]")
end

local clearscreen = function(pos)
	local objects = minetest.get_objects_inside_radius(pos, 0.5)
	for _, o in ipairs(objects) do
		local o_entity = o:get_luaentity()
		if o_entity and o_entity.name == "digilines_lcd:text" then
			o:remove()
		end
	end
end

local set_texture = function(ent)
	local meta = minetest.get_meta(ent.object:get_pos())
	local text = meta:get_string("text")
	ent.object:set_properties({
		textures = {
			generate_texture(create_lines(text))
		}
	})
end

local get_entity = function(pos)
	local lcd_entity
	local objects = minetest.get_objects_inside_radius(pos, 0.5)
	for _, o in ipairs(objects) do
		local o_entity = o:get_luaentity()
		if o_entity and o_entity.name == "digilines_lcd:text" then
			if not lcd_entity then
				lcd_entity = o_entity
			else
				-- Remove extras, if any
				o:remove()
			end
		end
	end
	return lcd_entity
end

local rotate_text = function(pos, param)
	local entity = get_entity(pos)
	if not entity then
		return
	end
	local lcd_info = lcds[param or minetest.get_node(pos).param2]
	if not lcd_info then
		return
	end
	entity.object:set_pos(vector.add(pos, lcd_info.delta))
	entity.object:set_yaw(lcd_info.yaw or 0)
end

local prepare_writing = function(pos)
	local entity = get_entity(pos)
	if entity then
		set_texture(entity)
		rotate_text(pos)
	end
end

local spawn_entity = function(pos)
	if not get_entity(pos) then
		minetest.add_entity(pos, "digilines_lcd:text")
		rotate_text(pos)
	end
end

local on_digiline_receive = function(pos, _, channel, msg)
	local meta = minetest.get_meta(pos)
	local setchan = meta:get_string("channel")
	if setchan ~= channel then return end

	if type(msg) ~= "string" and type(msg) ~= "number" then return end

	meta:set_string("text", msg)
	meta:set_string("infotext", msg)

	if msg ~= "" then
		prepare_writing(pos)
	end
end

local lcd_box = {
	type = "wallmounted",
	wall_top = {-8/16, 7/16, -8/16, 8/16, 8/16, 8/16}
}

minetest.register_alias("digilines_lcd:lcd", "digilines:lcd")
minetest.register_node("digilines:lcd", {
	drawtype = "nodebox",
	description = S("Digiline LCD"),
	inventory_image = "lcd_lcd.png",
	wield_image = "lcd_lcd.png",
	tiles = {"lcd_anyside.png"},
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 6,
	paramtype2 = "wallmounted",
	node_box = lcd_box,
	selection_box = lcd_box,
	groups = {choppy = 3, dig_immediate = 2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	after_place_node = function(pos)
		local param2 = minetest.get_node(pos).param2
		if param2 == 0 or param2 == 1 then
			minetest.add_node(pos, {name = "digilines:lcd", param2 = 3})
		end
		spawn_entity(pos)
		prepare_writing(pos)
	end,
	on_construct = reset_meta,
	on_destruct = clearscreen,
	on_punch = function(pos, _, puncher, _)
		if minetest.is_player(puncher) then
			spawn_entity(pos)
		end
	end,
	on_rotate = function(pos, _, _, mode, new_param2)
		if mode ~= screwdriver.ROTATE_FACE then
			return false
		end
		rotate_text(pos, new_param2)
	end,
	on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			return
		end
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
	digilines = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
})

minetest.register_lbm({
	label = "Replace Missing Text Entities",
	name = "digilines:replace_text",
	nodenames = {"digilines:lcd"},
	run_at_every_load = true,
	action = spawn_entity,
})

minetest.register_entity(":digilines_lcd:text", {
	initial_properties = {
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		visual = "upright_sprite",
		textures = {},
	},
	on_activate = set_texture,
})

local steel_ingot = "default:steel_ingot"
local glass = "default:glass"
local lightstone = "mesecons_lightstone:lightstone_green_off"

if digilines.mcl then
	steel_ingot = "mcl_core:iron_ingot"
	glass = "mcl_core:glass"
	lightstone = "mesecons_lightstone:lightstone_off"
end

minetest.register_craft({
	output = "digilines:lcd 2",
	recipe = {
		{steel_ingot, "digilines:wire_std_00000000", steel_ingot},
		{lightstone, lightstone, lightstone},
		{glass, glass, glass}
	}
})
