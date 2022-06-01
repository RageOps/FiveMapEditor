local objectSets
local removeSets
local placedObjects

RegisterNetEvent('MapEdit:SendObjectSets', function(sets)
    objectSets = sets
end)

RegisterNetEvent('MapEdit:SendRemoveSets', function(sets)
    removeSets = sets
end)

RegisterNetEvent('MapEdit:SendPlacedObjects', function(sets)
    placedObjects = sets
end)

-- object streamer
local function isNearObject(p1, obj)
	local diff = obj.pos - p1
	local dist = (diff.x * diff.x) + (diff.y * diff.y)

	return (dist < (500 * 500))
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
        if objectSets then
            -- spawn objects
            local pos = GetEntityCoords(PlayerPedId())

            for i, obj in pairs(objectSets) do
                local shouldHave = isNearObject(pos, obj)

                if shouldHave and not obj.object then
                    local o = CreateObjectNoOffset(obj.hash, obj.pos, true, true, false)

                    if o then
                        SetEntityRotation(o, obj.rot, 2, true)
                        FreezeEntityPosition(o, true)
                        SetObjectForceVehiclesToAvoid(o, true)

                        obj.object = o
                    end
                elseif not shouldHave and obj.object then
                    DeleteObject(obj.object)
                    obj.object = nil
                end

                if (i % 75) == 0 then
                    Citizen.Wait(15)
                end
            end
        else
            Wait(500)
            TriggerServerEvent('MapEdit:GetObjectSets')
        end
	end
end)

Citizen.CreateThread(function()
    while true do
        Wait(500)
        if removeSets and placedObjects then
            local pos = GetEntityCoords(PlayerPedId())
            for k, v in pairs(removeSets) do
                v.pos = vector3(v.pos.x, v.pos.y, v.pos.z)
                if #(pos - v.pos) < 150 then
                    local ent = GetClosestObjectOfType(v.pos, 1.5, v.model, false, false, false)
                    SetEntityAsMissionEntity(ent, 1, 1)
                    DeleteObject(ent)
                    SetEntityAsNoLongerNeeded(ent)
                end
            end

            for k, v in pairs(placedObjects) do
                local pedPos = GetEntityCoords(PlayerPedId())
                local model = v[1]
                local coords = v[2]
                local h = v[3]
                local pos = vector3(coords.x, coords.y, coords.z)
                local heading = vector3(h.x, h.y, h.z)
                if #(pos - pedPos) < 80 and not v.object then
                    local obj = CreateObjectNoOffset(model, pos, true, true)
                    if obj then
                        SetEntityHeading(obj, heading)
                        FreezeEntityPosition(obj, true)
                        SetObjectForceVehiclesToAvoid(obj, true)

                        v.object = obj
                    end
                elseif #(pos - pedPos) > 80 and v.object then
                    local ent = GetClosestObjectOfType(pos, 1.5, model, false, false, false)
                    SetEntityAsMissionEntity(ent, 1, 1)
                    DeleteObject(ent)
                    SetEntityAsNoLongerNeeded(ent)
                    v.object = nil
                end
            end
        else
            Wait(1500)
            TriggerServerEvent('MapEdit:GetRemoveSets')
            TriggerServerEvent('MapEdit:GetPlacedObjects')
        end
    end
end)