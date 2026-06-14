local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local RunService = game:GetService("RunService") local TweenService = game:GetService("TweenService") local UserInputService = game:GetService("UserInputService") local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = nil
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)
if _G.PlayerSettingsGUI_Unload then
	pcall(_G.PlayerSettingsGUI_Unload)
end
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	LocalPlayer = Players.PlayerAdded:Wait()
end
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
local function protectGui(gui)
	if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, gui)
	elseif typeof(protectgui) == "function" then
		pcall(protectgui, gui)
	elseif typeof(synprotect) == "function" then
		pcall(synprotect, gui)
	end
end
local function parentGui(gui)
	protectGui(gui)
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then
			gui.Parent = h
			return true
		end
	end
	if not PlayerGui then
		PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 60)
	end
	if PlayerGui then
		gui.Parent = PlayerGui
		return true
	end
	local ok = pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end)
	return ok
end
local function showBootError(msg)
	local errGui = Instance.new("ScreenGui")
	errGui.Name = "PlayerSettingsGUI_Error"
	errGui.ResetOnSpawn = false
	errGui.DisplayOrder = 10001
	errGui.IgnoreGuiInset = true
	parentGui(errGui)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 160)
	lbl.Position = UDim2.new(0, 10, 0.35, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
	lbl.BackgroundTransparency = 0.15
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextColor3 = Color3.fromRGB(255, 120, 120)
	lbl.Text = "[PlayerSettingsGUI error]\n" .. tostring(msg)
	lbl.Parent = errGui
end
local SLIDER_MAX = 100
local GUI_W, GUI_H = 580, 520
local SIDEBAR_W = 132
local EXPANDED_SIZE = Vector2.new(GUI_W, GUI_H)
local COLLAPSED_SIZE = Vector2.new(GUI_W, 48)
local CORNER_RADIUS = 8
local TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local COLORS = { bg = Color3.fromRGB(18, 18, 22), surface = Color3.fromRGB(28, 28, 34), surfaceAlt = Color3.fromRGB(36, 36, 44), accent = Color3.fromRGB(99, 102, 241), accentHover = Color3.fromRGB(129, 132, 255), text = Color3.fromRGB(240, 240, 245), textMuted = Color3.fromRGB(160, 163, 175), success = Color3.fromRGB(74, 222, 128), warn = Color3.fromRGB(251, 191, 36), danger = Color3.fromRGB(248, 113, 113), pirate = Color3.fromRGB(220, 90, 70), marine = Color3.fromRGB(70, 130, 220), stroke = Color3.fromRGB(55, 58, 70), track = Color3.fromRGB(45, 48, 58) }
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerSettingsGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.IgnoreGuiInset = true
protectGui(screenGui)
parentGui(screenGui)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.fromScale(0.5, 0.45)
mainFrame.Size = UDim2.fromOffset(EXPANDED_SIZE.X, EXPANDED_SIZE.Y)
mainFrame.BackgroundColor3 = COLORS.bg
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local bootLabel = Instance.new("TextLabel")
bootLabel.Name = "BootLabel"
bootLabel.Size = UDim2.fromScale(1, 1)
bootLabel.BackgroundTransparency = 1
bootLabel.Font = Enum.Font.GothamBold
bootLabel.TextSize = 18
bootLabel.TextColor3 = COLORS.text
bootLabel.Text = "Loading..."
bootLabel.Parent = mainFrame
local function mapWalkSpeed(slider)
	local t = slider / SLIDER_MAX
	return 16 + (t * t * t) * 484
end
local function mapJumpHeight(slider)
	if slider <= 0 then return 0 end
	local t = slider / SLIDER_MAX
	return 7.2 + (t * t * t) * 504
end
local alive, connections, isMinimized, isHidden, activeTab = true, {}, false, false, "Player"
local pendingWalk, pendingJump, appliedWalk, appliedJump = 0, 0, nil, nil
local walkBoostActive, jumpBoostActive = false, false
local originalWalk, originalJump, originalUseJumpPower = nil, nil, nil
local selectedRaid, raidLists = nil, { Normal = {}, Advanced = {} }
local raidBuyBeli, raidBuyFruit, autoStartRaid, autoCompleteRaid = false, false, false, false
local raidTargetIslandIndex, raidEmptySince, raidCyclesCompleted = 1, nil, 0
local raidSessionActive = false
local RAID_ISLAND_NEAR_RANGE = 3000
local lastRaidAutoTick, lastChipBuyTick, lastRaidStartAttempt, lastAttackTick = 0, 0, 0, 0
local lastRaidTimerVisible = false
local previewChipFruitName, previewChipFruitValue = nil, nil
local pendingRaidFruitLoad, lastFruitLoadTick = nil, 0
local lastSkillTicks = { Z = 0, X = 0, C = 0, V = 0, F = 0 }
local RAID_HOVER_HEIGHT = 72
local RAID_ISLAND_RANGE, RAID_ISLAND_COUNT = 550, 5
local RAID_BRING_RANGE, RAID_BRING_UNDER = 500, 0
local RAID_PLAYER_GAP = 50
local RAID_HITBOX_SIZE = 24
local RAID_FAST_ATTACK = 0.016
local RAID_CHIP_BUY_DELAY, RAID_START_DELAY = 1, 1
local RAID_SPEED_PAD, RAID_SPEED_COMBAT = 120, 220
local RAID_MOVE_CAP = 260
local RAID_MOVE_SPEED = 210
local RAID_MOVE_SPEED_TRAVEL = 228
local RAID_MOVE_ALPHA_CAP = 0.12
local RAID_HOVER_LERP, RAID_HOVER_TRAVEL_LERP = 11, 9
local RAID_MOB_LERP = 11
local RAID_MOB_PULL_SPEED = 165
local RAID_MOB_RING_BASE, RAID_MOB_RING_STEP = 14, 10
local RAID_ISLAND_CLEAR_DELAY = 2.2
local raidAttackAccum, raidSavedAutoRotate = 0, nil
local sendHitsToServer = nil
local fakeHitId = tostring(LocalPlayer.UserId):sub(2, 4) .. "psg"
local WEAPON_TOOLTIPS = { Melee = "Melee", Sword = "Sword", Fruit = "Blox Fruit", Gun = "Gun" }
local SKILL_KEYS = { Z = Enum.KeyCode.Z, X = Enum.KeyCode.X, C = Enum.KeyCode.C, V = Enum.KeyCode.V, F = Enum.KeyCode.F }
local ISLAND_TP_HEIGHT = 700
local MOVEMENT_SPEED_ISLAND, MOVEMENT_SPEED_FRUIT = 300, 380
local movementFollowTarget, movementFollowOwner, movementTweenPart, islandArrivalPending = nil, nil, nil, false
local noclipParts, savedGuiScreenPos = {}, nil
local selectedIsland, teleportToIslandEnabled = nil, false
local autoRandomFruit, autoStoreFruit, autoTweenFruit, fruitEspEnabled = false, false, false, false
local pendingFruitTarget, fruitEspByInstance = nil, {}
local stockNormalNames, stockMirageNames, fruitPriceByName, lastCousinAttempt, lastStoreAttempt = {}, {}, {}, 0, 0
local stockNormalResetIn, stockMirageResetIn = nil, nil
local lastStockFingerprint, lastStockPollAt = "", 0
local normalStockLabel, mirageStockLabel, stockDirty = nil, nil, true
local storeFruitBlocklist, lastTeleportMessage = {}, ""
local activeHrpTween = nil
local SEA_PLACE_IDS = { [1] = 2753915549, [2] = 4442272183, [3] = 7449423635 }
local FALLBACK_ISLANDS = {
	[1] = { "WindMill", "Marine", "Middle Town", "Jungle", "Pirate Village", "Desert", "Snow Island", "MarineFord", "Colosseum", "Sky Island 1", "Sky Island 2", "Sky Island 3", "Prison", "Magma Village", "Under Water Island", "Fountain City", "Shank Room", "Mob Island" },
	[2] = { "The Cafe", "Frist Spot", "Dark Area", "Flamingo Mansion", "Flamingo Room", "Green Zone", "Factory", "Colossuim", "Zombie Island", "Two Snow Mountain", "Punk Hazard", "Cursed Ship", "Ice Castle", "Forgotten Island", "Ussop Island", "Mini Sky Island" },
	[3] = { "Mansion", "Port Town", "Great Tree", "Castle On The Sea", "MiniSky", "Hydra Island", "Floating Turtle", "Haunted Castle", "Ice Cream Island", "Peanut Island", "Cake Island", "Cocoa Island", "Candy Island", "Tiki Outpost" },
}
local ISLAND_COORDS = {
	["WindMill"] = CFrame.new(979.79895019531, 16.516613006592, 1429.0466308594),
	["Marine"] = CFrame.new(-2566.4296875, 6.8556680679321, 2045.2561035156),
	["Middle Town"] = CFrame.new(-690.33081054688, 15.09425163269, 1582.2380371094),
	["Jungle"] = CFrame.new(-1612.7957763672, 36.852081298828, 149.12843322754),
	["Pirate Village"] = CFrame.new(-1181.3093261719, 4.7514905929565, 3803.5456542969),
	["Desert"] = CFrame.new(944.15789794922, 20.919729232788, 4373.3002929688),
	["Snow Island"] = CFrame.new(1347.8067626953, 104.66806030273, -1319.7370605469),
	["MarineFord"] = CFrame.new(-4914.8212890625, 50.963626861572, 4281.0278320313),
	["Colosseum"] = CFrame.new(-1427.6203613281, 7.2881078720093, -2792.7722167969),
	["Colossuim"] = CFrame.new(-1503.6224365234, 219.7956237793, 1369.3101806641),
	["Sky Island 1"] = CFrame.new(-4869.1025390625, 733.46051025391, -2667.0180664063),
	["Prison"] = CFrame.new(4875.330078125, 5.6519818305969, 734.85021972656),
	["Magma Village"] = CFrame.new(-5247.7163085938, 12.883934020996, 8504.96875),
	["Fountain City"] = CFrame.new(5127.1284179688, 59.501365661621, 4105.4458007813),
	["Shank Room"] = CFrame.new(-1442.16553, 29.8788261, -28.3547478),
	["Mob Island"] = CFrame.new(-2850.20068, 7.39224768, 5354.99268),
	["The Cafe"] = CFrame.new(-380.47927856445, 77.220390319824, 255.82550048828),
	["Frist Spot"] = CFrame.new(-11.311455726624, 29.276733398438, 2771.5224609375),
	["Dark Area"] = CFrame.new(3780.0302734375, 22.652164459229, -3498.5859375),
	["Flamingo Mansion"] = CFrame.new(-483.73370361328, 332.0383605957, 595.32708740234),
	["Flamingo Room"] = CFrame.new(2284.4140625, 15.152037620544, 875.72534179688),
	["Green Zone"] = CFrame.new(-2448.5300292969, 73.016105651855, -3210.6306152344),
	["Factory"] = CFrame.new(424.12698364258, 211.16171264648, -427.54049682617),
	["Zombie Island"] = CFrame.new(-5622.033203125, 492.19604492188, -781.78552246094),
	["Two Snow Mountain"] = CFrame.new(753.14288330078, 408.23559570313, -5274.6147460938),
	["Punk Hazard"] = CFrame.new(-6127.654296875, 15.951762199402, -5040.2861328125),
	["Cursed Ship"] = CFrame.new(923.40197753906, 125.05712890625, 32885.875),
	["Ice Castle"] = CFrame.new(6148.4116210938, 294.38687133789, -6741.1166992188),
	["Forgotten Island"] = CFrame.new(-3032.7641601563, 317.89672851563, -10075.373046875),
	["Ussop Island"] = CFrame.new(4816.8618164063, 8.4599885940552, 2863.8195800781),
	["Mini Sky Island"] = CFrame.new(-288.74060058594, 49326.31640625, -35248.59375),
	["Port Town"] = CFrame.new(-290.7376708984375, 6.729952812194824, 5343.5537109375),
	["Great Tree"] = CFrame.new(2681.2736816406, 1682.8092041016, -7190.9853515625),
	["Castle On The Sea"] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
	["MiniSky"] = CFrame.new(-260.65557861328, 49325.8046875, -35253.5703125),
	["Hydra Island"] = CFrame.new(5228.8842773438, 604.23400878906, 345.0400390625),
	["Floating Turtle"] = CFrame.new(-13274.528320313, 531.82073974609, -7579.22265625),
	["Haunted Castle"] = CFrame.new(-9515.3720703125, 164.00624084473, 5786.0610351562),
	["Ice Cream Island"] = CFrame.new(-902.56817626953, 79.93204498291, -10988.84765625),
	["Peanut Island"] = CFrame.new(-2062.7475585938, 50.473892211914, -10232.568359375),
	["Cake Island"] = CFrame.new(-1884.7747802734375, 19.327526092529297, -11666.8974609375),
	["Cocoa Island"] = CFrame.new(87.94276428222656, 73.55451202392578, -12319.46484375),
	["Candy Island"] = CFrame.new(-1014.4241943359375, 149.11068725585938, -14555.962890625),
	["Tiki Outpost"] = CFrame.new(-16542.447265625, 55.68632888793945, 1044.41650390625),
}
local ISLAND_ENTRANCE = {
	["Sky Island 2"] = Vector3.new(-4607.82275, 872.54248, -1667.55688),
	["Sky Island 3"] = Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047),
	["Under Water Island"] = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875),
	["Mansion"] = Vector3.new(-12471.169921875, 374.94024658203, -7551.677734375),
}
local SEA_TRAVEL_COMMF = {
	[1] = "TravelMain",
	[2] = "TravelDressrosa",
	[3] = "TravelZou",
}
local attackSettings = { weaponType = "Melee", attackMode = "Fast", skills = { Z = false, X = false, C = false, V = false, F = false } }
local bootstrapHits = 0
local lastRaidAction = "Select a raid, enable toggles. Buy/start work like ThanhDuy hub (CommF + pad click)."
local cachedCommF = nil
local FALLBACK_RAIDS = {
	Normal = { "Flame", "Ice", "Quake", "Light", "Dark", "Spider", "Magma", "Buddha", "Sand" },
	Advanced = { "Phoenix", "Dough", "Bird: Phoenix", "Dough: Dough" },
}
for _, name in FALLBACK_RAIDS.Normal do
	table.insert(raidLists.Normal, name)
end
for _, name in FALLBACK_RAIDS.Advanced do
	table.insert(raidLists.Advanced, name)
end
local function getCharacter() return LocalPlayer.Character end
local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end
local function tween(instance, props, info) return TweenService:Create(instance, info or TWEEN_INFO, props) end
local function bindHover(button, baseColor, hoverColor)
	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = hoverColor }, TWEEN_FAST):Play()
	end)
	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = baseColor }, TWEEN_FAST):Play()
	end)
end
local function getCommF()
	if cachedCommF and cachedCommF.Parent then return cachedCommF end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		or ReplicatedStorage:WaitForChild("Remotes", 15)
	cachedCommF = remotes and remotes:FindFirstChild("CommF_")
	return cachedCommF
end
local function invokeCommF(...)
	local commF = getCommF()
	if not commF then
		commF = ReplicatedStorage:WaitForChild("Remotes", 8):WaitForChild("CommF_", 8)
	end
	if not commF then return false, "CommF_ missing" end
	return pcall(function(...)
		return commF:InvokeServer(...)
	end, ...)
end
local function waitForDataLoaded(timeout)
	if LocalPlayer:FindFirstChild("DataLoaded") then return true end
	local marker = LocalPlayer:WaitForChild("DataLoaded", timeout or 12)
	return marker ~= nil
end
local function clickChooseTeamButton(teamName)
	local mainGui = LocalPlayer:FindFirstChild("PlayerGui")
		and LocalPlayer.PlayerGui:FindFirstChild("Main")
	if not mainGui then return false end
	local chooseTeam = mainGui:FindFirstChild("ChooseTeam")
	if not chooseTeam or not chooseTeam.Visible then return false end
	local container = chooseTeam:FindFirstChild("Container")
	if not container then return false end
	local teamFrame = container:FindFirstChild(teamName)
	if not teamFrame then return false end
	local viewport = teamFrame:FindFirstChild("Frame")
		and teamFrame.Frame:FindFirstChild("ViewportFrame")
	local button = viewport and viewport:FindFirstChild("TextButton")
	if not button then return false end
	if typeof(firesignal) == "function" then
		local ok = pcall(firesignal, button.MouseButton1Click)
		if ok then return true end
	end
	if typeof(getconnections) == "function" then
		for _, connection in getconnections(button.MouseButton1Click) do
			if connection.Function then
				pcall(connection.Function)
				return true
			end
		end
	end
	return false
