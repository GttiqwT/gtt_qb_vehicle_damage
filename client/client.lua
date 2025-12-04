----------------------------------
-- FIVEM QB-CORE VEHICLE DAMAGE SCRIPT (Fully Integrated UUID-based Vehicle Damage Script)
-- Version 1.0 // 12/03/25
-- Published by: GttiqwT
-- Made mostly using chatgpt
-- Very configurable, adds repair command, notifications with custom colours etc.
----------------------------------

local QBCore = exports['qb-core']:GetCoreObject()
math.randomseed(GetGameTimer())

local VehicleStates = {}      -- [netId] = { lastEngine, lastBody, uuid, smokeNotified, disabledNotified }
local RepairUses = {}         -- [uuid] = number of times repaired
local RepairCooldownActive = {} -- [uuid] = cooldown end timestamp

----------------------------------
-- UTILITIES
----------------------------------
local function GenerateVehicleUUID(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local coords = GetEntityCoords(vehicle)
    return plate .. '_' .. math.floor(coords.x*100) .. math.floor(coords.y*100) .. math.floor(coords.z*100) .. '_' .. math.random(1000,9999)
end

local function SetVehicleSmoke(vehicle, enabled)
    if enabled then
        UseParticleFxAssetNextCall('core')
        StartParticleFxLoopedOnEntity('exp_grd_petrol_pump_spawn', vehicle, 0.0,0.0,0.0,0,0,0,1.0,false,false,false) -- x,y,z
    end
end

----------------------------------
-- SERVER SYNC EVENTS
----------------------------------
RegisterNetEvent('qb-vehicle-damage:client:setVehicleHealth', function(netId, engine, body)
    local veh = NetToVeh(netId)
    if DoesEntityExist(veh) then
        SetVehicleEngineHealth(veh, engine)
        SetVehicleBodyHealth(veh, body)
    end
end)

RegisterNetEvent('qb-vehicle-damage:client:setVehicleHealthForAll', function(uuid, engine, body)
    for netId, state in pairs(VehicleStates) do
        if state.uuid == uuid then
            local veh = NetToVeh(netId)
            if DoesEntityExist(veh) then
                SetVehicleEngineHealth(veh, engine)
                SetVehicleBodyHealth(veh, body)
            end
        end
    end
end)

----------------------------------
-- DAMAGE CHECK THREAD
----------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped,false)

        if veh ~= 0 and GetPedInVehicleSeat(veh,-1) == ped then
            local netId = VehToNet(veh)
            if not VehicleStates[netId] then
                local uuid = GenerateVehicleUUID(veh)
                VehicleStates[netId] = { lastEngine=GetVehicleEngineHealth(veh), lastBody=GetVehicleBodyHealth(veh), uuid=uuid, smokeNotified=false, disabledNotified=false }
                TriggerServerEvent('qb-vehicle-damage:server:syncVehicle', uuid, netId)
            end

            local state = VehicleStates[netId]
            local engineHealth = GetVehicleEngineHealth(veh)
            local bodyHealth = GetVehicleBodyHealth(veh)
            state.lastEngine = engineHealth
            state.lastBody = bodyHealth

            -- Send server update
            TriggerServerEvent('qb-vehicle-damage:server:updateVehicleHealth', state.uuid, engineHealth, bodyHealth)

            -- Determine smoke / disable
            local shouldSmoke = (engineHealth < Config.SmokeThreshold or bodyHealth < Config.BodySmokeThreshold) and (engineHealth > Config.DisableThreshold and bodyHealth > Config.BodyDisableThreshold)
            local shouldDisable = (engineHealth <= Config.DisableThreshold or bodyHealth <= Config.BodyDisableThreshold)

            -- Notifications
            if shouldSmoke and not state.smokeNotified then
                QBCore.Functions.Notify('Your vehicle is smoking!', Config.SmokeNotifyColor)
                state.smokeNotified = true
            elseif not shouldSmoke then state.smokeNotified = false end

            if shouldDisable and not state.disabledNotified then
                QBCore.Functions.Notify('Your vehicle is disabled!', Config.DisabledNotifyColor)
                state.disabledNotified = true
            elseif not shouldDisable then state.disabledNotified = false end

            -- Apply smoke / disable effects
            if shouldSmoke then
                SetVehicleEngineCanDegrade(veh,true)
                SetVehicleUndriveable(veh,false)
                SetVehicleEngineOn(veh,true,true,true)
                SetVehicleSmoke(veh,true)
            elseif shouldDisable then
                SetVehicleEngineOn(veh,false,true,true)
                SetVehicleUndriveable(veh,true)
            end
        end
    end
