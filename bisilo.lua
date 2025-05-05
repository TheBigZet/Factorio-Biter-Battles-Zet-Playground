/sc
local pos = -2000
if not game.surfaces[storage.bb_surface_name].is_chunk_generated({x = -(3+math.abs(pos)/32),y = -6}) or not game.surfaces[storage.bb_surface_name].is_chunk_generated({x= 3+math.abs(pos)/32, y = 6})  then
	game.print("unable to start bisilo, chunks are not generated. wait until reveal is completed then run script again. ") 
	game.forces.spectator.chart(game.surfaces[storage.bb_surface_name], {{x = -(math.abs(pos) + 300)  ,y = -250}, {x = (math.abs(pos) + 300), y = 250}}) 
	return
end
if storage.multi_silo then
	game.player.print("biSilo is already running", {color = {r=0.9,g=0,b=0}})
	return
end

local Event = require "utils.event"
local Gui = require "maps.biter_battles_v2.gui"
local AiTargets = require('maps.biter_battles_v2.ai_targets')

storage.multi_silo = {
	north = {
		storage.rocket_silo["north"]
	},
	south = {
		storage.rocket_silo["south"]
	}
}

local surface = game.surfaces[storage.bb_surface_name]
local area1 = {
	left_top = { x = -150, y = -150 },
	right_bottom = { x = 150, y = 150 },
}
local area2 = {
    left_top = { x = area1.left_top.x + pos, y = area1.left_top.y },
    right_bottom = { x = area1.right_bottom.x + pos, y = area1.right_bottom.y },
}
local areaT = {
    left_top = { x = area1.left_top.x + pos, y = area1.left_top.y },
    right_bottom = { x = area1.right_bottom.x + pos, y = area1.right_bottom.y },
}

local function _clear_resources(surface, area2)
    local resources = surface.find_entities_filtered({area = area2, type = 'resource',})
    local i = 0
    for _, res in pairs(resources) do
        res.destroy()
        i = i + 1
    end
    return i
end

local limit = 20
local cnt = 0 
repeat 
    cnt = _clear_resources(surface, areaT)		
    limit = limit - 1 
	areaT.left_top.x = areaT.left_top.x  - 1 
	areaT.left_top.y  = areaT.left_top.y - 1 
	areaT.right_bottom.y  = areaT.right_bottom.y + 1 
	areaT.right_bottom.x = areaT.right_bottom.x + 1 	
until cnt == 0 or limit == 0

local entities_clear = surface.find_entities(area2)
for _, entity in pairs(entities_clear) do
    entity.destroy()
end

local lakes = {}
for x = area2.left_top.x, area2.right_bottom.x do
    for y = area2.left_top.y, area2.right_bottom.y do
        local tile = surface.get_tile(x, y)
        if tile.name =="water" or tile.name =="deepwater" then 
            table.insert(lakes, {name = "dirt-1", position = {x, y}})
        end
    end
end
surface.set_tiles(lakes)
local concrete = {}
for x = area1.left_top.x, area1.right_bottom.x do
    for y = area1.left_top.y, area1.right_bottom.y do
        local tile = surface.get_tile(x, y)
        if tile.name =="refined-concrete"  then 
            table.insert(concrete, {name = "refined-concrete", position = {x+pos, y}})
        end
        if tile.name =="water" or tile.name =="deepwater"  then 
            table.insert(concrete, {name = "deepwater", position = {x+pos, y}})
        end
    end
end
surface.set_tiles(concrete)

local entities = surface.find_entities({area1.left_top, area1.right_bottom})
for _, entity in pairs(entities) do 
    if entity.name == "copper-ore" or  entity.name == "iron-ore" or  entity.name == "stone" or  entity.name == "coal" then    
        surface.create_entity{        
            name = entity.name,
            position = {x = entity.position.x + pos, y = entity.position.y},
            surface = surface,
            force = entity.force,
            create_build_effect_smoke = false,
            amount = entity.amount,
        }
    elseif entity.name == "gun-turret" then
        local turet = surface.create_entity{        
            name = entity.name,
            position = {x = entity.position.x + pos, y = entity.position.y},
            surface = surface,
            force = entity.force,
            create_build_effect_smoke = false,
        }
		AiTargets.start_tracking(turet)
        turet.insert({name="firearm-magazine", count=10})
    elseif entity.name == "rocket-silo" then
        local silo = surface.create_entity{        
            name = entity.name,
            position = {x = entity.position.x + pos, y = entity.position.y},
            surface = surface,
            force = entity.force,
            create_build_effect_smoke = false,
        }
        silo.minable_flag = false
        table.insert(storage.multi_silo[entity.force.name], silo)
		AiTargets.start_tracking(silo)
		if storage.rocket_silo[entity.force.name] and #storage.multi_silo[entity.force.name] > 1 then
			storage.rocket_silo[entity.force.name] = nil
		end
	elseif entity.name == "character" then
    else
        surface.create_entity{        
            name = entity.name,
            position = {x = entity.position.x + pos, y = entity.position.y},
            surface = surface,
            force = entity.force,
            create_build_effect_smoke = false,
    }
    end
