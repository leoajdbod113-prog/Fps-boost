--[[
    NEXUS FPS BOOSTER V2
    LocalScript - Roblox Studio
    Otimizado para jogos pesados (Jujutsu Shenanigans, Blox Fruits, etc)

    Novidades da V2:
    • Reduz a qualidade gráfica global (SavedQualityLevel)
    • Lighting.Technology = Compatibility (remove sombras dinâmicas caras)
    • Desliga decoração do Terrain (grama, rochas, etc)
    • Reduz RenderFidelity de MeshParts (personagens/mapas com muito polígono)
    • Reduz distância de streaming (menos partes carregadas ao mesmo tempo)
    • Mantém toda a estrutura de interface da V1 (ON/OFF, modos, backup/restore)
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

local GameSettings
pcall(function()
	GameSettings = UserSettings():GetService("UserGameSettings")
end)

--==================================================
-- COLORS
--==================================================

local PURPLE = Color3.fromRGB(170, 50, 255)
local BACKGROUND = Color3.fromRGB(8, 6, 13)
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

-- Cada modo agora também define o "peso" das otimizações pesadas
local Modes = {
	LOW = {
		Textures = true, Decals = true, Particles = true,
		Effects = true, Shadows = true, Materials = true,
		Terrain = true, MeshFidelity = false, QualityLevel = nil, Streaming = false
	},
	MEDIUM = {
		Textures = false, Decals = false, Particles = false,
		Effects = true, Shadows = false, Materials = true,
		Terrain = true, MeshFidelity = false, QualityLevel = 10, Streaming = false
	},
	HIGH = {
		Textures = false, Decals = false, Particles = false,
		Effects = false, Shadows = false, Materials = true,
		Terrain = false, MeshFidelity = true, QualityLevel = 5, Streaming = false
	},
	ULTRA = {
		Textures = false, Decals = false, Particles = false,
		Effects = false, Shadows = false, Materials = false,
		Terrain = false, MeshFidelity = true, QualityLevel = 2, Streaming = true
	},
	["MEGA ULTRA"] = {
		Textures = false, Decals = false, Particles = false,
		Effects = false, Shadows = false, Materials = false,
		Terrain = false, MeshFidelity = true, QualityLevel = 1, Streaming = true
	}
}

--==================================================
-- BACKUP SYSTEM
--==================================================

local Backup = {}
local BackupCreated = false
local OriginalLightingTech = Lighting.Technology
local OriginalQualityLevel = nil
local OriginalStreamingRadius = Workspace.StreamingTargetRadius
local OriginalStreamingMinRadius = Workspace.StreamingMinRadius

pcall(function()
	if GameSettings then
		OriginalQualityLevel = GameSettings.SavedQualityLevel
	end
end)

local function SaveOriginal(obj)
	if Backup[obj] then return end

	local data = {}

	if obj:IsA("BasePart") then
		data.Material = obj.Material
		data.CastShadow = obj.CastShadow
	end

	if obj:IsA("MeshPart") then
		data.RenderFidelity = obj.RenderFidelity
	end

	if obj:IsA("Texture") or obj:IsA("Decal") then
		data.Transparency = obj.Transparency
	end

	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
		or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
		data.Enabled = obj.Enabled
	end

	if obj:IsA("PostEffect") then
		data.Enabled = obj.Enabled
	end

	Backup[obj] = data
end

local function CreateBackup()
	if BackupCreated then return end

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
				if data.Material then obj.Material = data.Material end
				if data.CastShadow ~= nil then obj.CastShadow = data.CastShadow end
			end

			if obj:IsA("MeshPart") and data.RenderFidelity then
				obj.RenderFidelity = data.RenderFidelity
			end

			if obj:IsA("Texture") or obj:IsA("Decal") then
				if data.Transparency ~= nil then obj.Transparency = data.Transparency end
			end

			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
				or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
				if data.Enabled ~= nil then obj.Enabled = data.Enabled end
			end

			if obj:IsA("PostEffect") then
				if data.Enabled ~= nil then obj.Enabled = data.Enabled end
			end
		end
	end

	Lighting.Technology = OriginalLightingTech
	Lighting.GlobalShadows = true
	Workspace.Terrain.Decoration = true
	Workspace.StreamingTargetRadius = OriginalStreamingRadius
	Workspace.StreamingMinRadius = OriginalStreamingMinRadius

	pcall(function()
		if GameSettings and OriginalQualityLevel then
			GameSettings.SavedQualityLevel = OriginalQualityLevel
		end
	end)

	BoosterEnabled = false
end

--==================================================
-- BOOST
--==================================================

local function ApplyBoost()

	CreateBackup()

	local Config = Modes[CurrentMode]

	for _, obj in ipairs(Workspace:GetDescendants()) do

		if obj:IsA("Texture") then
			if not Config.Textures then obj.Transparency = 1 end

		elseif obj:IsA("Decal") then
			if not Config.Decals then obj.Transparency = 1 end

		elseif obj:IsA("MeshPart") then
			if Config.MeshFidelity then
				obj.RenderFidelity = Enum.RenderFidelity.Performance
			end
			if not Config.Shadows then obj.CastShadow = false end
			if not Config.Materials then obj.Material = Enum.Material.SmoothPlastic end

		elseif obj:IsA("BasePart") then
			if not Config.Shadows then obj.CastShadow = false end
			if not Config.Materials then obj.Material = Enum.Material.SmoothPlastic end

		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
			or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
			if not Config.Particles then obj.Enabled = false end
		end
	end

	-- LIGHTING EFFECTS (Bloom, SunRays, DepthOfField, ColorCorrection, Blur)
	if not Config.Effects then
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("PostEffect") then
				obj.Enabled = false
			end
		end
	end

	-- SOMBRAS GLOBAIS + TECNOLOGIA DE RENDER
	if not Config.Shadows then
		Lighting.GlobalShadows = false
		Lighting.Technology = Enum.Technology.Compatibility
	end

	-- TERRAIN (grama, rochas, decoração pesada)
	if not Config.Terrain then
		Workspace.Terrain.Decoration = false
	end

	-- QUALIDADE GRÁFICA GLOBAL DO ROBLOX
	pcall(function()
		if GameSettings and Config.QualityLevel then
			GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
			-- Nota: o Roblox só aceita QualityLevel1 (auto) ou valores fixos
			-- via QualityLevel numérico em versões mais novas do client.
		end
	end)

	-- STREAMING (reduz distância de renderização de partes)
	if Config.Streaming then
		Workspace.StreamingEnabled = true
		Workspace.StreamingTargetRadius = 128
		Workspace.StreamingMinRadius = 64
	end
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "NexusFPSBoosterV2"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = Player:WaitForChild("PlayerGui")

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

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 55)
Top.BackgroundTransparency = 1
Top.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "N E X U S  //  FPS BOOSTER V2"
Title.TextColor3 = WHITE
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local BoostPage = Instance.new("Frame")
BoostPage.Size = UDim2.new(1, -30, 1, -75)
BoostPage.Position = UDim2.fromOffset(15, 70)
BoostPage.BackgroundTransparency = 1
BoostPage.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.55, 0, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "●  BOOST DISABLED"
Status.TextColor3 = RED
Status.TextSize = 14
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = BoostPage

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

local ModeContainer = Instance.new("Frame")
ModeContainer.Size = UDim2.new(1, 0, 0, 45)
ModeContainer.Position = UDim2.fromOffset(0, 125)
ModeContainer.BackgroundTransparency = 1
ModeContainer.Parent = BoostPage

local ModeNames = {"LOW", "MEDIUM", "HIGH", "ULTRA", "MEGA ULTRA"}
local ModeButtons = {}

for i, ModeName in ipairs(ModeNames) do
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0.19, 0, 1, 0)
	Button.Position = UDim2.new((i - 1) * 0.205, 0, 0, 0)
	Button.BackgroundColor3 = ModeName == CurrentMode and PURPLE or PANEL2
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
	Stroke.Transparency = ModeName == CurrentMode and 0 or 0.5
	Stroke.Parent = Button

	ModeButtons[ModeName] = Button
