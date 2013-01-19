function digiline:addPosRule(p, r)
	return {x = p.x + r.x, y = p.y + r.y, z = p.z + r.z}
end

function digiline:cmpPos(p1, p2)
	return (p1.x == p2.x and p1.y == p2.y and p1.z == p2.z)
end

--Rules rotation Functions:
function digiline:rotate_rules_right(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].z=rule.x
		nr[i].x=-rule.z
		nr[i].y=rule.y
	end
	return nr
end

function digiline:rotate_rules_left(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].z=-rules[i].x
		nr[i].x=rules[i].z
		nr[i].y=rules[i].y
	end
	return nr
end

function digiline:rotate_rules_down(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].y=rule.x
		nr[i].x=-rule.y
		nr[i].z=rule.z
	end
	return nr
end

function digiline:rotate_rules_up(rules)
	local nr={}
	for i, rule in ipairs(rules) do
		nr[i]={}
		nr[i].y=-rule.x
		nr[i].x=rule.y
		nr[i].z=rule.z
	end
	return nr
end
