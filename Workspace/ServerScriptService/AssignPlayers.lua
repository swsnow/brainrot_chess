local Players = game:GetService("Players")

local ARENA_NAME = "ChessArena"
local RED_MARKER_NAME = "PlayerBox_Red_SpawnMarker"
local BLUE_MARKER_NAME = "PlayerBox_Blue_SpawnMarker"

local sideAssignments = {
	White = nil,
	Black = nil,
}

local function assignSide(player)
	if not sideAssignments.White then
		sideAssignments.White = player
		player:SetAttribute("ChessSide", "White")
		player:SetAttribute("BoothColor", "Blue")
	elseif not sideAssignments.Black then
		sideAssignments.Black = player
		player:SetAttribute("ChessSide", "Black")
		player:SetAttribute("BoothColor", "Red")
	else
		player:SetAttribute("ChessSide", "Spectator")
		player:SetAttribute("BoothColor", "None")
	end
end

local function getArenaParts()
	local arena = workspace:FindFirstChild(ARENA_NAME)
	if not arena then
		return nil, nil, nil, nil
	end

	local redMarker = arena:FindFirstChild(RED_MARKER_NAME)
	local blueMarker = arena:FindFirstChild(BLUE_MARKER_NAME)
	local boardCenter = arena:FindFirstChild("BoardCenter")

	return arena, redMarker, blueMarker, boardCenter
end

local function getSpawnForPlayer(player, blueMarker, redMarker)
	local side = player:GetAttribute("ChessSide")
	if side == "White" then
		return blueMarker
	elseif side == "Black" then
		return redMarker
	end
	return nil
end

local function setupCharacter(player, character)
	local arena, redMarker, blueMarker, boardCenter = getArenaParts()
	if not arena or not redMarker or not blueMarker or not boardCenter then
		warn("Arena or spawn markers missing")
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	local spawnMarker = getSpawnForPlayer(player, blueMarker, redMarker)

	if spawnMarker then
		local pos = spawnMarker.Position + Vector3.new(0, 0.5, 0)
		character:PivotTo(CFrame.lookAt(pos, boardCenter.Position))
	end

	player:SetAttribute("InChessMatch", true)
	player:SetAttribute("CameraMode", "Booth")

	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	end
end

local function setupPlayer(player)
	assignSide(player)
	player:SetAttribute("InChessMatch", true)
	player:SetAttribute("CameraMode", "Booth")

	player.CharacterAdded:Connect(function(character)
		task.wait(0.25)
		setupCharacter(player, character)
	end)

	if player.Character then
		task.defer(function()
			setupCharacter(player, player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
