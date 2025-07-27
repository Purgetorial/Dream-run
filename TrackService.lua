-- TrackService.lua  |  loads and positions the stage maps
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")

local TEMPLATE_FOLDER = ReplicatedStorage
local STAGES_FOLDER   = Workspace:FindFirstChild("GeneratedStages") or Instance.new("Folder", Workspace)
STAGES_FOLDER.Name    = "GeneratedStages"

local STAGE_SPACING = 2000 -- How far apart to place each stage (in studs)
local NUM_STAGES = 10      -- Total number of stages

--------------------------------------------------------------------
-- BUILD TRACK
--------------------------------------------------------------------
local function clearPrevious()
	STAGES_FOLDER:ClearAllChildren()
end

local function buildAllStages()
	clearPrevious()

	for i = 1, NUM_STAGES do
		local stageName = "Stage" .. i

		-- ? FIX: Use WaitForChild to prevent a race condition.
		-- We give it a 5-second timeout. If it can't find the stage
		-- model in 5 seconds, it's likely missing, and this will error.
		local stageTemplate = TEMPLATE_FOLDER:WaitForChild(stageName, 5)

		if stageTemplate then
			print("Loading", stageName)
			local stageClone = stageTemplate:Clone()

			-- Add an attribute to the finish pad to identify its stage number
			local finishPad = stageClone:FindFirstChild("FinishPad")
			if finishPad then
				finishPad:SetAttribute("StageNumber", i)
			else
				warn(`Stage '{stageName}' is missing a 'FinishPad' part!`)
			end

			-- Position the stage in the world
			local offset = Vector3.new(0, 0, -(i - 1) * STAGE_SPACING)
			stageClone:SetPrimaryPartCFrame(CFrame.new(offset))
			stageClone.Parent = STAGES_FOLDER
		else
			-- This warning will now only appear if a stage is truly missing after the 5-second wait.
			warn(`Cannot find stage model named '{stageName}' in ReplicatedStorage!`)
		end
	end
end

--------------------------------------------------------------------
-- BOOTSTRAP
--------------------------------------------------------------------
buildAllStages()

-- The service now just exposes the build function in case you want to regenerate stages
_G.TrackService = {
	Regenerate = buildAllStages,
}