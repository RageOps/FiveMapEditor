local mapCreating = false
local placeMode = true
local controlsDisable = {38, 46, 51, 54, 86, 103, 119, 153, 184, 206, 350, 351, 355, 356,   -- E
                        45, 81, 140, 250, 263, 310,                                         -- R
                        14, 15, 16, 17, 27, 50, 99, 115, 180, 181, 198, 241, 242, 261, 262, 335, -- Scroll wheel stuff
                        191,                                                                -- Enter
                        47,                                                                 -- G
                        36,                                                                 -- LControl
                        }
local color = {r = 255, g = 255, b = 255, a = 200}
local editorCoords = {}
local editorHeading = 45
local editorModel = nil
local editorObject = nil
local count = 0
local hasResult = false
local DeleteObjectMode = false -- Change to true if you want to be able to permanently remove world props with "R"

-- Commands

RegisterCommand('addprop', function(source, args) -- Legacy but still usable
    SpawnObject(args[1])
end)

RegisterCommand('edit', function(source, args)
    if not mapCreating then
        mapCreating = true
        if not editorModel then
            GetUserInput()
        end
        StartEditor()
    else
        mapCreating = false
    end
end)
RegisterKeyMapping('edit', 'Toggle the Map Editor', 'keyboard', 'U')


-- Functions

SpawnObject = function(model, coords, heading)
    local model = model
    local coords = coords
    local heading = heading
    local ped = PlayerPedId()
    
    if model then
        model = GetHashKey(model)
        if coords then
            if heading then
                TriggerServerEvent('MapEdit:SpawnObject', model, coords, heading, true)
            else
                TriggerServerEvent('MapEdit:SpawnObject', model, coords, 0, true)
            end
        else
            coords = GetEntityCoords(ped)
            heading = GetEntityHeading(ped)

            TriggerServerEvent('MapEdit:SpawnObject', model, coords, heading, true)
        end
    end
end

StartEditor = function()

    if not IsModelInCdimage(editorModel) then
        return
    end

    LoadModel(editorModel)

    Citizen.CreateThread(function() -- Main thread
        local ped = PlayerPedId()
        local editorHeading = GetGameplayCamRot()
        
        while mapCreating do
            Wait(0)
            if placeMode or count < 2 then
                count = count + 1
            end

            -- Disable certain controls during editing
            DisableControls()

            -- Draw Instructional Overlay
            local buttons = SetupScaleform("instructional_buttons")
            DrawScaleformMovieFullscreen(buttons)
            
            -- Delete the old object that was created
            if placeMode and count >= 3 or not placeMode and count ~= 0 then -- Will catch if for some reason switching from place mode to remove mode messes up the count
                DeleteEntity(editorObject)
                count = 0
            end

            -- Draw the line from the player to the result of the raycast
            local position = GetEntityCoords(ped)
            local hit, coords, entity = RayCastGamePlayCamera(1000.0)
            if placeMode then
                color = {r = 255, g = 255, b = 255, a = 200}
            else
                color = {r = 199, g = 34, b = 34, a = 200}
            end
            DrawLine(position.x, position.y, position.z + 0.5, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)

            -- Handle control input
            local scrollAmount = 5
            if IsControlPressed(1, 21) then -- LShift
                scrollAmount = 25
            elseif IsDisabledControlPressed(1, 36) then -- LControl
                scrollAmount = 1
            end
            if IsDisabledControlJustPressed(1, 16) then -- Scrollwheel down
                editorHeading = editorHeading + scrollAmount
            elseif IsDisabledControlJustPressed(1, 17) then -- Scrollwheel up
                editorHeading = editorHeading - scrollAmount
            end

            if IsDisabledControlJustReleased(1, 38) then -- E
                if placeMode then
                    TriggerServerEvent('MapEdit:SpawnObject', editorModel, editorCoords, editorHeading, true)
                else
                    local netid = NetworkGetNetworkIdFromEntity(entity)
                    if not netid then
                        local ent = entity
                        SetEntityAsMissionEntity(ent, 1, 1)
                        DeleteObject(ent)
                        SetEntityAsNoLongerNeeded(ent)
                    end
                    TriggerServerEvent('MapEdit:DeleteObject', netid)
                end
            end

            if IsDisabledControlJustPressed(1, 47) then -- G
                placeMode = not placeMode
                count = 0
            end

            if DeleteObjectMode then
                if IsDisabledControlJustPressed(1, 45) then -- R
                    local ent = entity
                    local entModel = GetEntityModel(ent)
                    local entCoords = GetEntityCoords(ent)
                    SetEntityAsMissionEntity(ent, 1, 1)
                    DeleteObject(ent)
                    SetEntityAsNoLongerNeeded(ent)
                    TriggerServerEvent('MapEdit:AddObjectToRemove', entModel, entCoords)
                    print(entModel)
                end 
            end

            if IsDisabledControlJustPressed(1, 191) then -- Enter
                GetUserInput()
            end
            
            -- Handle the drawing of the object
            if placeMode and count == 0 then
                editorCoords = coords
                editorObject = CreateTempObject(editorModel, editorCoords, editorHeading)
            end
        end
        
        SetModelAsNoLongerNeeded(editorModel)
        DeleteEntity(editorObject)
        editorObject = nil
    end)
