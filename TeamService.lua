-- ServerScriptService/TeamService.lua

local TeamsService = game:GetService("Teams")

-- Create a team for the lobby
local lobbyTeam = Instance.new("Team")
lobbyTeam.Name = "Lobby"
lobbyTeam.TeamColor = BrickColor.new("Medium stone grey")
lobbyTeam.AutoAssignable = false
lobbyTeam.Parent = TeamsService

-- Create a team for each stage
for i = 1, 10 do
	local stageTeam = Instance.new("Team")
	stageTeam.Name = "Stage " .. i
	stageTeam.TeamColor = BrickColor.random() -- Give each stage a random color
	stageTeam.AutoAssignable = false
	stageTeam.Parent = TeamsService
end

print("Dream Run Teams Created.")