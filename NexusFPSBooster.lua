--[[
    NEXUS FPS BOOSTER
    LocalScript - Roblox Studio

    Recursos:
    • ON / OFF
    • LOW / MEDIUM / HIGH / ULTRA / MEGA ULTRA
    • FPS
    • Ping
    • Performance
    • Memória
    • Instâncias
    • Backup dos gráficos
    • Restore Graphics
    • Interface neon roxa
    • Animações
    • Janela arrastável
]]

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer

--==================================================
-- COLORS
--==================================================

local PURPLE = Color3.fromRGB(170, 50, 255)
local PURPLE_DARK = Color3.fromRGB(75, 20, 110)
local BACKGROUND = Color3.fromRGB(8, 6, 13)
local PANEL = Color3.fromRGB(18, 12, 27)
local PANEL2 = Color3.fromRGB(27, 17, 39)

local WHITE = Color3.fromRGB(240, 235, 250)
local GREEN = Color3.fromRGB(70, 255, 150)
local RED = Color3.fromRGB(255, 70, 90)
local YELLOW = Color3.fromRGB(255, 210, 70)

--==================================================
-- SETTINGS
--==================================================

local BoosterEnabled = false
local CurrentMode = "LOW"

local Modes = {
	LOW = {
		Textures = true,
		Decals = true,
		Particles = true,
		Effects = true,
		Shadows = true,
		Materials = true
	},

	MEDIUM = {
		Textures = false,
		Decals = false,
		Particles = false,
		Effects = true,
		Shadows = false,
		Materials = true
	},

	HIGH = {
		Textures = false,
		Decals = false,
		Particles = false,
		Effects = false,
		Shadows = false,
		Materials = true
	},

	ULTRA = {
		Textures = false,
		Decals = false,
		Particles = false,
		Effects = false,
		Shadows = false,
		Materials = false
	},

	["MEGA ULTRA"] = {
		Textures = false,
		Decals = false,
		Particles = false,
		Effects = false,
		Shadows = false,
		Materials = false
	}
}

--==================================================
-- BACKUP SYSTEM
--==================================================

local Backup = {}
local BackupCreated = false

local function SaveOriginal(obj)

	if Backup[obj] then
		return
	end

	local data = {}

	if obj:IsA("BasePart") then
		data.Material = obj.Material
		data.CastShadow = obj.CastShadow
	end

	if obj:IsA("Texture") or obj:IsA("Decal") then
		data.Transparency = obj.Transparency
	end

	if obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Beam")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles") then

		data.Enabled = obj.Enabled
	end

	if obj:IsA("PostEffect") then
		data.Enabled = obj.Enabled
	end

	Backup[obj] = data
end

local function CreateBackup()

	if BackupCreated then
		return
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		SaveOriginal(obj)
	end

	for _, obj in ipairs(Lighting:GetChildren()) do
		SaveOriginal(obj)
	end

	BackupCreated = true
end

--==================================================
-- RESTORE
--==================================================

local function RestoreGraphics()

	for obj, data in pairs(Backup) do

		if obj and obj.Parent then

			if obj:IsA("BasePart") then

				if data.Material then
					obj.Material = data.Material
				end

				if data.CastShadow ~= nil then
					obj.CastShadow = data.CastShadow
				end
			end

			if obj:IsA("Texture") or obj:IsA("Decal") then

				if data.Transparency ~= nil then
					obj.Transparency = data.Transparency
				end
			end

			if obj:IsA("ParticleEmitter")
				or obj:IsA("Trail")
				or obj:IsA("Beam")
				or obj:IsA("Smoke")
				or obj:IsA("Fire")
				or obj:IsA("Sparkles") then

				if data.Enabled ~= nil then
					obj.Enabled = data.Enabled
				end
			end

			if obj:IsA("PostEffect") then

				if data.Enabled ~= nil then
					obj.Enabled = data.Enabled
				end
			end
		end
	end

	BoosterEnabled = false
end

--==================================================
-- BOOST
--==================================================