end
local function joinTeam(teamName)
	waitForDataLoaded(12)
	if clickChooseTeamButton(teamName) then return true, "Joined via team selector (same as NPC click)." end
	local commF = getCommF()
	if not commF then
		commF = ReplicatedStorage:WaitForChild("Remotes", 10):WaitForChild("CommF_", 10)
	end
	if commF then
		local ok, result = pcall(function()
			return commF:InvokeServer("SetTeam", teamName)
		end)
		if ok then return true, "Team switch sent through CommF_ (recruiter path)." end
		return false, "CommF_ failed: " .. tostring(result)
	end
	return false, "Blox Fruits remotes not found."
end
local function getCurrentTeamLabel()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local teamStat = leaderstats:FindFirstChild("Team")
		if teamStat then return tostring(teamStat.Value) end
	end
	local data = LocalPlayer:FindFirstChild("Data")
	if data then
		local teamValue = data:FindFirstChild("Team")
		if teamValue then return tostring(teamValue.Value) end
	end
	return "Unknown"
end
local function getCurrentSeaNumber()
	for sea, placeId in SEA_PLACE_IDS do
		if game.PlaceId == placeId then return sea end
	end
	return 1
end
local function isPrivateServer() return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 end
local function ensureMovementTweenPart()
	if movementTweenPart and movementTweenPart.Parent then return movementTweenPart end
	local hrp = getRootPart()
	movementTweenPart = Instance.new("Part"); movementTweenPart.Name = "PlayerSettingsGUI_MoveTween"; movementTweenPart.Size = Vector3.new(1, 1, 1); movementTweenPart.Transparency = 1; movementTweenPart.CanCollide = false; movementTweenPart.Anchored = true; movementTweenPart.CFrame = hrp and hrp.CFrame or CFrame.new(); movementTweenPart.Parent = workspace
	return movementTweenPart
end
local function cancelHrpTween()
	if activeHrpTween then
		pcall(function()
			activeHrpTween:Cancel()
		end)
		activeHrpTween = nil
	end
end
local function hubTweenTo(cf, speed)
	local hrp = getRootPart()
	if not hrp or not cf then return false end
	local dist = (hrp.Position - cf.Position).Magnitude
	if dist < 4 then
		hrp.CFrame = cf
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		return true
	end
	cancelHrpTween()
	speed = speed or 300
	local duration = math.clamp(dist / speed, 0.08, 22)
	activeHrpTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = cf})
	activeHrpTween:Play()
	return false
end
local function setMovementTarget(cframe, owner, speed)
	ensureMovementTweenPart()
	movementFollowTarget = cframe
	movementFollowOwner = owner
	if speed then
		if owner == "raid" or owner == "raid_start" then
			if owner == "raid_start" then
				RAID_SPEED_PAD = speed
			else
				RAID_SPEED_COMBAT = speed
			end
		elseif owner == "fruit" then
			MOVEMENT_SPEED_FRUIT = speed
		elseif owner == "island" then
			MOVEMENT_SPEED_ISLAND = speed
		end
	end
	syncNoclipState()
end
local function syncMovementPartToPlayer()
	local hrp = getRootPart()
	if not hrp then return end
	ensureMovementTweenPart()
	if movementTweenPart then
		movementTweenPart.CFrame = hrp.CFrame
	end
end
local function smoothFlyTo(cf, speed, owner)
	if not cf then return end
	syncMovementPartToPlayer()
	setMovementTarget(cf, owner, speed)
end
local function hubFlyTo(cf, speed, owner)
	if not cf then return end
	local ownerName = owner or movementFollowOwner or "island"
	if ownerName == "island" or ownerName == "fruit" or ownerName == "raid" or ownerName == "raid_start" then
		local flySpeed = MOVEMENT_SPEED_ISLAND
		if ownerName == "fruit" then
			flySpeed = MOVEMENT_SPEED_FRUIT
		elseif ownerName == "raid_start" then
			flySpeed = RAID_SPEED_PAD
		elseif ownerName == "raid" then
			flySpeed = RAID_SPEED_COMBAT
		end
		smoothFlyTo(cf, speed or flySpeed, ownerName)
		return
	end
	local hrp = getRootPart()
	if not hrp then return end
	local dist = (hrp.Position - cf.Position).Magnitude
	if dist > 2500 then
		smoothFlyTo(cf, speed or MOVEMENT_SPEED_ISLAND, ownerName)
	else
		hubTweenTo(cf, speed)
	end
end
local function setNoclip(enabled)
	local char = getCharacter()
	if not char then return end
	for _, part in char:GetDescendants() do
		if part:IsA("BasePart") then
			if enabled then
				if noclipParts[part] == nil then
					noclipParts[part] = part.CanCollide
				end
				part.CanCollide = false
			elseif noclipParts[part] ~= nil then
				part.CanCollide = noclipParts[part]
				noclipParts[part] = nil
			end
		end
	end
end
local function isRaidTimerVisible()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	local main = playerGui:FindFirstChild("Main")
	if main then
		local timer = main:FindFirstChild("Timer")
		if timer and timer:IsA("GuiObject") and timer.Visible then return true end
		local topHud = main:FindFirstChild("TopHUDList")
		local raidTimer = topHud and topHud:FindFirstChild("RaidTimer")
		if raidTimer and raidTimer.Visible then return true end
	end
	for _, gui in playerGui:GetDescendants() do
		if gui.Name == "RaidTimer" and gui:IsA("GuiObject") and gui.Visible then
			return true
		end
	end
	return false
end
local function syncNoclipState()
	local shouldNoclip = movementFollowOwner ~= nil and (
		(movementFollowOwner == "island" and teleportToIslandEnabled)
		or (movementFollowOwner == "fruit" and autoTweenFruit)
		or (movementFollowOwner == "raid" and autoCompleteRaid)
		or (movementFollowOwner == "raid_start" and autoStartRaid)
	) or (autoCompleteRaid and (isRaidActive() or isNearAnyRaidIsland()))
	setNoclip(shouldNoclip)
end
local function raidTpTo(cf)
	local hrp = getRootPart()
	if not hrp or not cf then return end
	if hrp.Anchored then
		hrp.Anchored = false
	end
	hrp.CFrame = cf
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	local humanoid = getHumanoid()
	if humanoid and humanoid.Sit then
		humanoid.Sit = false
	end
	ensureMovementTweenPart()
	if movementTweenPart then
		movementTweenPart.CFrame = cf
	end
end
local function cleanupRaidMovement()
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, mob in enemies:GetChildren() do
			local mobRoot = mob:FindFirstChild("HumanoidRootPart")
			local lock = mobRoot:FindFirstChild("PSG_RaidBring")
			if lock then lock:Destroy() end
			local hitPart = mobRoot:FindFirstChild("PSG_RaidHit")
			if hitPart then hitPart:Destroy() end
		end
	end
	if movementFollowOwner == "raid" or movementFollowOwner == "raid_start" then
		clearMovement(movementFollowOwner)
	end
	setCombatHumanoidState(false)
end
local function setCombatHumanoidState(active)
	local humanoid = getHumanoid()
	if not humanoid then return end
	if active then
		if raidSavedAutoRotate == nil then
			raidSavedAutoRotate = humanoid.AutoRotate
		end
		humanoid.AutoRotate = false
	else
		if raidSavedAutoRotate ~= nil then
			humanoid.AutoRotate = raidSavedAutoRotate
			raidSavedAutoRotate = nil
		end
	end
end
local function clearMovement(owner)
	if owner == nil or movementFollowOwner == owner then
		movementFollowTarget = nil
		movementFollowOwner = nil
		cancelHrpTween()
		syncNoclipState()
	end
end
local function cleanupMovementSystem()
	clearMovement(nil)
	islandArrivalPending = false
	pendingFruitTarget = nil
	setNoclip(false)
	if movementTweenPart and movementTweenPart.Parent then
		movementTweenPart:Destroy()
	end
	movementTweenPart = nil
end
local function syncMovementTween(dt)
	if not alive or not movementFollowTarget then return end
	if movementFollowOwner == "raid" and not autoCompleteRaid then return end
	if movementFollowOwner == "raid_start" and not autoStartRaid then return end
	if movementFollowOwner == "island" and not teleportToIslandEnabled then return end
	if movementFollowOwner == "fruit" and not autoTweenFruit then return end
	local hrp = getRootPart()
	if not hrp or not movementTweenPart then return end
	local speed = MOVEMENT_SPEED_ISLAND
	if movementFollowOwner == "island" then
		speed = MOVEMENT_SPEED_ISLAND
	elseif movementFollowOwner == "fruit" then
		speed = MOVEMENT_SPEED_FRUIT
	elseif movementFollowOwner == "raid" then
		speed = RAID_SPEED_COMBAT
	elseif movementFollowOwner == "raid_start" then
		speed = RAID_SPEED_PAD
	end
	local current = movementTweenPart.CFrame
	local goal = movementFollowTarget
	local dist = (current.Position - goal.Position).Magnitude
	local step = speed * dt
	local alpha = dist > 0 and math.clamp(step / dist, 0, 1) or 1
	if movementFollowOwner == "raid" or movementFollowOwner == "raid_start" then
		alpha = math.min(alpha, RAID_MOVE_ALPHA_CAP)
	end
	local nextCf = current:Lerp(goal, alpha)
	movementTweenPart.CFrame = nextCf
	hrp.CFrame = nextCf
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.Sit = false
	end
	if movementFollowOwner == "island" and islandArrivalPending and dist <= 20 then
		islandArrivalPending = false
		if selectedIsland then
			pcall(function()
				invokeCommF("SetLastSpawnPoint", selectedIsland)
				invokeCommF("SetSpawnPoint")
			end)
		end
		if not teleportToIslandEnabled then
			clearMovement("island")
		end
	end
	syncNoclipState()
