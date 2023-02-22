local abs = math.abs
local min = math.min

local vector_up = vector.new(0, 1, 0)
local vector_down = vector.new(0, -1, 0)

function math.clamp(n, low, high) return math.min(math.max(n, low), high) end

local function sign(x)
    return (x < 0) and -1 or 1
end

local function minmax(v, m)
    return min(abs(v), m) * sign(v)
end

function tardis_api:set_acceleration(object, vec, limit)
    limit = limit or 100

    if type(object) == 'table' then object = object.object end

    vec.x = minmax(vec.x, limit)
    vec.y = minmax(vec.y, limit)
    vec.z = minmax(vec.z, limit)

    object:set_acceleration(vec)
end

local Tardis =
{
    initial_properties =
    {
        hp_max = 1000,

        visual = "mesh",
        visual_size = { x = 10, y = 10, z = 10},

        collisionbox = tardis_api.defaults.collision_box,
        selectionbox = tardis_api.defaults.selection_box,

        pointable = true,
        physical = true,
        makes_footstep_sound = true,
        backface_culling = false,
        static_save = true,
        shaded = true,
        show_on_minimap = true,
        collide_with_objects = true
    },

    tardis_owner = "none",
    skin = "S7 Tardis",
    power = 100,
    power_capacity = 100,
    fly = false
}

function Tardis:physics()
    local friction = 0.996
    local vel = self.object:get_velocity()

    if self.is_on_ground and not self.is_in_liquid then
        vel = vector.multiply(vel, friction)
        self.object:set_velocity(vel)
    end

    local surface = nil
    local surface_node_name = nil
    local spos = self.object:get_pos()
    local surfnode = minetest.get_node(spos)

    while surfnode and (surfnode.drawtype == "liquid" or surfnode.drawtype == "flowingliquid") do
        surface_node_name = surfnode.name
        surface = spos

        if surface > spos.y + 2 then break end

        spos.y = spos.y + 1
        surfnode = minetest.get_node(spos)
    end

    local new_vel = nil
    local accel = vector.zero()

    self.water_drag = 0.1
    self.object:move_to(self.object:get_pos())

    local time_correction = (self.dtime / 0.02)

    if surface then
        self.is_in_liquid = true

        accel = vector.new(-vel.x * self.water_drag, vel.y, -vel.z * self.water_drag)
        tardis_api:set_acceleration(self.object, accel)
    else
        self.is_in_liquid = false

        local velocity = vector.copy(vel)
        velocity.y = velocity.y - (velocity.y / 100)
        self.object:set_velocity(velocity)

        tardis_api:set_acceleration(self.object, vector.zero())
    end
end

function Tardis:control(player)
    local owner = minetest.get_player_by_name(self.object:get_luaentity():get_tardis_owner())

    local look_dir = owner:get_look_dir()
    local ctrl = owner:get_player_control()
    local vel = self.object:get_velocity()

    vel.x = math.clamp(vel.x, -10.0, 10.0)
    vel.y = math.clamp(vel.y, -10.0, 10.0)
    vel.z = math.clamp(vel.z, -10.0, 10.0)

    if self.fly then
        local rot = vector.length(vel) * 10 * self.dtime
        self.object:set_properties({ automatic_rotate = rot })

        local speed = 8
        local vright = vector.new(look_dir.z, look_dir.y, -look_dir.x)
        local vleft = -vright

        if ctrl.jump then
            vel = vector.add(vel, vector_up * speed * self.dtime)
        end

        if ctrl.sneak then
            vel = vector.add(vel, vector_down * speed * self.dtime)
        end

        if ctrl.up then
            vel = vector.add(vel, look_dir * speed * self.dtime)
        end

        if ctrl.down then
            vel = vector.add(vel, -look_dir * speed * self.dtime)
        end

        if ctrl.right then
            vel = vector.add(vel, vright * speed * self.dtime)
        end

        if ctrl.left then
            vel = vector.add(vel, vleft * speed * self.dtime)
        end

        if self.is_on_ground then vel = vector.zero() end
    end

    return vel
end

function Tardis:set_skin(skin)
    self.skin = skin
end

function Tardis:get_skin()
    return self.skin
end

function Tardis:set_fly(value)
    self.fly = value
end

function Tardis:get_fly()
    return self.fly
end

