--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Services
local Jecs = require(game:GetService("ServerScriptService").Modules.Jecs)

--// ++ Main script ++
export type Character = Model & {
	Humanoid : Humanoid,
	HumanoidRootPart : BasePart
}

export type Heart = {
	current : number,
	max : number,
}

export type VisionInfo = {
	angle : number,
	radius : number,
	height : number
}

export type Entity<T = nil> = Jecs.Entity<T>
return Jecs.world()