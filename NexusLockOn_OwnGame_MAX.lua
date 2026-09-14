-- Nexus Lock-On MAX
-- Legitimate Roblox Studio LocalScript for YOUR OWN GAME.
-- Place in StarterPlayer > StarterPlayerScripts.
-- No executor APIs, no exploit dependencies, no auto-reacquire while locked.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CONFIG = {
    Enabled = false,
    Range = 110,
    AcquireFOV = 0.78,                 -- fraction of screen half-width
    AcquireAngle = math.rad(62),
    MaxFollowDistance = 500,
    RequireVisibleOnAcquire = true,

    CameraPriority = Enum.RenderPriority.Camera.Value + 1,
    MaxAngleStep = math.rad(180),
    DeadzonePixels = 0.65,

    AimPointUpdateInterval = 0.08,
    AimPointSwitchCooldown = 0.16,
    CloseDistance = 22,
    FarDistance = 75,
    GroundOffset = 1.55,
    CloseOffset = 1.45,
    FarOffset = 1.62,
    AirborneOffset = 1.35,

    TrackingResponsiveness = 1,
    CameraWeight = 1,
    MobileButton = true,
    ShowTargetIndicator = true,
    Debug = false,
}

local State = {
    Locked = false,
    Target = nil,
    TargetRoot = nil,
    TargetHumanoid = nil,
    AimOffset = CONFIG.GroundOffset,
    LastAimPointUpdate = 0,
    LastAimOffsetChange = 0,
    LastCameraPosition = nil,
}

local function getCharacter(player)
    return player and player.Character
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function getAimPart(character)
    if not character then return nil end
    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
end

local function alive(humanoid)
    return humanoid and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

local function screenCenter()
    local viewport = Camera.ViewportSize
    return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
end

local function getScreenDistance(worldPosition)
    local screen, visible = Camera:WorldToViewportPoint(worldPosition)
    if not visible or screen.Z <= 0 then
        return math.huge, false, screen
    end
    return (Vector2.new(screen.X, screen.Y) - screenCenter()).Magnitude, true, screen
end

local function hasLineOfSight(character, worldPosition)
    if not CONFIG.RequireVisibleOnAcquire then
        return true
    end

    local origin = Camera.CFrame.Position
    local direction = worldPosition - origin
    if direction.Magnitude <= 0.01 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

local function targetData(player, acquisition)
    if not player or player == LocalPlayer then return nil end

    local character = getCharacter(player)
    local humanoid = getHumanoid(character)
    local root = getRoot(character)
    local aimPart = getAimPart(character)
    local myCharacter = LocalPlayer.Character
    local myRoot = getRoot(myCharacter)

    if not character or not humanoid or not root or not aimPart or not myRoot then return nil end
    if not alive(humanoid) then return nil end

    local distance = (root.Position - myRoot.Position).Magnitude
    if acquisition and distance > CONFIG.Range then return nil end
    if not acquisition and distance > CONFIG.MaxFollowDistance then return nil end

    local offset = aimPart.Position - Camera.CFrame.Position
    if offset.Magnitude <= 0.01 then return nil end

    local direction = offset.Unit
    local facingDot = Camera.CFrame.LookVector:Dot(direction)
    local angle = math.acos(math.clamp(facingDot, -1, 1))

    if acquisition then
        if angle > CONFIG.AcquireAngle then return nil end

        local screenDistance, visible = getScreenDistance(aimPart.Position)
        if not visible then return nil end

        local halfWidth = math.max(Camera.ViewportSize.X * 0.5, 1)
        if screenDistance > halfWidth * CONFIG.AcquireFOV then return nil end
        if not hasLineOfSight(character, aimPart.Position) then return nil end
    end

    return {
        Player = player,
        Character = character,
        Humanoid = humanoid,
        Root = root,
        AimPart = aimPart,
        Distance = distance,
        Angle = angle,
    }
end

local function findTarget()
    local best = nil
    local bestScore = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        local data = targetData(player, true)
        if data then
            local screenDistance = getScreenDistance(data.AimPart.Position)
            local score = screenDistance
                + data.Distance * 0.35
                + data.Angle * 180

            if score < bestScore then
                bestScore = score
                best = data
            end
        end
    end

    return best
end

local function getBodyState(humanoid)
    local state = humanoid:GetState()
    local airborne = state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Flying
        or state == Enum.HumanoidStateType.Climbing

    return airborne
end

local function computeAdaptiveOffset(data)
    local d = data.Distance
    local offset

    if getBodyState(data.Humanoid) then
        offset = CONFIG.AirborneOffset
    elseif d <= CONFIG.CloseDistance then
        offset = CONFIG.CloseOffset
    elseif d >= CONFIG.FarDistance then
        offset = CONFIG.FarOffset
    else
        local alpha = (d - CONFIG.CloseDistance) / (CONFIG.FarDistance - CONFIG.CloseDistance)
        offset = CONFIG.CloseOffset + (CONFIG.FarOffset - CONFIG.CloseOffset) * alpha
    end

    return offset
end

local function updateAdaptiveAimPoint(data, now)
    if now - State.LastAimPointUpdate < CONFIG.AimPointUpdateInterval then
        return
    end
    State.LastAimPointUpdate = now

    local desired = computeAdaptiveOffset(data)
    if math.abs(desired - State.AimOffset) < 0.05 then
        return
    end

    if now - State.LastAimOffsetChange < CONFIG.AimPointSwitchCooldown then
        return
    end

    State.AimOffset = desired
    State.LastAimOffsetChange = now
