Camera = {}
local cam
local camYaw = 200.0
local camPitch = -10.0
local camDist = 5.5
local targetVehicle
local running = false

local function refresh()
    if not cam or not DoesEntityExist(targetVehicle) then return end

    local vehCoords = GetEntityCoords(targetVehicle)
    local height = vehCoords.z + (Config.Camera and Config.Camera.defaultHeight or 0.6)

    local radYaw = math.rad(camYaw)
    local radPitch = math.rad(camPitch)
    local cosP = math.cos(radPitch)
    local x = vehCoords.x + math.cos(radYaw) * cosP * camDist
    local y = vehCoords.y + math.sin(radYaw) * cosP * camDist
    local z = height + math.sin(radPitch) * camDist

    SetCamCoord(cam, x, y, z)
    PointCamAtCoord(cam, vehCoords.x, vehCoords.y, height)
end

function Camera.start(vehicle)
    if running then return end
    targetVehicle = vehicle
    camYaw = GetEntityHeading(vehicle) - 160.0
    camPitch = -10.0
    camDist = Config.Camera and Config.Camera.defaultDist or 5.5

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    running = true

    refresh()
    CreateThread(function()
        while running do
            refresh()
            Wait(0)
        end
    end)
end

function Camera.stop()
    running = false
    if cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cam, true)
        cam = nil
    end
    targetVehicle = nil
end

function Camera.rotate(dx, dy)
    if not running then return end
    camYaw = (camYaw + dx) % 360
    camPitch = math.max(-60.0, math.min(25.0, camPitch - dy))
end

function Camera.zoom(delta)
    if not running then return end
    local minD = (Config.Camera and Config.Camera.minDist) or 3.0
    local maxD = (Config.Camera and Config.Camera.maxDist) or 9.0
    camDist = math.max(minD, math.min(maxD, camDist + delta))
end

function Camera.isRunning()
    return running
end
