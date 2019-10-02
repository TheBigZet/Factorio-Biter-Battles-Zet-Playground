--[[
Character Experience Gain RPG module by MewMew

STRENGTH > character_inventory_slots_bonus , character_mining_speed_modifier 

MAGIC >	character_build_distance_bonus, character_item_drop_distance_bonus, character_reach_distance_bonus,
				character_item_pickup_distance_bonus, character_loot_pickup_distance_bonus, 

DEXTERITY > character_running_speed_modifier, character_crafting_speed_modifier

VITALITY > character_health_bonus + damage resistance
]]

local visuals_delay = 60

local experience_levels = {0}
for a = 1, 9999, 1 do
	experience_levels[#experience_levels + 1] = experience_levels[#experience_levels] + a * 8
end

local classes = {
	["engineer"] = "ENGINEER",
	["strength"] = "MINER",
	["magic"] = "WIZZARD",
	["dexterity"] = "ROGUE",
	["vitality"] = "TANK",
}

local function create_gui_char_button(player)
	if player.gui.top.rpg then return end
	local b = player.gui.top.add({type = "sprite-button", name = "rpg", caption = "CHAR"})
	b.style.font_color = {180,180,180}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 60
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function update_player_stats(player)
	local strength = global.rpg[player.index].strength - 10
	player.character_inventory_slots_bonus = strength * 0.2
	player.character_mining_speed_modifier = strength * 0.01
	
	local magic = global.rpg[player.index].magic - 10
	local v = magic * 0.2
	player.character_build_distance_bonus = v
	player.character_item_drop_distance_bonus = v
	player.character_reach_distance_bonus = v
	--player.character_resource_reach_distance_bonus = v
	player.character_item_pickup_distance_bonus = v
	player.character_loot_pickup_distance_bonus = v
	
	local dexterity = global.rpg[player.index].dexterity - 10
	player.character_running_speed_modifier = dexterity * 0.005
	player.character_crafting_speed_modifier = dexterity * 0.01
	
	player.character_health_bonus = (global.rpg[player.index].vitality - 10) * 8
end

local function get_class(player)
	local average = (global.rpg[player.index].strength + global.rpg[player.index].magic + global.rpg[player.index].dexterity + global.rpg[player.index].vitality) / 4
	local high_attribute = 0
	local high_attribute_name = ""
	for _, attribute in pairs({"strength", "magic", "dexterity", "vitality"}) do
		if global.rpg[player.index][attribute] > high_attribute then
			high_attribute = global.rpg[player.index][attribute]
			high_attribute_name = attribute
		end
	end
	if high_attribute < average + average * 0.25 then high_attribute_name = "engineer" end
	return classes[high_attribute_name]
end

local function add_gui_description(element, value, width)
	local e = element.add({type = "label", caption = value})
	e.style.single_line = false
	e.style.maximal_width = width
	e.style.minimal_width = width
	e.style.font = "default-bold"
	e.style.font_color = {175, 175, 200}
	e.style.horizontal_align = "right"
	e.style.vertical_align = "center"
	return e
end

local function add_gui_stat(element, value, width)
	local e = element.add({type = "sprite-button", caption = value})
	e.style.maximal_width = width
	e.style.minimal_width = width
	e.style.maximal_height = 40
	e.style.minimal_height = 40
	e.style.font = "default-bold"
	e.style.font_color = {222, 222, 222}
	e.style.horizontal_align = "center"
	e.style.vertical_align = "center"
	return e
end

local function add_gui_increase_stat(element, name, player, width)
	local sprite = "virtual-signal/signal-red"
	local symbol = "✚"
	if global.rpg[player.index].points_to_distribute <= 0 then
		--symbol = " "
		sprite = "virtual-signal/signal-black" 
	end
	
	local e = element.add({type = "sprite-button", name = name, caption = symbol, sprite = sprite})
	e.style.maximal_height = 40
	e.style.minimal_height = 40
	e.style.maximal_width = width
	e.style.minimal_width = width
	e.style.font = "default-large-semibold"
	e.style.font_color = {0,0,0}
	e.style.horizontal_align = "center"	
	e.style.vertical_align = "center"	
	e.style.padding = 0
	e.style.margin = 0
	return e
end

local function add_separator(element, width)
	local e = element.add({type = "line"})
	e.style.maximal_width = width
	e.style.minimal_width = width
	e.style.minimal_height = 12
	return e
end

local function draw_gui(player)
	if player.gui.left.rpg then player.gui.left.rpg.destroy() end

	local frame = player.gui.left.add({type = "frame", name = "rpg", direction = "vertical"})
	frame.style.maximal_width = 425
	frame.style.minimal_width = 425
	
	local t = frame.add({type = "table", column_count = 2})
	local e = add_gui_stat(t, player.name, 200)
	e.style.font_color = player.chat_color
	e.style.font = "default-large-bold"
	local e = add_gui_stat(t, get_class(player), 200)
	e.style.font = "default-large-bold"
	
	add_separator(frame, 400)
	
	local t = frame.add({type = "table", column_count = 4})
	t.style.cell_padding = 1
	
	add_gui_description(t, "LEVEL", 80)
	add_gui_stat(t, global.rpg[player.index].level, 80)

	add_gui_description(t, "EXPERIENCE", 100)
	add_gui_stat(t, math.floor(global.rpg[player.index].xp), 125)
	
	add_gui_description(t, " ", 75)
	add_gui_description(t, " ", 75)
	
	add_gui_description(t, "NEXT LEVEL", 100)
	add_gui_stat(t, experience_levels[global.rpg[player.index].level + 1], 125)

	add_separator(frame, 400)
	
	local t = frame.add({type = "table", column_count = 2})
	local tt = t.add({type = "table", column_count = 3})
	tt.style.cell_padding = 1
	local w1 = 115
	local w2 = 40
	
	local e = add_gui_description(tt, "STRENGTH", w1)
	e.tooltip = "Increases inventory slots and mining speed."
	add_gui_stat(tt, global.rpg[player.index].strength, w2)
	add_gui_increase_stat(tt, "strength", player, w2)
	
	local e = add_gui_description(tt, "MAGIC", w1)
	e.tooltip = "Increases reach distance."
	add_gui_stat(tt, global.rpg[player.index].magic, w2)
	add_gui_increase_stat(tt, "magic", player, w2)
	
	local e = add_gui_description(tt, "DEXTERITY", w1)
	e.tooltip = "Increases running and crafting speed."
	add_gui_stat(tt, global.rpg[player.index].dexterity, w2)
	add_gui_increase_stat(tt, "dexterity", player, w2)
	
	local e = add_gui_description(tt, "VITALITY", w1)
	e.tooltip = "Increases health and damage resistance."
	add_gui_stat(tt, global.rpg[player.index].vitality, w2)
	add_gui_increase_stat(tt, "vitality", player, w2)
	
	add_gui_description(tt, "POINTS TO\nDISTRIBUTE", w1)
	local e = add_gui_stat(tt, global.rpg[player.index].points_to_distribute, w2)
	e.style.font_color = {200, 0, 0}	
	add_gui_description(tt, " ", w2)
	
	add_gui_description(tt, " ", w1)
	add_gui_description(tt, " ", w2)
	add_gui_description(tt, " ", w2)
	
	add_gui_description(tt, "LIFE", w1)
	add_gui_stat(tt, player.character.health, w2)
	add_gui_stat(tt, player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus, w2)

	local shield = 0
	local shield_max = 0	
	local i = player.character.get_inventory(defines.inventory.character_armor)
	if not i.is_empty() then
		if i[1].grid then
			shield = math.floor(i[1].grid.shield) 
			shield_max = math.floor(i[1].grid.max_shield)
		end
	end
	add_gui_description(tt, "SHIELD", w1)
	add_gui_stat(tt, shield, w2)
	add_gui_stat(tt, shield_max, w2)
	
	
	local tt = t.add({type = "table", column_count = 3})
	tt.style.cell_padding = 1
	local w0 = 18
	local w1 = 80
	local w2 = 80
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "MINING\nSPEED", w1)
	local value = (player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100 .. "%"
	add_gui_stat(tt, value, w2)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "SLOT\nBONUS", w1)
	local value = "+ " .. player.force.character_inventory_slots_bonus + player.character_inventory_slots_bonus
	add_gui_stat(tt, value, w2)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, " ", w0)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "REACH\nDISTANCE", w1)
	local value = "+ " .. (player.force.character_reach_distance_bonus + player.character_reach_distance_bonus)
	add_gui_stat(tt, value, w2)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, " ", w0)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "CRAFTING\nSPEED", w1)
	local value = (player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier + 1) * 100 .. "%"
	add_gui_stat(tt, value, w2)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "RUNNING\nSPEED", w1)
	local value = (player.force.character_running_speed_modifier  + player.character_running_speed_modifier + 1) * 100 .. "%"
	add_gui_stat(tt, value, w2)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, " ", w0)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "HEALTH\nBONUS", w1)
	local value = "+ " .. (player.force.character_health_bonus + player.character_health_bonus)
	add_gui_stat(tt, value, w2)
	
	add_gui_description(tt, " ", w0)
	add_gui_description(tt, "DAMAGE\nRESISTANCE", w1)
	local value = 0 .. "%"
	add_gui_stat(tt, value, w2)
