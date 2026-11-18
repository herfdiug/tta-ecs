--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
--// Modules
local World = require(game:GetService("ServerScriptService").Modules.World)

--// ++ Main Script ++
local EntityService = {}
EntityService.Entities = {}

--// There are no difference between :GetOrAddEntity() & :GetOrAddTag(), I just differed it for clarity while scripting. 
function EntityService.GetOrAddEntity<T>(self : typeof(EntityService), name : string)
	local entity = self.Entities[name]
	if entity then return entity end
	
	self.Entities[name] = World:entity()
	return self.Entities[name]
end

function EntityService.GetOrAddTag<T>(self : typeof(EntityService), name : string)
	local tag = self.Entities[name]
	if tag then return tag end

	self.Entities[name] = World:entity()
	return self.Entities[name]
end

function EntityService.GetOrAddComponent<T>(self : typeof(EntityService), name : string)
	local component = self.Entities[name]
	if component then return component end

	self.Entities[name] = World:component()
	return self.Entities[name]
end

return EntityService :: typeof(EntityService) & {
	Entities : {}
}