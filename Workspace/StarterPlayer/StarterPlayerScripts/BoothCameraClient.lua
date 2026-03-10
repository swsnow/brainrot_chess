local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function findMarkerByName(name)
	local arena = workspace:FindFirstChild("ChessArena")
	return arena and arena:FindFirstChild(name)
end

local function setCustomCamera()
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
end

local function applyCamera()
	local mode = player:GetAttribute("CameraMode")
	local side = player:GetAttribute("ChessSide")

	if mode == "Booth" then
		local markerName = nil

		if side == "White" then
			markerName = "PlayerBox_Blue_CameraMarker"
		elseif side == "Black" then
			markerName = "PlayerBox_Red_CameraMarker"
		end

		if markerName then
			local marker = findMarkerByName(markerName)
			if marker then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = marker.CFrame
				return
			end
		end
	end

	setCustomCamera()
end

player:GetAttributeChangedSignal("CameraMode"):Connect(function()
	task.wait()
	applyCamera()
end)

player:GetAttributeChangedSignal("ChessSide"):Connect(function()
	task.wait()
	applyCamera()
end)

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyCamera()
end)

RunService.RenderStepped:Connect(function()
	if player:GetAttribute("CameraMode") == "Booth" then
		local side = player:GetAttribute("ChessSide")
		local markerName = side == "White" and "PlayerBox_Blue_CameraMarker" or side == "Black" and "PlayerBox_Red_CameraMarker" or nil
		if markerName then
			local marker = findMarkerByName(markerName)
			if marker then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = marker.CFrame
			end
		end
	end
end)
