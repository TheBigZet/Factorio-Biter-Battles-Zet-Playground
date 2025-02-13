-- spawners release biters on death -- by mewmew

local event = require('utils.event')
local math_random = math.random

local biter_building_inhabitants = {
    { { 'small-biter', 8, 16 } },
    { { 'small-biter', 12, 24 } },
    { { 'small-biter', 8, 16 }, { 'medium-biter', 1, 2 } },
    { { 'small-biter', 4, 8 }, { 'medium-biter', 4, 8 } },
    { { 'small-biter', 3, 5 }, { 'medium-biter', 8, 12 } },
    { { 'small-biter', 3, 5 }, { 'medium-biter', 5, 7 }, { 'big-biter', 1, 2 } },
    { { 'medium-biter', 6, 8 }, { 'big-biter', 3, 5 } },
    { { 'medium-biter', 2, 4 }, { 'big-biter', 6, 8 } },
    { { 'medium-biter', 2, 3 }, { 'big-biter', 7, 9 } },
    { { 'big-biter', 4, 8 }, { 'behemoth-biter', 3, 4 } },
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end
    if event.entity.type ~= 'unit-spawner' then
        return
    end
    local e = math.ceil(event.entity.force.get_evolution_factor(storage.bb_surface_name) * 10)
    if e < 1 then
        e = 1
    end
    local entity_surface = event.entity.surface
    local entity_position = event.entity.position
    for _, t in pairs(biter_building_inhabitants[e]) do
        for x = 1, math_random(t[2], t[3]), 1 do
            local p = entity_surface.find_non_colliding_position(t[1], entity_position, 6, 1)
            if p then
                entity_surface.create_entity({ name = t[1], position = p, force = event.entity.force.name })
            end
        end
    end
end

event.add(defines.events.on_entity_died, on_entity_died)