end
local function getIslandPartFromInstance(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then return inst end
	if inst:IsA("Model") then
		if inst.PrimaryPart then return inst.PrimaryPart end
		return inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end
local function getIslandLocationPart(islandName)
	if not islandName then return nil end
	local locations = workspace:FindFirstChild("_WorldOrigin")
		and workspace._WorldOrigin:FindFirstChild("Locations")
	if locations then
		local direct = locations:FindFirstChild(islandName)
		if direct then return getIslandPartFromInstance(direct) end
		local lowerNeedle = string.lower(islandName)
		for _, child in locations:GetChildren() do
			if child:IsA("BasePart") or child:IsA("Model") then
				if string.lower(child.Name) == lowerNeedle then
					return getIslandPartFromInstance(child)
				end
			end
		end
	end
	local map = workspace:FindFirstChild("Map")
	if map then
		local direct = map:FindFirstChild(islandName)
		if direct then return getIslandPartFromInstance(direct) end
	end
	return nil
end
local lastEntranceIsland = nil
local lastEntranceTick = 0
local function getIslandTeleportCFrame(islandName)
	if not islandName then return nil end
	local part = getIslandLocationPart(islandName)
	if part then
		return part.CFrame * CFrame.new(0, ISLAND_TP_HEIGHT, 0)
	end
	local entrance = ISLAND_ENTRANCE[islandName]
	if entrance then
		local now = tick()
		if lastEntranceIsland ~= islandName or now - lastEntranceTick > 2 then
			lastEntranceIsland = islandName
			lastEntranceTick = now
			pcall(function()
				invokeCommF("requestEntrance", entrance)
			end)
		end
		part = getIslandLocationPart(islandName)
		if part then
			return part.CFrame * CFrame.new(0, ISLAND_TP_HEIGHT, 0)
		end
		return nil
	end
	local cf = ISLAND_COORDS[islandName]
	if cf then
		return cf * CFrame.new(0, ISLAND_TP_HEIGHT, 0)
	end
	return nil
end
local function getCurrentSeaIslands()
	local sea = getCurrentSeaNumber()
	local fallback = FALLBACK_ISLANDS[sea] or {}
	local locations = workspace:FindFirstChild("_WorldOrigin")
		and workspace._WorldOrigin:FindFirstChild("Locations")
	if not locations then
		return fallback
	end
	local names, seen = {}, {}
	for _, islandName in fallback do
		if getIslandLocationPart(islandName) or ISLAND_COORDS[islandName] or ISLAND_ENTRANCE[islandName] then
			table.insert(names, islandName)
			seen[islandName] = true
		end
	end
	for _, child in locations:GetChildren() do
		if not seen[child.Name] and not string.match(child.Name, "^Island %d+$") then
			if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Folder") then
				table.insert(names, child.Name)
				seen[child.Name] = true
			end
		end
	end
	table.sort(names)
	return #names > 0 and names or fallback
end
local function getNearestIslandLabel(position)
	if not position then return "Unknown" end
	local locations = workspace:FindFirstChild("_WorldOrigin")
		and workspace._WorldOrigin:FindFirstChild("Locations")
	if not locations then return "Open sea" end
	local bestDist, bestName = math.huge, "Open sea"
	for _, child in locations:GetChildren() do
		if not string.match(child.Name, "^Island %d+$") then
			local part = getIslandPartFromInstance(child)
			if part then
				local dist = (part.Position - position).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestName = child.Name
				end
			end
		end
	end
	return bestName
end
local function travelToSea(seaNum)
	local targetPlace = SEA_PLACE_IDS[seaNum]
	if not targetPlace then
		lastTeleportMessage = "Invalid sea number."
		return false
	end
	if game.PlaceId == targetPlace then
		lastTeleportMessage = "Already on Sea " .. tostring(seaNum) .. "."
		return false
	end
	lastTeleportMessage = "Traveling to Sea " .. tostring(seaNum) .. "..."
	local travelCmd = SEA_TRAVEL_COMMF[seaNum]
	if travelCmd then
		local ok = pcall(function()
			invokeCommF(travelCmd)
		end)
		if ok then
			task.wait(0.6)
			if game.PlaceId == targetPlace then
				lastTeleportMessage = "Arrived on Sea " .. tostring(seaNum) .. "."
				return true
			end
		end
	end
	local ok, err = pcall(function()
		if isPrivateServer() then
			TeleportService:TeleportToPlaceInstance(targetPlace, game.JobId, LocalPlayer)
		else
			TeleportService:Teleport(targetPlace, LocalPlayer)
		end
	end)
	if not ok then
		lastTeleportMessage = "Travel failed: " .. tostring(err)
	end
	return ok
end
local buildGui = (function()
local function parseStockNames(payload, depth)
	depth = depth or 0
	local names = {}
	if type(payload) ~= "table" or depth > 4 then return names end
	if #payload > 0 then
		for _, entry in ipairs(payload) do
			if type(entry) == "string" and entry ~= "" then
				table.insert(names, entry)
			elseif type(entry) == "table" then
				if type(entry.Name) == "string" and entry.Name ~= "" then
					table.insert(names, entry.Name)
				elseif type(entry.Fruit) == "string" and entry.Fruit ~= "" then
					table.insert(names, entry.Fruit)
				elseif type(entry[1]) == "string" and entry[1] ~= "" then
					table.insert(names, entry[1])
				else
					for _, sub in ipairs(parseStockNames(entry, depth + 1)) do
						table.insert(names, sub)
					end
				end
			end
		end
	else
		for key, val in pairs(payload) do
			if type(key) == "string" then
				local lower = string.lower(key)
				if type(val) == "table" and (lower == "normal" or lower == "mirage" or lower == "advanced" or lower == "stock") then
					for _, sub in ipairs(parseStockNames(val, depth + 1)) do
						table.insert(names, sub)
					end
				elseif type(val) ~= "table" and lower ~= "normal" and lower ~= "mirage" and lower ~= "advanced" then
					table.insert(names, key)
				end
			end
		end
	end
	return names
end
local function ingestFruitPricesFromTable(fruits)
	if type(fruits) ~= "table" then return end
	for _, entry in pairs(fruits) do
		if type(entry) == "table" and type(entry.Name) == "string" and entry.Name ~= "" then
			local price = entry.Price or entry.Cost or entry.Value or entry.RobuxPrice
			if type(price) == "number" then
				fruitPriceByName[entry.Name] = price
			end
		end
	end
end
local function sortStockByPrice(names)
	table.sort(names, function(a, b)
		return (fruitPriceByName[a] or 0) < (fruitPriceByName[b] or 0)
	end)
	return names
end
local function getUtcStockCountdown(intervalHours)
	local utc = os.date("!*t")
	local elapsed = (utc.hour * 3600) + (utc.min * 60) + utc.sec
	local period = intervalHours * 3600
	local remain = period - (elapsed % period)
	if remain <= 0 or remain > period then
		remain = period
	end
	return remain
end
local function formatStockCountdown(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%dm %02ds", minutes, secs)
end
local function extractStockTimer(payload, keys)
	if type(payload) ~= "table" then return nil end
	for _, key in keys do
		local value = payload[key]
		if type(value) == "number" and value > 0 then
			return value
		end
	end
	return nil
end
local function refreshFruitStockLists()
	local nextNormal, nextMirage = {}, {}
	local normalTimer, mirageTimer = nil, nil
	local ok, result = invokeCommF("GetStock")
	if ok and type(result) == "table" then
		if type(result.Normal) == "table" then
			nextNormal = sortStockByPrice(parseStockNames(result.Normal))
		end
		if type(result.Mirage) == "table" then
			nextMirage = sortStockByPrice(parseStockNames(result.Mirage))
		elseif type(result.Advanced) == "table" then
			nextMirage = sortStockByPrice(parseStockNames(result.Advanced))
		end
		normalTimer = extractStockTimer(result, { "NormalRefresh", "NormalTime", "RefreshNormal", "NormalTimer" })
		mirageTimer = extractStockTimer(result, { "MirageRefresh", "MirageTime", "RefreshMirage", "AdvancedRefresh", "AdvancedTime", "RefreshAdvanced" })
	end
	ok, result = invokeCommF("GetNormalStock")
	if ok and type(result) == "table" then
		local names = parseStockNames(result)
		if #names > 0 then
			nextNormal = sortStockByPrice(names)
		end
		normalTimer = normalTimer or extractStockTimer(result, { "Refresh", "Time", "Timer" })
	end
	ok, result = invokeCommF("GetMirageStock")
	if ok and type(result) == "table" then
		local names = parseStockNames(result)
		if #names > 0 then
			nextMirage = sortStockByPrice(names)
		end
		mirageTimer = mirageTimer or extractStockTimer(result, { "Refresh", "Time", "Timer" })
	end
	ok, result = invokeCommF("GetAdvancedStock")
	if ok and type(result) == "table" then
		local names = parseStockNames(result)
		if #names > 0 then
			nextMirage = sortStockByPrice(names)
		end
		mirageTimer = mirageTimer or extractStockTimer(result, { "Refresh", "Time", "Timer" })
	end
	ok, result = invokeCommF("GetFruits")
	if ok and type(result) == "table" then
		ingestFruitPricesFromTable(result)
		if #nextNormal == 0 then
			local normalFromSale = {}
			for _, entry in pairs(result) do
				if type(entry) == "table" and type(entry.Name) == "string" and entry.Name ~= "" then
					if entry.OnSale == true or entry.Stock == true or entry.InStock == true then
						table.insert(normalFromSale, entry.Name)
					end
				end
			end
			if #normalFromSale > 0 then
				nextNormal = sortStockByPrice(normalFromSale)
			end
		end
		if #nextMirage == 0 then
			local mirageFromSale = {}
			for _, entry in pairs(result) do
				if type(entry) == "table" and type(entry.Name) == "string" and entry.Name ~= "" then
					if entry.MirageOnSale == true or entry.AdvancedOnSale == true
						or entry.OnMirageSale == true or entry.MirageStock == true
						or entry.AdvancedStock == true
					then
						table.insert(mirageFromSale, entry.Name)
					end
				end
			end
			if #mirageFromSale > 0 then
				nextMirage = sortStockByPrice(mirageFromSale)
			end
		end
	end
	stockNormalNames = nextNormal
	stockMirageNames = nextMirage
	stockNormalResetIn = normalTimer or getUtcStockCountdown(4)
	stockMirageResetIn = mirageTimer or getUtcStockCountdown(2)
end
local function formatStockText(names, resetIn)
	local lines = {}
	if type(resetIn) == "number" then
		table.insert(lines, "Resets in: " .. formatStockCountdown(resetIn))
	end
	if #names == 0 then
		table.insert(lines, "— nothing in stock right now —")
	else
		for _, name in ipairs(names) do
			local price = fruitPriceByName[name]
			if type(price) == "number" and price > 0 then
				table.insert(lines, name .. " ($" .. tostring(price) .. ")")
			else
				table.insert(lines, name)
			end
		end
	end
	return table.concat(lines, "\n")
end
local lastStockUiRefresh = 0
local function refreshStockDisplay(force)
	local now = tick()
	if not force and now - lastStockUiRefresh < 1 then return end
	lastStockUiRefresh = now
	if force or now - lastStockPollAt >= 20 then
		lastStockPollAt = now
		pcall(refreshFruitStockLists)
	end
	local fingerprint = table.concat(stockNormalNames, "|") .. ";" .. table.concat(stockMirageNames, "|")
	if fingerprint ~= lastStockFingerprint then
		lastStockFingerprint = fingerprint
		stockDirty = true
	end
	local normalRemain = stockNormalResetIn or getUtcStockCountdown(4)
	local mirageRemain = stockMirageResetIn or getUtcStockCountdown(2)
	if normalStockLabel then
		normalStockLabel.Text = formatStockText(stockNormalNames, normalRemain)
	end
	if mirageStockLabel then
		mirageStockLabel.Text = formatStockText(stockMirageNames, mirageRemain)
	end
	stockDirty = false
end
local function getFruitHandle(fruit)
	if not fruit then return nil end
	if fruit:IsA("BasePart") then return fruit end
	if fruit:FindFirstChild("Handle") then return fruit.Handle end
	return fruit:FindFirstChildWhichIsA("BasePart")
end
local function isFruitInstance(obj)
	if not obj then return false end
	if obj.Parent == getCharacter() then return false end
	if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
		if obj:GetAttribute("WeaponType") then return false end
		if obj:FindFirstChild("Fruit") then return true end
		if obj.ToolTip == "Blox Fruit" then return true end
		if string.find(obj.Name, "Fruit", 1, true) then return true end
		if obj.Parent == workspace or (workspace:FindFirstChild("DroppedFruits") and obj.Parent == workspace.DroppedFruits) then
			if string.find(obj.Name, "-", 1, true) then return true end
		end
	end
	if obj:IsA("Model") and getFruitHandle(obj) then
		if obj:FindFirstChild("Fruit") or string.find(obj.Name, "Fruit", 1, true) or string.find(obj.Name, "-", 1, true) then
			return true
		end
	end
	return false
end
local function findWorldFruits()
	local found = {}
	local seen = {}
	local function add(obj)
		if obj and not seen[obj] and isFruitInstance(obj) then
			seen[obj] = true
			table.insert(found, obj)
		end
	end
	for _, child in workspace:GetChildren() do
		add(child)
	end
	local dropped = workspace:FindFirstChild("DroppedFruits")
	if dropped then
		for _, child in dropped:GetChildren() do
			add(child)
		end
		for _, child in dropped:GetDescendants() do
			if child:IsA("Tool") or child:IsA("Model") then
				add(child)
			end
		end
	end
	for _, child in workspace:GetChildren() do
		if child:IsA("Tool") and child.Parent == workspace and child:FindFirstChild("Handle") then
			add(child)
		end
	end
	return found
end
local function getNearestWorldFruit()
	local hrp = getRootPart()
	if not hrp then return nil end
	local nearest, best = nil, math.huge
	for _, fruit in findWorldFruits() do
		local handle = getFruitHandle(fruit)
		if handle then
			local dist = (handle.Position - hrp.Position).Magnitude
			if dist < best then
				best = dist
				nearest = fruit
			end
		end
	end
	return nearest
end
local function collectFruit(fruit)
	local handle = getFruitHandle(fruit)
	local hrp = getRootPart()
	if not handle or not hrp then return false end
	if typeof(firetouchinterest) == "function" then
		pcall(firetouchinterest, handle, hrp, 0)
		pcall(firetouchinterest, handle, hrp, 1)
		pcall(firetouchinterest, hrp, handle, 0)
		pcall(firetouchinterest, hrp, handle, 1)
	end
	local prompt = handle:FindFirstChildOfClass("ProximityPrompt")
		or fruit:FindFirstChildOfClass("ProximityPrompt")
	if prompt and typeof(fireproximityprompt) == "function" then
		pcall(fireproximityprompt, prompt, 0)
		pcall(fireproximityprompt, prompt)
	end
	return true
end
local function clearFruitEsp()
	for inst, visuals in fruitEspByInstance do
		if visuals.highlight then
			visuals.highlight:Destroy()
		end
		if visuals.gui then
			visuals.gui:Destroy()
		end
		fruitEspByInstance[inst] = nil
	end
end
local function buildFruitEspText(fruit, handle)
	local hrp = getRootPart()
	local distText = "?"
	if hrp and handle then
		distText = tostring(math.floor((handle.Position - hrp.Position).Magnitude)) .. " studs"
	end
	local islandName = handle and getNearestIslandLabel(handle.Position) or "Unknown"
	return fruit.Name .. "\n" .. distText .. " | " .. islandName
end
local function updateFruitEsp()
	if not fruitEspEnabled then
		clearFruitEsp()
		return
	end
	local live = {}
	for _, fruit in findWorldFruits() do
		live[fruit] = true
		local handle = getFruitHandle(fruit)
		if not fruitEspByInstance[fruit] then
			local highlight = Instance.new("Highlight"); highlight.Name = "PSG_FruitESP"; highlight.FillColor = Color3.fromRGB(255, 105, 220); highlight.OutlineColor = Color3.fromRGB(255, 255, 255); highlight.FillTransparency = 0.35; highlight.Parent = fruit
			local gui = Instance.new("BillboardGui"); gui.Name = "PSG_FruitTag"; gui.Size = UDim2.fromOffset(160, 52); gui.AlwaysOnTop = true; gui.MaxDistance = 9000; gui.Adornee = handle; gui.Parent = fruit
			local tag = Instance.new("TextLabel"); tag.Name = "Tag"; tag.Size = UDim2.fromScale(1, 1); tag.BackgroundTransparency = 0.35; tag.BackgroundColor3 = Color3.fromRGB(20, 20, 28); tag.Font = Enum.Font.GothamBold; tag.TextSize = 10; tag.TextWrapped = true; tag.TextColor3 = Color3.fromRGB(255, 220, 255); tag.Text = buildFruitEspText(fruit, handle); tag.Parent = gui
			local tagCorner = Instance.new("UICorner"); tagCorner.CornerRadius = UDim.new(0, 4); tagCorner.Parent = tag
			fruitEspByInstance[fruit] = { highlight = highlight, gui = gui, tag = tag }
		elseif fruitEspByInstance[fruit].tag and handle then
			fruitEspByInstance[fruit].tag.Text = buildFruitEspText(fruit, handle)
		end
	end
	for inst, visuals in fruitEspByInstance do
		if not live[inst] or not inst.Parent then
			if visuals.highlight then
				visuals.highlight:Destroy()
			end
			if visuals.gui then
				visuals.gui:Destroy()
			end
			fruitEspByInstance[inst] = nil
		end
	end
end
local function loadRaidLists()
	raidLists.Normal = {}
	raidLists.Advanced = {}
	local ok, raidsData = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Raids", 8))
	end)
	if not ok or type(raidsData) ~= "table" then
		for _, name in FALLBACK_RAIDS.Normal do
			table.insert(raidLists.Normal, name)
		end
		for _, name in FALLBACK_RAIDS.Advanced do
			table.insert(raidLists.Advanced, name)
		end
		return
	end
	local function addRaidName(raidName, isAdvanced)
		if type(raidName) ~= "string" or raidName == "" then return end
		local bucket = isAdvanced and raidLists.Advanced or raidLists.Normal
		if not table.find(bucket, raidName) then
			table.insert(bucket, raidName)
		end
		if string.find(raidName, ":", 1, true) and not table.find(raidLists.Advanced, raidName) then
			table.insert(raidLists.Advanced, raidName)
		end
	end
	if type(raidsData.raids) == "table" then
		for _, raidName in pairs(raidsData.raids) do
			addRaidName(raidName, false)
		end
	end
	if type(raidsData.advancedRaids) == "table" then
		for _, raidName in pairs(raidsData.advancedRaids) do
			addRaidName(raidName, true)
		end
	end
	for category, entries in pairs(raidsData) do
		if type(entries) == "table" then
			local categoryName = string.lower(tostring(category))
			local isAdvanced = string.find(categoryName, "advanced") ~= nil
				or string.find(categoryName, "special") ~= nil
			for _, raidName in pairs(entries) do
				if type(raidName) == "string" then
					local bucket = isAdvanced and raidLists.Advanced or raidLists.Normal
					if not table.find(bucket, raidName) then
						table.insert(bucket, raidName)
					end
					if string.find(raidName, ":") and not table.find(raidLists.Advanced, raidName) then
						table.insert(raidLists.Advanced, raidName)
					end
				end
			end
		elseif type(entries) == "string" then
			local bucket = raidLists.Normal
			if not table.find(bucket, entries) then
				table.insert(bucket, entries)
			end
		end
	end
	if #raidLists.Normal == 0 then
		for _, name in FALLBACK_RAIDS.Normal do
			table.insert(raidLists.Normal, name)
		end
	end
	if #raidLists.Advanced == 0 then
		for _, name in FALLBACK_RAIDS.Advanced do
			table.insert(raidLists.Advanced, name)
		end
	end
	table.sort(raidLists.Normal)
	table.sort(raidLists.Advanced)
end
local function getFruitToolInInventory()
	local character = getCharacter()
	for _, container in ipairs({ LocalPlayer.Backpack, character }) do
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and not item:GetAttribute("WeaponType") then
					if item:FindFirstChild("Fruit") or string.find(item.Name, "Fruit", 1, true)
						or item.ToolTip == "Blox Fruit" or string.find(item.Name, "-", 1, true)
					then
						return item
					end
				end
			end
		end
	end
	return nil
end
local function getFruitStorageName(tool)
	if not tool then return nil end
	local attr = tool:GetAttribute("OriginalName")
	if type(attr) == "string" and attr ~= "" then return attr end
	local fruitChild = tool:FindFirstChild("Fruit")
	if fruitChild and fruitChild:IsA("StringValue") and fruitChild.Value ~= "" then
		return fruitChild.Value
	end
	return tool.Name
end
local function normalizeFruitKey(name)
	if type(name) ~= "string" then return "" end
	local base = string.match(name, "^([^%-]+)")
	return string.lower(base or name)
end
local function isFruitAlreadyStored(storageName)
	if storeFruitBlocklist[storageName] then return true end
	local key = normalizeFruitKey(storageName)
	if key ~= "" and storeFruitBlocklist[key] then return true end
	local data = LocalPlayer:FindFirstChild("Data")
	if data then
		local fruitsFolder = data:FindFirstChild("Fruits") or data:FindFirstChild("StoredFruits")
		if fruitsFolder then
			for _, stored in fruitsFolder:GetChildren() do
				local storedName = stored.Name
				if stored:IsA("StringValue") then
					storedName = stored.Value
				end
				if normalizeFruitKey(storedName) == key then
					return true
				end
			end
		end
		for _, child in data:GetChildren() do
			local lower = string.lower(child.Name)
			if child:IsA("Folder") and (string.find(lower, "storage", 1, true) or string.find(lower, "treasure", 1, true)) then
				for _, stored in child:GetChildren() do
					if normalizeFruitKey(stored.Name) == key then
						return true
					end
				end
			end
		end
	end
	local ok, inv = invokeCommF("getInventory")
	if ok and type(inv) == "table" then
		for _, entry in pairs(inv) do
			if type(entry) == "table" and entry.Type == "Blox Fruit" then
				local name = entry.Name or entry.FruitName
				if name and normalizeFruitKey(name) == key then
					if entry.Storage or entry.Stored or entry.InStorage or entry.Location == "Storage" then
						return true
					end
				end
			end
		end
	end
	return false
end
local CHIP_FRUIT_VALUES = {
	["Rocket-Rocket"] = 5000, ["Spin-Spin"] = 75000, ["Spring-Spring"] = 60000,
	["Blade-Blade"] = 30000, ["Smoke-Smoke"] = 100000, ["Bomb-Bomb"] = 80000,
	["Spike-Spike"] = 180000, ["Chop-Chop"] = 30000, ["Barrier-Barrier"] = 80000,
	["Love-Love"] = 1300000, ["Rubber-Rubber"] = 750000, ["Ghost-Ghost"] = 940000,
}
local function raidAutomationEnabled()
	return raidBuyBeli or raidBuyFruit or autoStartRaid or autoCompleteRaid
end
local function resolveSendHits()
	if sendHitsToServer then return sendHitsToServer end
	if typeof(getsenv) == "function" then
		local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
		if playerScripts then
			for _, scriptInstance in playerScripts:GetChildren() do
				if scriptInstance:IsA("LocalScript") then
					local ok, env = pcall(getsenv, scriptInstance)
					if ok and type(env) == "table" and env._G and type(env._G.SendHitsToServer) == "function" then
						sendHitsToServer = env._G.SendHitsToServer
						return sendHitsToServer
					end
				end
			end
		end
	end
	local modules = ReplicatedStorage:FindFirstChild("Modules")
	local net = modules and modules:FindFirstChild("Net")
	if net then
		local registerAttack = net:FindFirstChild("RE/RegisterAttack")
		local registerHit = net:FindFirstChild("RE/RegisterHit")
		if registerAttack and registerHit then
			sendHitsToServer = function(hitPart, hitList)
				registerAttack:FireServer(0)
				registerHit:FireServer(hitPart, hitList or { { hitPart, hitPart } }, nil, fakeHitId)
			end
		end
	end
	return sendHitsToServer
end
local function isLoadingMap()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	for _, gui in playerGui:GetDescendants() do
		if gui:IsA("TextLabel") or gui:IsA("TextButton") then
			local text = string.lower(gui.Text or "")
			if string.find(text, "loading map", 1, true) then return true end
		end
	end
	return false
end
local function isRaidActive()
	return isRaidTimerVisible() or isLoadingMap()
end
local function hasMicrochip()
	for _, container in ipairs({ LocalPlayer.Backpack, getCharacter() }) do
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and item.Name == "Special Microchip" then return true end
			end
		end
	end
	return false
end
local function getMicrochipTool()
	for _, container in ipairs({ LocalPlayer.Backpack, getCharacter() }) do
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and item.Name == "Special Microchip" then return item end
			end
		end
	end
	return nil
end
local function equipMicrochip()
	local humanoid = getHumanoid()
	local chip = getMicrochipTool()
	if humanoid and chip and chip.Parent ~= getCharacter() then
		pcall(function() humanoid:EquipTool(chip) end)
	end
	return chip
end
local function getRaidSea()
	local sea = getCurrentSeaNumber()
	if sea == 2 or sea == 3 then return sea end
	local map = workspace:FindFirstChild("Map")
	if not map then return nil end
	if map:FindFirstChild("Boat Castle") or map:FindFirstChild("Castle on the Sea") then return 3 end
	if map:FindFirstChild("CircleIsland") or map:FindFirstChild("Hot and Cold") or map:FindFirstChild("HotAndCold") then
		return 2
	end
	return nil
end
local function getRaidIslandPartRaw(islandName)
	local locations = workspace:FindFirstChild("_WorldOrigin")
	locations = locations and locations:FindFirstChild("Locations")
	if not locations then return nil end
	local island = locations:FindFirstChild(islandName)
	if not island then return nil end
	return getIslandPartFromInstance(island) or (island:IsA("BasePart") and island) or island:FindFirstChildWhichIsA("BasePart", true)
end
local function getRaidIslandNear(islandName)
	local hrp = getRootPart()
	local part = getRaidIslandPartRaw(islandName)
	if not hrp or not part then return nil end
	if (part.Position - hrp.Position).Magnitude <= RAID_ISLAND_NEAR_RANGE then
		return part
	end
	return nil
end
local function isNearAnyRaidIsland()
	for index = 1, RAID_ISLAND_COUNT do
		if getRaidIslandNear("Island " .. tostring(index)) then return true end
	end
	return false
end
local function getActiveRaidIslandPart()
	if not isRaidActive() and not isNearAnyRaidIsland() then return nil, 1 end
	for index = RAID_ISLAND_COUNT, 1, -1 do
		local part = getRaidIslandNear("Island " .. tostring(index))
		if part then return part, index end
	end
	return nil, 1
end
local function clickAllRaidSummonPads()
	local map = workspace:FindFirstChild("Map")
	if not map or typeof(fireclickdetector) ~= "function" then return false end
	local sea = getRaidSea()
	local zoneNames = {}
	if sea == 2 then
		zoneNames = { "CircleIsland", "Hot and Cold", "HotAndCold" }
	elseif sea == 3 then
		zoneNames = { "Boat Castle", "Castle on the Sea" }
	end
	local fired = false
	for _, zoneName in zoneNames do
		local zone = map:FindFirstChild(zoneName)
		if zone then
			for _, summonName in ipairs({ "RaidSummon2", "RaidSummon" }) do
				local pad = zone:FindFirstChild(summonName)
				local main = pad and pad:FindFirstChild("Button") and pad.Button:FindFirstChild("Main")
				local detector = main and main:FindFirstChild("ClickDetector")
				if detector then
					pcall(fireclickdetector, detector, 0)
					fired = true
				end
				if pad then
					for _, prompt in pad:GetDescendants() do
						if prompt:IsA("ProximityPrompt") and typeof(fireproximityprompt) == "function" then
							pcall(fireproximityprompt, prompt, 0)
							fired = true
						end
					end
				end
			end
		end
	end
	return fired
end
local function isInPlayerRaidWorld()
	return isRaidActive() or isNearAnyRaidIsland()
end
local function isAdvancedRaidName(raidName)
	if type(raidName) ~= "string" then return false end
	if table.find(raidLists.Advanced, raidName) then return true end
	local lower = string.lower(raidName)
	return string.find(lower, "phoenix", 1, true) ~= nil or string.find(lower, "dough", 1, true) ~= nil
end
local function getFruitBeliValue(fruitName)
	if type(fruitName) ~= "string" or fruitName == "" then return math.huge end
	if CHIP_FRUIT_VALUES[fruitName] then return CHIP_FRUIT_VALUES[fruitName] end
	local key = normalizeFruitKey(fruitName)
	for name, value in CHIP_FRUIT_VALUES do
		if normalizeFruitKey(name) == key then return value end
	end
	return math.huge
end
local function hasFruitToolNamed(fruitName)
	if not fruitName then return false, nil end
	local key = normalizeFruitKey(fruitName)
	for _, container in ipairs({ LocalPlayer.Backpack, getCharacter() }) do
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and not item:GetAttribute("WeaponType") then
					local storageName = getFruitStorageName(item)
					if storageName and normalizeFruitKey(storageName) == key then
						return true, item
					end
				end
			end
		end
	end
	return false, nil
end
local function equipFruitToolNamed(fruitName)
	local found, tool = hasFruitToolNamed(fruitName)
	if not found or not tool then return nil end
	local humanoid = getHumanoid()
	if humanoid and tool.Parent ~= getCharacter() then
		pcall(function() humanoid:EquipTool(tool) end)
	end
	return tool
end
local function getLowestChipFruitInfo()
	local advanced = isAdvancedRaidName(selectedRaid)
	local minValue = advanced and 1000000 or 0
	local maxValue = advanced and math.huge or 1000000
	local bestName, bestValue = nil, math.huge
	local function consider(name, price)
		if type(name) ~= "string" or name == "" then return end
		price = tonumber(price) or getFruitBeliValue(name)
		if fruitPriceByName[name] then price = fruitPriceByName[name] end
		if type(price) == "number" then fruitPriceByName[name] = price end
		if price >= minValue and price < maxValue and price < bestValue then
			bestName, bestValue = name, price
		end
	end
	local ok, inv = invokeCommF("getInventory")
	if ok and type(inv) == "table" then
		for _, entry in pairs(inv) do
			if type(entry) == "table" and entry.Type == "Blox Fruit" then
				consider(entry.Name or entry.FruitName, entry.Value or entry.Price)
			end
		end
	end
	local okFruits, fruits = invokeCommF("getInventoryFruits")
	if okFruits and type(fruits) == "table" then
		for _, entry in pairs(fruits) do
			if type(entry) == "table" then consider(entry.Name, entry.Price or entry.Value) end
		end
	end
	for _, container in ipairs({ LocalPlayer.Backpack, getCharacter() }) do
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and not item:GetAttribute("WeaponType") then
					if item:FindFirstChild("Fruit") or item.ToolTip == "Blox Fruit" or string.find(item.Name, "-", 1, true) then
						consider(getFruitStorageName(item))
					end
				end
			end
		end
	end
	return bestName, bestValue
end
local function raidBuyChipBeli()
	if not selectedRaid then lastRaidAction = "Buy: select a raid"; return false end
	if hasMicrochip() then lastRaidAction = "Buy: already have chip"; return false end
	if isRaidActive() or isNearAnyRaidIsland() then lastRaidAction = "Buy: wait for raid to end"; return false end
	if not getRaidSea() then lastRaidAction = "Buy: need Sea 2 or 3"; return false end
	pendingRaidFruitLoad = nil
	local humanoid = getHumanoid()
	if humanoid then pcall(function() humanoid:UnequipTools() end) end
	local fruitTool = getFruitToolInInventory()
	if fruitTool and fruitTool.Parent == getCharacter() then
		lastRaidAction = "Buy: unequipping fruit for beli payment..."
		return false
	end
	lastRaidAction = "Buy: purchasing " .. selectedRaid .. " chip (beli)..."
	invokeCommF("RaidsNpc", "Select", selectedRaid)
	if not hasMicrochip() then
		invokeCommF("RaidsNpc", "Select", selectedRaid, "Money")
	end
	if hasMicrochip() then
		lastRaidAction = "Buy: chip acquired (beli)"
		return true
	end
	lastRaidAction = "Buy: beli payment pending (need 100k + lvl 1100)..."
	return false
end
local function raidBuyChipFruit()
	if not selectedRaid then lastRaidAction = "Buy: select a raid"; return false end
	if hasMicrochip() then lastRaidAction = "Buy: already have chip"; return false end
	if isRaidActive() or isNearAnyRaidIsland() then lastRaidAction = "Buy: wait for raid to end"; return false end
	if not getRaidSea() then lastRaidAction = "Buy: need Sea 2 or 3"; return false end
	local fruitName, fruitValue = getLowestChipFruitInfo()
	previewChipFruitName, previewChipFruitValue = fruitName, fruitValue
	if not fruitName then
		lastRaidAction = isAdvancedRaidName(selectedRaid) and "Buy: need fruit worth 1M+ in bag" or "Buy: no fruit in bag"
		return false
	end
	if not hasFruitToolNamed(fruitName) then
		if pendingRaidFruitLoad ~= fruitName or tick() - lastFruitLoadTick >= 1.5 then
			pendingRaidFruitLoad = fruitName
			lastFruitLoadTick = tick()
			lastRaidAction = string.format("Buy: pulling %s from bag ($%s)...", fruitName, tostring(fruitValue or "?"))
			invokeCommF("LoadFruit", fruitName)
		else
			lastRaidAction = string.format("Buy: waiting for %s to load...", fruitName)
		end
		return false
	end
	pendingRaidFruitLoad = nil
	equipFruitToolNamed(fruitName)
	lastRaidAction = string.format("Buy: purchasing %s chip with %s ($%s)", selectedRaid, fruitName, tostring(fruitValue or "?"))
	invokeCommF("RaidsNpc", "Select", selectedRaid)
	if hasMicrochip() then
		lastRaidAction = "Buy: chip acquired (" .. fruitName .. ")"
		return true
	end
	lastRaidAction = "Buy: fruit payment pending..."
	return false
end
local function raidAutoStart()
	if not autoStartRaid then return false end
	if not hasMicrochip() then lastRaidAction = "Start: need microchip"; return false end
	if isRaidActive() or isNearAnyRaidIsland() then return false end
	local now = tick()
	if now - lastRaidStartAttempt < RAID_START_DELAY then return false end
	lastRaidStartAttempt = now
	equipMicrochip()
	if not clickAllRaidSummonPads() then
		lastRaidAction = "Start: raid pad not found"
		return false
	end
	lastRaidAction = "Start: clicked raid pad — entering..."
	return true
end
local function isAliveMob(mob)
	if not mob or not mob.Parent then return false end
	local humanoid = mob:FindFirstChild("Humanoid")
	local head = mob:FindFirstChild("Head")
	local root = mob:FindFirstChild("HumanoidRootPart")
	return humanoid and humanoid.Health > 0 and head and root
end
local function getRaidNetRemotes()
	local modules = ReplicatedStorage:FindFirstChild("Modules")
	local net = modules and modules:FindFirstChild("Net")
	if not net then return nil, nil end
	return net:FindFirstChild("RE/RegisterAttack"), net:FindFirstChild("RE/RegisterHit")
end
local function equipWeaponByType(weaponType)
	local character, humanoid = getCharacter(), getHumanoid()
	if not character or not humanoid then return nil end
	local tooltip = WEAPON_TOOLTIPS[weaponType] or weaponType
	for _, container in ipairs({ LocalPlayer.Backpack, character }) do
		if container then
			for _, tool in container:GetChildren() do
				if tool:IsA("Tool") and tool.ToolTip == tooltip then
					if tool.Parent ~= character then pcall(function() humanoid:EquipTool(tool) end) end
					return tool
				end
			end
		end
	end
	return nil
end
local function attackAllMobs(mobs)
	if #mobs == 0 then return end
	local tool = equipWeaponByType(attackSettings.weaponType)
	if not tool then return end
	local hitList, primaryHit = {}, nil
	for _, mob in mobs do
		if isAliveMob(mob) then
			local mobRoot = mob.HumanoidRootPart
			local hitPart = mobRoot:FindFirstChild("PSG_RaidHit") or mob:FindFirstChild("Head") or mobRoot
			if hitPart then
				table.insert(hitList, { mob, hitPart })
				if not primaryHit then primaryHit = hitPart end
			end
		end
	end
	if #hitList == 0 or not primaryHit then return end
	local registerAttack, registerHit = getRaidNetRemotes()
	if not registerAttack or not registerHit then return end
	if tool.ToolTip == "Blox Fruit" then
		local leftClick = tool:FindFirstChild("LeftClickRemote")
		if leftClick and leftClick:IsA("RemoteEvent") then
			pcall(function()
				leftClick:FireServer(Vector3.new(0, -RAID_PLAYER_GAP, 0), #hitList, true)
				leftClick:FireServer(false)
			end)
		end
	end
	pcall(function() tool:Activate() end)
	registerAttack:FireServer(0)
	local hitsFn = resolveSendHits()
	if hitsFn then pcall(hitsFn, primaryHit, hitList) end
	registerHit:FireServer(primaryHit, hitList, nil, fakeHitId)
end
local function raidCappedLerpAlpha(fromPos, toPos, dt, speedStudsPerSec)
	local dist = (toPos - fromPos).Magnitude
	if dist < 0.05 then return 1 end
	dt = math.clamp(dt, 1 / 240, 0.1)
	local maxStep = math.min(speedStudsPerSec, RAID_MOVE_CAP) * dt
	local expAlpha = 1 - math.exp(-RAID_HOVER_LERP * dt)
	return math.min(expAlpha, maxStep / dist, RAID_MOVE_ALPHA_CAP)
end
local function getRaidHoverCFrame(islandPart)
	local hoverPos = islandPart.Position + Vector3.new(0, RAID_HOVER_HEIGHT, 0)
	local lookAt = hoverPos + Vector3.new(0, -RAID_PLAYER_GAP, 0)
	return CFrame.new(hoverPos, lookAt)
end
local function smoothCombatHover(islandPart, dt)
	local hrp = getRootPart()
	if not hrp or not islandPart then return end
	dt = math.clamp(dt or 1 / 60, 1 / 240, 0.1)
	ensureMovementTweenPart()
	local targetCf = getRaidHoverCFrame(islandPart)
	local currentCf = movementTweenPart.CFrame
	local dist = (currentCf.Position - targetCf.Position).Magnitude
	local speed = dist > 100 and RAID_MOVE_SPEED_TRAVEL or RAID_MOVE_SPEED
	local alpha = raidCappedLerpAlpha(currentCf.Position, targetCf.Position, dt, speed)
	local nextCf = currentCf:Lerp(targetCf, alpha)
	movementTweenPart.CFrame = nextCf
	hrp.CFrame = nextCf
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end
local function getOrCreateRaidHitPart(mob, mobRoot)
	local hit = mobRoot:FindFirstChild("PSG_RaidHit")
	if hit then return hit end
	hit = Instance.new("Part")
	hit.Name = "PSG_RaidHit"
	hit.Anchored = false
	hit.CanCollide = false
	hit.Transparency = 1
	hit.Massless = true
	hit.Size = Vector3.new(38, RAID_PLAYER_GAP - 6, 38)
	hit.CFrame = mobRoot.CFrame * CFrame.new(0, (RAID_PLAYER_GAP - 6) * 0.5, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = mobRoot
	weld.Part1 = hit
	weld.Parent = hit
	hit.Parent = mobRoot
	return hit
end
local function prepareMobForRaid(mob)
	local head = mob:FindFirstChild("Head")
	local mobRoot = mob:FindFirstChild("HumanoidRootPart")
	local humanoid = mob:FindFirstChild("Humanoid")
	if not head or not mobRoot then return end
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	end
	mobRoot.CanCollide = false
	head.CanCollide = false
	head.Massless = true
	head.Transparency = 1
	mobRoot.Size = Vector3.new(32, 24, 32)
	head.Size = Vector3.new(RAID_HITBOX_SIZE, RAID_HITBOX_SIZE, RAID_HITBOX_SIZE)
	head.CFrame = mobRoot.CFrame * CFrame.new(0, 1.5, 0)
	getOrCreateRaidHitPart(mob, mobRoot)
end
local function bringMobsUnderPlayer(mobs, dt)
	local hrp = getRootPart()
	if not hrp then return end
	dt = math.clamp(dt or 1 / 60, 1 / 240, 0.1)
	local floorY = hrp.Position.Y - RAID_PLAYER_GAP
	for index, mob in ipairs(mobs) do
		if not isAliveMob(mob) then continue end
		local mobRoot = mob.HumanoidRootPart
		if (mobRoot.Position - hrp.Position).Magnitude > RAID_BRING_RANGE then continue end
		prepareMobForRaid(mob)
		local angle = (index / math.max(#mobs, 1)) * math.pi * 2
		local ring = RAID_MOB_RING_BASE + ((index - 1) % 4) * RAID_MOB_RING_STEP
		local targetPos = Vector3.new(
			hrp.Position.X + math.cos(angle) * ring,
			floorY,
			hrp.Position.Z + math.sin(angle) * ring
		)
		local currentPos = mobRoot.Position
		local needsPullDown = currentPos.Y > floorY + 2
		local pullSpeed = needsPullDown and RAID_MOB_PULL_SPEED * 1.35 or RAID_MOB_PULL_SPEED
		local stepAlpha = raidCappedLerpAlpha(currentPos, targetPos, dt, pullSpeed)
		local newPos = currentPos:Lerp(targetPos, stepAlpha)
		mobRoot.AssemblyLinearVelocity = Vector3.zero
		mobRoot.AssemblyAngularVelocity = Vector3.zero
		mobRoot.CFrame = CFrame.new(newPos)
		local lock = mobRoot:FindFirstChild("PSG_RaidBring")
		if not lock then
			lock = Instance.new("BodyPosition")
			lock.Name = "PSG_RaidBring"
			lock.MaxForce = Vector3.new(400000, 400000, 400000)
			lock.P = 3200
			lock.D = 1800
			lock.Parent = mobRoot
		end
		lock.Position = newPos
	end
end
local function getRaidMobsNearPlayer(islandPart)
	local results, hrp = {}, getRootPart()
	if not hrp then return results end
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return results end
	local scanRange = islandPart and RAID_ISLAND_RANGE or 700
	local anchor = islandPart and islandPart.Position or hrp.Position
	for _, mob in enemies:GetChildren() do
		if isAliveMob(mob) then
			local root = mob.HumanoidRootPart
			local nearPlayer = (root.Position - hrp.Position).Magnitude <= scanRange
			local nearIsland = not islandPart or (root.Position - anchor).Magnitude <= scanRange
			if nearPlayer and nearIsland then table.insert(results, mob) end
		end
	end
	return results
end
local function runRaidCombat(dt)
	if not autoCompleteRaid then return end
	if not isRaidActive() and not isNearAnyRaidIsland() then return end
	dt = math.clamp(dt or 1 / 60, 1 / 240, 0.1)
	setNoclip(true)
	setCombatHumanoidState(true)
	local islandPart = getRaidIslandPartRaw("Island " .. tostring(raidTargetIslandIndex))
	if islandPart then smoothCombatHover(islandPart, dt) end
	local mobs = getRaidMobsNearPlayer(islandPart)
	if #mobs == 0 then
		if not raidEmptySince then
			raidEmptySince = tick()
			lastRaidAction = string.format("Combat: island %d cleared — checking...", raidTargetIslandIndex)
		elseif tick() - raidEmptySince >= RAID_ISLAND_CLEAR_DELAY then
			if raidTargetIslandIndex < RAID_ISLAND_COUNT then
				raidTargetIslandIndex += 1
				raidEmptySince = nil
				lastRaidAction = string.format("Traveling smoothly → island %d", raidTargetIslandIndex)
			else
				lastRaidAction = "All islands cleared — waiting for finish"
			end
		end
		return
	end
	raidEmptySince = nil
	bringMobsUnderPlayer(mobs, dt)
	raidAttackAccum += dt
	local delay = attackSettings.attackMode == "Fast" and RAID_FAST_ATTACK or 0.3
	if raidAttackAccum >= delay then
		raidAttackAccum = 0
		attackAllMobs(mobs)
	end
	lastRaidAction = string.format("Combat: island %d/%d | hitting %d mobs", raidTargetIslandIndex, RAID_ISLAND_COUNT, #mobs)
end
local function updateRaidSessionLock()
	local timerVisible = isRaidTimerVisible()
	if timerVisible and not lastRaidTimerVisible then
		raidSessionActive = true
		raidTargetIslandIndex = 1
		raidEmptySince = nil
		raidAttackAccum = 0
		clearMovement("raid_start")
		clearMovement("raid")
		syncMovementPartToPlayer()
		lastRaidAction = "Raid started"
	end
	if lastRaidTimerVisible and not timerVisible and not isLoadingMap() and not isNearAnyRaidIsland() then
		raidSessionActive = false
		raidCyclesCompleted += 1
		raidEmptySince = nil
		cleanupRaidMovement()
		lastRaidAction = "Raid done — cycle #" .. tostring(raidCyclesCompleted)
	end
	lastRaidTimerVisible = timerVisible
end
local function runRaidAutomation()
	if not alive or not raidAutomationEnabled() then return end
	resolveSendHits()
	local now = tick()
	if now - lastRaidAutoTick < 0.05 then return end
	lastRaidAutoTick = now
	updateRaidSessionLock()
	if isRaidActive() or isNearAnyRaidIsland() then
		clearMovement("raid_start")
		return
	end
	if hasMicrochip() then
		if autoStartRaid then raidAutoStart() end
		return
	end
	clearMovement("raid_start")
	clearMovement("raid")
	if now - lastChipBuyTick < RAID_CHIP_BUY_DELAY then return end
	if raidBuyBeli then
		raidBuyChipBeli()
		lastChipBuyTick = now
	elseif raidBuyFruit then
		raidBuyChipFruit()
		lastChipBuyTick = now
	elseif selectedRaid then
		lastRaidAction = "Enable Buy Chip (Beli) or (Lowest Fruit)"
	end
end
local function shouldDeferFruitAutomation()
	if isLoadingMap() then return true end
	if isInPlayerRaidWorld() then return true end
	if raidAutomationEnabled() and hasMicrochip() then return true end
	return false
end
local function runIslandTeleport()
	if not teleportToIslandEnabled or not selectedIsland then
		if movementFollowOwner == "island" then
			clearMovement("island")
		end
		return
	end
	if isInPlayerRaidWorld() or isLoadingMap() then return end
	if raidAutomationEnabled() and (hasMicrochip() or autoCompleteRaid) then return end
	if autoTweenFruit and movementFollowOwner == "fruit" and pendingFruitTarget then return end
	local targetCf = getIslandTeleportCFrame(selectedIsland)
	if not targetCf then
		if ISLAND_ENTRANCE[selectedIsland] then
			lastTeleportMessage = "Portal travel to " .. selectedIsland .. "..."
		else
			lastTeleportMessage = "No coordinates for: " .. tostring(selectedIsland)
		end
		return
	end
	syncMovementPartToPlayer()
	islandArrivalPending = true
	smoothFlyTo(targetCf, MOVEMENT_SPEED_ISLAND, "island")
	lastTeleportMessage = "Tweening to " .. selectedIsland .. "..."
end
local function runFruitAutomation()
	updateFruitEsp()
	local now = tick()
	if autoRandomFruit and now - lastCousinAttempt >= 3 then
		lastCousinAttempt = now
		pcall(function()
			invokeCommF("Cousin", "Buy")
		end)
	end
	if autoStoreFruit and now - lastStoreAttempt >= 1.2 then
		local tool = getFruitToolInInventory()
		if tool then
			local storageName = getFruitStorageName(tool)
			if storageName and not isFruitAlreadyStored(storageName) then
				lastStoreAttempt = now
				local ok, result = invokeCommF("StoreFruit", storageName, tool)
				if ok and result == true then
					storeFruitBlocklist[storageName] = true
					storeFruitBlocklist[normalizeFruitKey(storageName)] = true
				else
					storeFruitBlocklist[storageName] = true
					storeFruitBlocklist[normalizeFruitKey(storageName)] = true
					if type(result) == "string" then
						local lower = string.lower(result)
						if string.find(lower, "only store", 1, true)
							or string.find(lower, "already", 1, true)
							or string.find(lower, "1 of each", 1, true)
							or string.find(lower, "max", 1, true)
							or string.find(lower, "full", 1, true)
							or string.find(lower, "capacity", 1, true)
						then
							storeFruitBlocklist[storageName] = true
							storeFruitBlocklist[normalizeFruitKey(storageName)] = true
						end
					end
				end
			end
		end
	end
	if autoTweenFruit then
		if shouldDeferFruitAutomation() then
			local fruit = getNearestWorldFruit()
			if fruit then
				pendingFruitTarget = fruit
			end
			return
		end
		local fruit = pendingFruitTarget
		if not fruit or not fruit.Parent then
			fruit = getNearestWorldFruit()
		end
		pendingFruitTarget = fruit
		if fruit and fruit.Parent then
			local handle = getFruitHandle(fruit)
			local hrp = getRootPart()
			if handle and hrp then
				local goal = handle.CFrame * CFrame.new(0, math.max(3, handle.Size.Y + 2), 0)
				local dist = (goal.Position - hrp.Position).Magnitude
				if dist <= 10 then
					hrp.CFrame = goal
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					collectFruit(fruit)
					pendingFruitTarget = nil
					clearMovement("fruit")
				else
					smoothFlyTo(goal, MOVEMENT_SPEED_FRUIT, "fruit")
				end
			end
		end
	else
		pendingFruitTarget = nil
		if movementFollowOwner == "fruit" then
			clearMovement("fruit")
		end
	end
end
local function round(n) return math.floor(n + 0.5) end
local function captureOriginals()
	local humanoid = getHumanoid()
	if humanoid and originalWalk == nil then
		originalWalk = humanoid.WalkSpeed
		originalUseJumpPower = humanoid.UseJumpPower
		if humanoid.UseJumpPower then
			originalJump = humanoid.JumpPower
		else
			originalJump = humanoid.JumpHeight
		end
	end
end
local function setJumpProperty(humanoid, value)
	if humanoid.UseJumpPower then
		humanoid.JumpPower = value
	else
		humanoid.JumpHeight = value
	end
end
local function getJumpProperty(humanoid)
	if humanoid.UseJumpPower then return humanoid.JumpPower, "JumpPower" end
	return humanoid.JumpHeight, "JumpHeight"
end
local function applyWalkToHumanoid(realSpeed)
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = realSpeed
	end
end
local function applyJumpToHumanoid(realJump)
	local humanoid = getHumanoid()
	if humanoid then
		setJumpProperty(humanoid, realJump)
	end
end
local function boostJumpVelocity()
	local hrp = getRootPart()
	if not hrp or not appliedJump then return end
	local vy = math.sqrt(2 * workspace.Gravity * appliedJump)
	hrp.AssemblyLinearVelocity = Vector3.new(
		hrp.AssemblyLinearVelocity.X,
		math.max(hrp.AssemblyLinearVelocity.Y, vy),
		hrp.AssemblyLinearVelocity.Z
	)
end
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius or CORNER_RADIUS); c.Parent = parent
	return c
end
local function makeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke"); s.Color = color or COLORS.stroke; s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = parent
	return s
end
local function makeButton(parent, text, color, size)
	local btn = Instance.new("TextButton"); btn.Size = size or UDim2.fromOffset(88, 28); btn.BackgroundColor3 = color; btn.BorderSizePixel = 0; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12; btn.TextColor3 = COLORS.text; btn.Text = text; btn.AutoButtonColor = false; btn.Parent = parent
	makeCorner(btn, CORNER_RADIUS)
	return btn
end
local function createScrollPage(parent)
	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Scroll"; scroll.Size = UDim2.fromScale(1, 1); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = COLORS.accent; scroll.CanvasSize = UDim2.fromOffset(0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = parent
	local layout = Instance.new("UIListLayout"); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 10); layout.Parent = scroll
	local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 2); padding.PaddingBottom = UDim.new(0, 8); padding.Parent = scroll
	return scroll
end
local function createToggleRow(parent, labelText, defaultState, onChanged, layoutOrder)
	local row = Instance.new("Frame"); row.Name = labelText .. "Toggle"; row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundColor3 = COLORS.surface; row.BorderSizePixel = 0; row.LayoutOrder = layoutOrder or 0; row.Parent = parent
	makeCorner(row)
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -58, 1, 0); label.Position = UDim2.fromOffset(12, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextColor3 = COLORS.text; label.Text = labelText; label.Parent = row
	local toggleBg = Instance.new("TextButton"); toggleBg.Name = "Switch"; toggleBg.Size = UDim2.fromOffset(44, 22); toggleBg.Position = UDim2.new(1, -52, 0.5, -11); toggleBg.BackgroundColor3 = defaultState and COLORS.accent or COLORS.track; toggleBg.Text = ""; toggleBg.AutoButtonColor = false; toggleBg.Parent = row
	makeCorner(toggleBg, 11)
	local knob = Instance.new("Frame"); knob.Size = UDim2.fromOffset(18, 18); knob.Position = defaultState and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2); knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.Parent = toggleBg
	makeCorner(knob, 9)
	local enabled = defaultState
	local function setState(state, silent)
		enabled = state
		tween(toggleBg, { BackgroundColor3 = state and COLORS.accent or COLORS.track }, TWEEN_FAST):Play()
		tween(knob, { Position = state and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2) }, TWEEN_FAST):Play()
		if not silent and onChanged then
			onChanged(state)
		end
	end
	toggleBg.MouseButton1Click:Connect(function()
		setState(not enabled)
	end)
	return {
		Set = setState,
		Get = function()
			return enabled
		end,
	}
end
local function createSegmentedControl(parent, title, options, defaultValue, onPick, layoutOrder)
	local card = Instance.new("Frame"); card.Name = title .. "Choices"; card.Size = UDim2.new(1, 0, 0, 68); card.BackgroundColor3 = COLORS.surface; card.BorderSizePixel = 0; card.LayoutOrder = layoutOrder or 0; card.Parent = parent
	makeCorner(card)
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -16, 0, 18); label.Position = UDim2.fromOffset(12, 8); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextColor3 = COLORS.text; label.Text = title; label.Parent = card
	local row = Instance.new("Frame"); row.Size = UDim2.new(1, -16, 0, 28); row.Position = UDim2.fromOffset(8, 32); row.BackgroundTransparency = 1; row.Parent = card
	local rowLayout = Instance.new("UIListLayout"); rowLayout.FillDirection = Enum.FillDirection.Horizontal; rowLayout.SortOrder = Enum.SortOrder.LayoutOrder; rowLayout.Padding = UDim.new(0, 6); rowLayout.Parent = row
	local selected = defaultValue
	local buttons = {}
	local function highlightChoice(choice)
		selected = choice
		for option, btn in buttons do
			btn.BackgroundColor3 = option == choice and COLORS.accent or COLORS.bg
		end
		if onPick then
			onPick(choice)
		end
	end
	for index, option in options do
		local width = math.clamp(math.floor(380 / #options) - 4, 72, 160)
		local btn = makeButton(row, option, COLORS.bg, UDim2.fromOffset(width, 28)); btn.LayoutOrder = index; btn.TextSize = 10; btn.Name = option
		buttons[option] = btn
		btn.MouseButton1Click:Connect(function()
			highlightChoice(option)
		end)
	end
	highlightChoice(defaultValue)
	return {
		Set = highlightChoice,
		Get = function()
			return selected
		end,
	}
end
local walkSlider, jumpSlider
local debugLabel, raidStatusLabel, teamStatusLabel, islandSelectedLabel, teleportInfo
local tabButtons, tabAccents, tabPanels = {}, {}, {}
local islandMenu, islandMenuLayout, islandSelectBtn, raidMenu, raidMenuLayout, raidSelectBtn, raidSelectedLabel
local reopenGui, reopenButton, body, btnMinimize, btnHide, btnUnload, titleBar, titleLabel, titleAccent, titleFix
local playerTab, teamsTab, raidsTab, aSettingsTab, teleportTab, fruitsTab, btnPirates, btnMarines
local function createSliderRow(parent, labelText, defaultSlider, layoutOrder)
	local row = Instance.new("Frame"); row.Name = labelText .. "Row"; row.Size = UDim2.new(1, 0, 0, 96); row.BackgroundColor3 = COLORS.surface; row.BorderSizePixel = 0; row.LayoutOrder = layoutOrder; row.Parent = parent
	makeCorner(row, 10)
	local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 10); padding.PaddingBottom = UDim.new(0, 10); padding.PaddingLeft = UDim.new(0, 12); padding.PaddingRight = UDim.new(0, 12); padding.Parent = row
	local header = Instance.new("Frame"); header.Size = UDim2.new(1, 0, 0, 20); header.BackgroundTransparency = 1; header.Parent = row
	local nameLabel = Instance.new("TextLabel"); nameLabel.Size = UDim2.new(0.5, 0, 1, 0); nameLabel.BackgroundTransparency = 1; nameLabel.Font = Enum.Font.GothamMedium; nameLabel.TextSize = 13; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.TextColor3 = COLORS.text; nameLabel.Text = labelText; nameLabel.Parent = header
	local valueLabel = Instance.new("TextLabel"); valueLabel.Name = "Value"; valueLabel.Size = UDim2.new(0.5, 0, 1, 0); valueLabel.Position = UDim2.fromScale(0.5, 0); valueLabel.BackgroundTransparency = 1; valueLabel.Font = Enum.Font.Gotham; valueLabel.TextSize = 12; valueLabel.TextXAlignment = Enum.TextXAlignment.Right; valueLabel.TextColor3 = COLORS.accent; valueLabel.Text = tostring(defaultSlider); valueLabel.Parent = header
	local track = Instance.new("TextButton"); track.Name = "Track"; track.Size = UDim2.new(1, 0, 0, 8); track.Position = UDim2.fromOffset(0, 30); track.BackgroundColor3 = COLORS.track; track.BorderSizePixel = 0; track.Text = ""; track.AutoButtonColor = false; track.Parent = row
	makeCorner(track, 4)
	local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.fromScale(defaultSlider / SLIDER_MAX, 1); fill.BackgroundColor3 = COLORS.accent; fill.BorderSizePixel = 0; fill.Parent = track
	makeCorner(fill, 4)
	local knob = Instance.new("Frame"); knob.Name = "Knob"; knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Size = UDim2.fromOffset(18, 18); knob.Position = UDim2.fromScale(defaultSlider / SLIDER_MAX, 0.5); knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.ZIndex = 2; knob.Parent = track
	makeCorner(knob, 9)
	makeStroke(knob, COLORS.accent, 2)
	local applyBtn = makeButton(row, "Apply Value", COLORS.accent, UDim2.new(1, 0, 0, 30)); applyBtn.Position = UDim2.fromOffset(0, 48)
	local currentSlider = defaultSlider
	local dragging = false
	local function updateVisual(sliderValue, animate)
		local alpha = math.clamp(sliderValue / SLIDER_MAX, 0, 1)
		valueLabel.Text = string.format("%d  (real: %.0f)", round(sliderValue), labelText:find("Walk") and mapWalkSpeed(sliderValue) or mapJumpHeight(sliderValue))
		if animate then
			tween(fill, { Size = UDim2.fromScale(alpha, 1) }):Play()
			tween(knob, { Position = UDim2.fromScale(alpha, 0.5) }):Play()
		else
			fill.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.fromScale(alpha, 0.5)
		end
	end
	local function setSlider(raw, animate)
		local value = math.clamp(raw, 0, SLIDER_MAX)
		currentSlider = value
		updateVisual(value, animate)
	end
	local function valueFromInput(input)
		local trackPos = track.AbsolutePosition.X
		local trackSize = track.AbsoluteSize.X
		if trackSize <= 0 then return currentSlider end
		return math.clamp((input.Position.X - trackPos) / trackSize, 0, 1) * SLIDER_MAX
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setSlider(valueFromInput(input), true)
		end
	end)
	track.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			setSlider(valueFromInput(input), true)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	applyBtn.MouseEnter:Connect(function()
		tween(applyBtn, { BackgroundColor3 = COLORS.accentHover }):Play()
	end)
	applyBtn.MouseLeave:Connect(function()
		tween(applyBtn, { BackgroundColor3 = COLORS.accent }):Play()
	end)
	return {
		SetSlider = setSlider,
		GetSlider = function()
			return currentSlider
		end,
		ApplyButton = applyBtn,
	}
end
local function updateDebug()
	local humanoid = getHumanoid()
	if not humanoid then
		debugLabel.TextColor3 = COLORS.danger
		debugLabel.Text = "No character loaded."
		return
	end
	captureOriginals()
	local jumpActual, jumpProp = getJumpProperty(humanoid)
	local lines = {
		string.format("Walk: slider %s → real %s | boost %s", appliedWalk and "ON" or "OFF", appliedWalk or "-", walkBoostActive and "CFrame" or "off"),
		string.format("Jump: slider %s → real %s | %s: %.1f", appliedJump and "ON" or "OFF", appliedJump or "-", jumpProp, jumpActual),
	}
	if appliedWalk then
		local hrp = getRootPart()
		if hrp and humanoid.MoveDirection.Magnitude > 0 then
			local planar = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
			table.insert(lines, string.format("Planar velocity: %.1f studs/s", planar))
		end
	end
	debugLabel.TextColor3 = COLORS.textMuted
	debugLabel.Text = table.concat(lines, "\n")
end
local function applyWalk()
	captureOriginals()
	local slider = walkSlider.GetSlider()
	pendingWalk = slider
	appliedWalk = mapWalkSpeed(slider)
	walkBoostActive = appliedWalk > 16.5
	applyWalkToHumanoid(appliedWalk)
	updateDebug()
end
local function applyJump()
	captureOriginals()
	local slider = jumpSlider.GetSlider()
	pendingJump = slider
	appliedJump = mapJumpHeight(slider)
	jumpBoostActive = appliedJump > 0
	applyJumpToHumanoid(appliedJump)
	updateDebug()
end
local function restoreMovement()
	local humanoid = getHumanoid()
	if humanoid then
		if originalWalk then
			humanoid.WalkSpeed = originalWalk
		end
		if originalJump then
			setJumpProperty(humanoid, originalJump)
		end
	end
	appliedWalk = nil
	appliedJump = nil
	walkBoostActive = false
	jumpBoostActive = false
end
local function switchTab(tabName)
	activeTab = tabName
	for name, panel in tabPanels do
		panel.Visible = name == tabName
	end
	local tabToButton = {
		Player = "Player",
		Teams = "Teams",
		Raids = "Raids",
		["A-Settings"] = "A-Set",
		Teleport = "TP",
		Fruits = "Fruits",
	}
	local activeBtn = tabToButton[tabName]
	for name, btn in tabButtons do
		local active = name == activeBtn
		btn.BackgroundColor3 = active and COLORS.accent or COLORS.surfaceAlt
		btn.TextColor3 = active and COLORS.text or COLORS.textMuted
		if tabAccents[name] then
			tabAccents[name].Visible = active
		end
	end
end
local function unload()
	if not alive then return end
	alive = false
	raidBuyBeli = false
	raidBuyFruit = false
	autoStartRaid = false
	autoCompleteRaid = false
	raidSessionActive = false
	cleanupRaidMovement()
	restoreMovement()
	cleanupMovementSystem()
	setNoclip(false)
	clearFruitEsp()
	for _, c in connections do
		c:Disconnect()
	end
	connections = {}
	if screenGui.Parent then
		screenGui:Destroy()
	end
	if reopenGui.Parent then
		reopenGui:Destroy()
	end
	_G.PlayerSettingsGUI_Unload = nil
end
local function buildGui()
for _, child in mainFrame:GetChildren() do
	child:Destroy()
end
makeCorner(mainFrame, CORNER_RADIUS)
makeStroke(mainFrame, COLORS.stroke, 1)
local shadow = Instance.new("ImageLabel"); shadow.Name = "Shadow"; shadow.AnchorPoint = Vector2.new(0.5, 0.5); shadow.BackgroundTransparency = 1; shadow.Position = UDim2.fromScale(0.5, 0.5); shadow.Size = UDim2.new(1, 28, 1, 28); shadow.ZIndex = 0; shadow.Image = "rbxassetid://6014261993"; shadow.ImageColor3 = Color3.new(0, 0, 0); shadow.ImageTransparency = 0.6; shadow.Active = false; shadow.Parent = mainFrame
titleBar = Instance.new("Frame"); titleBar.Name = "TitleBar"; titleBar.Size = UDim2.new(1, 0, 0, 48); titleBar.BackgroundColor3 = COLORS.surface; titleBar.BorderSizePixel = 0; titleBar.ZIndex = 2; titleBar.Parent = mainFrame
makeCorner(titleBar, CORNER_RADIUS)
titleFix = Instance.new("Frame"); titleFix.Size = UDim2.new(1, 0, 0, 12); titleFix.Position = UDim2.new(0, 0, 1, -12); titleFix.BackgroundColor3 = COLORS.surface; titleFix.BorderSizePixel = 0; titleFix.ZIndex = 2; titleFix.Parent = titleBar
titleLabel = Instance.new("TextLabel"); titleLabel.BackgroundTransparency = 1; titleLabel.Position = UDim2.fromOffset(14, 0); titleLabel.Size = UDim2.new(1, -120, 1, 0); titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 16; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.TextColor3 = COLORS.text; titleLabel.Text = "Player Settings  ·  drag title to move"; titleLabel.ZIndex = 3; titleLabel.Parent = titleBar
titleAccent = Instance.new("Frame"); titleAccent.Size = UDim2.fromOffset(3, 20); titleAccent.Position = UDim2.fromOffset(14, 14); titleAccent.BackgroundColor3 = COLORS.accent; titleAccent.BorderSizePixel = 0; titleAccent.ZIndex = 3; titleAccent.Parent = titleBar
makeCorner(titleAccent, 2)
titleLabel.Position = UDim2.fromOffset(24, 0)
titleLabel.Size = UDim2.new(1, -130, 1, 0)
btnMinimize = makeButton(titleBar, "—", COLORS.surfaceAlt, UDim2.fromOffset(30, 30)); btnMinimize.Position = UDim2.new(1, -100, 0.5, -15); btnMinimize.ZIndex = 3
btnHide = makeButton(titleBar, "▁", COLORS.surfaceAlt, UDim2.fromOffset(30, 30)); btnHide.Position = UDim2.new(1, -66, 0.5, -15); btnHide.ZIndex = 3; btnHide.Text = "−"
btnUnload = makeButton(titleBar, "×", COLORS.danger, UDim2.fromOffset(30, 30)); btnUnload.Position = UDim2.new(1, -32, 0.5, -15); btnUnload.ZIndex = 3; btnUnload.TextSize = 18
body = Instance.new("Frame"); body.Name = "Body"; body.Size = UDim2.new(1, -20, 1, -58); body.Position = UDim2.fromOffset(10, 52); body.BackgroundTransparency = 1; body.ClipsDescendants = true; body.Parent = mainFrame
local sidebar = Instance.new("Frame"); sidebar.Name = "Sidebar"; sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0); sidebar.BackgroundColor3 = COLORS.surface; sidebar.BorderSizePixel = 0; sidebar.ZIndex = 2; sidebar.Parent = body
makeCorner(sidebar, CORNER_RADIUS)
makeStroke(sidebar, COLORS.stroke, 1)
local sidebarPad = Instance.new("UIPadding"); sidebarPad.PaddingTop = UDim.new(0, 8); sidebarPad.PaddingBottom = UDim.new(0, 8); sidebarPad.PaddingLeft = UDim.new(0, 6); sidebarPad.PaddingRight = UDim.new(0, 6); sidebarPad.Parent = sidebar
local tabBar = Instance.new("ScrollingFrame"); tabBar.Name = "TabBar"; tabBar.Size = UDim2.fromScale(1, 1); tabBar.BackgroundTransparency = 1; tabBar.BorderSizePixel = 0; tabBar.ScrollBarThickness = 3; tabBar.ScrollBarImageColor3 = COLORS.accent; tabBar.CanvasSize = UDim2.fromOffset(0, 0); tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y; tabBar.Parent = sidebar
local tabLayout = Instance.new("UIListLayout"); tabLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabLayout.Padding = UDim.new(0, 6); tabLayout.Parent = tabBar
tabButtons = {}
tabAccents = {}
local function registerTab(name, order)
	local row = Instance.new("Frame"); row.Name = name .. "TabRow"; row.Size = UDim2.new(1, 0, 0, 40); row.BackgroundTransparency = 1; row.LayoutOrder = order; row.Parent = tabBar
	local accent = Instance.new("Frame"); accent.Name = "Accent"; accent.Size = UDim2.new(0, 3, 0.55, 0); accent.Position = UDim2.new(0, 0, 0.225, 0); accent.BackgroundColor3 = COLORS.accent; accent.BorderSizePixel = 0; accent.Visible = false; accent.ZIndex = 2; accent.Parent = row
	makeCorner(accent, 2)
	local btn = makeButton(row, name, COLORS.surfaceAlt, UDim2.new(1, 0, 1, 0)); btn.TextSize = 12; btn.Name = name; btn.ZIndex = 1
	tabButtons[name] = btn
	tabAccents[name] = accent
	return btn
