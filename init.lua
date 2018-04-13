
digilines = {}

-- Backwards compatibility code.
-- We define a proxy table whose methods can be called with the
-- `foo:bar` notation, and it will redirect the call to the
-- real function, dropping the first implicit argument.
local digiline; digiline = setmetatable({}, {
	__index = function(_, k)
		-- Get method from real table.
		local v = digilines[k]
		if type(v) == "function" then
			-- We need to wrap functions in order to ignore
			-- the implicit `self` argument.
			local f = v
			return function(self, ...)
				-- Trap invalid calls of the form `digiline.foo(...)`.
				assert(self == digiline)
				return f(...)
			end
		end
		return v
	end,
})
rawset(_G, "digiline", digiline)

-- Let's test our proxy table.
function digilines._testproxy(x)
	return x
end

-- Test using old `digiline:foobar` form.
assert(digiline:_testproxy("foobar") == "foobar")

-- Test using new `digilines.foobar` form.
assert(digilines._testproxy("foobar") == "foobar")

-- Test calling incorrect form raises an error.
assert(not pcall(function() digiline._testproxy("foobar") end))

local modpath = minetest.get_modpath("digilines")
dofile(modpath .. "/presetrules.lua")
dofile(modpath .. "/util.lua")
dofile(modpath .. "/internal.lua")
dofile(modpath .. "/wires_common.lua")
dofile(modpath .. "/wire_std.lua")

function digilines.receptor_send(pos, rules, channel, msg)
	local checked = {}
	checked[minetest.hash_node_position(pos)] = true -- exclude itself
	for _,rule in ipairs(rules) do
		if digilines.rules_link(pos, digilines.addPosRule(pos, rule)) then
			digilines.transmit(digilines.addPosRule(pos, rule), channel, msg, checked)
		end
	end
end

minetest.register_craft({
	output = 'digilines:wire_std_00000000 2',
	recipe = {
		{'mesecons_materials:fiber', 'mesecons_materials:fiber', 'mesecons_materials:fiber'},
		{'mesecons_insulated:insulated_off', 'mesecons_insulated:insulated_off', 'default:gold_ingot'},
		{'mesecons_materials:fiber', 'mesecons_materials:fiber', 'mesecons_materials:fiber'},
	}
})

-- former submods
if minetest.is_yes(minetest.settings:get("digilines_enable_inventory") or true) then
	dofile(modpath .. "/inventory.lua")
end

if minetest.is_yes(minetest.settings:get("digilines_enable_lcd") or true) then
	dofile(modpath .. "/lcd.lua")
end

if minetest.is_yes(minetest.settings:get("digilines_enable_lightsensor") or true) then
	dofile(modpath .. "/lightsensor.lua")
end

if minetest.is_yes(minetest.settings:get("digilines_enable_rtc") or true) then
	dofile(modpath .. "/rtc.lua")
end
