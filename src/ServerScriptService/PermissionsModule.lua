local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local Permissions = {}

--[[
	CONFIGURE YOUR GROUPS HERE

	Add one entry per Roblox group you want this module to check against.
	Each group needs:
		- GroupId  (number) - the Roblox group's ID
		- Ranks    (table)  - a map of RoleName (string) -> RankId (number, 1-255)
		                      RankId values must match the actual rank numbers
		                      configured in the group's Roblox roleset.
		- SubGroups (optional table) - map of SubGroupName (string) -> GroupId (number)
		                      for satellite groups tied to this department
		                      (e.g. multiple squads/branches under one umbrella).

	Example:

	Permissions.Groups = {
		Main = {
			GroupId = 1234567,
			Ranks = {
				Owner   = 255,
				Admin   = 200,
				Member  = 1,
			},
		},

		SecurityDepartment = {
			GroupId = 2345678,
			Ranks = {
				SD_Chief    = 8,
				SD_Captain  = 7,
				SD_Guard    = 2,
				SD_Cadet    = 1,
			},
		},

		MobileTaskForces = {
			GroupId = 3456789,
			SubGroups = {
				MTF_Lambda = 4567890,
				MTF_Theta  = 5678901,
			},
			Ranks = {
				MTF_Chief   = 9,
				MTF_Private = 2,
				MTF_Cadet   = 1,
			},
		},
	}

	Tips:
	- Keys in Groups (e.g. "SecurityDepartment") are what you'll pass
	  around in code as the `groupKey` argument to every function below.
	- Keys in Ranks (e.g. "SD_Chief") are what you'll pass as `roleName` to
	  functions like HasRankAtLeast / HasExactRank.
	- Rank numbers come from your group's configuration on the Roblox website
	  (Group > Configure > Roles).
--]]
Permissions.Groups = {

}

-- Types
export type Group = keyof<typeof(Permissions.Groups)>

-- Helpers
local rankIdToNameCache = {}

local function getRankIdToNameMap(groupKey: Group)
	if rankIdToNameCache[groupKey] then
		return rankIdToNameCache[groupKey]
	end

	local group = Permissions.Groups[groupKey]
	if not group then return nil end

	local map = {}
	for roleName, rankId in pairs(group.Ranks) do
		if not map[rankId] then map[rankId] = roleName end
	end

	rankIdToNameCache[groupKey] = map
	return map
end

local groupCache = {}

-- Clear player's cached group data (saves memory)
function Permissions.ClearCache(player: Player)
	groupCache[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	Permissions.ClearCache(player)
end)

-- Fetch map of GroupId -> Rank for player
local function getPlayerGroupMap(player: Player)
	local userId = player.UserId

	if groupCache[userId] then return groupCache[userId] end

	local ok, groups = pcall(function()
		return GroupService:GetGroupsAsync(userId)
	end)

	if not ok or not groups then
		warn(("[PermissionsService] Failed to fetch groups for UserId %d"):format(userId))
		return {}
	end

	local map = {}
	for _, info in ipairs(groups) do
		map[info.Id] = info.Rank
	end

	groupCache[userId] = map
	return map
end

-- Main API

-- Returns GroupId for given group key
function Permissions.GetGroupId(groupKey: Group): number?
	local group = Permissions.Groups[groupKey]
	return group and group.GroupId
end

-- Returns numeric rank a player holds within a group
-- Returns 0 if player not in group or if group doesn't exist
function Permissions.GetRankId(player: Player, groupKey: Group): number
	local group = Permissions.Groups[groupKey]

	local groupMap = getPlayerGroupMap(player)
	return groupMap[group.GroupId] or 0
end

-- Returns role name (i.e. "SD_Lieutenant") matching player's current rank in given group or nil if none matches
function Permissions.GetRoleName(player: Player, groupKey: Group): string?
	local rankId = Permissions.GetRankId(player, groupKey)
	if rankId == 0 then return nil end

	local map = getRankIdToNameMap(groupKey)
	return map and map[rankId] or nil
end

-- Returns true if player is in a group
function Permissions.IsInGroup(player: Player, groupKey: Group): boolean
	return Permissions.GetRankId(player, groupKey) > 0
end

-- Returns true if player's rank in group is >= rank associated with roleName
function Permissions.HasRankAtLeast(player: Player, groupKey: Group, roleName: string): boolean
	local group = Permissions.Groups[groupKey]

	local requiredRank = group.Ranks[roleName]
	if not requiredRank then
		warn(("[PermissionsService] Unknown role '%s' in group '%s'"):format(roleName, groupKey))
		return false
	end

	local playerRank = Permissions.GetRankId(player, groupKey)
	return playerRank >= requiredRank
end

-- Returns true if player holds exactly given role
function Permissions.HasExactRank(player: Player, groupKey: Group, roleName: string): boolean
	local group = Permissions.Groups[groupKey]

	local requiredRank = group.Ranks[roleName]
	if not requiredRank then return false end

	return Permissions.GetRankId(player, groupKey) == requiredRank
end

-- Returns true if player is member of subgroup
function Permissions.IsInSubGroup(player: Player, groupKey: Group, subGroupKey: string): boolean
	local group = Permissions.Groups[groupKey]
	if not group.SubGroups then
		warn(("[PermissionsService] Group '%s' has no sub-groups"):format(groupKey))
		return false
	end

	local subGroupId = group.SubGroups[subGroupKey]
	if not subGroupId then
		warn(("[PermissionsService] Unknown sub-group '%s' in group '%s'"):format(subGroupKey, groupKey))
		return false
	end

	local groupMap = getPlayerGroupMap(player)
	return groupMap[subGroupId] ~= nil
end

-- Returns the users highest rank in a given group
function Permissions.GetHighestRank(player: Player, groupKey: Group): string?
	local group = Permissions.Groups[groupKey]

	local groupMap = getPlayerGroupMap(player)
	local playerRank = groupMap[group.GroupId]
	if not playerRank then return nil end

	local highestRankName: string?
	local highestRankId = -1

	for roleName, rankId in pairs(group.Ranks) do
		if playerRank >= rankId and rankId > highestRankId then
			highestRankId = rankId
			highestRankName = roleName
		end
	end

	return highestRankName
end

return Permissions
