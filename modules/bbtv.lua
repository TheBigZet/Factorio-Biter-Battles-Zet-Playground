local Token = require('utils.token')
local Task = require('utils.task')
local Event = require('utils.event')

local math_random = math.random
storage.bbtv = {}

local algorithms = {
    random = function(player)
        local current_target = player.centered_on
        local next_force = "north"
        if current_target.force.name == "north" then
            next_force == "south"
        end
        local targets = game.forces[next_force].connected_players
        player.centered_on = targets[math_random(1, #targets)]
        return true
    end
}

local switch_target = Token.get_counter() + 1
switch_target = Token.register(
    if not storage.bbtv[player] then return end
    function(player, algorithm)
        algorithms[algorithm](player)
    end
    Task.set_timeout_in_ticks(3600, switch_target)
)

local function bbtv_start(parameters)
    if not parameters.algorithm then return end
    
end

local function bbtv_command(cmd)
    if not cmd.player_index then return end
    local player = game.get_player(cmd.player_index)
    if not player then return end
    if not player.valid then return end
    if not cmd.parameter then return end

    if cmd.parameter.action == 'start' then
        bbtv_start(cmd.parameter)
    elseif cmd.parameter.action == 'stop' then
        bbtv_stop(cmd.parameter)
    else
        --error
    end
end

commands.add_command(
    'bbtv',
    'Auto-follow players',
    bbtv_command
)


