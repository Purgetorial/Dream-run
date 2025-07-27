-- TeleportToStartHandler.lua
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocationService    = require(ReplicatedStorage:WaitForChild("LocationService"))

local TeleportToStart = ReplicatedStorage:WaitForChild("TeleportToStart")
local TeleportToLobby = ReplicatedStorage:WaitForChild("TeleportToLobby")
local player          = Players.LocalPlayer

-- ? MODIFIED: Add 'startCFrame' as a parameter to the function
TeleportToStart.OnClientEvent:Connect(function(startCFrame)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	-- Check that the hrp exists AND that a CFrame was sent from the server
	if hrp and startCFrame then
		-- Use the CFrame provided by the server
		hrp.CFrame = startCFrame
	end
end)

-- No changes needed below this line
TeleportToLobby.OnClientEvent:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		hrp.CFrame = LocationService.GetLobbyCFrame()
	end
end)