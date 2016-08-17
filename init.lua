-- lava tanks for Technic
--
-- this is basically lava cans ex
--
-- license: WTFPL

local tanks = {
	{	name = "lava_tank",
		description = "Lava Tank",
		capacity = 32,
		material = "moreores:tin_ingot",
		base = "technic:lava_can",
		texture = "lava_tanks1.png",
	},
	{	name = "lava_tank_harden",
		description = "Hardened Lava Tank",
		capacity = 128,
		material = "technic:carbon_steel_ingot",
		base = "lava_tanks:lava_tank",
		texture = "lava_tanks2.png",
	},
	{	name = "lava_tank_reinfo",
		description = "Reinforced Lava Tank",
		capacity = 512,
		material = "default:obsidian_glass",
		base = "lava_tanks:lava_tank_harden",
		texture = "lava_tanks3.png",
	},
	{	name = "lava_tank_arcane",
		description = "Arcane Lava Tank",
		capacity = 2048,
		material = "moreores:mithril_ingot",
		base = "lava_tanks:lava_tank_reinfo",
		texture = "lava_tanks4.png",
	},
}

-- some code "borrowed" from Technic

local function set_can_wear(itemstack, level, max_level)
	local temp
	if level == 0 then
		temp = 0
	else
		temp = 65536 - math.floor(level / max_level * 65535)
		if temp > 65535 then temp = 65535 end
		if temp < 1 then temp = 1 end
	end
	itemstack:set_wear(temp)
end

local function get_can_level(itemstack)
	if itemstack:get_metadata() == "" then
		return 0
	else
		return tonumber(itemstack:get_metadata())
	end
end

-- handle transfer of meta on crafted upgrades

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if minetest.get_item_group(itemstack:get_name(), "lava_tanks") > 0 then
		local i = 1
		local craft_size = player:get_inventory():get_size("craft")
		while i <= craft_size do
			local old = old_craft_grid[i]
			i = i + 1

			-- copy old cache meta to output stack
			if (old:get_name() == "technic:lava_can" or
				minetest.get_item_group(old:get_name(), "lava_tanks") > 0) then

				local def = minetest.registered_items[itemstack:get_name()]
				if def then
					local value = get_can_level(old)
					itemstack:set_metadata(tostring(value))
					set_can_wear(itemstack, value, def.capacity)
				end
				return
			end
		end
	end
end)

for _, x in pairs(tanks) do
	minetest.register_tool("lava_tanks:"..x.name, {
		description = x.description,
		inventory_image = x.texture,
		stack_max = 1,
		capacity = x.capacity,
		wear_represents = "content_level",
		liquids_pointable = true,
		groups = {lava_tanks = 1},
		on_use = function(itemstack, user, pointed_thing)
			if pointed_thing.type ~= "node" then return end
			local node = minetest.get_node(pointed_thing.under)
			if node.name ~= "default:lava_source" then return end
			local charge = get_can_level(itemstack)
			if charge == x.capacity then return end
			if minetest.is_protected(pointed_thing.under, user:get_player_name()) then
				minetest.chat_send_player(user:get_player_name(),
					"You are not permitted to access lava in this area.")
				return
			end
			minetest.remove_node(pointed_thing.under)
			charge = charge + 1
			itemstack:set_metadata(tostring(charge))
			set_can_wear(itemstack, charge, x.capacity)
			return itemstack
		end,
		on_place = function(itemstack, user, pointed_thing)
			if pointed_thing.type ~= "node" then return end
			local pos = pointed_thing.under
			local def = minetest.registered_nodes[minetest.get_node(pos).name] or {}
			if def.on_rightclick and user and not user:get_player_control().sneak then
				return def.on_rightclick(pos, minetest.get_node(pos), user, itemstack, pointed_thing)
			end
			if not def.buildable_to then
				pos = pointed_thing.above
				def = minetest.registered_nodes[minetest.get_node(pos).name] or {}
				if not def.buildable_to then return end
			end
			local charge = get_can_level(itemstack)
			if charge == 0 then return end
			if minetest.is_protected(pos, user:get_player_name()) then
				minetest.chat_send_player(user:get_player_name(),
					"You are not permitted to place lava in this area.")
				return
			end
			minetest.set_node(pos, {name="default:lava_source"})
			charge = charge - 1
			itemstack:set_metadata(tostring(charge))
			set_can_wear(itemstack, charge, x.capacity)
			return itemstack
		end,
	})

	minetest.register_craft({
		output = "lava_tanks:"..x.name,
		recipe = {
			{"", x.material, ""},
			{x.material, x.base, x.material},
			{"", x.material, ""},
		}
	})
end
