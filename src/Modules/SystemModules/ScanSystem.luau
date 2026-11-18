--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

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
local Name = EntityService:GetOrAddComponent("Name") :: Entity<string>
local Scanning = EntityService:GetOrAddTag("Scanning")
local Character = EntityService:GetOrAddComponent("Character") :: Entity<World.Character>
local VisionInfo = EntityService:GetOrAddComponent("VisionInfo") :: Entity<World.VisionInfo>
local InstantChaseRadius = EntityService:GetOrAddComponent("InstantChaseRadius") :: Entity<number>

--// Components to be added
local Pathfinding = EntityService:GetOrAddTag("Pathfinding")
local Prey = EntityService:GetOrAddComponent("Prey") :: Entity<World.Character>

--// System only components
local CharacterDistances = World:component() :: Entity<{[World.Character] : number}>

--// ++ Main script ++

return function()
	
	do
		--// Cache every player position
		local characterPositions : {[World.Character] : Vector3} = {}

		for _, player in Players:GetPlayers() do
			local character = player.Character
			
			if not character then continue end
			
			characterPositions[character] = character.PrimaryPart.Position
		end

		--// Scan for players
		for entityID, character : World.Character in
			World:query(Character):with(Scanning)
		do
			local humanoidRootPartPosition = character.HumanoidRootPart.Position
			local characterDistances : {[World.Character] : number} = {}

			for playerCharacter, position in characterPositions do
				characterDistances[playerCharacter] = (position - humanoidRootPartPosition).Magnitude
			end

			table.insert(LuauFuturesExtension.DeferredFutures, LuauFutures.Future.new(function()
				World:set(entityID, CharacterDistances, characterDistances)
			end))
			
		end
		
	end
	
	LuauFuturesExtension:AwaitAll()
	
	--// Check instant radius
	for entityID, characterDistances : {[World.Character] : number}, instantChaseRadius : number in
		World:query(CharacterDistances, InstantChaseRadius):with(Character, Scanning)
	do
		local closestValidCharacter : World.Character
		local closestValidDistance : number = math.huge
		
		for character, distance in characterDistances do
			
			if distance > instantChaseRadius or distance > closestValidDistance then continue end
			
			closestValidCharacter = character
		end
		
		if not closestValidCharacter then continue end
		
		table.insert(LuauFuturesExtension.DeferredFutures, LuauFutures.Future.new(function()
			World:set(entityID, Prey, closestValidCharacter)
			World:add(entityID, Jecs.pair(Pathfinding, Prey))
		end))
		
	end
	
	LuauFuturesExtension:PollAll()
end