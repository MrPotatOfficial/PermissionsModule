# API Guide

## Types

```lua
export type Group = keyof<typeof(Permissions.Groups)>
```

`Group` is a union of whatever keys you've defined in `Permissions.Groups` (e.g. `"Main" | "SecurityDepartment" | "MobileTaskForces"`). Every function below takes a `groupKey: Group` argument referring to one of these keys.

---

## Functions

### `Permissions.GetGroupId(groupKey: Group): number?`

Returns the Roblox `GroupId` configured for `groupKey`.

```lua
local id = Permissions.GetGroupId("SecurityDepartment")
-- 2345678
```

---

### `Permissions.GetRankId(player: Player, groupKey: Group): number`

Returns the numeric rank the player holds in the group. Returns `0` if the player isn't in the group.

```lua
local rank = Permissions.GetRankId(player, "SecurityDepartment")
-- e.g. 5
```

---

### `Permissions.GetRoleName(player: Player, groupKey: Group): string?`

Returns the role name (a key from that group's `Ranks` table) matching the player's current rank. Returns `nil` if the player has no rank in the group or if no role name matches their exact rank number.

```lua
local role = Permissions.GetRoleName(player, "SecurityDepartment")
-- "SD_Sergeant"
```

---

### `Permissions.IsInGroup(player: Player, groupKey: Group): boolean`

Returns `true` if the player holds any rank above 0 in the group.

```lua
if Permissions.IsInGroup(player, "Main") then
	-- player is a group member
end
```

---

### `Permissions.HasRankAtLeast(player: Player, groupKey: Group, roleName: string): boolean`

Returns `true` if the player's rank is **greater than or equal to** the rank associated with `roleName`. This is the main check for "does this player have at least X permission level."

```lua
if Permissions.HasRankAtLeast(player, "SecurityDepartment", "SD_Sergeant") then
	-- player is SD_Sergeant or higher
end
```

If `roleName` doesn't exist in that group's `Ranks` table, this warns and returns `false`.

---

### `Permissions.HasExactRank(player: Player, groupKey: Group, roleName: string): boolean`

Returns `true` only if the player's rank **exactly matches** the rank associated with `roleName`.

```lua
if Permissions.HasExactRank(player, "SecurityDepartment", "SD_Cadet") then
	-- player is specifically an SD_Cadet, nothing higher or lower
end
```

---

### `Permissions.IsInSubGroup(player: Player, groupKey: Group, subGroupKey: string): boolean`

Returns `true` if the player is a member of a sub-group (satellite group) tied to `groupKey`. Requires the parent group to have a `SubGroups` table defined. Warns and returns `false` if the group has no sub-groups or if `subGroupKey` is unrecognized.

```lua
if Permissions.IsInSubGroup(player, "MobileTaskForces", "MTF_Lambda") then
	-- player belongs to the MTF Lambda sub-group
end
```

---

### `Permissions.GetHighestRank(player: Player, groupKey: Group): string?`

Returns the role name corresponding to the **highest rank number at or below** the player's current rank in the group. Useful when your `Ranks` table doesn't map every possible rank number 1:1 to a role name, and you want the closest matching (i.e. next lowest) named role. Returns `nil` if the player isn't in the group.

```lua
local highest = Permissions.GetHighestRank(player, "SecurityDepartment")
-- "SD_Sergeant"
```

---

### `Permissions.ClearCache(player: Player)`

Clears the cached group/rank data for a player. Called automatically on `Players.PlayerRemoving`, so you generally don't need to call this yourself, however it's exposed in case you need to force a refresh (e.g. after promoting/demoting someone mid-session).

```lua
Permissions.ClearCache(player)
```

---

## Notes on caching

- Group/rank data is fetched via `GroupService:GetGroupsAsync` once per
  player and cached in memory for the rest of their session.
- If a player's rank changes while they're in-game, the cached value
  will be stale until you call `Permissions.ClearCache(player)` (or they
  rejoin).

## Example: gating a feature

```lua
local Permissions = require(ServerScriptService.PermissionsModule)

local function onAdminCommand(player)
	if not Permissions.HasRankAtLeast(player, "Main", "Admin") then
		return false, "You don't have permission to do that."
	end

	-- proceed with admin logic
	return true
end
```