end
registerTab("Player", 1)
registerTab("Teams", 2)
registerTab("Raids", 3)
registerTab("A-Set", 4)
registerTab("TP", 5)
registerTab("Fruits", 6)
playerTab = tabButtons.Player
teamsTab = tabButtons.Teams
raidsTab = tabButtons.Raids
aSettingsTab = tabButtons["A-Set"]
teleportTab = tabButtons.TP
fruitsTab = tabButtons.Fruits
local contentArea = Instance.new("Frame"); contentArea.Name = "Content"; contentArea.Size = UDim2.new(1, -(SIDEBAR_W + 10), 1, 0); contentArea.Position = UDim2.fromOffset(SIDEBAR_W + 10, 0); contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = body
local pages = Instance.new("Frame"); pages.Name = "Pages"; pages.Size = UDim2.fromScale(1, 1); pages.BackgroundTransparency = 1; pages.ClipsDescendants = false; pages.Parent = contentArea
local playerPanel = Instance.new("Frame"); playerPanel.Name = "PlayerPanel"; playerPanel.Size = UDim2.fromScale(1, 1); playerPanel.BackgroundTransparency = 1; playerPanel.Visible = true; playerPanel.Parent = pages
local teamsPanel = Instance.new("Frame"); teamsPanel.Name = "TeamsPanel"; teamsPanel.Size = UDim2.fromScale(1, 1); teamsPanel.BackgroundTransparency = 1; teamsPanel.Visible = false; teamsPanel.Parent = pages
local raidsPanel = Instance.new("Frame"); raidsPanel.Name = "RaidsPanel"; raidsPanel.Size = UDim2.fromScale(1, 1); raidsPanel.BackgroundTransparency = 1; raidsPanel.Visible = false; raidsPanel.Parent = pages
local aSettingsPanel = Instance.new("Frame"); aSettingsPanel.Name = "ASettingsPanel"; aSettingsPanel.Size = UDim2.fromScale(1, 1); aSettingsPanel.BackgroundTransparency = 1; aSettingsPanel.Visible = false; aSettingsPanel.Parent = pages
local teleportPanel = Instance.new("Frame"); teleportPanel.Name = "TeleportPanel"; teleportPanel.Size = UDim2.fromScale(1, 1); teleportPanel.BackgroundTransparency = 1; teleportPanel.Visible = false; teleportPanel.Parent = pages
local fruitsPanel = Instance.new("Frame"); fruitsPanel.Name = "FruitsPanel"; fruitsPanel.Size = UDim2.fromScale(1, 1); fruitsPanel.BackgroundTransparency = 1; fruitsPanel.Visible = false; fruitsPanel.Parent = pages
local raidsScroll = createScrollPage(raidsPanel)
local aSettingsScroll = createScrollPage(aSettingsPanel)
local teleportScroll = createScrollPage(teleportPanel)
local fruitsScroll = createScrollPage(fruitsPanel)
tabPanels = {
	Player = playerPanel,
	Teams = teamsPanel,
	Raids = raidsPanel,
	["A-Settings"] = aSettingsPanel,
	Teleport = teleportPanel,
	Fruits = fruitsPanel,
}
local playerLayout = Instance.new("UIListLayout"); playerLayout.SortOrder = Enum.SortOrder.LayoutOrder; playerLayout.Padding = UDim.new(0, 14); playerLayout.Parent = playerPanel
local teamsCard = Instance.new("Frame"); teamsCard.Name = "TeamsCard"; teamsCard.Size = UDim2.new(1, 0, 0, 220); teamsCard.BackgroundColor3 = COLORS.surface; teamsCard.BorderSizePixel = 0; teamsCard.Parent = teamsPanel
makeCorner(teamsCard, 10)
local teamsPadding = Instance.new("UIPadding"); teamsPadding.PaddingTop = UDim.new(0, 14); teamsPadding.PaddingBottom = UDim.new(0, 14); teamsPadding.PaddingLeft = UDim.new(0, 14); teamsPadding.PaddingRight = UDim.new(0, 14); teamsPadding.Parent = teamsCard
local teamsTitle = Instance.new("TextLabel"); teamsTitle.Size = UDim2.new(1, 0, 0, 20); teamsTitle.BackgroundTransparency = 1; teamsTitle.Font = Enum.Font.GothamBold; teamsTitle.TextSize = 14; teamsTitle.TextXAlignment = Enum.TextXAlignment.Left; teamsTitle.TextColor3 = COLORS.text; teamsTitle.Text = "Choose Your Team"; teamsTitle.Parent = teamsCard
local teamsSubtitle = Instance.new("TextLabel"); teamsSubtitle.Size = UDim2.new(1, 0, 0, 34); teamsSubtitle.Position = UDim2.fromOffset(0, 24); teamsSubtitle.BackgroundTransparency = 1; teamsSubtitle.Font = Enum.Font.Gotham; teamsSubtitle.TextSize = 11; teamsSubtitle.TextXAlignment = Enum.TextXAlignment.Left; teamsSubtitle.TextYAlignment = Enum.TextYAlignment.Top; teamsSubtitle.TextWrapped = true; teamsSubtitle.TextColor3 = COLORS.textMuted; teamsSubtitle.Text = "Uses the same path as the in-game recruiter / team selector (CommF_ SetTeam)."; teamsSubtitle.Parent = teamsCard
btnPirates = makeButton(teamsCard, "🏴‍☠️  Join Pirates", COLORS.pirate, UDim2.new(1, 0, 0, 42)); btnPirates.Position = UDim2.fromOffset(0, 68); btnPirates.TextSize = 13
makeCorner(btnPirates, 8)
bindHover(btnPirates, COLORS.pirate, Color3.fromRGB(240, 110, 85))
btnMarines = makeButton(teamsCard, "⚓  Join Marines", COLORS.marine, UDim2.new(1, 0, 0, 42)); btnMarines.Position = UDim2.fromOffset(0, 118); btnMarines.TextSize = 13
makeCorner(btnMarines, 8)
bindHover(btnMarines, COLORS.marine, Color3.fromRGB(95, 155, 245))
teamStatusLabel = Instance.new("TextLabel"); teamStatusLabel.Name = "TeamStatus"; teamStatusLabel.Size = UDim2.new(1, 0, 0, 44); teamStatusLabel.Position = UDim2.fromOffset(0, 168); teamStatusLabel.BackgroundTransparency = 1; teamStatusLabel.Font = Enum.Font.Code; teamStatusLabel.TextSize = 11; teamStatusLabel.TextXAlignment = Enum.TextXAlignment.Left; teamStatusLabel.TextYAlignment = Enum.TextYAlignment.Top; teamStatusLabel.TextWrapped = true; teamStatusLabel.TextColor3 = COLORS.textMuted; teamStatusLabel.Text = "Current team: " .. getCurrentTeamLabel(); teamStatusLabel.Parent = teamsCard
raidSelectBtn = makeButton(raidsScroll, "Select Raid", COLORS.accent, UDim2.new(1, 0, 0, 34)); raidSelectBtn.LayoutOrder = 1; raidSelectBtn.TextSize = 12
raidSelectedLabel = Instance.new("TextLabel"); raidSelectedLabel.Size = UDim2.new(1, 0, 0, 28); raidSelectedLabel.BackgroundTransparency = 1; raidSelectedLabel.Font = Enum.Font.Gotham; raidSelectedLabel.TextSize = 11; raidSelectedLabel.TextXAlignment = Enum.TextXAlignment.Left; raidSelectedLabel.TextColor3 = COLORS.textMuted; raidSelectedLabel.Text = "Selected: none"; raidSelectedLabel.LayoutOrder = 2; raidSelectedLabel.Parent = raidsScroll
raidMenu = Instance.new("Frame"); raidMenu.Name = "RaidMenu"; raidMenu.Size = UDim2.new(1, 0, 0, 0); raidMenu.BackgroundColor3 = COLORS.surface; raidMenu.BorderSizePixel = 0; raidMenu.Visible = false; raidMenu.LayoutOrder = 3; raidMenu.Parent = raidsScroll
makeCorner(raidMenu)
raidMenuLayout = Instance.new("UIListLayout"); raidMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder; raidMenuLayout.Padding = UDim.new(0, 4); raidMenuLayout.Parent = raidMenu
local raidMenuPad = Instance.new("UIPadding"); raidMenuPad.PaddingTop = UDim.new(0, 8); raidMenuPad.PaddingBottom = UDim.new(0, 8); raidMenuPad.PaddingLeft = UDim.new(0, 8); raidMenuPad.PaddingRight = UDim.new(0, 8); raidMenuPad.Parent = raidMenu
local toggleBuyBeli = createToggleRow(raidsScroll, "Buy Chip (Beli)", false, function(v)
	raidBuyBeli = v
	if v and raidBuyFruit then
		raidBuyFruit = false
		toggleBuyFruit.Set(false, true)
	end
	if v then
		pendingRaidFruitLoad = nil
		ensureMovementTweenPart()
		local humanoid = getHumanoid()
		if humanoid then pcall(function() humanoid:UnequipTools() end) end
		lastRaidAction = "Beli buy ON — paying with 100k beli"
	end
end, 4)
local toggleBuyFruit = createToggleRow(raidsScroll, "Buy Chip (Lowest Fruit)", false, function(v)
	raidBuyFruit = v
	if v and raidBuyBeli then
		raidBuyBeli = false
		toggleBuyBeli.Set(false, true)
	end
	if v then
		ensureMovementTweenPart()
		local fruitName, fruitValue = getLowestChipFruitInfo()
		previewChipFruitName = fruitName
		previewChipFruitValue = fruitValue
		if fruitName then
			lastRaidAction = string.format("Fruit buy ON — lowest in bag: %s ($%s)", fruitName, tostring(fruitValue or "?"))
		else
			lastRaidAction = "Fruit buy ON — no eligible fruit in bag yet"
		end
	else
		previewChipFruitName = nil
		previewChipFruitValue = nil
	end
end, 5)
local toggleAutoStart = createToggleRow(raidsScroll, "Auto Start Raid", false, function(v)
	autoStartRaid = v
	if v then
		ensureMovementTweenPart()
		lastRaidStartAttempt = 0
	else
		clearMovement("raid_start")
	end
end, 6)
local toggleAutoComplete = createToggleRow(raidsScroll, "Auto Complete Raid", false, function(v)
	autoCompleteRaid = v
	if v then
		ensureMovementTweenPart()
		raidTargetIslandIndex = 1
		raidEmptySince = nil
		raidAttackAccum = 0
		syncMovementPartToPlayer()
	else
		cleanupRaidMovement()
	end
end, 7)
raidStatusLabel = Instance.new("TextLabel"); raidStatusLabel.Size = UDim2.new(1, 0, 0, 88); raidStatusLabel.BackgroundColor3 = COLORS.surface; raidStatusLabel.BackgroundTransparency = 0; raidStatusLabel.BorderSizePixel = 0; raidStatusLabel.Font = Enum.Font.Code; raidStatusLabel.TextSize = 10; raidStatusLabel.TextXAlignment = Enum.TextXAlignment.Left; raidStatusLabel.TextYAlignment = Enum.TextYAlignment.Top; raidStatusLabel.TextWrapped = true; raidStatusLabel.TextColor3 = COLORS.textMuted; raidStatusLabel.Text = lastRaidAction; raidStatusLabel.LayoutOrder = 8; raidStatusLabel.Parent = raidsScroll
makeCorner(raidStatusLabel)
local raidStatusPad = Instance.new("UIPadding"); raidStatusPad.PaddingTop = UDim.new(0, 8); raidStatusPad.PaddingLeft = UDim.new(0, 8); raidStatusPad.PaddingRight = UDim.new(0, 8); raidStatusPad.Parent = raidStatusLabel
createSegmentedControl(aSettingsScroll, "Weapon", { "Melee", "Sword", "Fruit", "Gun" }, "Melee", function(value)
	attackSettings.weaponType = value
end, 1)
createSegmentedControl(aSettingsScroll, "Attack", { "Normal", "Fast" }, "Fast", function(value)
	attackSettings.attackMode = value
end, 2)
createToggleRow(aSettingsScroll, "Z Move", false, function(v) attackSettings.skills.Z = v end, 3)
createToggleRow(aSettingsScroll, "X Move", false, function(v) attackSettings.skills.X = v end, 4)
createToggleRow(aSettingsScroll, "C Move", false, function(v) attackSettings.skills.C = v end, 5)
createToggleRow(aSettingsScroll, "V Move", false, function(v) attackSettings.skills.V = v end, 6)
createToggleRow(aSettingsScroll, "F Move", false, function(v) attackSettings.skills.F = v end, 7)
local aSettingsInfo = Instance.new("TextLabel"); aSettingsInfo.Size = UDim2.new(1, 0, 0, 70); aSettingsInfo.BackgroundColor3 = COLORS.surface; aSettingsInfo.BorderSizePixel = 0; aSettingsInfo.Font = Enum.Font.Gotham; aSettingsInfo.TextSize = 11; aSettingsInfo.TextWrapped = true; aSettingsInfo.TextXAlignment = Enum.TextXAlignment.Left; aSettingsInfo.TextYAlignment = Enum.TextYAlignment.Top; aSettingsInfo.TextColor3 = COLORS.textMuted; aSettingsInfo.Text = "Fast mode uses 16ms multi-hit during Auto Complete. Mobs are pulled under you with safe spacing."; aSettingsInfo.LayoutOrder = 8; aSettingsInfo.Parent = aSettingsScroll
makeCorner(aSettingsInfo)
local aInfoPad = Instance.new("UIPadding"); aInfoPad.PaddingTop = UDim.new(0, 8); aInfoPad.PaddingLeft = UDim.new(0, 8); aInfoPad.PaddingRight = UDim.new(0, 8); aInfoPad.Parent = aSettingsInfo
islandSelectBtn = makeButton(teleportScroll, "Select Island", COLORS.accent, UDim2.new(1, 0, 0, 34)); islandSelectBtn.LayoutOrder = 1; islandSelectBtn.TextSize = 12
islandSelectedLabel = Instance.new("TextLabel"); islandSelectedLabel.Size = UDim2.new(1, 0, 0, 28); islandSelectedLabel.BackgroundTransparency = 1; islandSelectedLabel.Font = Enum.Font.Gotham; islandSelectedLabel.TextSize = 11; islandSelectedLabel.TextXAlignment = Enum.TextXAlignment.Left; islandSelectedLabel.TextColor3 = COLORS.textMuted; islandSelectedLabel.Text = "Selected: none (Sea " .. tostring(getCurrentSeaNumber()) .. ")"; islandSelectedLabel.LayoutOrder = 2; islandSelectedLabel.Parent = teleportScroll
islandMenu = Instance.new("Frame"); islandMenu.Name = "IslandMenu"; islandMenu.Size = UDim2.new(1, 0, 0, 0); islandMenu.BackgroundColor3 = COLORS.surface; islandMenu.BorderSizePixel = 0; islandMenu.Visible = false; islandMenu.LayoutOrder = 3; islandMenu.Parent = teleportScroll
makeCorner(islandMenu)
islandMenuLayout = Instance.new("UIListLayout"); islandMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder; islandMenuLayout.Padding = UDim.new(0, 4); islandMenuLayout.Parent = islandMenu
local islandMenuPad = Instance.new("UIPadding"); islandMenuPad.PaddingTop = UDim.new(0, 8); islandMenuPad.PaddingBottom = UDim.new(0, 8); islandMenuPad.PaddingLeft = UDim.new(0, 8); islandMenuPad.PaddingRight = UDim.new(0, 8); islandMenuPad.Parent = islandMenu
createToggleRow(teleportScroll, "Teleport to Island", false, function(v)
	teleportToIslandEnabled = v
	if not v then
		islandArrivalPending = false
		clearMovement("island")
	else
		ensureMovementTweenPart()
		task.defer(function()
			pcall(runIslandTeleport)
		end)
	end
end, 4)
local seaBtnRow = Instance.new("Frame"); seaBtnRow.Size = UDim2.new(1, 0, 0, 34); seaBtnRow.BackgroundTransparency = 1; seaBtnRow.LayoutOrder = 5; seaBtnRow.Parent = teleportScroll
local seaBtnLayout = Instance.new("UIListLayout"); seaBtnLayout.FillDirection = Enum.FillDirection.Horizontal; seaBtnLayout.Padding = UDim.new(0, 6); seaBtnLayout.Parent = seaBtnRow
local function styleSeaTravelButton(btn, glowColor)
	btn.AutoButtonColor = false
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	local glow = Instance.new("Frame"); glow.Name = "Glow"; glow.AnchorPoint = Vector2.new(0.5, 0.5); glow.Position = UDim2.fromScale(0.5, 0.5); glow.Size = UDim2.new(1, 10, 1, 10); glow.BackgroundColor3 = glowColor; glow.BackgroundTransparency = 0.82; glow.BorderSizePixel = 0; glow.ZIndex = math.max(0, btn.ZIndex - 1); glow.Parent = btn
	makeCorner(glow, 10)
	local stroke = Instance.new("UIStroke"); stroke.Color = glowColor; stroke.Thickness = 2; stroke.Transparency = 0.45; stroke.Parent = btn
	makeCorner(btn, 8)
	task.spawn(function()
		local pulseOut = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local pulseIn = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		while btn.Parent and alive do
			tween(glow, { BackgroundTransparency = 0.55, Size = UDim2.new(1, 14, 1, 14) }, pulseOut):Play()
			tween(stroke, { Transparency = 0.1, Thickness = 2.5 }, pulseOut):Play()
			task.wait(0.9)
			tween(glow, { BackgroundTransparency = 0.88, Size = UDim2.new(1, 8, 1, 8) }, pulseIn):Play()
			tween(stroke, { Transparency = 0.55, Thickness = 1.5 }, pulseIn):Play()
			task.wait(0.9)
		end
	end)
	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = glowColor:Lerp(Color3.new(1, 1, 1), 0.15) }, TWEEN_FAST):Play()
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = glowColor }, TWEEN_FAST):Play()
	end)