end

local function draw_level_text(player)
	if global.rpg[player.index].text then
		rendering.destroy(global.rpg[player.index].text)
		global.rpg[player.index].text = nil
	end
	
	global.rpg[player.index].text = rendering.draw_text{
		text = "lvl " .. global.rpg[player.index].level,
		surface = player.surface,
		target = player.character,
		target_offset = {-0.05, -3},
		color = {
			r = player.color.r * 0.6 + 0.25,
			g = player.color.g * 0.6 + 0.25,
			b = player.color.b * 0.6 + 0.25,
			a = 1
		},
		--time_to_live = 600,
		scale = 1.0 + global.rpg[player.index].level * 0.01,
		font = "scenario-message-dialog",
		alignment = "center",
		scale_with_zoom = false
	}
end

local function level_up(player)
	global.rpg[player.index].level = global.rpg[player.index].level + 1
	global.rpg[player.index].points_to_distribute = global.rpg[player.index].points_to_distribute + 5
	draw_level_text(player)
	draw_gui(player)
end

local function gain_xp(player, amount)
	global.rpg[player.index].xp = global.rpg[player.index].xp + amount
	global.rpg[player.index].xp_since_last_floaty_text = global.rpg[player.index].xp_since_last_floaty_text + amount
	if not experience_levels[global.rpg[player.index].level + 1] then return end
	if global.rpg[player.index].xp >= experience_levels[global.rpg[player.index].level + 1] then
		level_up(player)
		return
	end
	if global.rpg[player.index].last_floaty_text > game.tick then return end
	player.create_local_flying_text{text="+" .. global.rpg[player.index].xp_since_last_floaty_text .. " xp", position=player.position, color={r = 177, g = 177, b = 177}, time_to_live=120, speed=1}
	if player.gui.left.rpg then draw_gui(player) end
	global.rpg[player.index].xp_since_last_floaty_text = 0
	global.rpg[player.index].last_floaty_text = game.tick + visuals_delay
