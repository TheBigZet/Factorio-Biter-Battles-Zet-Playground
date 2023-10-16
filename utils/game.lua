local Global = require 'utils.global'
local pairs = pairs

local Game = {}

local bad_name_players = {}
Global.register(
    bad_name_players,
    function(tbl)
        bad_name_players = tbl
    end
)

--- Prints to player or console.
function Game.player_print(str)
    if game.player then
        game.player.print(str)
    else
        print(str)
    end
end

---@param surface LuaSurface
---@param position MapPosition to display at
---@param text LocalisedString to display
---@param color Color in {r = 0~1, g = 0~1, b = 0~1}, defaults to white.
---@return LuaEntity? the created entity
function Game.print_floating_text(surface, position, text, color)
    return surface.create_entity{
        name = 'tutorial-flying-text',
        color = color,
        text = text,
        position = position
    }
end


---Creates a floating text entity at the player location with the specified color in {r, g, b} format.
---Example: "+10 iron" or "-10 coins"
---@param player_index uint
---@param text LocalisedString to display
---@param color Color in {r = 0 ~ 1, g = 0 ~ 1, b = 0 ~ 1}, defaults to white.
---@param x_offset number
---@param y_offset number
---@return LuaEntity? _ the created entity
function Game.print_player_floating_text_position(player_index, text, color, x_offset, y_offset)
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    local position = player.position
    return Game.print_floating_text(player.surface, {x = position.x + x_offset, y = position.y + y_offset}, text, color)
end

function Game.print_player_floating_text(player_index, text, color)
    Game.print_player_floating_text_position(player_index, text, color, 0, -1.5)
end

return Game