end

local function clearLock()
    State.Locked = false
    State.Target = nil
    State.TargetRoot = nil
    State.TargetHumanoid = nil
    State.AimOffset = CONFIG.GroundOffset
    State.LastAimPointUpdate = 0
    State.LastAimOffsetChange = 0
end

local function acquireLock()
    if State.Locked then
        return false
    end

    local data = findTarget()
    if not data then
        return false
    end

    State.Locked = true
    State.Target = data.Player
    State.TargetRoot = data.Root
    State.TargetHumanoid = data.Humanoid
    State.AimOffset = computeAdaptiveOffset(data)
    State.LastAimPointUpdate = os.clock()
    State.LastAimOffsetChange = os.clock()
    return true
end

local function currentTargetValid()
    if not State.Locked or not State.Target then
        return false
    end

    local data = targetData(State.Target, false)
    if not data then
        return false
    end

    State.TargetRoot = data.Root
    State.TargetHumanoid = data.Humanoid
    return data
end

local function smoothAngle(current, desired, maxStep)
    local dot = math.clamp(current.LookVector:Dot(desired.LookVector), -1, 1)
    local angle = math.acos(dot)
    if angle <= maxStep or angle < 1e-5 then
        return desired
    end

    local alpha = maxStep / angle
    return current:Lerp(desired, alpha)
end

local function updateCamera(data)
    local root = data.Root
    if not root then return end

    local aimPosition = root.Position + Vector3.new(0, State.AimOffset, 0)
    local cameraPosition = Camera.CFrame.Position
    local delta = aimPosition - cameraPosition
    if delta.Magnitude <= 0.01 then return end

    local desired = CFrame.lookAt(cameraPosition, aimPosition, Vector3.yAxis)
    local current = Camera.CFrame
    local screenDistance = getScreenDistance(aimPosition)

    if screenDistance <= CONFIG.DeadzonePixels then
        return
    end

    local limited = smoothAngle(current, desired, CONFIG.MaxAngleStep)
    local response = math.clamp(CONFIG.TrackingResponsiveness * CONFIG.CameraWeight, 0, 1)
    local final = current:Lerp(limited, response)

    Camera.CFrame = final
end

-- Target indicator ---------------------------------------------------------
local indicatorGui = Instance.new("BillboardGui")
indicatorGui.Name = "NexusLockTargetIndicator"
indicatorGui.Size = UDim2.fromOffset(52, 52)
indicatorGui.StudsOffset = Vector3.new(0, 2.8, 0)
indicatorGui.AlwaysOnTop = true
indicatorGui.Enabled = false
indicatorGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local indicator = Instance.new("Frame")
indicator.BackgroundTransparency = 1
indicator.Size = UDim2.fromScale(1, 1)
indicator.Parent = indicatorGui

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Transparency = 0.05
stroke.Parent = indicator

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = indicator

local function updateIndicator()
    if not CONFIG.ShowTargetIndicator or not State.Locked or not State.TargetRoot then
        indicatorGui.Enabled = false
        return
    end

    indicatorGui.Adornee = State.TargetRoot
    indicatorGui.Enabled = State.TargetRoot.Parent ~= nil
end

-- Small mobile/keyboard control ------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NexusLockOnUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "LockOnButton"
button.Size = UDim2.fromOffset(72, 72)
button.Position = UDim2.new(1, -92, 1, -120)
button.BackgroundTransparency = 0.18
button.Text = "LOCK\nOFF"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = gui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 16)
buttonCorner.Parent = button

local function refreshButton()
    if State.Locked then
        button.Text = "LOCK\nON"
        button.BackgroundTransparency = 0.05
    else
        button.Text = "LOCK\nOFF"
        button.BackgroundTransparency = 0.18
    end
end

local function toggleLock()
    if State.Locked then
        clearLock()
    else
        acquireLock()
    end
    refreshButton()
end

button.Activated:Connect(toggleLock)

-- Keyboard: Q toggles. Change this to any key desired for your game.
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        toggleLock()
    end
end)

-- Main tracking loop. The target is acquired ONLY when enabling.
RunService:BindToRenderStep("NexusOwnGameLockOn", CONFIG.CameraPriority, function()
    if not State.Locked then
        updateIndicator()
        return
    end

    local data = currentTargetValid()
    if not data then
        -- Important: clear only. NEVER choose a replacement target here.
        clearLock()
        refreshButton()
        updateIndicator()
        return
    end

    local now = os.clock()
    updateAdaptiveAimPoint(data, now)
    updateCamera(data)
    updateIndicator()
end)

-- Cleanly clear the lock when the local player respawns.
LocalPlayer.CharacterRemoving:Connect(function()
    clearLock()
    refreshButton()
end)

-- Optional public API for your own game's other LocalScripts.
-- Example: _G.NexusLockOn.Toggle()
_G.NexusLockOn = {
    Toggle = toggleLock,
    Acquire = acquireLock,
    Release = clearLock,
    IsLocked = function()
        return State.Locked
    end,
    GetTarget = function()
        return State.Target
    end,
    Config = CONFIG,
}

refreshButton()
