local Public = {}
local math_random = math.random
local math_floor = math.floor
local math_max = math.max


---@alias  BiterRaffle.SIZE_SMALL 1
---@alias  BiterRaffle.SIZE_MEDIUM 2
---@alias  BiterRaffle.SIZE_BIG 3
---@alias  BiterRaffle.SIZE_BEHEMOTH 4

---@alias  BiterRaffle.TYPE_BITER 1
---@alias  BiterRaffle.TYPE_SPITTER 2
---@alias  BiterRaffle.TYPE_WORM 3
---@alias  BiterRaffle.TYPE_MIXED 4

---@alias BiterRaffle.RaffleTable { BiterRaffle.SIZE_SMALL: number, BiterRaffle.SIZE_MEDIUM: number, BiterRaffle.SIZE_BIG: number, BiterRaffle.SIZE_BEHEMOTH: number}
---@alias BiterRaffle.EnemyTable table<BiterRaffle.TYPE_BITER|BiterRaffle.TYPE_SPITTER|BiterRaffle.TYPE_WORM, table<BiterRaffle.SIZE_SMALL|BiterRaffle.SIZE_MEDIUM|BiterRaffle.SIZE_BIG|BiterRaffle.SIZE_BEHEMOTH, string>>

---@type BiterRaffle.EnemyTable
local ENEMY = {
    {
        'small-biter',
        'medium-biter',
        'big-biter',
        'behemoth-biter',
    },
    {
        'small-spitter',
        'medium-spitter',
        'big-spitter',
        'behemoth-spitter',
    },
    {
        'small-worm-turret',
        'medium-worm-turret',
        'big-worm-turret',
        'behemoth-worm-turret',
    },
}

---@return BiterRaffle.RaffleTable
local function get_raffle_table(level)
    if level < 500 then
        return {
            1000 - level * 1.75,
            math_max(-250 + level * 1.5, 0), -- only this one can be negative for level < 500
            0,
            0,
        }
    end
    if level < 900 then
        return {
            math_max(1000 - level * 1.75, 0), -- only this one can be negative for level < 900
            1000 - level,
            (level - 500) * 2,
            0,
        }
    end
    return {
        0,
        math_max(1000 - level, 0),
        (level - 500) * 2,
        (level - 900) * 8,
    }
end

---@return BiterRaffle.SIZE_SMALL | BiterRaffle.SIZE_MEDIUM | BiterRaffle.SIZE_BIG | BiterRaffle.SIZE_BEHEMOTH
local function roll(evolution_factor)
    local raffle = get_raffle_table(math_floor(evolution_factor * 1000))
    local r = math_random(0, math_floor(raffle[1] + raffle[2] + raffle[3] + raffle[4]))
    local current_chance = 0
    for i=1,4,1 do
        current_chance = current_chance + raffle[i]
        if r <= current_chance then
            return i
        end
    end
end

local function get_biter_name(evolution_factor)
    return ENEMY[1][roll(evolution_factor)]
end

local function get_spitter_name(evolution_factor)
    return ENEMY[2][roll(evolution_factor)]
end

local function get_worm_raffle_table(level)
    if level < 500 then
        return {
            1000 - level * 1.75,
            level,
            0,
            0,
        }
    end
    if level < 900 then
        return {
            math_max(1000 - level * 1.75, 0),
            1000 - level,
            (level - 500) * 2,
            0,
        }
    end
    return {
        math_max(1000 - level * 1.75, 0),
        math_max(1000 - level, 0),
        (level - 500) * 2,
        (level - 900) * 3,
    }
end

---@return string
local function get_worm_name(evolution_factor)
    local raffle = get_worm_raffle_table(math_floor(evolution_factor * 1000))
    local r = math_random(0, math_floor(raffle[1] + raffle[2] + raffle[3] + raffle[4]))
    local current_chance = 0
    for i=1,4,1 do
        current_chance = current_chance + raffle[i]
        if r <= current_chance then
            return ENEMY[3][i]
        end
    end
end

local function get_unit_name(evolution_factor)
    if math_random(1, 3) == 1 then
        return get_spitter_name(evolution_factor)
    else
        return get_biter_name(evolution_factor)
    end
end

local type_functions = {
    get_biter_name,
    get_spitter_name,
    get_worm_name,
    get_unit_name,
}

---@param entity_type BiterRaffle.TYPE_BITER|BiterRaffle.TYPE_SPITTER|BiterRaffle.TYPE_WORM|BiterRaffle.TYPE_MIXED
---@param evolution_factor number?
---@return string?
function Public.roll(entity_type, evolution_factor)
    if not entity_type then
        return
    end
    if not type_functions[entity_type] then
        return
    end
    local evo = evolution_factor
    if not evo then
        evo = game.forces.enemy.get_evolution_factor(storage.bb_surface_name)
    end
    return type_functions[entity_type](evo)
end

return Public
