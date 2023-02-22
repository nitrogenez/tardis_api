-- Tardis API is licensed under GNU Affero General Public License v3-or-later

-- Initialization
tardis_api = {}
tardis_api.globs = {}

tardis_api.mod = minetest.get_current_modname()
tardis_api.path = minetest.get_modpath(tardis_api.mod)
tardis_api.storage = minetest.get_mod_storage(tardis_api.mod)
tardis_api.S = minetest.get_translator(tardis_api.mod)

-- Methods
function tardis_api:log(msg) minetest.log("verbose", "[Tardis API]: " .. msg) end
function tardis_api:err(msg) minetest.log("error", "[Tardis API]: ERROR: " .. msg) end
function tardis_api:warn(msg) minetest.log("warning", "[Tardis API]: WARNING: " .. msg) end

function tardis_api:exists(file)
    local f = io.open(file, 'rb')
    if f ~= nil then io.close(f) return true else return false end
end


-- Modules
dofile(("%s/api/settings.lua"):format(tardis_api.path))
dofile(("%s/defaults.lua"):format(tardis_api.path))

dofile(("%s/api/tardis.lua"):format(tardis_api.path))

tardis_api:register_tardis()
