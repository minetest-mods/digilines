function digilines.getspec(node)
	if not minetest.registered_nodes[node.name] then return false end
	return minetest.registered_nodes[node.name].digiline
end

function digilines.importrules(spec, node)
	if type(spec) == 'function' then
		return spec(node)
	elseif spec then
		return spec
	else
		return digilines.rules.default
	end
end

function digilines.getAnyInputRules(pos)
	local node = digilines.get_node_force(pos)
	local spec = digilines.getspec(node)
	if not spec then return end

	if spec.wire then
		return digilines.importrules(spec.wire.rules, node)
	end
	if spec.effector then
		return digilines.importrules(spec.effector.rules, node)
	end
end

function digilines.getAnyOutputRules(pos)
	local node = digilines.get_node_force(pos)
	local spec = digilines.getspec(node)
	if not spec then return end

	if spec.wire then
		return digilines.importrules(spec.wire.rules, node)
	end
	if spec.receptor then
		return digilines.importrules(spec.receptor.rules, node)
	end
end

function digilines.rules_link(output, input)
	local outputrules = digilines.getAnyOutputRules(output)
	local inputrules  = digilines.getAnyInputRules (input)

	if not outputrules or not inputrules then return false end


	for _, orule in ipairs(outputrules) do
		if digilines.cmpPos(digilines.addPosRule(output, orule), input) then
			for _, irule in ipairs(inputrules) do
				if digilines.cmpPos(digilines.addPosRule(input, irule), output) then
					return true
				end
			end
		end
	end
	return false
end

function digilines.rules_link_anydir(output, input)
	return digilines.rules_link(output, input)
	or     digilines.rules_link(input, output)
end

local function queue_new()
	return {nextRead = 1, nextWrite = 1}
end

local function queue_empty(queue)
	return queue.nextRead == queue.nextWrite
end

local function queue_enqueue(queue, object)
	local nextWrite = queue.nextWrite
	queue[nextWrite] = object
	queue.nextWrite = nextWrite + 1
end

local function queue_dequeue(queue)
	local nextRead = queue.nextRead
	local object = queue[nextRead]
	queue[nextRead] = nil
	queue.nextRead = nextRead + 1
	return object
end

function digilines.transmit(pos, channel, msg, checked)
	digilines.vm_begin()
	local queue = queue_new()
	queue_enqueue(queue, pos)
	while not queue_empty(queue) do
		local curPos = queue_dequeue(queue)
		local node = digilines.get_node_force(curPos)
		local spec = digilines.getspec(node)
		if spec then
			-- Effector actions --> Receive
			if spec.effector then
				spec.effector.action(curPos, node, channel, msg)
			end

			-- Cable actions --> Transmit
			if spec.wire then
				local rules = digilines.importrules(spec.wire.rules, node)
				for _, rule in ipairs(rules) do
					local nextPos = digilines.addPosRule(curPos, rule)
					if digilines.rules_link(curPos, nextPos) then
						local checkedID = minetest.hash_node_position(nextPos)
						if not checked[checkedID] then
							checked[checkedID] = true
							queue_enqueue(queue, nextPos)
						end
					end
				end
			end
		end
	end
	digilines.vm_end()
end
