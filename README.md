# PermissionsModule
A simple permissions module for group and role checking on Roblox groups.

## Requirements

- A Roblox place with access to Studio.

## 1. Place the files

Recreate this structure in your game (Studio Explorer paths shown):<br>

```
ServerScriptService
├── PermissionsModule   (ModuleScript)  <= PermissionsModule.lua
└── PermissionsHandler  (Script)        <= PermissionsHandler.lua

ReplicatedStorage
└── PermissionsRemote (RemoteFunction)
```

**Setup**

1. In `ServerScriptService`, create a `ModuleScript` named `PermissionsModule`. Paste in the contents of `PermissionsModule.lua`.
2. In `ServerScriptService`, again create a `Script` named `PermissionsHandler`. Paste in the contents of `PermissionsHandler.lua`.
3. In `ReplicatedStorage`, create a `RemoteFunction` named `PermissionsRemote`.

> Note: The structure can vary based on what your games structure has. The important part is that you ensure all paths are correct, and that the scripts are located in the correct service location.

## 2. Configure your groups

Open `PermissionsModule.lua` and fill in `Permissions.Departments` - There is a comment located in the script that will help you walk through how to set it up for your group(s). For each group, you will need:

- The Roblox **Group ID** (e.g. `roblox.com/groups/1234567/...`).
- The **rank numbers** for each role you care about, taken from the group's role configuration on the Roblox website (Group -> Configure -> Roles).

## 3. Verify it works

From a server script:

```lua
local Permissions = require(ServerScriptService.PermissionsModule)

Players.PlayerAdded:Connect(function(player)
	print(player.Name, "rank in Main:", Permissions.GetRoleName(player, "Main"))
end)
```

If you see a role name (or `nil` for players not in the group) printed in the output, the setup is working.

## 4. Client-side usage

The `PermissionsHandler` script exposes a subset of checks (`HasRankAtLeast`, `HasExactRank`, `IsInDept`, `IsInSubGroup`) to the client via `PermissionsRemote`. Invoke it like any `RemoteFunction`:

```lua
local ok = PermissionsRemote:InvokeServer("HasRankAtLeast", "SecurityDepartment", "SD_Guard")
```

Only checks listed in `allowedChecks` inside `PermissionsHandler.lua` are reachable from the client. You may add or remove entries there if you want to expose more or fewer functions.
