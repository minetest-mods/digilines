digiline = {}
dofile(minetest.get_modpath("digilines").."/presetrules.lua")
dofile(minetest.get_modpath("digilines").."/util.lua")
dofile(minetest.get_modpath("digilines").."/internal.lua")
dofile(minetest.get_modpath("digilines").."/wires_common.lua")
dofile(minetest.get_modpath("digilines").."/wire_std.lua")

function digiline:receptor_send(pos, rules, channel, msg)
	local checked = {}
	checked[tostring(pos.x).."_"..tostring(pos.y).."_"..tostring(pos.z)] = true -- exclude itself
	for _,rule in ipairs(rules) do
		if digiline:rules_link(pos, digiline:addPosRule(pos, rule)) then
			digiline:transmit(digiline:addPosRule(pos, rule), channel, msg, checked)
		end
	end
end
