local S = digilines.S
local FS = digilines.FS

local GET_COMMAND = "GET"

local lsensor_nodebox =
{
	type = "fixed",
	fixed = {
		{ -8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }, -- bottom slab

		{ -7/16, -7/16, -7/16, -4/16, -5/16,  7/16 }, -- bonds
		{  4/16, -7/16, -7/16,  7/16, -5/16,  7/16 },
		{ -7/16, -7/16, -7/16,  7/16, -5/16, -4/16 },
		{ -7/16, -7/16,  4/16,  7/16, -5/16,  7/16 },

		{ -1/16, -7/16, -1/16, 1/16, -5/16, 1/16 }, -- pin thing in the middle
	}
}

local lsensor_selbox =
{
	type = "fixed",
	fixed = {{ -8/16, -8/16, -8/16, 8/16, -3/16, 8/16 }}
}

local on_digiline_receive = function (pos, _, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	if channel == setchan and msg == GET_COMMAND then
		local lightval = minetest.get_node_light(pos)
		digilines.receptor_send(pos, digilines.rules.default, channel, lightval)
	end
end

minetest.register_alias("digilines_lightsensor:lightsensor", "digilines:lightsensor")
minetest.register_node("digilines:lightsensor", {
	description = S("Digiline Lightsensor"),
	drawtype = "nodebox",
	tiles = {"digilines_lightsensor.png"},

	paramtype = "light",
	groups = {dig_immediate=2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	selection_box = lsensor_selbox,
	node_box = lsensor_nodebox,
	digilines =
	{
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;"..FS("Channel")..";${channel}]")
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
})

local steel_ingot = "default:steel_ingot"
local glass = "default:glass"

if digilines.mcl then
	steel_ingot = "mcl_core:iron_ingot"
	glass = "mcl_core:glass"
end

minetest.register_craft({
	output = "digilines:lightsensor",
	recipe = {
		{glass, glass, glass},
		{steel_ingot, "digilines:wire_std_00000000", steel_ingot},
	}
})
