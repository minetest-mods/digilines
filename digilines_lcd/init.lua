--* parts are currently not possible because you cannot set the pitch of an entity from lua

-- Font: 04.jp.org

-- load characters map
local chars_file = io.open(minetest.get_modpath("digilines_lcd").."/characters", "r")
local charmap = {}
local max_chars = 12
if not chars_file then
	print("[digilines_lcd] E: character map file not found")
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

local lcds = {
	-- on ceiling
	--* [0] = {delta = {x = 0, y = 0.4, z = 0}, pitch = math.pi / -2},
	-- on ground
	--* [1] = {delta = {x = 0, y =-0.4, z = 0}, pitch = math.pi /  2},
	-- sides
	[2] = {delta = {x =  0.4, y = 0, z = 0}, yaw = math.pi / -2},
	[3] = {delta = {x = -0.4, y = 0, z = 0}, yaw = math.pi /  2},
	[4] = {delta = {x = 0, y = 0, z =  0.4}, yaw = 0},
	[5] = {delta = {x = 0, y = 0, z = -0.4}, yaw = math.pi},
}

local reset_meta = function(pos)
	minetest.get_meta(pos):set_string("formspec", "field[channel;Channel;${channel}]")
end

local clearscreen = function(pos)
	local objects = minetest.get_objects_inside_radius(pos, 0.5)
	for _, o in ipairs(objects) do
		if o:get_entity_name() == "digilines_lcd:text" then
			o:remove()
		end
	end
end

local prepare_writing = function(pos)
	lcd_info = lcds[minetest.get_node(pos).param2]
	if lcd_info == nil then return end
	local text = minetest.add_entity(
		{x = pos.x + lcd_info.delta.x,
		 y = pos.y + lcd_info.delta.y,
		 z = pos.z + lcd_info.delta.z}, "digilines_lcd:text")
	text:setyaw(lcd_info.yaw or 0)
	--* text:setpitch(lcd_info.yaw or 0)
	return text
end

local on_digiline_receive = function(pos, node, channel, msg)
	local meta = minetest.get_meta(pos)
	local setchan = meta:get_string("channel")
	if setchan ~= channel then return end

	meta:set_string("text", msg)
	clearscreen(pos)
	if msg ~= "" then
		prepare_writing(pos)
	end
end

local lcd_box = {
	type = "wallmounted",
	wall_top = {-8/16, 7/16, -8/16, 8/16, 8/16, 8/16}
}

minetest.register_node("digilines_lcd:lcd", {
	drawtype = "nodebox",
	description = "Digiline LCD",
	inventory_image = "lcd_lcd.png",
	wield_image = "lcd_lcd.png",
	tiles = {"lcd_anyside.png"},

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	node_box = lcd_box,
	selection_box = lcd_box,
	groups = {choppy = 3, dig_immediate = 2},

	after_place_node = function (pos, placer, itemstack)
		local param2 = minetest.get_node(pos).param2
		if param2 == 0 or param2 == 1 then
			minetest.add_node(pos, {name = "digilines_lcd:lcd", param2 = 3})
		end
		prepare_writing (pos)
	end,

	on_construct = function(pos)
		reset_meta(pos)
	end,

	on_destruct = function(pos)
		clearscreen(pos)
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,

	digiline = 
	{
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},

	light_source = 6,
})

minetest.register_entity("digilines_lcd:text", {
	collisionbox = { 0, 0, 0, 0, 0, 0 },
	visual = "upright_sprite",
	textures = {},

	on_activate = function(self)
		local meta = minetest.get_meta(self.object:getpos())
		local text = meta:get_string("text")
		self.object:set_properties({textures={generate_texture(create_lines(text))}})
	end
})

-- CONSTANTS
local LCD_WITH = 100
local LCD_PADDING = 8

local LINE_LENGTH = 12
local NUMBER_OF_LINES = 5

local LINE_HEIGHT = 14
local CHAR_WIDTH = 5

create_lines = function(text)
	local line = ""
	local line_num = 1
	local tab = {}
	for word in string.gmatch(text, "%S+") do
		if string.len(line)+string.len(word) < LINE_LENGTH and word ~= "|" then
			if line ~= "" then
				line = line.." "..word
			else
				line = word
			end
		else
			table.insert(tab, line)
			if word ~= "|" then
				line = word
			else
				line = ""
			end
			line_num = line_num+1
			if line_num > NUMBER_OF_LINES then
				return tab
			end
		end
	end
	table.insert(tab, line)
	return tab
end

generate_texture = function(lines)
	local texture = "[combine:"..LCD_WITH.."x"..LCD_WITH
	local ypos = 16
	for i = 1, #lines do
		texture = texture..generate_line(lines[i], ypos)
		ypos = ypos + LINE_HEIGHT
	end
	return texture
end

generate_line = function(s, ypos)
	local i = 1
	local parsed = {}
	local width = 0
	local chars = 0
	while chars < max_chars and i <= #s do
		local file = nil
		if charmap[s:sub(i, i)] ~= nil then
			file = charmap[s:sub(i, i)]
			i = i + 1
		elseif i < #s and charmap[s:sub(i, i + 1)] ~= nil then
			file = charmap[s:sub(i, i + 1)]
			i = i + 2
		else
			print("[digilines_lcd] W: unknown symbol in '"..s.."' at "..i)
			i = i + 1
		end
		if file ~= nil then
			width = width + CHAR_WIDTH
			table.insert(parsed, file)
			chars = chars + 1
		end
	end
	width = width - 1

	local texture = ""
	local xpos = math.floor((LCD_WITH - 2 * LCD_PADDING - width) / 2 + LCD_PADDING)
	for i = 1, #parsed do
		texture = texture..":"..xpos..","..ypos.."="..parsed[i]..".png"
		xpos = xpos + CHAR_WIDTH + 1
	end
	return texture
end

minetest.register_craft({
	output = "digilines_lcd:lcd 2",
	recipe = {
		{"default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot"},
		{"mesecons_lightstone:lightstone_green_off","mesecons_lightstone:lightstone_green_off","mesecons_lightstone:lightstone_green_off"},
		{"default:glass","default:glass","default:glass"}
	}
})
