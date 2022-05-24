local objectSets
local removeSets

RegisterNetEvent('MapEdit:SendObjectSets', function(sets)
    objectSets = sets
end)

RegisterNetEvent('MapEdit:SendRemoveSets', function(sets)
    removeSets = sets
end)

-- object streamer
local function isNearObject(p1, obj)
	local diff = obj.pos - p1
	local dist = (diff.x * diff.x) + (diff.y * diff.y)

	return (dist < (400 * 400))
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
        if removeSets then
            for k, v in pairs(removeSets) do
                local pos = GetEntityCoords(PlayerPedId())
                v.pos = vector3(v.pos.x, v.pos.y, v.pos.z)
                if #(pos - v.pos) < 150 then
                    local ent = GetClosestObjectOfType(v.pos, 1.5, v.model, false, false, false)
                    SetEntityAsMissionEntity(ent, 1, 1)
                    DeleteObject(ent)
                    SetEntityAsNoLongerNeeded(ent)
                end
            end
        else
            Wait(1500)
            TriggerServerEvent('MapEdit:GetRemoveSets')
        end
    end
end)