end
local btnSea1 = makeButton(seaBtnRow, "Sea 1", Color3.fromRGB(70, 130, 220), UDim2.fromOffset(128, 32))
styleSeaTravelButton(btnSea1, Color3.fromRGB(70, 130, 220))
local btnSea2 = makeButton(seaBtnRow, "Sea 2", Color3.fromRGB(220, 120, 70), UDim2.fromOffset(128, 32))
styleSeaTravelButton(btnSea2, Color3.fromRGB(220, 120, 70))
local btnSea3 = makeButton(seaBtnRow, "Sea 3", Color3.fromRGB(140, 90, 220), UDim2.fromOffset(128, 32))
styleSeaTravelButton(btnSea3, Color3.fromRGB(140, 90, 220))
teleportInfo = Instance.new("TextLabel"); teleportInfo.Size = UDim2.new(1, 0, 0, 52); teleportInfo.BackgroundColor3 = COLORS.surface; teleportInfo.BorderSizePixel = 0; teleportInfo.Font = Enum.Font.Gotham; teleportInfo.TextSize = 10; teleportInfo.TextWrapped = true; teleportInfo.TextXAlignment = Enum.TextXAlignment.Left; teleportInfo.TextYAlignment = Enum.TextYAlignment.Top; teleportInfo.TextColor3 = COLORS.textMuted; teleportInfo.Text = "Smooth tween to island. Toggle off mid-travel to stop where you are. Sea buttons keep public/private server type."; teleportInfo.LayoutOrder = 6; teleportInfo.Parent = teleportScroll
makeCorner(teleportInfo)
local tpInfoPad = Instance.new("UIPadding"); tpInfoPad.PaddingTop = UDim.new(0, 8); tpInfoPad.PaddingLeft = UDim.new(0, 8); tpInfoPad.PaddingRight = UDim.new(0, 8); tpInfoPad.Parent = teleportInfo
local function makeStockCard(parent, title, layoutOrder)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 0, 132); card.BackgroundColor3 = COLORS.surface; card.BorderSizePixel = 0; card.LayoutOrder = layoutOrder; card.Parent = parent
	makeCorner(card)
	local header = Instance.new("TextLabel"); header.Size = UDim2.new(1, -16, 0, 20); header.Position = UDim2.fromOffset(10, 8); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 12; header.TextXAlignment = Enum.TextXAlignment.Left; header.TextColor3 = COLORS.text; header.Text = title; header.Parent = card
	local body = Instance.new("TextLabel"); body.Size = UDim2.new(1, -16, 1, -34); body.Position = UDim2.fromOffset(10, 30); body.BackgroundTransparency = 1; body.Font = Enum.Font.Code; body.TextSize = 10; body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top; body.TextWrapped = true; body.TextColor3 = COLORS.textMuted; body.Text = "— loading —"; body.Parent = card
	return body
