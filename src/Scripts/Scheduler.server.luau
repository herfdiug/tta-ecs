--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Modules
local World = require(ServerScriptService.Modules.World)
local EntityService = require(ServerScriptService.Modules.EntityService)

--// Systems

--// ++ Main script ++
local PlayerSystem = require(ServerScriptService.Modules.SystemModules.PlayerSystem)
local MoveSystem = require(ServerScriptService.Modules.SystemModules.MoveSystem)
local PathfindSystem = require(ServerScriptService.Modules.SystemModules.PathfindSystem)
local ScanSystem = require(ServerScriptService.Modules.SystemModules.ScanSystem)

--// Heartbeat scheduler
RunService.Heartbeat:Connect(function(deltaTime)
	ScanSystem()
	PathfindSystem()
	MoveSystem()
end)