
local Event = require('utils.event')
local Token = require('utils.token')

local evo_threshold = 1 -- 100% evo

local dmg_modifier_formula = function(evo)
    return 0.5 * (evo-evo_threshold) + 1
end

---@param biter_force LuaForce
---@param evo number
local update_damage_modifiers = function(biter_force, evo)
    if evo < evo_threshold then return end
    biter_force.set_ammo_damage_modifier('melee', dmg_modifier_formula(evo))
    biter_force.set_ammo_damage_modifier('biological', dmg_modifier_formula(evo))
end


local on_3600th_tick = Token.register(
    function()
        update_damage_modifiers(game.forces.north_biters, storage.bb_evolution.north_biters)
        update_damage_modifiers(game.forces.south_biters, storage.bb_evolution.south_biters)
    end
)

local enable = function()
    Event.add_removable_nth_tick(3600, on_3600th_tick)
    game.print("Extra biters damage enabled. Threshold: " .. evo_threshold .. "%")
end

local disable = function()
    Event.remove_removable_nth_tick(3600, on_3600th_tick)
    game.print("Extra biters damage disabled.)
end

return {enable = enable, disable = disable}