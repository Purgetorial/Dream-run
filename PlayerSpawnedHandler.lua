-- PlayerSpawnedHandler.lua  |  spawns players in the lobby & handles fall reset
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocationService    = require(ReplicatedStorage:WaitForChild("LocationService"))
local DataAPI            = require(game.ServerScriptService.PlayerDataManager) -- ADD THIS LINE

local ServerResetRunTimer = ReplicatedStorage:WaitForChild("ServerResetRunTimer")
local TeleportToLobby     = ReplicatedStorage:WaitForChild("TeleportToLobby")
local TeleportToStart     = ReplicatedStorage:WaitForChild("TeleportToStart")
local OpenMainMenu        = ReplicatedStorage:WaitForChild("OpenMainMenu")

local RESPAWN_Y = -20      -- Y-level that counts as “fallen”

--------------------------------------------------------------------
--  Player join / respawn
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if not hrp then return end

		-- ? NO CHANGE HERE
		hrp.CFrame = LocationService.GetLobbyCFrame()
		player.Team = game:GetService("Teams"):FindFirstChild("Lobby")
		ServerResetRunTimer:Fire(player)
		OpenMainMenu:FireClient(player)

		----------------------------------------------------------------
		--  Fall-detection loop – teleport back to StartPad
		----------------------------------------------------------------
		task.spawn(function()
			while character.Parent and player.Parent == Players do
				if hrp.Position.Y < RESPAWN_Y then
					-- ? START OF CHANGES
					-- Get the player's current stage from their data
					local data = DataAPI.Get(player)
					local currentStage = data and data.CurrentStage or 1 -- Default to stage 1
					-- Get the correct CFrame for that stage
					local startCFrame = LocationService.GetStartCFrame(currentStage)
					-- Fire the event WITH the CFrame data
					TeleportToStart:FireClient(player, startCFrame)
					-- ? END OF CHANGES

					repeat task.wait(0.2) until
					not (character.Parent
						and player.Parent == Players
						and hrp.Position.Y < RESPAWN_Y)
				end
				task.wait(0.2)
			end
		end)
	end)
end)
