--[[
# DON'T BE A DICK PUBLIC LICENSE

> Version 1.1, December 2016

> Copyright (C) [2020] [Janek "superyu"]

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document.

> DON'T BE A DICK PUBLIC LICENSE
> TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

1. Do whatever you like with the original work, just don't be a dick.

   Being a dick includes - but is not limited to - the following instances:

 1a. Outright copyright infringement - Don't just copy this and change the name.
 1b. Selling the unmodified original with no work done what-so-ever, that's REALLY being a dick.
 1c. Modifying the original work to contain hidden harmful content. That would make you a PROPER dick.

2. If you become rich through modifications, related works/services, or supporting the original work,
share the love. Only a dick would make loads off this work and not buy the original work's
creator(s) a pint.

3. Code is provided with no warranty. Using somebody else's code and bitching when it goes wrong makes
you a DONKEY dick. Fix the problem yourself. A non-dick would submit the fix back.
]]

local ENABLE = gui.new_checkbox("Sonar ESP", "superyu_sonar", false);
local SOUND = gui.new_combobox("Sound", "superyu_sonar_sound", false, "Button 17", "Button 15", "Blip 1", "Blip 2", "Bell", "Button 10");
local VOLUME = gui.new_slider("Volume", "superyu_sonar_volume", 100, 1, 100, 1);
local DISTANCE = gui.new_slider("Range", "superyu_sonar_range", 200, 100, 1000, 50);
local FOV = gui.new_slider("FOV", "superyu_sonar_fov", 180, 1, 180, 1);
local FOV_ROTATION = gui.new_slider("FOV Rotation", "superyu_sonar_fov_rotation", 180, 0, 360, 1);
local DISTANCEBASED = gui.new_checkbox("Distancebased Sound frequency", "superyu_sonar_distancebased_freq", false);
local DISTANCEBASEDVOLUME = gui.new_checkbox("Distancebased Sound volume", "superyu_sonar_distancebased_volume", false);
local VISUALIZE_FOV = gui.new_checkbox("Vizualize FOV", "superyu_sonar_fov_visualize", false);

--- Descriptions
ENABLE:set_tooltip("Enables Sonar ESP.")
SOUND:set_tooltip("Select which sound should be played.")
DISTANCE:set_tooltip("Distance of the FOV.")
FOV:set_tooltip("Field of view of the sonar.")
FOV_ROTATION:set_tooltip("Rotation of the FOV.")
DISTANCEBASED:set_tooltip("Play sound more frequently when enemies are near.")
DISTANCEBASED:set_tooltip("Play sound louder when enemies are near.")
VISUALIZE_FOV:set_tooltip("Visualize the FOV.")

--- Localize API
local rad = math.rad
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local atan = math.atan
local renderLine = renderer.line
local w2s = renderer.world_to_screen
local getLocalIndex = engine_client.get_local_player
local getEngineAngles = engine_client.get_view_angles
local gameCommand = engine_client.exec
local getEntityByIndex = entity_list.get_entity
local Vector3 = vec3.new
local Color = color.new

--- Variables
local data = {

    ["Globaldata"] = {
        ["LastBeep"] = 0,
        ["EnemiesInRange"] = 0,
        ["Enemies"] = 0,
    },

    ["Localdata"] = {
        ["AbsOrigin"] = Vector3(0, 0, 0)
    },

    ["Sounds"] = {
        ["Button 17"] = "button17", 
        ["Button 15"] = "button15", 
        ["Blip 1"] = "blip1", 
        ["Blip 2"] = "blip2", 
        ["Bell"] = "bell1", 
        ["Button 10"] = "button10"}
}

--- Some Helper functions
local function Magnitude(vec)
    return sqrt(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z);
end

local function Subtract(vector1, vector2)
    return Vector3(vector1.x - vector2.x, vector1.y - vector2.y, vector1.z - vector2.z);
end

local function Normalize(angles)

	if (angles.x > 89) then
		angles.x = 89;
    elseif (-89 > angles.x) then
		angles.x = -89;
    end

	if (angles.y > 180) then
		angles.y = angles.y - 360;
	elseif (-180 > angles.y) then
		angles.y = angles.y + 360;
    end

	angles.z = 0;

	return angles;
end

local function calcAngle(src, dst) --- From source sdk, thx valve

    local angles = Vector3(0, 0, 0);
    local delta = Subtract(src, dst);
    local hyp = Magnitude(delta);
    angles.x = atan(delta.z / hyp) * 180.0 / math.pi
    angles.y = atan(delta.y / delta.x) * 180.0 / math.pi
    angles.z = 0.0;

    if delta.x >= 0.0 then
        angles.y = angles.y + 180.0;
    end

    return Normalize(angles);
