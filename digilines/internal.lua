function digiline:getspec(node)
	if not minetest.registered_nodes[node.name] then return false end
	return minetest.registered_nodes[node.name].digiline
end

function digiline:importrules(spec, node)
	if type(spec) == 'function' then
		return spec(node)
	elseif spec then
		return spec
	else
		return digiline.rules.default
	end
end

function digiline:getAnyInputRules(pos)
	local node = minetest.get_node(pos)
	local spec = digiline:getspec(node)
	if not spec then return end

	if spec.wire then
		return digiline:importrules(spec.wire.rules, node)
	end
	if spec.effector then
		return digiline:importrules(spec.effector.rules, node)
	end

	return rules
end

function digiline:getAnyOutputRules(pos)
	local node = minetest.get_node(pos)
	local spec = digiline:getspec(node)
	if not spec then return end

	if spec.wire then
		return digiline:importrules(spec.wire.rules, node)
	end
	if spec.receptor then
		return digiline:importrules(spec.receptor.rules, node)
	end
end

function digiline:rules_link(output, input)
	local outputrules = digiline:getAnyOutputRules(output)
	local inputrules  = digiline:getAnyInputRules (input)

	if not outputrules or not inputrules then return false end


	for _, orule in ipairs(outputrules) do
		if digiline:cmpPos(digiline:addPosRule(output, orule), input) then
			for _, irule in ipairs(inputrules) do
				if digiline:cmpPos(digiline:addPosRule(input, irule), output) then
					return true
				end
			end
		end
	end
	return false
end

function digiline:rules_link_anydir(output, input)
	return digiline:rules_link(output, input)
	or     digiline:rules_link(input, output)
end

function digiline:transmit(pos, channel, msg, checked)
	local checkedid = tostring(pos.x).."_"..tostring(pos.y).."_"..tostring(pos.z)
	if checked[checkedid] then return end
	checked[checkedid] = true

	local node = minetest.get_node(pos)
	local spec = digiline:getspec(node)
	if not spec then return end


	-- Effector actions --> Receive
	if spec.effector then
		spec.effector.action(pos, node, channel, msg)
	end

	-- Cable actions --> Transmit
	if spec.wire then
		local rules = digiline:importrules(spec.wire.rules, node)
		for _,rule in ipairs(rules) do
			if digiline:rules_link(pos, digiline:addPosRule(pos, rule)) then
				digiline:transmit(digiline:addPosRule(pos, rule), channel, msg, checked)
			end
		end
	end
end