end
normalStockLabel = makeStockCard(fruitsScroll, "Normal Stock", 1)
mirageStockLabel = makeStockCard(fruitsScroll, "Mirage Stock", 2)
createToggleRow(fruitsScroll, "Auto Random Fruit", false, function(v)
	autoRandomFruit = v
end, 3)
createToggleRow(fruitsScroll, "Auto Store Fruit", false, function(v)
	autoStoreFruit = v
end, 4)
createToggleRow(fruitsScroll, "Auto Tween to Fruit", false, function(v)
	autoTweenFruit = v
	if v then
		ensureMovementTweenPart()
		local fruit = getNearestWorldFruit()
		if fruit then
			pendingFruitTarget = fruit
		end
	else
		pendingFruitTarget = nil
		clearMovement("fruit")
	end
end, 5)
createToggleRow(fruitsScroll, "Fruit ESP", false, function(v)
	fruitEspEnabled = v
	if not v then
		clearFruitEsp()
	end
end, 6)
local function updateIslandMenuSize()
	if not islandMenu.Visible then
		islandMenu.Size = UDim2.new(1, 0, 0, 0)
		return
	end
	islandMenu.Size = UDim2.new(1, 0, 0, islandMenuLayout.AbsoluteContentSize.Y + 16)
end
local function rebuildIslandMenu()
	for _, child in islandMenu:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local order = 1
	for _, islandName in getCurrentSeaIslands() do
		local pick = makeButton(islandMenu, islandName, COLORS.bg, UDim2.new(1, 0, 0, 26)); pick.LayoutOrder = order; pick.TextSize = 10
		pick.MouseButton1Click:Connect(function()
			selectedIsland = islandName
			islandSelectedLabel.Text = "Selected: " .. islandName .. " (Sea " .. tostring(getCurrentSeaNumber()) .. ")"
			islandMenu.Visible = false
			islandMenu.Size = UDim2.new(1, 0, 0, 0)
			if teleportToIslandEnabled then
				clearMovement("island")
				islandArrivalPending = false
				pcall(runIslandTeleport)
			end
		end)
		order = order + 1
	end
	task.defer(updateIslandMenuSize)
