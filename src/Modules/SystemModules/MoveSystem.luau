--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Services
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local Jecs = require(ServerScriptService.Modules.Jecs)
local World = require(ServerScriptService.Modules.World)
local EntityService = require(ServerScriptService.Modules.EntityService)
local LuauFutures = require(ServerScriptService.Modules.LuauFutures)
local LuauFuturesExtension = require(ServerScriptService.Modules.LuauFuturesExtension)

--// Types
type Entity<T> = World.Entity<T>

--// ++ Configuration ++
--// General components
local Pathfinding = EntityService:GetOrAddTag("Pathfinding")
local Character = EntityService:GetOrAddComponent("Character") :: Entity<World.Character>
local Walkspeed = EntityService:GetOrAddComponent("Walkspeed") :: Entity<number>

--// Optional components (Must choose one pair)
local Following = EntityService:GetOrAddTag("Following")
local Waypoints = EntityService:GetOrAddComponent("Waypoints") :: Entity<{Vector3}>
local CurrentWaypointIndex = EntityService:GetOrAddComponent("CurrentWaypointIndex") :: Entity<number>

local Prey = EntityService:GetOrAddComponent("Prey") :: Entity<World.Character>

--// System only components
local FutureArrival = World:component() :: Entity<LuauFutures.FutureLike<any, boolean>>

--// ++ Main script ++

return function()
	
	--// Move to waypoint (nodes)
	for entityID,
		character : World.Character,
		walkspeed : number,
		waypoints : {Vector3},
		currentWaypointIndex : number
	in
		World:query(Character, Walkspeed, Waypoints, CurrentWaypointIndex)
			:with(Jecs.pair(Following, Waypoints))
			:without(FutureArrival, Pathfinding)
	do
		local humanoid = character.Humanoid
		humanoid.WalkSpeed = walkspeed
		
		local futureArrivalFunction : LuauFutures.FutureLike<any, boolean> = LuauFutures.Future.new(function()
			return humanoid.MoveToFinished:Wait()
		end)
		
		futureArrivalFunction:poll()
		World:set(entityID, FutureArrival, futureArrivalFunction)
		
		humanoid:MoveTo(waypoints[currentWaypointIndex])
	end
	
	--// Detect & Update movement (nodes)
	for entityID,
		waypoints : {Vector3},
		currentWaypointIndex : number,
		futureArrival : LuauFutures.FutureLike<any, boolean>
	in 
		World:query(Waypoints, CurrentWaypointIndex, FutureArrival)
			:with(Jecs.pair(Following, Waypoints), Character, Walkspeed)
			:without(Pathfinding)
	do
		local arrivalPoll = futureArrival:poll()
		
		--// Wait until :MoveToFinished:Wait() triggers
		if arrivalPoll:isPending() then continue end
		
		--// If reached
		if arrivalPoll:unwrap():unwrapOk() then
			
			--// Remove movement components if the character has reached the last waypoint, otherwise increase index
			if currentWaypointIndex == #waypoints then
				World:remove(entityID, Jecs.pair(Following, Waypoints))
				World:remove(entityID, Waypoints)
				World:remove(entityID, CurrentWaypointIndex)
			else
				
				table.insert(LuauFuturesExtension.DeferredFutures, LuauFutures.Future.new(function()
					World:set(entityID, CurrentWaypointIndex, currentWaypointIndex + 1)
				end))
				
			end
			
		end
		
		--// Reset Future
		World:remove(entityID, FutureArrival)
	end
	
	LuauFuturesExtension:AwaitAll()
	
	--// Constantly update the waypoint to move to (Prey)
	for entityID,
		character : World.Character,
		walkspeed : number,
		waypoints : {Vector3}
	in 
		World:query(Character, Walkspeed, Waypoints)
			:with(Jecs.pair(Following, Prey))
	do
		
		--// I couldn't care less to make a "set this only once" function so for now it'll just run every frame lol!
		task.defer(function()
			character.Humanoid.WalkSpeed = walkspeed
		end)
		
		character.Humanoid:MoveTo(waypoints[1])
	end
	
end