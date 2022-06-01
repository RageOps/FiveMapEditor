path = GetResourcePath(GetCurrentResourceName()) .. '/data/'
objects = {}

if not io.open(path .. 'objects.json') then
    local file = io.output(path .. 'objects.json') -- Create the objects.json file if it is not already created
    io.close(file)
end
if not io.open(path .. 'removables.json') then
    local file = io.output(path .. 'removables.json') -- Create the removables.json file if it is not already created
    io.close(file)
end

-- Create Objects in a serversided manner from save file
--[[Citizen.CreateThread(function()
    local ped
    local fire = false
    repeat -- Wait until a player exists on the server to create the objects since CreateObject is RPC
        local players = GetPlayers()
        for k,v in pairs(players) do
            if GetPlayerPed(v) ~= 0 then
                while not DoesEntityExist(GetPlayerPed(v)) do
                    Wait(100)
                end
                fire = true
                break
            end
        end
        Wait(2000)
    until fire

    local file = io.open(path .. 'objects.json', 'r+')
        local data = file:read('a')
        io.close(file)
        local table = json.decode(data)

        for k,v in pairs(table) do
            Wait(10)
            local model, coords, heading = v[1], vector3(v[2].x, v[2].y, v[2].z), vector3(v[3].x, v[3].y, v[3].z) -- heading goes in as vector for some reason
            TriggerEvent('MapEdit:SpawnObject', model, coords, heading, false) -- False since all of these objects are already in the save file
        end
end)]]

Citizen.CreateThread(function()
    local file = io.open(path .. 'objects.json', 'r+')
    local data = file:read('a')
    io.close(file)
    objects = json.decode(data)
end)


-- Events

RegisterNetEvent('MapEdit:GetIsAllowed', function()
    if IsPlayerAceAllowed(source, 'command') then -- Checks if the source has permission to run restricted commands
        TriggerClientEvent('MapEdit:ClientConfirm', source)
    end
end)

RegisterNetEvent('MapEdit:GetPlacedObjects', function()
    TriggerClientEvent('MapEdit:SendPlacedObjects', source, objects)
end)

RegisterNetEvent('MapEdit:SpawnObject', function(model, coords, heading, save)
    if save then
        TriggerClientEvent('MapEdit:CreateObject_cl', -1, model, coords, heading)
        AddObjectToSave(model, coords, heading) -- If the object was successfully created, save it
    else
        local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true) -- Create the object
        while not DoesEntityExist(obj) do
            Wait(10)
        end
        SetEntityHeading(obj, heading)
        FreezeEntityPosition(obj, true)
    end
end)

RegisterNetEvent('MapEdit:DeleteObject', function(netid)
    local ent = NetworkGetEntityFromNetworkId(netid)
    local coords = GetEntityCoords(ent)
    DeleteEntity(ent)
    if ent then
        RemoveObjectFromSave(coords) -- If an entity was found, remove it from the save file
    end
end)

RegisterNetEvent('MapEdit:AddObjectToRemove', function(model, coords)
    local newObject = { -- Create the table for our new object
        ['model'] = model,
        ['pos'] = coords,
    }

    local file = io.open(path .. 'removables.json', 'r+') -- Open our file and read it all in
    local data = file:read('a')
    io.close(file)
    local table = json.decode(data)

    if not table then
        table = {}
    end
    table[#table + 1] = newObject -- Add our new object to our existing json data

    local file = io.open(path .. 'removables.json', 'w+') -- Put the table with the new object back into the json file
    file:write(json.encode(table))
    io.close(file)
    TriggerEvent('MapEdit:GetRemoveSets')
end)

-- Functions

AddObjectToSave = function(model, coords, heading)
    local newObject = { -- Create the table for our new object
        model,
        coords,
        heading,
    }

    local file = io.open(path .. 'objects.json', 'r+') -- Open our file and read it all in
    local data = file:read('a')
    io.close(file)
    local table = json.decode(data)

    if not table then
        table = {}
    end
    table[#table + 1] = newObject -- Add our new object to our existing json data

    local file = io.open(path .. 'objects.json', 'w+') -- Put the table with the new object back into the json file
    file:write(json.encode(table))
    io.close(file)
end

RemoveObjectFromSave = function(coords)
    local file = io.open(path .. 'objects.json', "r+")
    local data = file:read("a")
    io.close(file)
    local array = json.decode(data)

    local moe = 0.002 -- Margin of Error
    for i=1,3 do
        moe = moe * 5 -- Increase margin of error iteratively to accomodate for discrepancies in concatenation
        for k,v in pairs(array) do
            local math = #(coords - vector3(v[2].x, v[2].y, v[2].z))    -- Get dist between the coords we are checking
            
            if math < moe and math > (0 - moe) then
                table.remove(array, k)                                         -- If coords are close enough then remove from table
                
                local file = io.open(path .. 'objects.json', 'w+')              -- Put the array with the new object back into the json file
                file:write(json.encode(array))
                io.close(file)
                return
            end
        end
    end
end

RemoveObjectFromSave2 = function(coords, model) -- Cleanup the save file if duplicate removables are created
    local file = io.open(path .. 'removables.json', "r+")
    local data = file:read("a")
    io.close(file)
    local array = json.decode(data)

    local moe = 0.002 -- Margin of Error
    for i=1,3 do
        moe = moe * 5 -- Increase margin of error iteratively to accomodate for discrepancies in concatenation
        for k,v in pairs(array) do
            local math = #(coords - vector3(v.pos.x, v.pos.y, v.pos.z))    -- Get dist between the coords we are checking
            
            if math < moe and math > (0 - moe) and v.model == model then
                print('removed')
                table.remove(array, k)                                         -- If coords are close enough then remove from table
                
                local file = io.open(path .. 'removables.json', 'w+')              -- Put the array with the new object back into the json file
                file:write(json.encode(array))
                io.close(file)
                return
            end
        end
    end
end

-- Commands
