--Digiboard by bas080
minetest.register_node("digiboard:keyboard", {
  description = "Digilines Keyboard",
  tiles = {"keyboard_top.png", "keyboard_bottom.png", "keyboard_side.png", "keyboard_side.png", "keyboard_side.png", "keyboard_side.png"},
  walkable = true,
  paramtype = "light",
  paramtype2 = "facedir",
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-4/8, -4/8, 0, 4/8, -3/8, 4/8},
    },
  },
  selection_box = {
    type = "fixed",
    fixed = {
      {-4/8, -4/8, 0, 4/8, -3/8, 4/8},
    },
  },
  digiline = { receptor = {},
    effector = {
      action = function(pos, node, channel, msg)
      end
    },
  },
  groups =  {choppy = 3, dig_immediate = 2},
  on_construct = function(pos)
    local meta = minetest.env:get_meta(pos)
    meta:set_string("formspec", "field[text;;]")
    meta:set_string("infotext", "Keyboard")
    meta:set_int("lines", 0)
  end,
  on_receive_fields = function(pos, formname, fields, sender)
    local meta = minetest.env:get_meta(pos)
    local text = fields.text
    local channel = "keyboard"
    if text ~= nil then
      digiline:receptor_send(pos, digiline.rules.default, channel, text)
    end
  end,
})
