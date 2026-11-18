--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--// Modules
local World = require(ServerScriptService.Modules.World)
local EntityService = require(ServerScriptService.Modules.EntityService)
local LuauFutures = require(ServerScriptService.Modules.LuauFutures)

--// Types
type Entity<T> = World.Entity<T>

--// ++ Configuration ++
--// Initialized player components
local Player = EntityService:GetOrAddComponent("Player") :: Entity<Player>
local Character = EntityService:GetOrAddComponent("Character") :: Entity<World.Character>
local Heart = EntityService:GetOrAddComponent("Heart") :: Entity<World.Heart>

--// ++ Main script ++

local function OnDeath(playerID : Entity<number>, character : Model)
	task.wait(3)
	
	World:remove(playerID, Character)
	World:remove(playerID, Heart)
	
	character:Destroy()
end

--// Initialize players
local function OnPlayerAdded(player : Player)
	local playerID = World:entity()
	World:set(playerID, Player, player)
	World:set(playerID, Heart, {current = 3, max = 3})
	
	--// Initializes character
	local character = workspace.Camera.ToonGurt:Clone()
	
	World:set(playerID, Character, character)
	
	character.Name = player.Name
	character:SetPrimaryPartCFrame(CFrame.new(0, 5, 0)) --// Adjust spawn position
	player.Character = character
	character.Parent = workspace.AlivePlayers
	
	character.Humanoid.Died:Once(function()
		OnDeath(playerID, character)
	end)
	
end

Players.PlayerAdded:Connect(OnPlayerAdded)

--// Race condition prevention
local allPlayers = Players:GetPlayers()

for _, player in World:query(Player) do
	table.remove(allPlayers, table.find(allPlayers, player))
end

for _, player in allPlayers do
	OnPlayerAdded(player)
end

return nil