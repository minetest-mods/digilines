local S = digilines.S
local FS = digilines.FS

local GET_COMMAND = "GET"

local rtc_nodebox =
{
	type = "fixed",
	fixed = {
		{ -8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }, -- bottom slab

		{ -7/16, -7/16, -7/16, 7/16, -5/16,  7/16 },
	}
}

local rtc_selbox =
{
	type = "fixed",
	fixed = {{ -8/16, -8/16, -8/16, 8/16, -3/16, 8/16 }}
}

local on_digiline_receive = function (pos, _, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	if channel == setchan and msg == GET_COMMAND then
		local timeofday = minetest.get_timeofday()
		digilines.receptor_send(pos, digilines.rules.default, channel, timeofday)
	end
end

minetest.register_alias("digilines_rtc:rtc", "digilines:rtc")
minetest.register_node("digilines:rtc", {
	description = S("Digiline Real Time Clock (RTC)"),
	drawtype = "nodebox",
	tiles = {
		"digilines_rtc.png", "digilines_rtc_bottom.png", "digilines_rtc.png",
		"digilines_rtc.png", "digilines_rtc.png", "digilines_rtc.png"
	},

	paramtype = "light",
	paramtype2 = "facedir",
	groups = {dig_immediate=2},
	is_ground_content = false,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 0.8,
	selection_box = rtc_selbox,
	node_box = rtc_nodebox,
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
local mese_crystal = "default:mese_crystal_fragment"
local dye_black = "dye:black"

if digilines.mcl then
	steel_ingot = "mcl_core:iron_ingot"
	mese_crystal = "mesecons:redstone"
end

if minetest.get_modpath("mcl_dye") then
	dye_black = "mcl_dye:black"
end

minetest.register_craft({
	output = "digilines:rtc",
	recipe = {
		{"", dye_black, ""},
		{steel_ingot, mese_crystal, steel_ingot},
		{"", "digilines:wire_std_00000000", ""}
	}
})
