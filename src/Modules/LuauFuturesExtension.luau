--!strict
--!native
--// Made by Herfdiug

--// ++ Dependencies ++
local LuauFutures = require(game:GetService("ServerScriptService").Modules.LuauFutures)

--// ++ Main script ++
local LuauFuturesExtension = {}

type LuauFuturesExtension = typeof(LuauFuturesExtension) & {
	DeferredFutures : {LuauFutures.FutureLike<any>}
}

LuauFuturesExtension.__index = LuauFuturesExtension

LuauFuturesExtension.DeferredFutures = {}

function LuauFuturesExtension.AwaitAll(self : LuauFuturesExtension)
	
	for _, future in self.DeferredFutures :: {LuauFutures.FutureLike<any>} do
		future:await()
	end
	
end

function LuauFuturesExtension.PollAll(self : LuauFuturesExtension)

	for _, future in self.DeferredFutures :: {LuauFutures.FutureLike<any>} do
		future:poll()
	end

end

return setmetatable({} :: LuauFuturesExtension, LuauFuturesExtension)