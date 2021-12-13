local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Tables = require 'maps.biter_battles_v2.tables'
local Utils = require 'utils.utils'

local Public = {}
global.active_special_games = {}
global.special_games_variables = {}
local valid_special_games = {
	--[[ 
	Add your special game here.
	Syntax:
	<game_name> = {
		name = {type = "label", caption = "<Name displayed in gui>", tooltip = "<Short description of the mode"
		config = {
			list of all knobs, leavers and dials used to config your game
			[1] = {name = "<name of this element>" called in on_gui_click to set variables, type = "<type of this element>", any other parameters needed to define this element},
			[2] = {name = "example_1", type = "textfield", text = "200", numeric = true, width = 40},
			[3] = {name = "example_2", type = "checkbox", caption = "Some checkbox", state = false}
			NOTE all names should be unique in the scope of the game mode
		},
		button = {name = "<name of this button>" called in on_gui_clicked , type = "button", caption = "Apply"}
	}
	]]
	turtle = {
		name = {type = "label", caption = "Turtle", tooltip = "Generate moat with given dimensions around the spawn"},
		config = {
			[1] = {name = "label1", type = "label", caption = "moat width"},
			[2] = {name = 'moat_width', type = "textfield", text = "5", numeric = true, width = 40},
			[3] = {name = "label2", type = "label", caption = "entrance width"},
			[4] = {name = 'entrance_width', type = "textfield", text = "20", numeric = true, width = 40},
			[5] = {name = "label3", type = "label", caption = "size x"},
			[6] = {name = 'size_x', type = "textfield", text = "200", numeric = true, width = 40},
			[7] = {name = "label4", type = "label", caption = "size y"},
			[8] = {name = 'size_y', type = "textfield", text = "200", numeric = true, width = 40},
			[9] = {name = "chart_turtle", type = "button", caption = "Chart", width = 60}
		},
		button = {name = "turtle_apply", type = "button", caption = "Apply"}
	},

	infinity_chest = {
		name = {type = "label", caption = "Infinity chest", tooltip = "Spawn infinity chests with given filters"},
		config = {
			[1] = {name = "separate_chests", type = "switch", switch_state = "left", tooltip = "Single chest / Multiple chests"},
			[2] = {name = "operable", type = "switch", switch_state = "left", tooltip = "Operable? Y / N"},
			[3] = {name = "label1", type = "label", caption = "Gap size"},
			[4] = {name = "gap", type = "textfield", text = "3", numeric = true, width = 40},
			[5] = {name = "eq1", type = "choose-elem-button", elem_type = "item"},
			[6] = {name = "eq2", type = "choose-elem-button", elem_type = "item"},
			[7] = {name = "eq3", type = "choose-elem-button", elem_type = "item"},
			[8] = {name = "eq4", type = "choose-elem-button", elem_type = "item"},
			[9] = {name = "eq5", type = "choose-elem-button", elem_type = "item"},
			[10] = {name = "eq6", type = "choose-elem-button", elem_type = "item"},
			[11] = {name = "eq7", type = "choose-elem-button", elem_type = "item"}
		},
		button = {name = "infinity_chest_apply", type = "button", caption = "Apply"}
	},
	
	vietnam = {
		name = {type = "label", caption = "Vietnam War", tooltip = "Minefield, artilery, biters hiding in trees and many more!"},
		config = {
			[1] = {name = "mines_count", type = "textfield", text = "300", numeric = true, width = 40, tooltip = "Number of mines to be generated at start. Be careful with high values lol"},
			[2] = {name = "size_x", type = "textfield", text = "400", numeric = true, width = 40, tooltip = "X dimension of the minefield, for silo and for players"},
			[3] = {name = "size_y", type = "textfield", text = "400", numeric = true, width = 40, tooltip = "Y dimension of the minefield, for silo and for players"},
			[4] = {name = "forest_density", type = "textfield", text = "50", numeric = true, width = 30, tooltip = "Forest density: 0-100"},
			[5] = {name = "item1", type = "choose-elem-button", elem_type = "item", tooltip = "Type of item"},
			[6] = {name = "item_count1", type = "textfield", text = "10", numeric = true, width = 30, tooltip = "Number of items per 1 mine"},
			[7] = {name = "item2", type = "choose-elem-button", elem_type = "item", tooltip = "Type of item"},
			[8] = {name = "item_count2", type = "textfield", text = "10", numeric = true, width = 30, tooltip = "Number of items per 1 mine"},
			[9] = {name = "item3", type = "choose-elem-button", elem_type = "item", tooltip = "Type of item"},
			[10] = {name = "item_count3", type = "textfield", text = "10", numeric = true, width = 30, tooltip = "Number of items per 1 mine"},
			[11] = {name = "item4", type = "choose-elem-button", elem_type = "item", tooltip = "Type of item"},
			[12] = {name = "item_count4", type = "textfield", text = "10", numeric = true, width = 30, tooltip = "Number of items per 1 mine"}			
		},
		button = {name = "vietnam_apply", type = "button", caption = "Apply"}
	}

}

function Public.reset_active_special_games() for _, i in ipairs(global.active_special_games) do i = false end end
function Public.reset_special_games_variables() global.special_games_variables = {} end

local function generate_turtle(moat_width, entrance_width, size_x, size_y)
	game.print("Special game turtle is being generated!", Color.warning)
	local surface = game.surfaces[global.bb_surface_name]
	local water_positions = {}
	local concrete_positions = {}
	local landfill_positions = {}

	for i = 0, size_y + moat_width do -- veritcal canals
		for a = 1, moat_width do
			table.insert(water_positions, {name = "deepwater", position = {x = (size_x / 2) + a, y = i}})
			table.insert(water_positions, {name = "deepwater", position = {x = (size_x / 2) - size_x - a, y = i}})
			table.insert(water_positions, {name = "deepwater", position = {x = (size_x / 2) + a, y = -i - 1}})
			table.insert(water_positions, {name = "deepwater", position = {x = (size_x / 2) - size_x - a, y = -i - 1}})
		end
	end
	for i = 0, size_x do -- horizontal canals
		for a = 1, moat_width do
			table.insert(water_positions, {name = "deepwater", position = {x = i - (size_x / 2), y = size_y + a}})
			table.insert(water_positions, {name = "deepwater", position = {x = i - (size_x / 2), y = -size_y - 1 - a}})
		end
	end

	for i = 0, entrance_width - 1 do
		for a = 1, moat_width + 6 do
			table.insert(concrete_positions,
			             {name = "refined-concrete", position = {x = -entrance_width / 2 + i, y = size_y - 3 + a}})
			table.insert(concrete_positions,
			             {name = "refined-concrete", position = {x = -entrance_width / 2 + i, y = -size_y + 2 - a}})
			table.insert(landfill_positions, {name = "landfill", position = {x = -entrance_width / 2 + i, y = size_y - 3 + a}})
			table.insert(landfill_positions, {name = "landfill", position = {x = -entrance_width / 2 + i, y = -size_y + 2 - a}})
		end
	end

	surface.set_tiles(water_positions)
	surface.set_tiles(landfill_positions)
	surface.set_tiles(concrete_positions)
	global.active_special_games["turtle"] = true
end

local function generate_infinity_chest(separate_chests, operable, gap, eq)
	local surface = game.surfaces[global.bb_surface_name]
	local position_0 = {x = 0, y = -42}

	local objects = surface.find_entities_filtered {name = 'infinity-chest'}
	for _, object in pairs(objects) do object.destroy() end

	game.print("Special game Infinity chest is being generated!", Color.warning)
	if operable == "left" then
		operable = true
	else
		operable = false
	end

	if separate_chests == "left" then
		local chest = surface.create_entity {
			name = "infinity-chest",
			position = position_0,
			force = "neutral",
			fast_replace = true
		}
		chest.minable = false
		chest.operable = operable
		chest.destructible = false
		for i, v in ipairs(eq) do
			chest.set_infinity_container_filter(i, {name = v, index = i, count = game.item_prototypes[v].stack_size})
		end
		chest.clone {position = {position_0.x, -position_0.y}}

	elseif separate_chests == "right" then
		local k = gap + 1
		for i, v in ipairs(eq) do
			local chest = surface.create_entity {
				name = "infinity-chest",
				position = position_0,
				force = "neutral",
				fast_replace = true
			}
			chest.minable = false
			chest.operable = operable
			chest.destructible = false
			chest.set_infinity_container_filter(i, {name = v, index = i, count = game.item_prototypes[v].stack_size})
			chest.clone {position = {position_0.x, -position_0.y}}
			position_0.x = position_0.x + (i * k)
			k = k * -1
		end
	end
	global.active_special_games["infinity_chest"] = true
end

local function spawn_mines(center_entity, field_size, count)	--field_size must have structure {x = _, y = _}
	local surface = center_entity.surface
	local pos_x, pos_y, max_y, min_y

	if center_entity.force.name == "north" then
		--game.print("generating for north")
		if center_entity.position.y + (field_size.y / 2) > -40 then
			max_y = -40
			min_y = center_entity.position.y - (field_size.y / 2)
		else
			max_y = center_entity.position.y + (field_size.y / 2)
			min_y = center_entity.position.y - (field_size.y / 2)
		end
		--game.print(min_y .. "   " .. max_y)
	else
		--game.print("generating for south")
		if center_entity.position.y - (field_size.y / 2) < 40 then
			max_y = center_entity.position.y + (field_size.y / 2)
			min_y = 40
		else
			max_y = center_entity.position.y + (field_size.y / 2)
			min_y = center_entity.position.y - (field_size.y / 2)
		end	
		--game.print(min_y .. "   " .. max_y)
	end
	
	for i = 1, count do
		pos_x = math.random(center_entity.position.x - (field_size.x / 2), center_entity.position.x + (field_size.x / 2))
		pos_y = math.random(min_y, max_y)
		surface.create_entity {
			name = "land-mine",
			position = {pos_x , pos_y},
			force = game.forces[center_entity.force.name .. "_biters"]
		}
	end
end

local function generate_vietnam(field_size, mines_count, forest_density, prices)
	local surface = game.surfaces[global.bb_surface_name]
	local silos = global.rocket_silo
	for _, v in pairs(global.rocket_silo) do
		local offset = -1
		if v.force.name == "south" then offset = 1 end
		local enemy = Tables.enemy_team_of[v.force.name]

		local market = surface.create_entity {
			name = "market",
			position = {v.position.x + 2, v.position.y - offset * 6},
			force = v.force
		}
		local ammo_chest = surface.create_entity {
			name = "infinity-chest",
			position = {v.position.x, v.position.y - offset * 6},
			force = v.force
		}
		ammo_chest.set_infinity_container_filter(1, {name = "artillery-shell", index = 1, count = 1})
		ammo_chest.set_infinity_container_filter(2, {name = "coal", index = 1, count = 1})
		local inserter = surface.create_entity {
			name = "burner-inserter",
			direction = defines.direction.east,
			position = {v.position.x - 1, v.position.y - offset * 6},
			force = v.force
		}
		local arty = surface.create_entity {
			name = "artillery-turret",
			position = {v.position.x - 3, v.position.y - offset * 6},
			force = v.force
		}
		for a, p in pairs(prices) do
			if p[1] == nil then break end
			market.add_market_item {
				price = {p},
				offer = {type = "nothing", effect_description = "Add mines to team " .. Tables.enemy_team_of[v.force.name]}
			}
		end
		for _, i in pairs({market, arty, ammo_chest, inserter}) do
			i.destructible = false
			i.operable = false
			i.minable = false
			i.rotatable = false
		end
		market.operable = true
		spawn_mines(v, field_size, mines_count)
	end
	global.special_games_variables["field_size"] = field_size
	global.special_games_variables["forest_density"] = math.clamp(forest_density, 0, 100)
	global.active_special_games["vietnam"] = true
	game.print("Special game Vietnam War is being generated!", Color.warning)
end


function Public.vietnam_trees(surface, left_top_x, left_top_y)
	--[[
	local trees = {
		"dead-dry-hairy-tree",
		"dead-grey-trunk",
		"dead-tree-desert",
		"dry-hairy-tree",
		"dry-tree",
		"tree-01",
		"tree-02",
		"tree-02-red",
		"tree-03",
		"tree-04",
		"tree-05",
		"tree-06",
		"tree-06-brown",
		"tree-07",
		"tree-08",
		"tree-08-brown",
		"tree-08-red",
		"tree-09",
		"tree-09-brown",
		"tree-09-red",
		}
	for i=1, global.special_games_variables["forest_density"]*0.01*32*32 do
		surface.create_entity{
			name = trees[math.random(1,20)],
			position = {math.random(left_top_x*32, left_top_x*32+32), math.random(left_top_y*32, left_top_y*32+32)}
		}
	
	end
	]]
end



local function on_market_item_purchased(event)
	if global.active_special_games["vietnam"] == true then
		local player = game.get_player(event.player_index)
		local enemy = Tables.enemy_team_of[player.force.name]
		local field_size = global.special_games_variables["field_size"]
		local count = event.count
		local surface = game.surfaces[global.bb_surface_name]
		game.print(player.name .. " purchased " .. event.count .. " mines!")
		
		local silo_mines = math.random(0, count)	-- randomizing number of mines to be generated around silo
		spawn_mines(global.rocket_silo[enemy], field_size, silo_mines)
		--game.print("Spawned mines around silo: " .. silo_mines)
		count = count - silo_mines	-- leftover mines
		if #game.forces[enemy].players ~= 0 then
			--game.print("Enemy team is not empty")
			
			local list = Utils.lotery(game.forces[enemy].players, count)	-- randomizing leftover mines across players
			for k, v in pairs(list) do
				spawn_mines(k, field_size, v)
				--game.print("Spawning " .. v .. " mines around player " .. k.name)
			end
		else
			spawn_mines(global.rocket_silo[enemy], field_size, count) 	--spawning leftover mines in case the team is empty
			--game.print("Spawned mines around silo again: " .. count)
		end
	end
end

local create_special_games_panel = (function(player, frame)
	frame.clear()
	frame.add{type = "label", caption = "Configure and apply special games here"}.style.single_line = false

	for k, v in pairs(valid_special_games) do
		local a = frame.add {type = "frame"}
		a.style.width = 750
		local table = a.add {name = k, type = "table", column_count = 3, draw_vertical_lines = true}
		table.add(v.name).style.width = 100
		local config = table.add {name = k .. "_config", type = "flow", direction = "horizontal"}
		config.style.width = 500
		for _, i in ipairs(v.config) do
			config.add(i)
			config[i.name].style.width = i.width
		end
		table.add {name = v.button.name, type = v.button.type, caption = v.button.caption}
		table[k .. "_config"].style.vertical_align = "center"
	end
end)

local function on_gui_click(event)
	local player = game.get_player(event.player_index)
	local element = event.element
	if not element.type == "button" then return end
	local config = element.parent.children[2]

	if string.find(element.name, "_apply") then
		local flow = element.parent.add {type = "flow", direction = "vertical"}
		flow.add {type = "button", name = string.gsub(element.name, "_apply", "_confirm"), caption = "Confirm"}
		flow.add {type = "button", name = "cancel", caption = "Cancel"}
		element.visible = false -- hides Apply button	
		player.print("[SPECIAL GAMES] Are you sure? This change will be reversed only on map restart!", Color.cyan)

	elseif string.find(element.name, "_confirm") then
		config = element.parent.parent.children[2]

	end
	-- Insert logic for apply button here

	if element.name == "turtle_confirm" then

		local moat_width = config["moat_width"].text
		local entrance_width = config["entrance_width"].text
		local size_x = config["size_x"].text
		local size_y = config["size_y"].text

		generate_turtle(moat_width, entrance_width, size_x, size_y)
	elseif element.name == "chart_turtle" then
		config = element.parent.parent.children[2]
		local moat_width = config["moat_width"].text
		local entrance_width = config["entrance_width"].text
		local size_x = config["size_x"].text
		local size_y = config["size_y"].text

		game.forces["spectator"].chart(game.surfaces[global.bb_surface_name], {
			{-size_x / 2 - moat_width, -size_y - moat_width}, {size_x / 2 + moat_width, size_y + moat_width}
		})

	elseif element.name == "infinity_chest_confirm" then

		local separate_chests = config["separate_chests"].switch_state
		local operable = config["operable"].switch_state
		local gap = config["gap"].text
		local eq = {
			config["eq1"].elem_value, 
			config["eq2"].elem_value, 
			config["eq3"].elem_value, 
			config["eq4"].elem_value,
			config["eq5"].elem_value,
			config["eq6"].elem_value,
			config["eq7"].elem_value
		}

		generate_infinity_chest(separate_chests, operable, gap, eq)

	elseif element.name == "vietnam_confirm" then
		local field_size = {x = tonumber(config["size_x"].text), y = tonumber(config["size_y"].text)}
		local mines_count = config["mines_count"].text
		local forest_density = tonumber(config["forest_density"].text)
		local prices = {
			[1] = {config["item1"].elem_value, tonumber(config["item_count1"].text)},
			[2] = {config["item2"].elem_value, tonumber(config["item_count2"].text)},
			[3] = {config["item3"].elem_value, tonumber(config["item_count3"].text)},
			[4] = {config["item4"].elem_value, tonumber(config["item_count4"].text)}
		}
		
		generate_vietnam(field_size, mines_count, forest_density, prices)

	end

	if string.find(element.name, "_confirm") or element.name == "cancel" then
		element.parent.parent.children[3].visible = true -- shows back Apply button
		element.parent.destroy() -- removes confirm/Cancel buttons
	end
end
comfy_panel_tabs['Special games'] = {gui = create_special_games_panel, admin = true}

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
return Public