local function ApplyBoost()

	CreateBackup()

	local Config = Modes[CurrentMode]

	for _, obj in ipairs(Workspace:GetDescendants()) do

		-- TEXTURES
		if obj:IsA("Texture") then

			if not Config.Textures then
				obj.Transparency = 1
			end

		-- DECALS
		elseif obj:IsA("Decal") then

			if not Config.Decals then
				obj.Transparency = 1
			end

		-- PARTS
		elseif obj:IsA("BasePart") then

			if not Config.Shadows then
				obj.CastShadow = false
			end

			if not Config.Materials then
				obj.Material = Enum.Material.SmoothPlastic
			end

		-- PARTICLES / EFFECTS
		elseif obj:IsA("ParticleEmitter")
			or obj:IsA("Trail")
			or obj:IsA("Beam")
			or obj:IsA("Smoke")
			or obj:IsA("Fire")
			or obj:IsA("Sparkles") then

			if not Config.Particles then
				obj.Enabled = false
			end
		end
	end

	-- LIGHTING EFFECTS
	if not Config.Effects then

		for _, obj in ipairs(Lighting:GetChildren()) do

			if obj:IsA("PostEffect") then
				obj.Enabled = false
			end
		end
	end

	-- GLOBAL SHADOWS
	if not Config.Shadows then
		Lighting.GlobalShadows = false
	end
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "NexusFPSBooster"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = Player:WaitForChild("PlayerGui")

--==================================================
-- MAIN FRAME
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(480, 360)
Main.Position = UDim2.new(0.5, -240, 0.5, -180)
Main.BackgroundColor3 = BACKGROUND
Main.BackgroundTransparency = 0.10
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 15)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = PURPLE
MainStroke.Thickness = 2
MainStroke.Transparency = 0.15
MainStroke.Parent = Main

--==================================================
-- TOP BAR
--==================================================

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 55)
Top.BackgroundTransparency = 1
Top.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "N E X U S  //  FPS BOOSTER"
Title.TextColor3 = WHITE
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

--==================================================
-- TABS
--==================================================

local BoostTab = Instance.new("TextButton")
BoostTab.Size = UDim2.fromOffset(115, 32)
BoostTab.Position = UDim2.fromOffset(15, 58)
BoostTab.BackgroundColor3 = PURPLE
BoostTab.Text = "BOOST"
BoostTab.TextColor3 = WHITE
BoostTab.Font = Enum.Font.GothamBold
BoostTab.TextSize = 12
BoostTab.AutoButtonColor = false
BoostTab.Parent = Main

local BoostTabCorner = Instance.new("UICorner")
BoostTabCorner.CornerRadius = UDim.new(0, 7)
BoostTabCorner.Parent = BoostTab

local PerfTab = Instance.new("TextButton")
PerfTab.Size = UDim2.fromOffset(125, 32)
PerfTab.Position = UDim2.fromOffset(140, 58)
PerfTab.BackgroundColor3 = PANEL2
PerfTab.Text = "PERFORMANCE"
PerfTab.TextColor3 = WHITE
PerfTab.Font = Enum.Font.GothamBold
PerfTab.TextSize = 12
PerfTab.AutoButtonColor = false
PerfTab.Parent = Main

local PerfTabCorner = Instance.new("UICorner")
PerfTabCorner.CornerRadius = UDim.new(0, 7)
PerfTabCorner.Parent = PerfTab

--==================================================
-- BOOST PAGE
--==================================================

local BoostPage = Instance.new("Frame")
BoostPage.Size = UDim2.new(1, -30, 1, -105)
BoostPage.Position = UDim2.fromOffset(15, 100)
BoostPage.BackgroundTransparency = 1
BoostPage.Parent = Main

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.55, 0, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "●  BOOST DISABLED"
Status.TextColor3 = RED
Status.TextSize = 14
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = BoostPage

--==================================================
-- FPS / PING
--==================================================

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.fromOffset(180, 55)
StatsLabel.Position = UDim2.fromOffset(0, 35)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "FPS: --\nPING: -- ms"
StatsLabel.TextColor3 = WHITE
StatsLabel.TextSize = 14
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = BoostPage

--==================================================
-- ON / OFF
--==================================================

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(110, 44)
Toggle.Position = UDim2.new(1, -110, 0, 30)
Toggle.BackgroundColor3 = PANEL2
Toggle.Text = "OFF"
Toggle.TextColor3 = RED
Toggle.TextSize = 15
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = false
Toggle.Parent = BoostPage

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = PURPLE
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = Toggle

--==================================================
-- MODE TITLE
--==================================================

local ModeTitle = Instance.new("TextLabel")
ModeTitle.Size = UDim2.new(1, 0, 0, 25)
ModeTitle.Position = UDim2.fromOffset(0, 95)
ModeTitle.BackgroundTransparency = 1
ModeTitle.Text = "OPTIMIZATION MODE"
ModeTitle.TextColor3 = PURPLE
ModeTitle.TextSize = 11
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
ModeTitle.Parent = BoostPage

