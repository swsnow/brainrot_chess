local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsStudio() then
	return
end

local debugEvent = ReplicatedStorage:WaitForChild("ChessDebugCommand")

local function getArena()
	return workspace:FindFirstChild("ChessArena")
end

local function getArenaPart(name)
	local arena = getArena()
	return arena and arena:FindFirstChild(name)
end

local function teleportCharacterTo(character, marker, boardCenter)
	if not character or not marker or not boardCenter then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local pos = marker.Position + Vector3.new(0, 0.5, 0)
	character:PivotTo(CFrame.lookAt(pos, boardCenter.Position))
end

local function setPlayerRole(player, role)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local blueSpawn = getArenaPart("PlayerBox_Blue_SpawnMarker")
	local redSpawn = getArenaPart("PlayerBox_Red_SpawnMarker")
	local boardCenter = getArenaPart("BoardCenter")

	if not boardCenter then
		warn("DebugCommands: BoardCenter not found")
		return
	end

	if role == "blue" then
		if not blueSpawn then
			warn("DebugCommands: PlayerBox_Blue_SpawnMarker not found")
			return
		end

		player:SetAttribute("ChessSide", "White")
		player:SetAttribute("BoothColor", "Blue")
		player:SetAttribute("InChessMatch", true)
		player:SetAttribute("CameraMode", "Booth")

		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		end

		teleportCharacterTo(character, blueSpawn, boardCenter)

	elseif role == "red" then
		if not redSpawn then
			warn("DebugCommands: PlayerBox_Red_SpawnMarker not found")
			return
		end

		player:SetAttribute("ChessSide", "Black")
		player:SetAttribute("BoothColor", "Red")
		player:SetAttribute("InChessMatch", true)
		player:SetAttribute("CameraMode", "Booth")

		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		end

		teleportCharacterTo(character, redSpawn, boardCenter)

	elseif role == "spectator" then
		player:SetAttribute("ChessSide", "Spectator")
		player:SetAttribute("BoothColor", "None")
		player:SetAttribute("InChessMatch", false)
		player:SetAttribute("CameraMode", "Spectator")

		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(0, 20, 85)
		end

	elseif role == "freelook" then
		player:SetAttribute("CameraMode", "FreeLook")
		player:SetAttribute("InChessMatch", false)

		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end

	elseif role == "noclip" then
		player:SetAttribute("ChessSide", "Spectator")
		player:SetAttribute("BoothColor", "None")
		player:SetAttribute("InChessMatch", false)
		player:SetAttribute("CameraMode", "FreeLook")
		player:SetAttribute("DebugNoClip", true)

		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(0, 18, 65)
		end

	elseif role == "walk" then
		player:SetAttribute("CameraMode", "FreeLook")
		player:SetAttribute("DebugNoClip", false)

		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end
	end
end

debugEvent.OnServerEvent:Connect(function(player, command)
	if type(command) ~= "string" then
		return
	end

	setPlayerRole(player, command:lower())
end)