end
islandMenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateIslandMenuSize)
islandSelectBtn.MouseButton1Click:Connect(function()
	rebuildIslandMenu()
	islandMenu.Visible = not islandMenu.Visible
	updateIslandMenuSize()
end)
btnSea1.MouseButton1Click:Connect(function()
	travelToSea(1)
	if teleportInfo then
		teleportInfo.Text = lastTeleportMessage
	end
end)
btnSea2.MouseButton1Click:Connect(function()
	travelToSea(2)
	if teleportInfo then
		teleportInfo.Text = lastTeleportMessage
	end
end)
btnSea3.MouseButton1Click:Connect(function()
	travelToSea(3)
	if teleportInfo then
		teleportInfo.Text = lastTeleportMessage
	end
end)
local function updateRaidMenuSize()
	if not raidMenu.Visible then
		raidMenu.Size = UDim2.new(1, 0, 0, 0)
		return
	end
	raidMenu.Size = UDim2.new(1, 0, 0, raidMenuLayout.AbsoluteContentSize.Y + 16)
end
local function rebuildRaidMenu()
	for _, child in raidMenu:GetChildren() do
		if child:IsA("TextButton") or child.Name == "SectionTitle" then
			child:Destroy()
		end
	end
	local function addSection(title, list, startOrder)
		if #list == 0 then return startOrder end
		local header = Instance.new("TextLabel"); header.Name = "SectionTitle"; header.Size = UDim2.new(1, 0, 0, 18); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 11; header.TextXAlignment = Enum.TextXAlignment.Left; header.TextColor3 = COLORS.textMuted; header.Text = title; header.LayoutOrder = startOrder; header.Parent = raidMenu
		local order = startOrder + 1
		for _, raidName in list do
			local pick = makeButton(raidMenu, raidName, COLORS.bg, UDim2.new(1, 0, 0, 28)); pick.LayoutOrder = order; pick.TextSize = 10
			pick.MouseButton1Click:Connect(function()
				selectedRaid = raidName
				raidSelectedLabel.Text = "Selected: " .. raidName
				lastRaidAction = "Selected raid: " .. raidName
				raidMenu.Visible = false
				raidMenu.Size = UDim2.new(1, 0, 0, 0)
			end)
			order = order + 1
		end
		return order
	end
	local order = 1
	order = addSection("Normal Raids", raidLists.Normal, order)
	addSection("Advanced Raids", raidLists.Advanced, order)
	task.defer(updateRaidMenuSize)