end

local spawn_trusted_at_vet_silo = 'function(event)
	local player = game.players[event.player_index]
	if not player.valid then return end
	local force = player.force.name
	if force ~= "north" and force ~= "south" then return end
	local SessionData = require("utils.datastore.session_data")    
	local trusted = SessionData.get_trusted_table()
	if not storage.multi_silo then return end
	if not storage.multi_silo[player.force.name] then return end
	local silo = 1	
	if storage.multi_silo[player.force.name][2] then
		if trusted[player.name] then
			silo = 2
		end
	end
	if not storage.multi_silo[player.force.name][silo] then return end
	if not storage.multi_silo[player.force.name][silo].valid then return end
	local position = storage.multi_silo[player.force.name][silo].position
	position.y = position.y*0.8
	local vet_spawn = player.physical_surface.find_non_colliding_position("character", position, 20, 0.5) 
	player.teleport(vet_spawn)
end'
Event.add_removable_function(Gui.events.on_player_joined_team, spawn_trusted_at_vet_silo , "spawn_trusted_at_vet_silo")

local multi_silo_on_gui_click = 'function(event) local on_gui_click = nil
	if not event.element.valid or event.element.name ~= "bb_spectate" then return end
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.position.x ^ 2 + player.character.position.y ^ 2 < 12000 then return end

	local silos = player.physical_surface.find_entities_filtered{name="rocket-silo", position=player.character.position, radius=20, limit=1}
	if #silos == 0 then return end
	spectate(player, false, player.character.position)
end'
Event.add_removable_function(defines.events.on_gui_click, multi_silo_on_gui_click, "multi_silo_on_gui_click")


local multi_silo_on_unit_group_finished_gathering = 'function(event) local on_unit_group_finished_gathering = nil
	if storage.bb_game_won_by_team then return end
	if not storage.multi_silo then return end

	local biter_force = event.group.force.name
	local force
	if biter_force == "north_biters" or biter_force == "north_biters_boss" then
		force = "north"
	elseif biter_force == "south_biters" or biter_force == "south_biters_boss" then
		force = "south"
	else
		return
	end

	local silos = storage.multi_silo[force]
	if not silos or #silos == 0 then return end

	local function closest_silo(pos)
		local closest_silo = silos[1]
		local dist = (pos.x - closest_silo.position.x) ^ 2 + (pos.y - closest_silo.position.y) ^ 2
		for i = 2, #silos do
			local other_silo = silos[i]
			local other_dist = (pos.x - other_silo.position.x) ^ 2 + (pos.y - other_silo.position.y) ^ 2
			if other_dist < dist then
				closest_silo = other_silo
				dist = other_dist
			end
		end
		return closest_silo
	end

	local command = event.group.command
	if not command or (command.type == defines.command.attack and not command.target.valid)  then
		local command = {
			type = defines.command.attack,
			target = closest_silo(event.group.position),
			distraction = defines.distraction.by_damage,
		}
		event.group.set_command(command)
	elseif command.type == defines.command.compound then
		local target_pos = nil
		for _, cmd in ipairs(command.commands) do
			if cmd.type == defines.command.attack_area then
				target_pos = cmd.destination
				break
			end
		end
		if target_pos then
			local attack_cmd = nil
			for _, cmd in ipairs(command.commands) do
				if cmd.type == defines.command.attack then
					attack_cmd = cmd
					break
				end
			end
			local nearby_silo = closest_silo(target_pos)
			if not attack_cmd then
				command.commands[#command.commands + 1] = {
					type = defines.command.attack,
					target = nearby_silo,
					distraction = defines.distraction.by_damage,
				}
				event.group.set_command(command)
			elseif attack_cmd.target ~= nearby_silo then
				attack_cmd.target = nearby_silo
				event.group.set_command(command)
			end
		end
	end
end'
Event.add_removable_function(defines.events.on_unit_group_finished_gathering, multi_silo_on_unit_group_finished_gathering, "multi_silo_on_unit_group_finished_gathering")

local multi_silo_on_entity_died = 'function(event) local on_entity_died = nil
	if not storage.multi_silo then return end
    if not event.entity.valid or  event.entity.name ~= "rocket-silo" then return end

	local entity = event.entity
	local force = entity.force.name
	

	if not storage.multi_silo[force] then return end
	if storage.rocket_silo[force] and entity == storage.rocket_silo[force] then
		storage.multi_silo[force] = {}
		return
	end
	if storage.rocket_silo[force] and entity.position.x == storage.rocket_silo[force].position.x and entity.position.y == storage.rocket_silo[force].position.y and #storage.multi_silo[force] == 1 then
		storage.multi_silo[force][1] = storage.rocket_silo[force]
		return
	end

	for i,silo in pairs(storage.multi_silo[force]) do
		if silo == entity then
			if event.force == entity.force then
				local surface = entity.surface
				entity = surface.create_entity {
					name = entity.name,
					position = entity.position,
					surface = surface,
					force = entity.force,
					create_build_effect_smoke = false,
				}
				entity.minable_flag = false
				entity.health = 5
				local AiTargets = require "maps.biter_battles_v2.ai_targets"
				AiTargets.start_tracking(entity)
				storage.multi_silo[force][i] = entity
				return
			end
			table.remove(storage.multi_silo[force], i)
			if #storage.multi_silo[force] == 1 then
				storage.rocket_silo[force] = storage.multi_silo[force][1]
			end
			if event.force then
				entity.surface.create_entity({
					name = "atomic-rocket",
					position = entity.position,
					force = event.force,
					source = entity.position,
					target = entity.position,
					max_range = 1,
					speed = 0.1
				})
			else
				entity.surface.create_entity({
					name = "atomic-rocket",
					position = entity.position,
					force = entity.force.name .. "_biters",
					source = entity.position,
					target = entity.position,
					max_range = 1,
					speed = 0.1
				})
			end
			return
		end
	end
