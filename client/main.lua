local currentZone = nil
local GravePrompt
local hasAlreadyEnteredMarker
local grave
local SucceededAttempts = 0
local NeededAttempts = 4

local PromptGorup = GetRandomIntInRange(0, 0xffffff)

function SetupGravePrompt()
    Citizen.CreateThread(function()
        local str = 'Dig Grave'
        GravePrompt = PromptRegisterBegin()
        PromptSetControlAction(GravePrompt, 0x27D1C284)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(GravePrompt, str)
        PromptSetEnabled(GravePrompt, 1)
        PromptSetVisible(GravePrompt, 1)
        PromptSetStandardMode(GravePrompt, 1)
        PromptSetGroup(GravePrompt, PromptGorup)
        PromptRegisterEnd(GravePrompt)
    end)
end

function AttachEnt(from, to, boneIndex, x, y, z, pitch, roll, yaw, useSoftPinning, collision, vertex, fixedRot)
    return AttachEntityToEntity(from, to, boneIndex, x, y, z, pitch, roll, yaw, false, useSoftPinning, collision, false, vertex, fixedRot, false, false)
end

function DigGrave()
    exports['qbr-core']:TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local playerPed = PlayerPedId()
            local Skillbar = exports['qbr-skillbar']:GetSkillbarObject()
            local playerCoords = GetEntityCoords(PlayerPedId())
            local shovelObject = CreateObject(Config.Dig.model, playerCoords.x, playerCoords.y, playerCoords.z, true, true, true) 
            RequestAnimDict(Config.Dig.anim[1])
            TaskPlayAnim(playerPed, Config.Dig.anim[1], Config.Dig.anim[2], 1.0, 1.0, -1, 1, 0, false, false, false)
            AttachEntityToEntity(shovelObject, playerPed, GetEntityBoneIndexByName(playerPed, Config.Dig.bone), Config.Dig.pos[1], Config.Dig.pos[2], Config.Dig.pos[3], Config.Dig.pos[4], Config.Dig.pos[5], Config.Dig.pos[6], false, 0, 1, false, 1, 1, false, false)
            ---------------------------
            Skillbar.Start({
                duration = math.random(7500, 15000),
                pos = math.random(10, 30),
                width = math.random(10, 20),
            }, function()
                if SucceededAttempts + 1 >= NeededAttempts then
                    DeleteObject(shovelObject)
                    ClearPedTasksImmediately(PlayerPedId())
                    TriggerServerEvent('gp_grave:server:giveitem')
                    for k, v in pairs(Config.Graves) do 
                        if k == grave then
                            v.robbed = true
                        end
                    end
                else
                    Skillbar.Repeat({
                        duration = math.random(700, 1250),
                        pos = math.random(10, 40),
                        width = math.random(10, 13),
                    })
                    SucceededAttempts = SucceededAttempts + 1
                end
            end, function()
                DeleteObject(shovelObject)
                ClearPedTasksImmediately(PlayerPedId())
                exports['gp_notify']:SendNotify('Failed', '1500')
                SucceededAttempts = 0
            end)
            ------------------------------
        else
            exports['gp_notify']:SendNotify('You don´t have a shovel', '2500')
        end
    end, 'shovel')
end

Citizen.CreateThread(function()
    SetupGravePrompt()
	while true do
		Wait(500)
		local isInMarker, tempZone = false
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for k, v in pairs(Config.Graves) do 
            local distance = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
            if distance < 1.5 and not v.robbed then
                isInMarker  = true
                tempZone = 'Grave'
                grave = k
            end
		end

		if isInMarker and not hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = true
			currentZone = tempZone
		end

		if not isInMarker and hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = false
			currentZone = nil
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

        if currentZone then
            local label  = CreateVarString(10, 'LITERAL_STRING', "Grave")
            PromptSetActiveGroupThisFrame(PromptGorup, label)
            if PromptHasStandardModeCompleted(GravePrompt) then
                DigGrave()
                currentZone = nil
            end
        else
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        PromptSetEnabled(GravePrompt, false)
        PromptSetVisible(GravePrompt, false)
    end
end)