end

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
		{ BackgroundColor3 = BoosterEnabled and Color3.fromRGB(15, 45, 30) or PANEL2 }
	):Play()

	UpdateToggle()
end)

for ModeName, Button in pairs(ModeButtons) do
	Button.MouseButton1Click:Connect(function()
		CurrentMode = ModeName
		CurrentModeLabel.Text = "MODE: " .. ModeName

		for Name, OtherButton in pairs(ModeButtons) do
			TweenService:Create(
				OtherButton, TweenInfo.new(0.2),
				{ BackgroundColor3 = Name == CurrentMode and PURPLE or PANEL2 }
			):Play()
		end

		if BoosterEnabled then
			ApplyBoost()
		end
	end)
end

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
	if not Dragging then return end
	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local Delta = Input.Position - DragStart
	Main.Position = UDim2.new(
		StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
	)
end)

--==================================================
-- FPS / PING
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

		StatsLabel.Text = "FPS: " .. FPS .. "\nPING: " .. Ping .. " ms"
	end
end)

--==================================================
-- NEON ANIMATION
--==================================================

task.spawn(function()
	while Gui.Parent do
		TweenService:Create(
			MainStroke,
			TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Transparency = 0.45 }
		):Play()
		task.wait(1.4)

		TweenService:Create(
			MainStroke,
			TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Transparency = 0.05 }
		):Play()
		task.wait(1.4)
	end
end)

print("NEXUS FPS BOOSTER V2 iniciado.")