end'
Event.add_removable_function(defines.events.on_entity_died, multi_silo_on_entity_died, "multi_silo_on_entity_died")

local multi_silo_on_player_respawned = 'function(event) local on_player_respawned = nil
	local player = game.players[event.player_index]
	if not player.valid then return end
	local force = player.force.name
	if force ~= "north" and force ~= "south" then return end
	if not storage.multi_silo then return end
	if not storage.multi_silo[player.force.name] then return end
	local SessionData = require("utils.datastore.session_data")    
	local trusted = SessionData.get_trusted_table()
	local silo = 1
	if storage.multi_silo[player.force.name][2] then
		if trusted[player.name] then
			silo = 2
		end
	end
	if not storage.multi_silo[player.force.name][silo] then return end
	if not storage.multi_silo[player.force.name][silo].valid then return end
	local position = storage.multi_silo[player.force.name][silo].position
	position.y = position.y*0.8
	local spawn = player.physical_surface.find_non_colliding_position("character", position, 20, 0.5) 
	player.teleport(spawn)
end'
Event.add_removable_function(defines.events.on_player_respawned, multi_silo_on_player_respawned, "multi_silo_on_player_respawned")


local multi_silo_chart_silos = 'function (event) local chart_silos = nil
	if not storage.multi_silo then return end
	local r = 48
	local surface = game.surfaces[storage.bb_surface_name]
	local enemy = {
		["north"] = "south",
		["south"] = "north",
	}
	for _, force in pairs({"north", "south"}) do
		for _, silo in pairs(storage.multi_silo[force]) do
			if silo.valid then
				game.forces[force].chart(surface, {{silo.position.x - r, silo.position.y - r}, {silo.position.x + r, silo.position.y + r}})
				if storage.spy_fish_timeout[enemy[force]] and storage.spy_fish_timeout[enemy[force]] > game.tick then
					game.forces[enemy[force]].chart(surface, {{silo.position.x - r, silo.position.y - r}, {silo.position.x + r, silo.position.y + r}})
				end
			end
		end
	end
end'
Event.add_removable_nth_tick_function(300, multi_silo_chart_silos, "multi_silo_chart_silos")


local multi_silo_on_surface_deleted = 'function(event) local on_surface_deleted = nil
	if not storage.multi_silo then return end
	local Event = require "utils.event"
	local Gui = require "maps.biter_battles_v2.gui"
	Event.remove_removable_function(defines.events.on_surface_deleted, "multi_silo_on_surface_deleted")
	Event.remove_removable_function(defines.events.on_player_respawned, "multi_silo_on_player_respawned")
	Event.remove_removable_function(defines.events.on_gui_click, "multi_silo_on_gui_click")
	Event.remove_removable_function(defines.events.on_entity_died, "multi_silo_on_entity_died")
	Event.remove_removable_function(defines.events.on_unit_group_finished_gathering, "multi_silo_on_unit_group_finished_gathering")
	Event.remove_removable_function(Gui.events.on_player_joined_team, "spawn_trusted_at_vet_silo")
	Event.remove_removable_nth_tick_function(300, "multi_silo_chart_silos")
	storage.multi_silo = nil
	game.print("Special game: biSilo removed.")
end'
Event.add_removable_function(defines.events.on_surface_deleted, multi_silo_on_surface_deleted, "multi_silo_on_surface_deleted")

local texts = {
	"Special game: bisilo",
	"Your team will survive until both rocket-silos have been destroyed.",
	"untrusted players spawn in main silo, trusted in outpost.",
}

local surface = game.surfaces[storage.bb_surface_name]
local chest = surface.create_entity({name = "wooden-chest", position = {0.5, -25.5}})
chest.destructible = false
chest.minable_flag = false
chest.operable = false

for i, text in pairs(texts) do
	local color = {255, 255, 0}
	rendering.draw_text {
		text = text,
		surface = surface,
		target = { entity = chest, offset = {0, 2 * i}},
		color = color,
		scale = 1.00,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = true
	}
end

game.forces.spectator.chart(game.surfaces[storage.bb_surface_name], {{x = -(math.abs(pos) + 300)  ,y = -250}, {x = (math.abs(pos) + 300), y = 250}}) 

game.print("Special game: biSilo loaded.", {color = {r=0.9,g=0.1,b=0.9}})