function Tardis:get_tardis_owner()
    return self.tardis_owner
end

function Tardis:set_tardis_owner(owner)
    self.tardis_owner = owner
end

function Tardis:get_staticdata()
    return minetest.write_json({
        tardis_owner = self.tardis_owner,
        skin = self.skin,
        power = self.power,
        power_capacity = self.power_capacity
    })
end

function Tardis:on_activate(staticdata, dtime_s)
    if staticdata ~= "" and staticdata ~= nil then
        local data = minetest.parse_json(staticdata) or {}

        self:set_tardis_owner(data.tardis_owner)
    end
end

function Tardis:on_rightclick(clicker)
    if not clicker then return end

    local obj = self.object
    local name = clicker:get_player_name()
    local tardis = tardis_api:get_coords(name, "ext_pos")
    local entity = obj:get_luaentity()

    if self.fly then
        self.fly = false

        clicker:set_detach()
        obj:set_properties({ automatic_rotate = 0 })
        clicker:set_physics_override({ gravity = 1 })
        clicker:set_pos(obj:get_pos())
        clicker:set_properties({ visual_size = {x = 1, y = 1}})

        return

    else self.fly = true end

    clicker:set_attach(obj, "", vector.new(0, 0, 0), vector.new(0, 0, 0), false)

    obj:set_properties({ automatic_rotate = math.deg(0.1) })

    clicker:set_physics_override({ gravity = 0 })
    clicker:set_properties({ visual_size = {x = 0, y = 0}})
end

function Tardis:on_step(dtime, collision)
    self.collision = collision
    self.dtime = min(dtime, 0.2)

    local vel = self.object:get_velocity()

    if collision then
        self.is_on_ground = collision.touching_ground
    else
        if self.last_velocity.y == 0 and vel.y == 0 then
            self.is_on_ground = true
        else
            self.is_on_ground = false
        end
    end

    self:physics()
    self.object:set_velocity(self:control())

    self.last_velocity = self.object:get_velocity()
    -- self.time_total = self.time_total + self.dtime
end

local TardisCraftitem =
{
    item =
    {
        inventory_image = "tardis_item.png",

        stack_max = 1,
        liquids_pointable = false
    },
    skin = Tardis:get_skin()
}


function TardisCraftitem.item:on_place(placer, pointed_thing)
    if not placer or not placer:is_player() then return end

    local name = placer:get_player_name()
    local ext_pos = pointed_thing.above or pointed_thing.ref:get_pos()

    if tardis_api:get_bool(name, "owns_tardis") then 
        minetest.chat_send_player(name, tardis_api.S("[Tardis API]: ALERT: You can own only one Tardis"))
        return
    end

    tardis_api:set_bool(name, "owns_tardis", true)
    tardis_api:set_coords(name, "ext_pos", ext_pos)

    local entity = minetest.add_entity(ext_pos, tardis_api.mod .. ":" .. TardisCraftitem.skin, nil)

    if entity == nil then
        minetest.chat_send_player(name, tardis_api.S("[Tardis API]: WARNING: Something went wrong"))
        return
    end

    local luaentity = entity:get_luaentity()

    luaentity:set_tardis_owner(name)
    minetest.sound_play({ name = "tardis_placed", object = entity, max_hear_distance = 8 })
end



function tardis_api:register_tardis(skin, max_health, power_capacity)
    skin = skin or "S7 Tardis"
    max_health = max_health or 1000
    power_capacity = power_capacity or 100

    local skin_lc = skin:lower():gsub(" ", "_")

    Tardis.initial_properties.mesh = ("%s.obj"):format(skin_lc)
    Tardis.initial_properties.textures = {("%s.png"):format(skin_lc)}
    Tardis.initial_properties.hp_max = max_health

    TardisCraftitem.item.description = tardis_api.S(("Tardis (%s)"):format(skin))
    TardisCraftitem.skin = skin_lc

    minetest.register_entity(tardis_api.mod .. ":" .. skin_lc, Tardis)
    minetest.register_craftitem(tardis_api.mod .. ":" .. skin_lc, TardisCraftitem.item)
end


minetest.register_craftitem(tardis_api.mod .. ":key", {
    description = tardis_api.S("Tardis Key"),

    inventory_image = "tardis_key.png",
    stack_max = 1,
    liquids_pointable = false
})