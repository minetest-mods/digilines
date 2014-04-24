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

local on_digiline_receive = function (pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	if channel == setchan and msg == GET_COMMAND then
		local lightval = minetest.get_node_light(pos)
		digiline:receptor_send(pos, digiline.rules.default, channel, lightval)
	end
end

minetest.register_node("digilines_lightsensor:lightsensor", {
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
	on_receive_fields = function(pos, formname, fields, sender)
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
})
