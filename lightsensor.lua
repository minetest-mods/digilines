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
	description = "Digiline Lightsensor",
	drawtype = "nodebox",
	tiles = {"digilines_lightsensor.png"},

	paramtype = "light",
	groups = {dig_immediate=2},
	selection_box = lsensor_selbox,
	node_box = lsensor_nodebox,
	digiline =
	{
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;Channel;${channel}]")
	end,
	on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
})
