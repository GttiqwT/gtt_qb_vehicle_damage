local QBCore = exports['qb-core']:GetCoreObject()
local VehicleData = {} -- [uuid] = { engine = float, body = float }
local saveFile = 'data/vehicle_health.json'

-- Load saved vehicle data from JSON
local function LoadVehicleData()
    local file = LoadResourceFile(GetCurrentResourceName(), saveFile)
    if file then
        VehicleData = json.decode(file) or {}
    else
        VehicleData = {}
    end
end

-- Save vehicle data to JSON
local function SaveVehicleData()
    SaveResourceFile(GetCurrentResourceName(), saveFile, json.encode(VehicleData), -1)
end

-- Initial load
LoadVehicleData()

-- Sync vehicle to client when first entering
RegisterNetEvent('qb-vehicle-damage:server:syncVehicle', function(uuid, netId)
    local src = source
    local vehHealth = VehicleData[uuid]
    if vehHealth then
        TriggerClientEvent('qb-vehicle-damage:client:setVehicleHealth', src, netId, vehHealth.engine, vehHealth.body)
    else
        -- Initialize if not found
        VehicleData[uuid] = { engine = 1000.0, body = 1000.0 }
        SaveVehicleData()
    end
end)

-- Update vehicle health from client
RegisterNetEvent('qb-vehicle-damage:server:updateVehicleHealth', function(uuid, engine, body)
    VehicleData[uuid] = { engine = engine, body = body }
    SaveVehicleData()
    -- Broadcast to all clients
    TriggerClientEvent('qb-vehicle-damage:client:setVehicleHealthForAll', -1, uuid, engine, body)
end)

-- Optional: command to force save all vehicle data manually
QBCore.Commands.Add('savevehicledata', 'Force save vehicle health', {}, false, function(source, args)
    SaveVehicleData()
    QBCore.Functions.Notify(source, 'Vehicle data saved!', 'success')
end)

-- AUTO SAVE VEHICLE DATA EVERY 60 SECONDS
CreateThread(function()
    while true do
        Wait(60000) -- 60 seconds
        SaveVehicleData()
        print('[qb-vehicle-damage] Vehicle data auto-saved.')
    end
end)
