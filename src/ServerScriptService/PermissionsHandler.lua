local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Permissions = require("path.to.module.script)

local remote = path.to.remote.in.ReplicatedStorage -- You must have a remote named "PermissionsRemote" somewhere in ReplicatedStorage to communicate between client and the API. This is the path to said remote.

local allowedChecks = {
	HasRankAtLeast = Permissions.HasRankAtLeast,
	HasExactRank = Permissions.HasExactRank,
	IsInGroup = Permissions.IsInGroup,
	IsInSubGroup = Permissions.IsInSubGroup,
}

function remote.OnServerInvoke(player, checkType, a, b)
	local fn = allowedChecks[checkType]
	if not fn then
		warn(("[PermissionsHandler] Unknown checkType '%s' requested by %s"):format(tostring(checkType), player.Name))
		return false
	end

	local ok, result = pcall(fn, player, a, b)
	if not ok then
		warn(("[PermissionsHandler] Error running '%s': %s"):format(checkType, tostring(result)))
		return false
	end

	return result
end
