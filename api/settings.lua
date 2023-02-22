function tardis_api:get_int(owner, property)
    return tardis_api.storage:get_int(("%s/%s"):format(owner, property))
end


function tardis_api:get_float(owner, property)
    return tardis_api.storage:get_float(("%s/%s"):format(owner, property))
end


function tardis_api:get_str(owner, property)
    return tardis_api.storage:get_string(("%s/%s"):format(owner, property))
end


function tardis_api:get_bool(owner, property)
    local prop = tardis_api.storage:get_int(("%s/%s"):format(owner, property))

    if prop == 0 or prop == nil then return false end
    if prop == 1 then return true end

    return false
end


function tardis_api:set_int(owner, property, value)
    tardis_api.storage:set_string(("%s/%s"):format(owner, property), value)
end


function tardis_api:set_float(owner, property, value)
    tardis_api.storage:set_float(("%s/%s"):format(owner, property), value)
end


function tardis_api:set_bool(owner, property, value)
    local path = ("%s/%s"):format(owner, property)

    if value == true then tardis_api.storage:set_int(path, 1) end
    if value == false then tardis_api.storage:set_int(path, 0) end
end


function tardis_api:set_coords(owner, property, coords)
    local c = minetest.serialize(coords)

    tardis_api:set_str(owner, property, c)
end


function tardis_api:get_coords(owner, property)
    return minetest.deserialize(tardis_api:get_str(owner, property))
end

function tardis_api:set_str(owner, property, value)
    tardis_api.storage:set_string(("%s/%s"):format(owner, property), value)
end

function tardis_api:set_glob(property, value)
    tardis_api.storage:set_string(property, value)
end

function tardis_api:get_glob(property)
    return tardis_api.storage:get_string(property)
end