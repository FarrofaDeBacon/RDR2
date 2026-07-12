-- ============================================================
-- fdb-hud | c/vehicle.lua
-- Detecta entrada/saída de veículo e envia dados de veículo à NUI
-- ============================================================

local inVehicle = false
local lastVehicleData = {}

local function knotsToKmh(knots) return knots * 1.852 end
local function knotsToMph(knots) return knots * 1.15078 end

local function GetSpeed(vehicle)
    local raw = GetEntitySpeed(vehicle) * 1.943844  -- m/s → nós
    if Config.VehicleHud.speedUnit == 'mph' then
        return math.floor(knotsToMph(raw))
    end
    return math.floor(knotsToKmh(raw))
end

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        if not isLoggedIn or not Config.VehicleHud.enabled then goto continue end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local nowIn   = vehicle ~= 0

        if nowIn ~= inVehicle then
            inVehicle = nowIn
            SendNUI('setVehicleVisible', inVehicle)
        end

        if inVehicle then
            local data = {
                speed    = GetSpeed(vehicle),
                gear     = GetVehicleCurrentGear(vehicle),
                rpm      = math.floor(GetVehicleCurrentRpm(vehicle) * 100),
                unit     = Config.VehicleHud.speedUnit,
            }
            if data.speed ~= (lastVehicleData.speed or -1) then
                lastVehicleData = data
                SendNUI('updateVehicle', data)
            end
        end

        ::continue::
    end
end)