end
raidMenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateRaidMenuSize)
raidSelectBtn.MouseButton1Click:Connect(function()
	loadRaidLists()
	rebuildRaidMenu()
	raidMenu.Visible = not raidMenu.Visible
	updateRaidMenuSize()
end)
connect(ReplicatedStorage.DescendantAdded, function(obj)
	local lower = string.lower(obj.Name)
	if string.find(lower, "stock", 1, true) or string.find(lower, "shop", 1, true) then
		stockDirty = true
	end
end)
local function hookDroppedFruitsFolder(folder)
	if not folder then return end
	connect(folder.ChildAdded, function(child)
		if autoTweenFruit and isFruitInstance(child) then
			pendingFruitTarget = child
		end
	end)
	for _, child in folder:GetChildren() do
		if autoTweenFruit and isFruitInstance(child) then
			pendingFruitTarget = child
		end
	end
end
local existingDropped = workspace:FindFirstChild("DroppedFruits")
if existingDropped then
	hookDroppedFruitsFolder(existingDropped)
end
connect(workspace.ChildAdded, function(child)
	if child.Name == "DroppedFruits" then
		hookDroppedFruitsFolder(child)
	end
	if autoTweenFruit and isFruitInstance(child) then
		pendingFruitTarget = child
		stockDirty = true
	end
end)
local debugFrame = Instance.new("Frame"); debugFrame.Name = "Debug"; debugFrame.Size = UDim2.new(1, 0, 0, 78); debugFrame.BackgroundColor3 = COLORS.surface; debugFrame.BorderSizePixel = 0; debugFrame.LayoutOrder = 99; debugFrame.Parent = playerPanel
makeCorner(debugFrame, 8)
debugLabel = Instance.new("TextLabel"); debugLabel.Size = UDim2.new(1, -16, 1, -12); debugLabel.Position = UDim2.fromOffset(8, 6); debugLabel.BackgroundTransparency = 1; debugLabel.Font = Enum.Font.Code; debugLabel.TextSize = 11; debugLabel.TextXAlignment = Enum.TextXAlignment.Left; debugLabel.TextYAlignment = Enum.TextYAlignment.Top; debugLabel.TextWrapped = true; debugLabel.TextColor3 = COLORS.textMuted; debugLabel.Text = "Adjust sliders, then click Apply."; debugLabel.Parent = debugFrame
reopenGui = Instance.new("ScreenGui"); reopenGui.Name = "PlayerSettingsGUI_ToggleGui"; reopenGui.ResetOnSpawn = false; reopenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; reopenGui.DisplayOrder = 10001; reopenGui.IgnoreGuiInset = true; reopenGui.Enabled = true
protectGui(reopenGui)
parentGui(reopenGui)
reopenButton = makeButton(reopenGui, "⚙", COLORS.accent, UDim2.fromOffset(46, 46)); reopenButton.Name = "PlayerSettingsGUI_Toggle"; reopenButton.AnchorPoint = Vector2.new(0, 0); reopenButton.Position = UDim2.fromOffset(14, 80); reopenButton.TextSize = 20; reopenButton.ZIndex = 10; reopenButton.Visible = false; reopenButton.Active = true
makeCorner(reopenButton, 23)
makeStroke(reopenButton, COLORS.accent, 1)
bindHover(reopenButton, COLORS.accent, COLORS.accentHover)
walkSlider = createSliderRow(playerPanel, "Walk Speed", round(pendingWalk), 1)
jumpSlider = createSliderRow(playerPanel, "Jump Height", round(pendingJump), 2)
connect(RunService.RenderStepped, function(dt)
	if not alive then return end
	syncMovementTween(dt)
	if autoCompleteRaid and (isRaidActive() or isNearAnyRaidIsland()) then
		pcall(updateRaidSessionLock)
		pcall(runRaidCombat, dt)
		return
	end
	if movementFollowOwner then return end
	if not walkBoostActive or not appliedWalk then return end
	local humanoid = getHumanoid()
	local hrp = getRootPart()
	if not humanoid or not hrp then return end
	applyWalkToHumanoid(appliedWalk)
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.05 then return end
	local delta = moveDir.Unit * appliedWalk * dt
	hrp.CFrame = hrp.CFrame + delta
end)
connect(RunService.Heartbeat, function()
	if not alive then return end
	if bootstrapHits == 0 then
		bootstrapHits = 1
		pcall(loadRaidLists)
		pcall(refreshStockDisplay, true)
	end
	pcall(refreshStockDisplay)
	if jumpBoostActive and appliedJump then
		local humanoid = getHumanoid()
		if humanoid then
			applyJumpToHumanoid(appliedJump)
		end
	end
	pcall(runIslandTeleport)
	pcall(runFruitAutomation)
	pcall(runRaidAutomation)
	if raidStatusLabel then
		raidStatusLabel.Text = lastRaidAction
	end
	updateDebug()
end)
connect(LocalPlayer.CharacterAdded, function()
	task.wait(0.15)
	captureOriginals()
	if appliedWalk then
		applyWalkToHumanoid(appliedWalk)
	end
	if appliedJump then
		applyJumpToHumanoid(appliedJump)
	end
end)
local function onJumpState(_, newState)
	if not alive or not jumpBoostActive or newState ~= Enum.HumanoidStateType.Jumping then return end
	boostJumpVelocity()
end
local function hookJumpOnCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		connect(humanoid.StateChanged, onJumpState)
	end
end
if LocalPlayer.Character then
	hookJumpOnCharacter(LocalPlayer.Character)
end
connect(LocalPlayer.CharacterAdded, hookJumpOnCharacter)
switchTab("Player")
task.defer(function()
	refreshStockDisplay(true)
end)
local function setTeamStatus(text, color)
	teamStatusLabel.TextColor3 = color or COLORS.textMuted
	teamStatusLabel.Text = text
end
local function onTeamSelected(teamName)
	setTeamStatus("Switching to " .. teamName .. "...", COLORS.warn)
	task.spawn(function()
		local ok, message = joinTeam(teamName)
		if ok then
			setTeamStatus(message .. "\nCurrent team: " .. getCurrentTeamLabel(), COLORS.success)
		else
			setTeamStatus(message, COLORS.danger)
		end
	end)
end
playerTab.MouseButton1Click:Connect(function()
	switchTab("Player")
end)
teamsTab.MouseButton1Click:Connect(function()
	switchTab("Teams")
	teamStatusLabel.Text = "Current team: " .. getCurrentTeamLabel()
end)
raidsTab.MouseButton1Click:Connect(function()
	switchTab("Raids")
end)
aSettingsTab.MouseButton1Click:Connect(function()
	switchTab("A-Settings")
end)
teleportTab.MouseButton1Click:Connect(function()
	switchTab("Teleport")
	islandSelectedLabel.Text = "Selected: "
		.. (selectedIsland or "none")
		.. " (Sea "
		.. tostring(getCurrentSeaNumber())
		.. ")"
end)
fruitsTab.MouseButton1Click:Connect(function()
	switchTab("Fruits")
	refreshStockDisplay(true)
end)
btnPirates.MouseButton1Click:Connect(function()
	onTeamSelected("Pirates")
end)
btnMarines.MouseButton1Click:Connect(function()
	onTeamSelected("Marines")
end)
local function showReopenIcon()
	local pos = savedGuiScreenPos
	if not pos and mainFrame.Visible then
		pos = mainFrame.AbsolutePosition
	end
	if pos then
		reopenButton.Position = UDim2.fromOffset(math.max(14, pos.X), math.max(14, pos.Y + 8))
	end
	reopenGui.Enabled = true
	reopenButton.Visible = true
	reopenButton.Active = true
end
local function hideReopenIcon()
	if not isHidden and not isMinimized then
		reopenButton.Visible = false
	end
end
local function setMinimized(minimized)
	isMinimized = minimized
	if minimized then
		if mainFrame.Visible then
			savedGuiScreenPos = mainFrame.AbsolutePosition
		end
		mainFrame.Visible = false
		btnMinimize.Text = "+"
		showReopenIcon()
	else
		mainFrame.Visible = true
		body.Visible = true
		btnMinimize.Text = "—"
		tween(mainFrame, { Size = UDim2.fromOffset(EXPANDED_SIZE.X, EXPANDED_SIZE.Y) }):Play()
		hideReopenIcon()
	end
end
local function setHidden(hidden)
	isHidden = hidden
	if hidden then
		if mainFrame.Visible then
			savedGuiScreenPos = mainFrame.AbsolutePosition
		end
		mainFrame.Visible = false
		showReopenIcon()
	elseif not isMinimized then
		mainFrame.Visible = true
		hideReopenIcon()
	end
end
local draggingWindow = false
local dragOffset = Vector2.zero
local dragTargets = {
	[titleBar] = true,
	[titleLabel] = true,
	[titleAccent] = true,
	[titleFix] = true,
}
connect(titleBar.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not dragTargets[input.Target] then return end
	draggingWindow = true
	local pos = mainFrame.AbsolutePosition
	dragOffset = Vector2.new(input.Position.X - pos.X, input.Position.Y - pos.Y)
end)
local draggingReopen = false
local reopenDragOffset = Vector2.zero
local reopenDragMoved = false
local reopenPressPos = Vector2.zero
connect(reopenButton.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	draggingReopen = true
	reopenDragMoved = false
	reopenPressPos = Vector2.new(input.Position.X, input.Position.Y)
	local pos = reopenButton.AbsolutePosition
	reopenDragOffset = Vector2.new(input.Position.X - pos.X, input.Position.Y - pos.Y)
end)
connect(UserInputService.InputChanged, function(input)
	if draggingWindow then
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			mainFrame.Position = UDim2.fromOffset(
				input.Position.X - dragOffset.X,
				input.Position.Y - dragOffset.Y
			)
			mainFrame.AnchorPoint = Vector2.new(0, 0)
		end
	elseif draggingReopen then
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local current = Vector2.new(input.Position.X, input.Position.Y)
			if (current - reopenPressPos).Magnitude > 6 then
				reopenDragMoved = true
			end
			reopenButton.Position = UDim2.fromOffset(
				input.Position.X - reopenDragOffset.X,
				input.Position.Y - reopenDragOffset.Y
			)
			reopenButton.AnchorPoint = Vector2.new(0, 0)
		end
	end
end)
connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if draggingReopen and not reopenDragMoved then
			isHidden = false
			isMinimized = false
			mainFrame.Visible = true
			body.Visible = true
			btnMinimize.Text = "—"
			tween(mainFrame, { Size = UDim2.fromOffset(EXPANDED_SIZE.X, EXPANDED_SIZE.Y) }):Play()
			hideReopenIcon()
		end
		draggingWindow = false
		draggingReopen = false
	end
end)
btnMinimize.MouseButton1Click:Connect(function()
	setMinimized(not isMinimized)
end)
btnHide.MouseButton1Click:Connect(function()
	setHidden(true)
end)
bindHover(btnHide, COLORS.surfaceAlt, COLORS.track)
bindHover(btnMinimize, COLORS.surfaceAlt, COLORS.track)
bindHover(btnUnload, COLORS.danger, Color3.fromRGB(239, 68, 68))
walkSlider.ApplyButton.MouseButton1Click:Connect(applyWalk)
jumpSlider.ApplyButton.MouseButton1Click:Connect(applyJump)
btnUnload.MouseButton1Click:Connect(unload)
_G.PlayerSettingsGUI_Unload = unload
end
return buildGui
end)()
local buildOk, buildErr = pcall(buildGui)
if not buildOk then
	showBootError(buildErr)
	warn("[PlayerSettingsGUI]", buildErr)
	return
end
print("[PlayerSettingsGUI] Loaded successfully.")
