--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local PathfindingService = game:GetService("PathfindingService")

--// Modules
local Jecs = require(ServerScriptService.Modules.Jecs)
local World = require(ServerScriptService.Modules.World)
local EntityService = require(ServerScriptService.Modules.EntityService)
local NodeService = require(ServerScriptService.Modules.NodeService)
local LuauFutures = require(ServerScriptService.Modules.LuauFutures)
local LuauFuturesExtension = require(ServerScriptService.Modules.LuauFuturesExtension)

--// Types
type Entity<T> = World.Entity<T>

--// Initialization
NodeService:Initialize("TestMap", workspace.Map.Waypoints)

--// ++ Configuration ++
local agentParameters = {
	AgentRadius = 2,
	AgentHeight	= 5,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 4
}

--// General components
local Pathfinding = EntityService:GetOrAddTag("Pathfinding")
local Character = EntityService:GetOrAddComponent("Character") :: Entity<World.Character>
local MaxNodeChain = EntityService:GetOrAddComponent("MaxNodeChain") :: Entity<number>
local PathfindAngle = EntityService:GetOrAddComponent("PathfindAngle") :: Entity<number>

--// Components to be added (Must choose one pair)
local Following = EntityService:GetOrAddTag("Following")
local Waypoints = EntityService:GetOrAddComponent("Waypoints") :: Entity<{Vector3}>
local CurrentWaypointIndex = EntityService:GetOrAddComponent("CurrentWaypointIndex") :: Entity<number>

local Prey = EntityService:GetOrAddComponent("Prey") :: Entity<World.Character>

--// System only component
local FuturePath = World:component() :: Entity<LuauFutures.FutureLike<any, {PathWaypoint}>>

--// ++ Main script ++

return function()
	
	--// Node pathfind
	for entityID, character : World.Character, maxNodeChain : number, pathfindAngle : number in 
		World:query(Character, MaxNodeChain, PathfindAngle):with(Pathfinding):without(Jecs.pair(Following, Jecs.Wildcard))
	do
		--// Generate nodes
		World:set(entityID,
			Waypoints,
			NodeService:Generate("TestMap", character.HumanoidRootPart.Position, maxNodeChain, pathfindAngle))
		
		World:add(entityID, Jecs.pair(Following, Waypoints))
		World:remove(entityID, Pathfinding)
		
		table.insert(LuauFuturesExtension.DeferredFutures, LuauFutures.Future.new(function()
			World:set(entityID, CurrentWaypointIndex, 1)
		end))
		
	end
	
	LuauFuturesExtension:AwaitAll()
	
	--// Prey pathfind
	for entityID, character : World.Character, prey : World.Character in
		World:query(Character, Prey):with(Jecs.pair(Pathfinding, Prey)):without(FuturePath)
	do
		
		local futurePath : LuauFutures.FutureLike<any, {PathWaypoint}> = LuauFutures.Future.new(function()
			local path = PathfindingService:CreatePath(agentParameters)
			path:ComputeAsync(character.HumanoidRootPart.Position, prey.HumanoidRootPart.Position)
			return path:GetWaypoints()
		end)
		
		futurePath:poll()
		World:set(entityID, FuturePath, futurePath)
	end
	
	for entityID, character : World.Character, prey : World.Character, futurePath : LuauFutures.FutureLike<any, {PathWaypoint}> in
		World:query(Character, Prey, FuturePath):with(Jecs.pair(Pathfinding, Prey))
	do
		local pathPoll = futurePath:poll()
		
		--// Wait until :ComputeAsync() finishes
		if pathPoll:isPending() then continue end

		--// After computation
		local waypoints = pathPoll:unwrap():unwrapOk()

		if #waypoints > 0 then
			
			table.insert(LuauFuturesExtension.DeferredFutures, LuauFutures.Future.new(function()
				World:add(entityID, Jecs.pair(Following, Prey))
				--// Following the first waypoint results in "stuttery" movement, only opted if there is no other waypoints
				World:set(entityID, Waypoints, {((waypoints[2] or waypoints[1]) :: PathWaypoint).Position})
			end))
			
		else
			
			table.insert(LuauFuturesExtension.DeferredFutures, LuauFutures.Future.new(function()
				World:remove(entityID, Jecs.pair(Following, Prey))
				World:remove(entityID, Waypoints)
			end))
			
		end
	
		--// Reset Future
		World:remove(entityID, FuturePath)
	end
	
	LuauFuturesExtension:PollAll()
end