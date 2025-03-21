-- A pool memory allocator.
local mod = {}

function mod.malloc(size)
    -- Force allocates an array with hard size limit, then
    -- returns reference to it. The 'memory' here is just a representation
    -- layer that emulates cells within RAM.
    local memory = {}

    for i = 1, size, 1 do
        memory[i] = 0
    end

    return memory
end

function mod.enlarge(memory, offset, bytes)
    -- Resizes memory from offset by bytes. The offset should point at
    -- last cell of allocated region to prevent overwriting.
    if memory[offset + 1] ~= nil then
        log('pool::enlarge: writing over allocated region!')
        local detail_fmt = 'pool::enlarge: offset = %d, request = %d'
        log(string.format(detail_fmt, offset, bytes))
    end

    for i = offset + 1, offset + bytes, 1 do
        memory[i] = 0
    end

    return memory
end

--- nested localised string ready for concat
--- number of available entries: 19^depth
local function localised_string_recursive(depth)
    if depth > 10
        -- be reasonable
        log("Capping nested LocalisedString depth to 10")
        depth = 10
    end
    local t = {'', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}
    if depth > 1 then
        for i = 2, 20, 1 do
            t[i] = localised_string_recursive(depth-1)
        end
    end
    return t
end
return mod
