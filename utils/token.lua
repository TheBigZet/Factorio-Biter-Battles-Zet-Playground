local Token = {}
--- @type any[]
local tokens = {}
--- @type uint
local counter = 0

--- Assigns a unquie id for the given var.
--- This function cannot be called after on_init() or on_load() has run as that is a desync risk.
--- Typically this is used to register functions, so the id can be stored in the global table
--- instead of the function. This is becasue closures cannot be safely stored in the global table.
--- @param var any
--- @return number #the unique token for the variable.
function Token.register(var)
    if _LIFECYCLE == 8 then
        error('Calling Token.register after on_init() or on_load() has run is a desync risk.', 2)
    end

    counter = counter + 1

    tokens[counter] = var

    return counter
end

--- @param token_id uint
--- @return any
function Token.get(token_id)
    return tokens[token_id]
end
--- @type any[]
global.tokens = {}

---@param var any
---@return uint
function Token.register_global(var)
    local c = #global.tokens + 1

    global.tokens[c] = var

    return c
end

--- @param token_id uint
--- @return any
function Token.get_global(token_id)
    return global.tokens[token_id]
end

--- @param token_id uint
--- @param var any
function Token.set_global(token_id, var)
    global.tokens[token_id] = var
end

local uid_counter = 100

function Token.uid()
    uid_counter = uid_counter + 1

    return uid_counter
end

return Token