end)

----------------------------------
-- REPAIR COMMAND
----------------------------------
RegisterCommand(Config.RepairCommand,function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped,false)
    if veh == 0 then 
        QBCore.Functions.Notify('You must be in a vehicle to repair it.','error')
        return 
    end

    local netId = VehToNet(veh)
    local state = VehicleStates[netId]
    local uuid = state.uuid

    -- Check if player is on cooldown
    if RepairCooldownActive[uuid] then
        local remaining = math.ceil((RepairCooldownActive[uuid] - GetGameTimer()) / 1000)
        if remaining > 0 then
            QBCore.Functions.Notify("You have reached the repair limit! Wait " .. remaining .. " seconds.", "error")
            return
        else
            RepairCooldownActive[uuid] = nil
            RepairUses[uuid] = 0
        end
    end

    -- Calculate repair amounts
    local engineHealth = GetVehicleEngineHealth(veh)
    local bodyHealth = GetVehicleBodyHealth(veh)
    local newEngine = math.min(Config.MaxRepairEngine, engineHealth + Config.RepairAmount)
    local newBody = math.min(Config.MaxRepairBody, bodyHealth + Config.BodyRepairAmount)

    -- Start progress bar
    QBCore.Functions.Progressbar('repair_vehicle','Repairing Vehicle...',Config.RepairDuration,false,true,
        {disableMovement=true,disableCarMovement=true,disableMouse=false,disableCombat=true},
        {animDict='mini@repair',anim='fixing_a_ped',flags=49},{},{},
        function() -- SUCCESS
            -- Apply repairs
            SetVehicleEngineHealth(veh,newEngine)
            SetVehicleBodyHealth(veh,newBody)
            SetVehicleUndriveable(veh,false)
            SetVehicleEngineOn(veh,true,true,true)

            -- Random repair message
            local messages = {
                'You put in your last new spark plug, get to a mechanic!',
                'You tightened that loose bolt, now go to the mechanic!',
                'Looks like your exhaust fell off, get to a body shop ASAP!'
            }
            QBCore.Functions.Notify(messages[math.random(#messages)], Config.RepairMessageColor)

            -- Sync with server
            TriggerServerEvent('qb-vehicle-damage:server:updateVehicleHealth',uuid,newEngine,newBody)

            -- Increment uses and handle cooldown only if repair SUCCESS
            RepairUses[uuid] = (RepairUses[uuid] or 0) + 1

            if RepairUses[uuid] >= Config.MaxRepairUses then
                QBCore.Functions.Notify('You have reached the repair limit! Cooldown started.','error')
                RepairCooldownActive[uuid] = GetGameTimer() + (Config.RepairCooldown * 1000)
                
                SetTimeout(Config.RepairCooldown * 1000, function()
                    RepairUses[uuid] = 0
                    RepairCooldownActive[uuid] = nil
                    QBCore.Functions.Notify("Repair is available again!", "success")
                end)
            end
        end,
        function() -- CANCEL
            -- Do not increment uses or start cooldown
            QBCore.Functions.Notify('Repair cancelled.','error')
        end
    )
end,false)


----------------------------------
-- DEBUG OVERLAY
----------------------------------
CreateThread(function()
    while true do
        Wait(0)
        if Config.DebugEnabled then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped,false)
            if veh~=0 then
                local engineHealth = math.floor(GetVehicleEngineHealth(veh))
                local bodyHealth = math.floor(GetVehicleBodyHealth(veh))
                SetTextFont(0) SetTextProportional(1) SetTextScale(0.35,0.35) SetTextColour(255,255,255,200) SetTextOutline()
                SetTextRightJustify(true) SetTextWrap(0.0,0.98) BeginTextCommandDisplayText('STRING')
                AddTextComponentString('Engine: ~b~'..engineHealth..' ~s~| Body: ~g~'..bodyHealth)
                EndTextCommandDisplayText(0.98,0.05)
            end
        end
    end
end)
---------------------------------------------------------
--THIS IS A FREE SCRIPT. DO NOT REDISTRIBUTE OR SELL THIS.
--YOU MAY MODIFY THIS SCRIPT BUT PLEASE CREDIT ME, THANKS: GTTIQWT
---------------------------------------------------------