end

GetUserInput = function()
    SendNUIMessage({
        type = "ui",
        display = true
    })
    SetNuiFocus(true, true)
    repeat
        Wait(10)
    until hasResult
end

CreateTempObject = function(model, coords, heading)
    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true)
    SetEntityHeading(obj, heading)
    return obj
end

CreatePermObject = function(model, coords, heading)
    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true) -- client sided creation because it's less prone to breaking
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
end
RegisterNetEvent('MapEdit:CreateObject_cl', CreatePermObject)

RayCastGamePlayCamera = function(distance) -- from qb-core
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
    local adjustedRotation = {
		x = (math.pi / 180) * cameraRotation.x,
		y = (math.pi / 180) * cameraRotation.y,
		z = (math.pi / 180) * cameraRotation.z
	}
	local direction = {
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	local destination = {
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end

DisableControls = function()
    for k,v in pairs(controlsDisable) do
        DisableControlAction(2, v, true)
    end
end

LoadModel = function(modelHash) -- from qb-core
    if not HasModelLoaded(modelHash) then
		-- If the model isnt loaded we request the loading of the model and wait that the model is loaded
		RequestModel(modelHash)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(1)
		end
	end
end

SetupScaleform = function() -- from qb-adminmenu
    local scaleform = RequestScaleformMovie("instructional_buttons")

    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(1)
    end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    local order = 0 -- Keep all of our buttons in order

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(1, 303, true)) -- Scroll Wheel
    ButtonMessage("Close Editor")
    PopScaleformMovieFunctionVoid()
    order = order + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(2, 47, true)) -- G
    local message
    if placeMode then
        message = "Switch to Remove Mode"
    else
        message = "Switch to Place Mode"
    end
    ButtonMessage(message)
    PopScaleformMovieFunctionVoid()
    order = order + 1
    
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(1, 191, true)) -- Enter
    ButtonMessage("Change Prop")
    PopScaleformMovieFunctionVoid()
    order = order + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(1, 21, true)) -- Left Shift
    ButtonMessage("Faster Rotation")
    PopScaleformMovieFunctionVoid()
    order = order + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(1, 36, true)) -- Left Ctrl
    ButtonMessage("Slower Rotation")
    PopScaleformMovieFunctionVoid()
    order = order + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(1, 14, true)) -- Scroll Wheel
    Button(GetControlInstructionalButton(1, 15, true))
    ButtonMessage("Rotate Prop")
    PopScaleformMovieFunctionVoid()
    order = order + 1

    local message
    if placeMode then
        message = "Place Prop"
    else
        message = "Delete Prop"
    end
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(order)
    Button(GetControlInstructionalButton(2, 38, true))
    ButtonMessage(message)
    PopScaleformMovieFunctionVoid()
    order = order + 1


    --[[
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(5)
    Button(GetControlInstructionalButton(2, Config.NoClip.controls.openKey, true))
    ButtonMessage("Disable Noclip")
    PopScaleformMovieFunctionVoid()
    ]]

    --[[PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(4)
    Button(GetControlInstructionalButton(2, 38, true)) -- E
    ButtonMessage("Place Prop")
    PopScaleformMovieFunctionVoid()]]

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

Button = function(ControlButton) -- from qb-adminmenu
    N_0xe83a3e3557a56640(ControlButton)
end

ButtonMessage = function(text) -- from qb-adminmenu
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end


-- Callbacks

RegisterNUICallback('MapEdit:CloseUI', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('MapEdit:GetInput', function(data, cb)
    local tryNum = tonumber(data.text)
    if type(tryNum) == 'number' then
        editorModel = tryNum
    else
        editorModel = GetHashKey(data.text)
    end
    if not IsModelInCdimage(editorModel) then
        cb(false)
    else
        hasResult = true
        SetNuiFocus(false, false)
        cb(true)
    end
end)