--!strict
--!native
--[[
Script by Herfdiug

Contributors :
- Synabe
- AI
- 

Notes :
- Input scripts under "Main script"
-
-
]]

--// ++ Configuration ++
local ServerScriptService = game:GetService("ServerScriptService")

local NodeService = {}

NodeService.pathfindProperties = {
	AgentHeight = 5,
	AgentRadius = 2,
	AgentCanJump = false,
	AgentCanClimb = false
}

--// ++ Main script ++

type NodeService = typeof(NodeService)

type NodeKey = string
type Vector3InString = string

type Angle = number

type NodeDictionary = { [Vector3] : { [Vector3] : Angle } }

local nodeIndex : { [NodeKey] : NodeDictionary } = {}

local function GetAngle(anchorPoint : Vector3, variablePoint : Vector3) : Angle
	local delta = anchorPoint - variablePoint
	local dx, dz = delta.X, delta.Z

	--// Compute angle from -Z axis, clockwise
	local angleDeg = math.deg(math.atan2(delta.X, -delta.Z)) --// Note the `-dz`

	return angleDeg < 0 and angleDeg + 360 or angleDeg
end

--// Initializes the node set and saves it, also it returns invalid nodes
function NodeService.Initialize(self : NodeService,nodeKey : NodeKey, nodeFolder : Folder & {BasePart}, visualize : boolean?)
	
	assert(
		typeof(nodeKey) == "string",
		`NodeService Module error; :Initialize() -> parameter nodeKey must be a string`
	)

	assert(
		nodeFolder:IsDescendantOf(workspace),
		`NodeService Module error; :Initialize() -> parameter nodeFolder must be a descendant of workspace`
	)

	local localNodeIndex = {}
	local invalidNodes = {}
	local allNodes = nodeFolder:GetChildren()

	--// Used to detect if the path to the neighborNode is obstructed
	local partForChecking = Instance.new("Part")
	partForChecking.Anchored = true
	partForChecking.CanCollide = false
	partForChecking.CanQuery = false
	partForChecking.Transparency = 1
	partForChecking.Parent = workspace

	--// Used to exclude unwanted parts when checking for path obstruction
	local overlapParamsForPartChecking = OverlapParams.new()
	overlapParamsForPartChecking.FilterType = Enum.RaycastFilterType.Exclude
	overlapParamsForPartChecking.FilterDescendantsInstances = {workspace.Baseplate}

	--// Finds all valid neighborNode of each mainNode
	for index, mainNode in allNodes do
		
		if index % 10 == 0 then
			wait() --// Prevent script timeout
			print("Loading")
		end
		
		local mainNode = mainNode :: BasePart
		local mainNodePosition = mainNode.Position
		localNodeIndex[mainNodePosition] = {}

		local neighborPositions = localNodeIndex[mainNodePosition]
		local hasNeighbors : boolean

		local AgentDiameter = self.pathfindProperties.AgentRadius * 2

		for _, neighborNode in allNodes do
			local neighborNode = neighborNode :: BasePart

			--// Skips if it's iterating the same node
			if neighborNode == mainNode then continue end

			local neighborNodePosition = neighborNode.Position

			--// Places partForChecking at the midpoint of both nodes looking at the neighborNode
			partForChecking.CFrame = CFrame.lookAt((neighborNodePosition + mainNodePosition) / 2, neighborNodePosition)

			partForChecking.Size = --// X = Diameter of the twisted's hitbox; Y = 1; Z = Distance between nodes
				Vector3.new(AgentDiameter, 1, (neighborNodePosition - mainNodePosition).Magnitude)

			--// Continues if path isn't clear
			if #workspace:GetPartsInPart(partForChecking, overlapParamsForPartChecking) ~= 0 then continue end

			if visualize then
				--// Path visualization
				local pathVisual = partForChecking:Clone()

				task.defer(function()
					pathVisual.Transparency = .8
					pathVisual.Parent = workspace
				end)

			end

			neighborPositions[neighborNodePosition] = GetAngle(mainNodePosition, neighborNodePosition)
			hasNeighbors = true
		end

		if hasNeighbors then continue end --// Continues if there are valid neighbors to mainNode
		localNodeIndex[mainNodePosition] = nil
		table.insert(invalidNodes, mainNode)
	end

	nodeIndex[nodeKey] = localNodeIndex
	return invalidNodes
end

--// Gets a specific set of nodes
function NodeService.Get(nodeKey : NodeKey)
	return nodeIndex[nodeKey]
end

local function IsInFOV(anchorAngle : Angle, variableAngle : Angle, FOVRangeHalfed : Angle) : boolean
	local shift = (variableAngle + 180 - anchorAngle) % 360
	return shift >= (180 - FOVRangeHalfed) and shift <= (180 + FOVRangeHalfed)
end

