local Global = require('utils.global')
local Session = require('utils.datastore.session_data')
local Game = require('utils.game')
local Token = require('utils.token')
local Task = require('utils.task')
local Server = require('utils.server')
local Event = require('utils.event')
local Utils = require('utils.core')

local jailed_data_set = 'jailed'
local jailed = {}
local player_data = {}
local votejail = {}
local votefree = {}
local settings = {
    playtime_for_vote = 3600,
    playtime_for_instant_jail = 103680000, -- 20 days
    votejail_count = 3,
}
local Server_set_data = Server.set_data
local Server_try_get_data = Server.try_get_data
local concat = table.concat

local valid_commands = {
    ['free'] = true,
    ['jail'] = true,
}

Global.register({
    jailed = jailed,
    votejail = votejail,
    votefree = votefree,
    settings = settings,
    player_data = player_data,
}, function(t)
    jailed = t.jailed
    votejail = t.votejail
    votefree = t.votefree
    settings = t.settings
    player_data = t.player_data
end)

local Public = {}

local clear_gui = Token.register(function(data)
    local player = data.player
    if player and player.valid then
        for _, child in pairs(player.gui.screen.children) do
            child.destroy()
        end
        for _, child in pairs(player.gui.left.children) do
            child.destroy()
        end
    end
end)

---@param player LuaPlayer
---@return uint 
local validate_playtime = function(player)
    local tracker = Session.get_session_table()

    local playtime = player.online_time

    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end

    return playtime
end

---@param player LuaPlayer
---@return boolean
local validate_trusted = function(player)
    return Session.get_trusted_table()[player.name]
end

---=================
---player data stuff
---=================

---@param player LuaPlayer
local get_player_data = function(player)
    if not player_data[player.name] then
        player_data[player.name] = {}
    end
    return player_data[player.name]
end

---@param player LuaPlayer
local function remove_player_data(player)
    player_data[player.name] = nil
end

---@param player LuaPlayer
local function store_player_data(player)
    player_data[player.name] = {
        fallback_surface_index = player.physical_surface_index
        position = player.physical_position
        p_group_id = player.permission_group.group_id
        locked = true
    }
end

---=================
---gulag permission stuff
---=================

---@return LuaPermissionGroup
local function create_gulag_permission_group()
    local gulag = game.permissions.get_group('gulag')
    if not gulag then
        gulag = game.permissions.create_group('gulag')
        for action_name, _ in pairs(defines.input_action) do
            gulag.set_allows_action(defines.input_action[action_name], false)
        end
        gulag.set_allows_action(defines.input_action.write_to_console, true)
    end

    return gulag
end

---@return LuaPermissionGroup
local get_gulag_permission_group = function()
    return game.permissions.get_group('gulag') or create_gulag_permission_group()
end

---=================
---gulag surface stuff
---=================