end

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	local element = event.element
	
	if element.type ~= "sprite-button" then return end
	
	if element.caption == "CHAR" then
		if element.name == "rpg" then
			local player = game.players[event.player_index]
			if player.gui.left.rpg then
				player.gui.left.rpg.destroy()
				return
			end
			draw_gui(player)
		end
	end
	
	if element.caption ~= "✚" then return end
	if element.sprite ~= "virtual-signal/signal-red" then return end
	
	local index = element.name
	local player = game.players[event.player_index]
	if not global.rpg[player.index][index] then return end
	global.rpg[player.index].points_to_distribute = global.rpg[player.index].points_to_distribute - 1
	global.rpg[player.index][index] = global.rpg[player.index][index] + 1
	update_player_stats(player)
	draw_gui(player)
end

local xp_yield = {
	["small-biter"] = 1,
	["medium-biter"] = 2,
	["big-biter"] = 3,
	["behemoth-biter"] = 5,
	["small-spitter"] = 1,
	["medium-spitter"] = 2,
	["big-spitter"] = 3,
	["behemoth-spitter"] = 5,
	["spitter-spawner"] = 32,
	["biter-spawner"] = 32,	
	["small-worm-turret"] = 8,
	["medium-worm-turret"] = 16,
	["big-worm-turret"] = 24
}

local function on_entity_died(event)
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.name ~= "character" then return end
	if not event.cause.player then return end
	if not event.entity.valid then return end
	if event.cause.force.name == event.entity.force.name then return end
	local xp = 0.5
	if xp_yield[event.entity.name] then xp = xp_yield[event.entity.name] end
	gain_xp(event.cause.player, xp)	
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	gain_xp(player, 0.01)	
end

local function on_player_mined_entity(event)
	if not event.entity.valid then return end	
	local player = game.players[event.player_index]
	if event.entity.force.name == "neutral" then gain_xp(player, 1.5 + event.entity.prototype.max_health * 0.005) return end
	gain_xp(player, 0.1 + event.entity.prototype.max_health * 0.0005)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.rpg[player.index] then
		global.rpg[player.index] = {level = 0, xp = 0, strength = 10, magic = 10, dexterity = 10, vitality = 10, points_to_distribute = -5, last_floaty_text = visuals_delay, xp_since_last_floaty_text = 0}
	end
	create_gui_char_button(player)
	level_up(player)
	update_player_stats(player)
	draw_gui(player)
end

local function on_init(event)
	global.rpg = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_player_joined_game, on_player_joined_game)