--// Generates a path the twisted can follow
function NodeService.Generate(
	self : NodeService,
	nodeKey : NodeKey,
	startPosition : Vector3,
	maxNodeChain : number,
	fovRange : Angle
) : {Vector3}

	assert(
		typeof(nodeKey) == "string",
		`NodeService Module error; :Generate() -> parameter nodeKey must be a string`
	)

	assert(
		typeof(startPosition) == "Vector3",
		`NodeService Module error; :Generate() -> parameter startPosition must be a Vector3 or a string`
	)

	local nodes = self.Get(nodeKey)

	assert(
		nodes,
		`NodeService Module error; :Generate() -> nodeKey isn't found in nodeIndex` 
	)

	local startDepth = 0

	--// Checks if the startPosition is a position of a node or not. Usually if it's not, it means the twisted just lost interest & is back to patrolling
	if not nodes[startPosition] then 
		local closestNodePosition : Vector3
		local closestNodeDistance = math.huge

		--// This loop finds the closest node to the start position
		for nodePosition, _ in nodes do
			local currentDistance = (startPosition - nodePosition).Magnitude

			if currentDistance >= closestNodeDistance then continue end

			closestNodePosition = nodePosition
			closestNodeDistance = currentDistance
		end

		startPosition = closestNodePosition
		--// Since the twisted isn't on a node, the beginning node is considered as the first waypoint
		-- DISABLED; Doesn't really work, will probably remove later
		--startDepth = 1
	end

	--// Randomized DFS algorithm
	local lastNodeSeesNeighbor : boolean? = false --// Saves the info if last node has nodes in its FOV
	local pathfindingFOVHalfed = fovRange / 2

	local stack : {{any}} = {{startPosition, startDepth}}
	local visitedSet : { [Vector3] : boolean } = {}
	local traversalOrder : { [number] : Vector3 } = {} --// Used to update the depth found in real time
	--// The longest valid path found, only updates whenever the longest valid path is found, obviously
	local longestTraversalOrder : typeof(traversalOrder) = {}
	local furthestDepth = startDepth

	while #stack > 0 do
		local nodeSet = table.remove(stack) :: {any} --// Pop last element (LIFO)
		local nodePosition : Vector3 = nodeSet[1] --// Position of node
		local depth : number = nodeSet[2] --// Depth of node
		visitedSet[nodePosition] = true --// Mark as visited
		traversalOrder[depth] = nodePosition --// Sets the order of the node according to the path.

		local isCurrentIterationTheDeepest = false

		if depth > furthestDepth then
			furthestDepth = depth --// Updates furthestDepth if depth is bigger than it
			longestTraversalOrder = table.clone(traversalOrder)
			isCurrentIterationTheDeepest = true
			lastNodeSeesNeighbor = false
		end

		if #traversalOrder == maxNodeChain then
			lastNodeSeesNeighbor = nil
			break
		end --// Breaks loop if the desired amount of nodes is reached

		local POVAngle : Angle? =
			--// pathfindingFOVHalfed >= 180 means that it can see 360 degrees (full circle), making POVAngle checking a bloat
			pathfindingFOVHalfed < 180 and depth > startDepth and GetAngle(traversalOrder[depth - 1], nodePosition) or nil

		local validNeighborPositions : {{any}} = {} --// Will save the next stack candidates

		for neighborNodePosition, angle in nodes[nodePosition] do --// Iterates all neighbors

			--// Doesn't skip the iteration if there's either no POVAngle or the POVAngle is in range
			if POVAngle and not IsInFOV(POVAngle, angle, pathfindingFOVHalfed) then continue end

			if isCurrentIterationTheDeepest and POVAngle then
				lastNodeSeesNeighbor = true
			end

			if visitedSet[neighborNodePosition] then continue end

			table.insert(validNeighborPositions, {neighborNodePosition, depth + 1} :: {any})
		end

		for i = #validNeighborPositions, 2, -1 do --// Fisher-Yates uniform shuffle algorithm
			local j = math.random(i)
			validNeighborPositions[i], validNeighborPositions[j] = validNeighborPositions[j], validNeighborPositions[i]
		end

		table.move(validNeighborPositions, 1, #validNeighborPositions, #stack + 1, stack)

		--// If the previous lines fails adding nodes to the stack & the last node sees a neighbor in its FOV, we add the last node to the stack & reset the visitedSet log, allowing the algorithm to re-loop
		if #stack == 0 and lastNodeSeesNeighbor then
			visitedSet = {}
			traversalOrder = table.clone(longestTraversalOrder) --// Makes sure the traversalOrder aligns with the logged longest path
			table.insert(stack, {longestTraversalOrder[#longestTraversalOrder], furthestDepth} :: {any})
		end

	end

	--// Rid the 0th index as it is useless
	longestTraversalOrder[0] = nil
	return longestTraversalOrder
end

return NodeService