---@return LuaSurface
local create_gulag_surface = function()
    local surface = game.surfaces['gulag']
    if not surface then 
        local walls = {}
        local tiles = {}
        pcall(function()
            surface = game.create_surface('gulag', {
                autoplace_controls = {
                    ['coal'] = { frequency = 23, size = 3, richness = 3 },
                    ['stone'] = { frequency = 20, size = 3, richness = 3 },
                    ['copper-ore'] = { frequency = 25, size = 3, richness = 3 },
                    ['iron-ore'] = { frequency = 35, size = 3, richness = 3 },
                    ['uranium-ore'] = { frequency = 20, size = 3, richness = 3 },
                    ['crude-oil'] = { frequency = 80, size = 3, richness = 1 },
                    ['trees'] = { frequency = 0.75, size = 2, richness = 0.1 },
                    ['enemy-base'] = { frequency = 15, size = 0, richness = 1 },
                },
                cliff_settings = { cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff' },
                height = 64,
                width = 256,
                peaceful_mode = false,
                seed = 1337,
                starting_area = 'very-low',
                starting_points = { { x = 0, y = 0 } },
                terrain_segmentation = 'normal',
                water = 'normal',
            })
        end)
        if not surface then
            surface = game.create_surface('gulag', { width = 40, height = 40 })
        end
        surface.always_day = true
        surface.request_to_generate_chunks({ 0, 0 }, 9)
        surface.force_generate_chunk_requests()
        local area = { left_top = { x = -128, y = -32 }, right_bottom = { x = 128, y = 32 } }
        for x = area.left_top.x, area.right_bottom.x, 1 do
            for y = area.left_top.y, area.right_bottom.y, 1 do
                tiles[#tiles + 1] = { name = 'black-refined-concrete', position = { x = x, y = y } }
                if
                    x == area.left_top.x
                    or x == area.right_bottom.x
                    or y == area.left_top.y
                    or y == area.right_bottom.y
                then
                    walls[#walls + 1] = { name = 'stone-wall', force = 'neutral', position = { x = x, y = y } }
                end
            end
        end
        surface.set_tiles(tiles)
        for _, entity in pairs(walls) do
            local e = surface.create_entity(entity)
            e.destructible = false
            e.minable_flag = false
        end

        rendering.draw_text({
            text = 'The pit of despair ☹',
            surface = surface,
            target = { 0, -50 },
            color = { r = 0.98, g = 0.66, b = 0.22 },
            scale = 10,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false,
        })
    end
    return game.surfaces['gulag']
end

---@return LuaSurface
local function get_gulag_surface()
    return game.get_surface('gulag') or create_gulag_surface()
end


---@param player LuaPlayer
local teleport_player_to_gulag = function(player)
    store_player_data(player)
    local gulag = get_gulag_surface() 
    player.character.teleport(gulag.find_non_colliding_position('character', { 0, 0 }, 128, 1), gulag)
    Task.set_timeout_in_ticks(5, clear_gui, {player = player})
end

---@param player LuaPlayer
local function teleport_player_from_gulag(player)
    local p_data = get_player_data(player)
    local target_surface = game.get_surface(p_data.fallback_surface_index)
    local target_position = p_data.position
    local target_group = game.permissions.get_group(p_data.p_group_id)
    target_group.add_player(player)
    local target_tile = surface.get_tile(position)
    if target_tile.valid and target_tile.name == 'out-of-map' then
        player.character.teleport(
            target_surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(target_surface), 128, 1),
            target_surface
        )
    else
        player.character.teleport(target_surface.find_non_colliding_position('character', target_position, 128, 1), target_surface)
    end
    remove_player_data(player)
end

local on_player_changed_surface = function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if not jailed[player.name] then
        return
    end

    local surface = game.surfaces['gulag']
    if player.surface.index ~= surface.index then
        local p_data = get_player_data(player)
        if jailed[player.name] and p_data and p_data.locked then
            teleport_player_to_gulag(player)
        end
    end
end

local validate_args = function(data)
    local player = data.player
    local griefer = data.griefer
    local trusted = data.trusted
    local playtime = data.playtime
    local message = data.message
    local cmd = data.cmd

    if not griefer or not game.get_player(griefer) then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    if votejail[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if votefree[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if jailed[player.name] and not player.admin then
        Utils.print_to(player, 'You are jailed, you can´t run this command.')
        return false
    end

    if player.name == griefer and not player.admin then
        Utils.print_to(player, 'You can´t select yourself.')
        return false
    end

    if game.get_player(griefer).admin and not player.admin then
        Utils.print_to(player, 'You can´t select an admin.')
        return false
    end

    if not trusted and not player.admin or playtime <= settings.playtime_for_vote and not player.admin then
        Utils.print_to(player, 'You are not trusted enough to run this command.')
        return false
    end

    if not message then
        Utils.print_to(player, 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 0 then
        Utils.print_to(player, 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 10 then
        Utils.print_to(player, 'Reason is too short.')
        return false
    end

    return true
end

local vote_to_jail = function(player, griefer, msg)
    if not votejail[griefer] then
        votejail[griefer] = { index = 0, actor = player.name }
        local message = player.name .. ' has started a vote to jail player ' .. griefer
        Utils.print_to(nil, message)
    end
    if not votejail[griefer][player.name] then
        votejail[griefer][player.name] = true
        votejail[griefer].index = votejail[griefer].index + 1
        Utils.print_to(player, 'You have voted to jail player ' .. griefer .. '.')
        if
            votejail[griefer].index >= settings.votejail_count
            or (
                votejail[griefer].index == #game.connected_players - 1
                and #game.connected_players > votejail[griefer].index
            )
        then
            Public.try_ul_data(griefer, true, votejail[griefer].actor, msg)
        end
    else
        Utils.print_to(player, 'You have already voted to kick ' .. griefer .. '.')
    end
end

local vote_to_free = function(player, griefer)
    if not votefree[griefer] then
        votefree[griefer] = { index = 0, actor = player.name }
        local message = player.name .. ' has started a vote to free player ' .. griefer
        Utils.print_to(nil, message)
    end
    if not votefree[griefer][player.name] then
        votefree[griefer][player.name] = true
        votefree[griefer].index = votefree[griefer].index + 1

        Utils.print_to(player, 'You have voted to free player ' .. griefer .. '.')
        if
            votefree[griefer].index >= settings.votejail_count
            or (
                votefree[griefer].index == #game.connected_players - 1
                and #game.connected_players > votefree[griefer].index
            )
        then
            Public.try_ul_data(griefer, false, votefree[griefer].actor)
            votejail[griefer] = nil
            votefree[griefer] = nil
        end
    else
        Utils.print_to(player, 'You have already voted to free ' .. griefer .. '.')
    end
    return
end

---@param player_name string #name of the player trying to jail the griefer
---@param griefer_name string #the griefer to be jailed
---@param msg string #reason for jailing
local jail = function(player_name, griefer_name, msg)
    player_name = player_name or 'script'
    if jailed[griefer_name] then
        return false
    end

    if not msg then
        return
    end
    local griefer = game.get_player(griefer_name)

    if not griefer then
        return
    end
    
    teleport_player_to_gulag(griefer)

    if griefer.surface.name == 'gulag' then
        local gulag = get_gulag_permission_group()
        gulag.add_player(griefer_name)
    end
    local message = griefer_name .. ' has been jailed by ' .. player_name .. '. Cause: ' .. msg

    if griefer.character and griefer.character.valid and griefer.character.driving then
        griefer.character.driving = false
    end
    griefer.driving = false
    --- try: set_driving(false, true)
    jailed[griefer_name] = { jailed = true, actor = player_name, reason = msg }
    Server_set_data(jailed_data_set, griefer_name, { jailed = true, actor = player_name, reason = msg })

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)

    griefer.clear_console()
    Utils.print_to(griefer_name, message)
    griefer.opened = defines.gui_type.none
    return true
end

---@param player_name string #name of the player trying to free the griefer
---@param griefer_name string #name of the griefer
local free = function(player_name, griefer_name)
    player_name = player_name or 'script'
    if not jailed[griefer] then
        return false
    end

    local griefer = game.get_player(griefer_name)
    if not griefer then
        return
    end

    teleport_player_from_gulag(griefer)

    local message = griefer_name .. ' was set free from jail by ' .. player_name .. '.'

    jailed[griefer_name] = nil

    Server_set_data(jailed_data_set, griefer_name, nil)

    votejail[griefer_name] = nil
    votefree[griefer_name] = nil

    Utils.print_to(nil, message)    --?
    Utils.action_warning_embed('{Jailed}', message)
    return true
end

local is_jailed = Token.register(function(data)
    local key = data.key
    local value = data.value
    if value then
        if value.jailed then
            jail(value.actor, key)
        end
    end
end)

local update_jailed = Token.register(function(data)
    local key = data.key
    local value = data.value or false
    local player = data.player or 'script'
    local message = data.message
    if value then
        jail(player, key, message)
    else
        free(player, key)
    end
end)

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    key = tostring(key)

    local secs = Server.get_current_time()

    if not secs then
        return
    else
        Server_try_get_data(jailed_data_set, key, is_jailed)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_ul_data(key, value, player, message)
    if type(key) == 'table' then
        key = key.name
    end

    key = tostring(key)

    local data = {
        key = key,
        value = value,
        player = player,
        message = message,
    }

    Task.set_timeout_in_ticks(1, update_jailed, data)
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return jailed[player_name] ~= nil
end

--- Prints a list of all players in the player_jailed table.
function Public.print_jailed()
    local result = {}

    for k, _ in pairs(jailed) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of jailed
-- @return <table>
function Public.get_jailed_table()
    return jailed
end

Event.add(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Public.try_dl_data(player.name)
end)


Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.on_init(create_gulag_surface)

Server.on_data_set_changed(jailed_data_set, function(data)
    if data and data.value then
        if data.value.jailed and data.value.actor then
            jail(data.value.actor, data.key)
        end
    else
        free('script', data.key)
    end
end)

commands.add_command('jail', 'Sends the player to gulag! Valid arguments are:\n/jail <LuaPlayer> <reason>', function(cmd)
    if not cmd.player_index then return end
    local player = game.get_player(cmd.player_index)

    local playtime = validate_playtime(player)
    local trusted = validate_trusted(player)

    local param = cmd.parameters

    if not param then
        return Utils.print_to(player, 'No valid reason given.')
    end

    local t = {}

    for i in string.gmatch(param, '%S+') do
        t[#t + 1] = i
    end

    local griefer_name = t[1]
    table.remove(t, 1)
    local message = concat(t, ' ')
    local data = {
        player = player,
        griefer = griefer,
        trusted = trusted,
        playtime = playtime,
        message = message,
        cmd = cmd,
    }

    if not validate_args(data) then
        return
    end

    local griefer = game.get_player(griefer)
    if griefer then
        griefer_name = griefer.name
    end

    ---vote jail
    if
        trusted
        and playtime >= settings.playtime_for_vote
        and playtime < settings.playtime_for_instant_jail
        and not player.admin
    then
        vote_to_jail(player, griefer_name, message)
        return
    end

    ---insta jail
    if player.admin or playtime >= settings.playtime_for_instant_jail then
        if player.admin then
            Utils.warning(
                player,
                'Abusing the jail command will lead to revoked permissions. Jailing someone in case of disagreement is not OK!'
            )
        end
        jail(player.name, griefer_name, message)
        return
    end
    return
end)

commands.add_command('free', 'Brings back the player from gulag.', function(cmd)
    if not cmd.player_index then return end
    local player = game.get_player(cmd.player_index)

    local playtime = validate_playtime(player)
    local trusted = validate_trusted(player)

    local param = cmd.parameters

    if not param then
        return Utils.print_to(player, 'No valid reason given.')
    end

    local t = {}

    for i in string.gmatch(param, '%S+') do
        t[#t + 1] = i
    end

    local griefer_name = t[1]
    table.remove(t, 1)
    local message = concat(t, ' ')
    local data = {
        player = player,
        griefer = griefer,
        trusted = trusted,
        playtime = playtime,
        message = message,
        cmd = cmd,
    }

    if not validate_args(data) then
        return
    end

    local griefer = game.get_player(griefer)
    if griefer then
        griefer_name = griefer.name
    end

    ---vote free
    if
        trusted
        and playtime >= settings.playtime_for_vote
        and playtime < settings.playtime_for_instant_jail
        and not player.admin
    then
        vote_to_free(player, griefer_name)
        return
    end

    ---insta free
    if player.admin or playtime >= settings.playtime_for_instant_jail then
        free(player.name, griefer_name)
        return
    end
    return
end)

function Public.required_playtime_for_instant_jail(value)
    if value then
        settings.playtime_for_instant_jail = value
    end
    return settings.playtime_for_instant_jail
end

function Public.required_playtime_for_vote(value)
    if value then
        settings.playtime_for_vote = value
    end
    return settings.playtime_for_vote
end

Event.on_init(get_gulag_permission_group)

return Public
