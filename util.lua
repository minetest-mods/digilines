function digilines.addPosRule(p, r)
	return {x = p.x + r.x, y = p.y + r.y, z = p.z + r.z}
end

function digilines.cmpPos(p1, p2)
	return (p1.x == p2.x and p1.y == p2.y and p1.z == p2.z)
end

--Rules rotation Functions:
function digilines.rotate_rules_right(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].z=rule.x
		nr[i].x=-rule.z
		nr[i].y=rule.y
	end
	return nr
end

function digilines.rotate_rules_left(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].z=-rule.x
		nr[i].x=rule.z
		nr[i].y=rule.y
	end
	return nr
end

function digilines.rotate_rules_down(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].y=rule.x
		nr[i].x=-rule.y
		nr[i].z=rule.z
	end
	return nr
end

function digilines.rotate_rules_up(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].y=-rule.x
		nr[i].x=rule.y
		nr[i].z=rule.z
	end
	return nr
end

function digilines.tablecopy(table) -- deep table copy
	if type(table) ~= "table" then return table end -- no need to copy
	local newtable = {}

	for idx, item in pairs(table) do
		if type(item) == "table" then
			newtable[idx] = digilines.tablecopy(item)
		else
			newtable[idx] = item
		end
	end

	return newtable
end



-- VoxelManipulator-based node access functions:

-- Maps from a hashed mapblock position (as returned by hash_blockpos) to a
-- table.
--
-- Contents of the table are:
-- “va” → the VoxelArea
-- “data” → the data array
-- “param1” → the param1 array
-- “param2” → the param2 array
--
-- Nil if no bulk-VM operation is in progress.
local vm_cache = nil

-- Starts a bulk-VoxelManipulator operation.
--
-- During a bulk-VoxelManipulator operation, calls to get_node_force operate
-- directly on VM-loaded arrays, which should be faster for reading many nodes
-- in rapid succession. However, the cache must be flushed with vm_end once the
-- scan is finished, to avoid using stale data in future.
function digilines.vm_begin()
	vm_cache = {}
end

-- Ends a bulk-VoxelManipulator operation, freeing the cached data.
function digilines.vm_end()
	vm_cache = nil
end

-- The dimension of a mapblock in nodes.
local MAPBLOCKSIZE = 16

-- Converts a node position into a hash of a mapblock position.
local function vm_hash_blockpos(pos)
	return minetest.hash_node_position({
		x = math.floor(pos.x / MAPBLOCKSIZE),
		y = math.floor(pos.y / MAPBLOCKSIZE),
		z = math.floor(pos.z / MAPBLOCKSIZE)
	})
end

-- Gets the cache entry covering a position, populating it if necessary.
local function vm_get_or_create_entry(pos)
	local hash = vm_hash_blockpos(pos)
	local tbl = vm_cache[hash]
	if not tbl then
		local vm = minetest.get_voxel_manip(pos, pos)
		local min_pos, max_pos = vm:get_emerged_area()
		local va = VoxelArea:new{MinEdge = min_pos, MaxEdge = max_pos}
		tbl = {va = va, data = vm:get_data(), param1 = vm:get_light_data(), param2 = vm:get_param2_data()}
		vm_cache[hash] = tbl
	end
	return tbl
end

-- Gets the node at a position during a bulk-VoxelManipulator operation.
local function vm_get_node(pos)
	local tbl = vm_get_or_create_entry(pos)
	local index = tbl.va:indexp(pos)
	local node_value = tbl.data[index]
	local node_param1 = tbl.param1[index]
	local node_param2 = tbl.param2[index]
	return {name = minetest.get_name_from_content_id(node_value), param1 = node_param1, param2 = node_param2}
end

-- Gets the node at a given position, regardless of whether it is loaded or
-- not.
--
-- Outside a bulk-VoxelManipulator operation, if the mapblock is not loaded, it
-- is pulled into the server’s main map data cache and then accessed from
-- there.
--
-- Inside a bulk-VoxelManipulator operation, the operation’s VM cache is used.
function digilines.get_node_force(pos)
	if vm_cache then
		return vm_get_node(pos)
	end
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		-- Node is not currently loaded; use a VoxelManipulator to prime
		-- the mapblock cache and try again.
		minetest.get_voxel_manip(pos, pos)
		node = minetest.get_node(pos)
	end
	return node
end
