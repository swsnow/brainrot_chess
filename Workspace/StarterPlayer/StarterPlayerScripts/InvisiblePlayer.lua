local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function setCharacterLocalTransparency(character, value)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = value
		end
	end
end

local function updateBoothVisibility()
	local character = player.Character
	if not character then
		return
	end

	if player:GetAttribute("CameraMode") == "Booth" then
		setCharacterLocalTransparency(character, 1)
	else
		setCharacterLocalTransparency(character, 0)
	end
end

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	updateBoothVisibility()
end)

player:GetAttributeChangedSignal("CameraMode"):Connect(function()
	updateBoothVisibility()
end)
