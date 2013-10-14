value, err = minetest.require('digilines_inventory','chest')
if err then
    error(err)
end

print("Digilines Inventory loaded")