--==================================================
-- MODE BUTTONS
--==================================================

local ModeContainer = Instance.new("Frame")
ModeContainer.Size = UDim2.new(1, 0, 0, 45)
ModeContainer.Position = UDim2.fromOffset(0, 125)
ModeContainer.BackgroundTransparency = 1
ModeContainer.Parent = BoostPage

local ModeNames = {
	"LOW",
	"MEDIUM",
	"HIGH",
	"ULTRA",
	"MEGA ULTRA"
}

local ModeButtons = {}

for i, ModeName in ipairs(ModeNames) do

	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(0.19, 0, 1, 0)
	Button.Position = UDim2.new((i - 1) * 0.205, 0, 0, 0)

	Button.BackgroundColor3 =
		ModeName == CurrentMode and PURPLE or PANEL2

	Button.Text = ModeName
	Button.TextColor3 = WHITE
	Button.TextSize = 9
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.Parent = ModeContainer

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 7)
	Corner.Parent = Button

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = PURPLE
	Stroke.Thickness = 1
	Stroke.Transparency =
		ModeName == CurrentMode and 0 or 0.5

	Stroke.Parent = Button

	ModeButtons[ModeName] = Button
end

--==================================================
-- RESTORE BUTTON
--==================================================

local Restore = Instance.new("TextButton")
Restore.Size = UDim2.fromOffset(150, 35)
Restore.Position = UDim2.fromOffset(0, 185)
Restore.BackgroundColor3 = PANEL2
Restore.Text = "↻  RESTORE GRAPHICS"
Restore.TextColor3 = WHITE
Restore.TextSize = 11
Restore.Font = Enum.Font.GothamBold
Restore.AutoButtonColor = false
Restore.Parent = BoostPage

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 7)
RestoreCorner.Parent = Restore

local RestoreStroke = Instance.new("UIStroke")
RestoreStroke.Color = PURPLE
RestoreStroke.Thickness = 1
RestoreStroke.Parent = Restore

--==================================================
-- CURRENT MODE LABEL
--==================================================

local CurrentModeLabel = Instance.new("TextLabel")
CurrentModeLabel.Size = UDim2.new(1, -165, 0, 35)
CurrentModeLabel.Position = UDim2.fromOffset(165, 185)
CurrentModeLabel.BackgroundTransparency = 1
CurrentModeLabel.Text = "MODE: LOW"
CurrentModeLabel.TextColor3 = WHITE
CurrentModeLabel.TextSize = 12
CurrentModeLabel.Font = Enum.Font.GothamMedium
CurrentModeLabel.TextXAlignment = Enum.TextXAlignment.Right
CurrentModeLabel.Parent = BoostPage

--==================================================
-- PERFORMANCE PAGE
--==================================================

local PerfPage = Instance.new("Frame")
PerfPage.Size = BoostPage.Size
PerfPage.Position = BoostPage.Position
PerfPage.BackgroundTransparency = 1
PerfPage.Visible = false
PerfPage.Parent = Main

local PerformanceText = Instance.new("TextLabel")
PerformanceText.Size = UDim2.new(1, 0, 1, 0)
PerformanceText.BackgroundTransparency = 1
PerformanceText.TextColor3 = WHITE
PerformanceText.TextSize = 14
PerformanceText.Font = Enum.Font.Code
PerformanceText.TextXAlignment = Enum.TextXAlignment.Left
PerformanceText.TextYAlignment = Enum.TextYAlignment.Top
PerformanceText.Text = "N E X U S // PERFORMANCE"
PerformanceText.Parent = PerfPage

--==================================================
-- TOGGLE FUNCTION
--==================================================

local function UpdateToggle()

	if BoosterEnabled then

		Toggle.Text = "ON"
		Toggle.TextColor3 = GREEN
		Status.Text = "●  BOOST ACTIVE"
		Status.TextColor3 = GREEN

		ApplyBoost()

	else

		Toggle.Text = "OFF"
		Toggle.TextColor3 = RED
		Status.Text = "●  BOOST DISABLED"
		Status.TextColor3 = RED

		RestoreGraphics()
	end
end

Toggle.MouseButton1Click:Connect(function()

	BoosterEnabled = not BoosterEnabled

	TweenService:Create(
		Toggle,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{
			BackgroundColor3 =
				BoosterEnabled
				and Color3.fromRGB(15, 45, 30)
				or PANEL2
		}
	):Play()

	UpdateToggle()
end)

