local defaultChest = minetest.registered_nodes['default:chest']

if table.copy == nil then
    -- http://lua-users.org/wiki/CopyTable
    table.copy = function(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in pairs(orig) do
                copy[orig_key] = orig_value
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end
end

local sendMessage = function (pos, msg, channel)
    if channel == nil then
        channel = minetest.get_meta(pos):get_string("channel")
    end
    digiline:receptor_send(pos,digiline.rules.default,channel,msg)
end

tableMerge =  function(first_table,second_table)
    for k,v in pairs(second_table) do first_table[k] = v end
end

local mychest = table.copy(defaultChest)

function defer(what,...)
    if what then
        return what(...)
    end
end

tableMerge(mychest,{
    description = "Digiline Chest",
    digiline = {
        receptor = {
            rules=digiline.rules.default
        },
        effector = {}
    },
    on_construct = function(pos)
        defaultChest.on_construct(pos)
        local meta = minetest.get_meta(pos)
        -- we'll  sneak into row 4 thanks
        meta:set_string("formspec",meta:get_string("formspec").."\nfield[2,4.5;5,1;channel;Channel;${channel}]")
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        minetest.get_meta(pos):set_string("channel",fields.channel)
        return defer(defaultChest.on_receive_fields, pos, formname, fields, sender)        
    end,
    tube = {
        -- note: mese filters cannot put part of a stack in the destination. 
        -- space for 50 coal with 99 added will pop out 99, not 49.
        insert_object = function(pos, node, stack, direction)
            local leftover = defaultChest.tube.insert_object(pos,node,stack,direction)
            local count = leftover:get_count()
            if count == 0 then
                local derpstack = stack:get_name()..' 1'
                if not defaultChest.tube.can_insert(pos, node, derpstack, direction) then
                    -- when you can't put a single more of whatever you just put,
                    -- you'll get a put for it, then a full                    
                    sendMessage(pos,"full "..stack:to_string()..' '..tostring(count))
                end
            else
                -- this happens when the chest has received two stacks in a row and
                -- filled up exactly with the first one.
                -- You get a put for the first stack, a put for the second
                -- and then a overflow with the first in stack and the second in leftover
                -- and NO full?
                sendMessage(pos,"overflow "..stack:to_string()..' '..tostring(count))
            end
            return leftover
        end,
        can_insert = function(pos, node, stack, direction)
            local can = defaultChest.tube.can_insert(pos, node, stack, direction)
            if can then
                sendMessage(pos,"put "..stack:to_string())
            else
                -- overflow and lost means that items are gonna be out as entities :/
                sendMessage(pos,"lost "..stack:to_string())
            end
            return can
        end,
        input_inventory=defaultChest.input_inventory
    },
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if not mychest.can_insert(pos,nil,stack,nil) then
            sendMessage(pos,"uoverflow "..stack:to_string())
        end
        local ret = defer(defaultChest.allow_metadata_inventory_put, pos, listname, index, stack, player) 
        if ret then return ret end
        return stack:get_count()
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        local channel = minetest.get_meta(pos):get_string("channel")
        local send = function(msg) 
            sendMessage(pos,msg,channel)
        end
        -- direction is only for furnaces
        -- as the item has already been put, can_insert should return false if the chest is now full.
        local derpstack = stack:get_name()..' 1'
        if mychest.can_insert(pos,nil,derpstack,nil) then
            send("uput "..stack:to_string())
        else
            send("ufull "..stack:to_string())
        end
        return defer(defaultChest.on_metadata_inventory_put, pos, listname, index, stack, player)
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
        sendMessage(pos,"utake "..stack:to_string())
        return defaultChest.on_metadata_inventory_take(pos, listname, index, stack, player)
    end
})

if mychest.can_insert == nil then
    -- we can use the can_insert function from pipeworks, but will duplicate if not found.
    mychest.can_insert = function(pos,node,stack,direction)
        local meta=minetest.get_meta(pos)
        local inv=meta:get_inventory()
        return inv:room_for_item("main",stack)
    end
end

-- minetest.register_node(":default:chest", mychest)
minetest.register_node("digilines_inventory:chest", mychest)