end

--- Actual code
local function drawFOV(vector, radius)
    local r = 255*(data["Globaldata"]["EnemiesInRange"]/data["Globaldata"]["Enemies"])
    if data["Globaldata"]["Enemies"] == 0 then
        r = 255*(data["Globaldata"]["EnemiesInRange"]/2);
    end
    r = math.floor(r);
    local color = Color(r, 25, 25, 155);

    local oldX, oldY
    local fov = FOV:get_value()
    local fovRotation = 180 - FOV_ROTATION:get_value()
    local engineAngles = getEngineAngles()
    engineAngles.y = engineAngles.y+fovRotation+(180-fov)
    engineAngles = Normalize(engineAngles)

    for rotation = engineAngles.y, engineAngles.y+(fov*2), 1 do
        local rotRad = rad(rotation)
        local newVector = Vector3(radius * cos(rotRad) + vector.x, radius * sin(rotRad) + vector.y, vector.z)
        local x, y = w2s(newVector)

        if fov ~= 180 then
            if rotation == engineAngles.y or rotation == engineAngles.y+(fov*2) then
                local x2, y2 = w2s(vector)
                if x ~= nil and x2 ~= nil and x ~= -1 and x2 ~= -1 then
                    renderLine(x, y, x2, y2, color)
                    for i = 0, 4 do
                        renderLine(x, y + i, x2, y2 + i, color)
                    end
                end
            end
        end

        if x ~= nil and oldX ~= nil and x ~= -1 and oldX ~= -1 then
            renderLine(x, y, oldX, oldY, color)
            for i = 0, 4 do
                renderLine(x, y + i, oldX, oldY + i, color)
            end
        end
        oldX, oldY = x, y
    end
end

function on_setup_command(cmd)

    local pLocal = getEntityByIndex(getLocalIndex());

    if pLocal and pLocal:is_valid() and ENABLE:get_value() then
        local absOrigin = pLocal:get_prop_vec3("m_vecOrigin");
        local enemiesInRange = 0;
        local enemies = 0;
        local replayGap = 1;
        local closestDistance = 9999;
        local fov = FOV:get_value()
        local fovRotation = FOV_ROTATION:get_value();
        local engineAngles = getEngineAngles();
        local maxDistance = DISTANCE:get_value();

        for i=1, 64, 1 do
            local pEntity = getEntityByIndex(i);

            if pEntity and pEntity:is_valid() then
                if pEntity:is_enemy() and not pEntity:is_dormant() then
                    enemies = enemies + 1;
                    local pEntityOrigin = pEntity:get_prop_vec3("m_vecOrigin");
                    local CalcAngles = calcAngle(absOrigin, pEntityOrigin);
                    local originDelta = sqrt((absOrigin.x-pEntityOrigin.x)^2 + (absOrigin.y-pEntityOrigin.y)^2);

                    if originDelta <= maxDistance then
                        CalcAngles.y = (CalcAngles.y - (engineAngles.y)+fovRotation);
                        CalcAngles = Normalize(CalcAngles);

                        if CalcAngles.y < 0 then
                            if CalcAngles.y >= (fov * -1) then
                                enemiesInRange = enemiesInRange + 1;
                                if originDelta < closestDistance then
                                    closestDistance = originDelta;
                                end
                            end
                        elseif CalcAngles.y > 0 then
                            if CalcAngles.y <= fov then
                                enemiesInRange = enemiesInRange + 1;
                                if originDelta < closestDistance then
                                    closestDistance = originDelta;
                                end
                            end
                        end
                    end
                end
            end
        end

        data["Localdata"]["AbsOrigin"] = absOrigin;
        data["Globaldata"]["EnemiesInRange"] = enemiesInRange;
        data["Globaldata"]["Enemies"] = enemies;

        if DISTANCEBASED:get_value() then
            replayGap = 0.1 + ((0.8) * (closestDistance / 1000));
        end

        if enemiesInRange > 0 and data["Globaldata"]["LastBeep"] < global_vars.realtime - replayGap then
            local button = data["Sounds"][SOUND:get_value()]
            local vol = VOLUME:get_value() / 100

            if DISTANCEBASEDVOLUME:get_value() then
                vol = (1 - (closestDistance / 1000)) * vol
            end
            gameCommand("playvol buttons/".. button .. " " .. vol)
            data["Globaldata"]["LastBeep"] = global_vars.realtime;
        end
    end
end

function on_paint()
    if ENABLE:get_value() then
        if VISUALIZE_FOV:get_value() then

            drawFOV(data["Localdata"]["AbsOrigin"], DISTANCE:get_value());
        end
    end
end