--==================================================
-- MODE SELECTION
--==================================================

for ModeName, Button in pairs(ModeButtons) do

	Button.MouseButton1Click:Connect(function()

		CurrentMode = ModeName

		CurrentModeLabel.Text = "MODE: " .. ModeName

		for Name, OtherButton in pairs(ModeButtons) do

			TweenService:Create(
				OtherButton,
				TweenInfo.new(0.2),
				{
					BackgroundColor3 =
						Name == CurrentMode
						and PURPLE
						or PANEL2
				}
			):Play()
		end

		if BoosterEnabled then
			ApplyBoost()
		end
	end)
end

--==================================================
-- RESTORE BUTTON
--==================================================

Restore.MouseButton1Click:Connect(function()

	RestoreGraphics()

	Status.Text = "●  GRAPHICS RESTORED"
	Status.TextColor3 = YELLOW

	task.delay(2, function()

		if not BoosterEnabled then
			Status.Text = "●  BOOST DISABLED"
			Status.TextColor3 = RED
		end
	end)

	Toggle.Text = "OFF"
	Toggle.TextColor3 = RED
	Toggle.BackgroundColor3 = PANEL2
end)

--==================================================
-- TABS
--==================================================

BoostTab.MouseButton1Click:Connect(function()

	BoostPage.Visible = true
	PerfPage.Visible = false

	BoostTab.BackgroundColor3 = PURPLE
	PerfTab.BackgroundColor3 = PANEL2
end)

PerfTab.MouseButton1Click:Connect(function()

	BoostPage.Visible = false
	PerfPage.Visible = true

	PerfTab.BackgroundColor3 = PURPLE
	BoostTab.BackgroundColor3 = PANEL2
end)

--==================================================
-- DRAGGING
--==================================================

local Dragging = false
local DragStart
local StartPosition

Top.InputBegan:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position

		Input.Changed:Connect(function()

			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(Input)

	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local Delta = Input.Position - DragStart

	Main.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end)

--==================================================
-- FPS / PING / PERFORMANCE
--==================================================

local Frames = 0
local LastFPSUpdate = os.clock()
local FPS = 0

RunService.RenderStepped:Connect(function()

	Frames += 1

	local Now = os.clock()

	if Now - LastFPSUpdate >= 1 then

		FPS = Frames
		Frames = 0
		LastFPSUpdate = Now

		local Ping = 0

		pcall(function()
			Ping = math.floor(Player:GetNetworkPing() * 1000)
		end)

		local InstanceCount = #Workspace:GetDescendants()

		local Memory = "N/A"

		pcall(function()
			Memory = string.format(
				"%.1f MB",
				Stats:GetTotalMemoryUsageMb()
			)
		end)

		StatsLabel.Text =
			"FPS: " .. FPS ..
			"\nPING: " .. Ping .. " ms"

		PerformanceText.Text =
			"N E X U S  //  PERFORMANCE\n\n" ..
			"STATUS       : " ..
			(BoosterEnabled and "ACTIVE" or "DISABLED") ..
			"\n\n" ..
			"MODE         : " .. CurrentMode ..
			"\n\n" ..
			"FPS          : " .. FPS ..
			"\nPING         : " .. Ping .. " ms" ..
			"\nMEMORY       : " .. Memory ..
			"\nINSTANCES    : " .. InstanceCount ..
			"\n\n" ..
			"TEXTURES     : " ..
			(BoosterEnabled and "OPTIMIZED" or "DEFAULT") ..
			"\nEFFECTS      : " ..
			(BoosterEnabled and "OPTIMIZED" or "DEFAULT") ..
			"\nSHADOWS      : " ..
			(BoosterEnabled and "OPTIMIZED" or "DEFAULT")
	end
end)

--==================================================
-- NEON ANIMATION
--==================================================

task.spawn(function()

	while Gui.Parent do

		TweenService:Create(
			MainStroke,
			TweenInfo.new(
				1.4,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			),
			{
				Transparency = 0.45
			}
		):Play()

		task.wait(1.4)

		TweenService:Create(
			MainStroke,
			TweenInfo.new(
				1.4,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			),
			{
				Transparency = 0.05
			}
		):Play()

		task.wait(1.4)
	end
end)

--==================================================
-- START
--==================================================

print("NEXUS FPS BOOSTER iniciado.")
