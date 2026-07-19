-- ==================== SERVICES & VARIABLES ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
local Humanoid = Character:WaitForChild('Humanoid')

local AntiBatConn = nil
local AntiRagdollConn = nil
local JumpRequestConn = nil

local CurrentScale = 1

local Keybinds = {
    AntiBat = Enum.KeyCode.F,
    InfJump = Enum.KeyCode.G
}
local AntiBatEnabled = false
local InfJumpEnabled = false
local KEYBIND_FILE = "SpiderHub_Keybinds.txt"

-- ==================== LOAD / SAVE KEYBINDS ====================
local function loadKeybinds()
    if isfile and isfile(KEYBIND_FILE) then
        local success, data = pcall(function() return readfile(KEYBIND_FILE) end)
        if success and data then
            local tbl = {}
            for pair in data:gmatch("([^,]+)") do
                local k, v = pair:match("([^=]+)=(.+)")
                if k and v then
                    for _, enum in ipairs(Enum.KeyCode:GetEnumItems()) do
                        if enum.Name == v then
                            tbl[k] = enum
                            break
                        end
                    end
                end
            end
            if tbl.AntiBat then Keybinds.AntiBat = tbl.AntiBat end
            if tbl.InfJump then Keybinds.InfJump = tbl.InfJump end
        end
    end
end

local function saveKeybinds()
    if writefile then
        local str = "AntiBat=" .. tostring(Keybinds.AntiBat.Name) .. "," .. "InfJump=" .. tostring(Keybinds.InfJump.Name)
        pcall(function() writefile(KEYBIND_FILE, str) end)
    end
end

loadKeybinds()

-- ==================== ANTI BAT CORE ====================
local function startAntiBat()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild('HumanoidRootPart')
    if not root then return end
    if AntiBatConn then AntiBatConn:Disconnect() end
    AntiBatConn = RunService.Heartbeat:Connect(function()
        if not root or not root.Parent then return end
        local origXZ = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        root.Velocity = Vector3.new(1000, root.Velocity.Y, 1000)
        RunService.RenderStepped:Wait()
        root.Velocity = Vector3.new(origXZ.X, root.Velocity.Y, origXZ.Z)
    end)
end

local function stopAntiBat()
    if AntiBatConn then
        AntiBatConn:Disconnect()
        AntiBatConn = nil
    end
end

-- ==================== INFINITE JUMP ====================
local function setupInfJump()
    if JumpRequestConn then JumpRequestConn:Disconnect() end
    JumpRequestConn = UserInputService.JumpRequest:Connect(function()
        if not InfJumpEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild('HumanoidRootPart')
        if root then
            root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
        end
    end)
end

-- ==================== ANTI RAGDOLL ====================
local function startAntiRagdoll()
    if AntiRagdollConn then return end
    AntiRagdollConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass('Humanoid')
        local root = char:FindFirstChild('HumanoidRootPart')
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild('PlayerModule')
                    if pm then require(pm:FindFirstChild('ControlModule')):Enable() end
                end)
                if root then
                    root.Velocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA('Motor6D') and not obj.Enabled then
                obj.Enabled = true
            end
        end
    end)
end

-- ==================== CHARACTER RESPAWN ====================
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild('HumanoidRootPart')
    Humanoid = newChar:WaitForChild('Humanoid')
    if AntiBatEnabled then
        task.wait(0.3)
        startAntiBat()
    end
    task.wait(0.5)
    startAntiRagdoll()
end)

-- ==================== UI CREATION ====================
local COLORS = {
    MainBg = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(230, 36, 41),
    Stroke = Color3.fromRGB(70, 70, 70),
    RowBg = Color3.fromRGB(45, 45, 45),
    RowBgTrans = 0.4,
    ButtonBase = Color3.fromRGB(55, 55, 55),
    ButtonSelected = Color3.fromRGB(230, 36, 41),
    ButtonText = Color3.fromRGB(220, 220, 220),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    StatusActive = Color3.fromRGB(230, 36, 41),
    StatusOff = Color3.fromRGB(150, 150, 150),
    KeybindText = Color3.fromRGB(230, 36, 41),
}

local gui = Instance.new('ScreenGui')
gui.Name = 'spider_hub'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local MainFrame = Instance.new('Frame')
MainFrame.Name = 'MainFrame'
MainFrame.Active = true
MainFrame.AnchorPoint = Vector2.new(0,0)
MainFrame.BackgroundColor3 = COLORS.MainBg
MainFrame.BackgroundTransparency = 0
MainFrame.BorderColor3 = COLORS.Stroke
MainFrame.BorderMode = Enum.BorderMode.Outline
MainFrame.BorderSizePixel = 1
MainFrame.ClipsDescendants = true
MainFrame.Draggable = true
MainFrame.Position = UDim2.new(0.5,-120,0.5,-140)
MainFrame.Rotation = 0
MainFrame.Selectable = false
MainFrame.Size = UDim2.new(0,240,0,280)
MainFrame.SizeConstraint = Enum.SizeConstraint.RelativeXY
MainFrame.Visible = true
MainFrame.ZIndex = 1
MainFrame.Parent = gui

local UICorner = Instance.new('UICorner')
UICorner.CornerRadius = UDim.new(0,12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new('UIStroke')
UIStroke.Color = COLORS.Stroke
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- ===== TITLE BAR =====
local TitleBar = Instance.new('Frame')
TitleBar.Name = 'TitleBar'
TitleBar.BackgroundTransparency = 1
TitleBar.Size = UDim2.new(1,0,0,50)
TitleBar.ZIndex = 3
TitleBar.Parent = MainFrame

-- Script Title
local TitleLabel = Instance.new('TextLabel')
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Spider Hub Anti Bat"
TitleLabel.TextColor3 = COLORS.Accent
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Size = UDim2.new(1,0,1,0)
TitleLabel.Position = UDim2.new(0,0,0,0)
TitleLabel.Parent = TitleBar

local ToggleBtn = Instance.new('TextButton')
ToggleBtn.Name = 'ToggleBtn'
ToggleBtn.Size = UDim2.new(0,20,0,20)
ToggleBtn.Position = UDim2.new(1,-28,0.5,-10)
ToggleBtn.BackgroundColor3 = COLORS.ButtonBase
ToggleBtn.Text = '-'
ToggleBtn.TextColor3 = COLORS.Accent
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 12
ToggleBtn.AutoButtonColor = false
ToggleBtn.ZIndex = 4
ToggleBtn.Parent = TitleBar
local ToggleCorner = Instance.new('UICorner')
ToggleCorner.CornerRadius = UDim.new(0,5)
ToggleCorner.Parent = ToggleBtn
local ToggleStroke = Instance.new('UIStroke')
ToggleStroke.Color = COLORS.Stroke
ToggleStroke.Thickness = 0.8
ToggleStroke.Parent = ToggleBtn

local Divider = Instance.new('Frame')
Divider.Size = UDim2.new(1,-16,0,1)
Divider.Position = UDim2.new(0,8,0,50)
Divider.BackgroundColor3 = COLORS.Stroke
Divider.BackgroundTransparency = 0.5
Divider.Parent = MainFrame

local ContentContainer = Instance.new('Frame')
ContentContainer.Name = 'ContentContainer'
ContentContainer.BackgroundTransparency = 1
ContentContainer.Size = UDim2.new(1,0,0,230)
ContentContainer.Position = UDim2.new(0,0,0,50)
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = MainFrame

-- ==================== ANTI BAT ROW ====================
local AntiBatRow = Instance.new('Frame')
AntiBatRow.Size = UDim2.new(1,-16,0,38)
AntiBatRow.Position = UDim2.new(0,8,0,10)
AntiBatRow.BackgroundColor3 = COLORS.RowBg
AntiBatRow.BackgroundTransparency = COLORS.RowBgTrans
AntiBatRow.Parent = ContentContainer
local RowCorner = Instance.new('UICorner')
RowCorner.CornerRadius = UDim.new(0,10)
RowCorner.Parent = AntiBatRow
local RowStroke = Instance.new('UIStroke')
RowStroke.Color = COLORS.Stroke
RowStroke.Thickness = 1
RowStroke.Parent = AntiBatRow

local AntiBatLabel = Instance.new('TextLabel')
AntiBatLabel.Size = UDim2.new(0.5,0,1,0)
AntiBatLabel.Position = UDim2.new(0,12,0,0)
AntiBatLabel.BackgroundTransparency = 1
AntiBatLabel.Text = 'Anti Bat'
AntiBatLabel.TextColor3 = COLORS.TextPrimary
AntiBatLabel.Font = Enum.Font.GothamBold
AntiBatLabel.TextSize = 12
AntiBatLabel.TextXAlignment = Enum.TextXAlignment.Left
AntiBatLabel.Parent = AntiBatRow

local AntiBatStatus = Instance.new('TextLabel')
AntiBatStatus.Size = UDim2.new(0.4,0,1,0)
AntiBatStatus.Position = UDim2.new(0.5,0,0,0)
AntiBatStatus.BackgroundTransparency = 1
AntiBatStatus.Text = 'OFF'
AntiBatStatus.TextColor3 = COLORS.StatusOff
AntiBatStatus.Font = Enum.Font.GothamBold
AntiBatStatus.TextSize = 12
AntiBatStatus.TextXAlignment = Enum.TextXAlignment.Right
AntiBatStatus.Parent = AntiBatRow

local AntiBatClick = Instance.new('TextButton')
AntiBatClick.Size = UDim2.new(1,0,1,0)
AntiBatClick.BackgroundTransparency = 1
AntiBatClick.Text = ''
AntiBatClick.Parent = AntiBatRow

-- ==================== INF JUMP ROW ====================
local JumpRow = Instance.new('Frame')
JumpRow.Size = UDim2.new(1,-16,0,38)
JumpRow.Position = UDim2.new(0,8,0,52)
JumpRow.BackgroundColor3 = COLORS.RowBg
JumpRow.BackgroundTransparency = COLORS.RowBgTrans
JumpRow.Parent = ContentContainer
local JumpCorner = Instance.new('UICorner')
JumpCorner.CornerRadius = UDim.new(0,10)
JumpCorner.Parent = JumpRow
local JumpStroke = Instance.new('UIStroke')
JumpStroke.Color = COLORS.Stroke
JumpStroke.Thickness = 1
JumpStroke.Parent = JumpRow

local JumpLabel = Instance.new('TextLabel')
JumpLabel.Size = UDim2.new(0.5,0,1,0)
JumpLabel.Position = UDim2.new(0,12,0,0)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Text = 'Inf Jump'
JumpLabel.TextColor3 = COLORS.TextPrimary
JumpLabel.Font = Enum.Font.GothamBold
JumpLabel.TextSize = 12
JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
JumpLabel.Parent = JumpRow

local JumpStatus = Instance.new('TextLabel')
JumpStatus.Size = UDim2.new(0.4,0,1,0)
JumpStatus.Position = UDim2.new(0.5,0,0,0)
JumpStatus.BackgroundTransparency = 1
JumpStatus.Text = 'OFF'
JumpStatus.TextColor3 = COLORS.StatusOff
JumpStatus.Font = Enum.Font.GothamBold
JumpStatus.TextSize = 12
JumpStatus.TextXAlignment = Enum.TextXAlignment.Right
JumpStatus.Parent = JumpRow

local JumpClick = Instance.new('TextButton')
JumpClick.Size = UDim2.new(1,0,1,0)
JumpClick.BackgroundTransparency = 1
JumpClick.Text = ''
JumpClick.Parent = JumpRow

-- ==================== KEYBINDS FRAME ====================
local KeybindsFrame = Instance.new('Frame')
KeybindsFrame.Size = UDim2.new(1,-16,0,75)
KeybindsFrame.Position = UDim2.new(0,8,0,94)
KeybindsFrame.BackgroundColor3 = COLORS.RowBg
KeybindsFrame.BackgroundTransparency = COLORS.RowBgTrans
KeybindsFrame.Parent = ContentContainer
local KbCorner = Instance.new('UICorner')
KbCorner.CornerRadius = UDim.new(0,10)
KbCorner.Parent = KeybindsFrame
local KbStroke = Instance.new('UIStroke')
KbStroke.Color = COLORS.Stroke
KbStroke.Thickness = 1
KbStroke.Parent = KeybindsFrame

local KbTitle = Instance.new('TextLabel')
KbTitle.Size = UDim2.new(1,-12,0,12)
KbTitle.Position = UDim2.new(0,6,0,4)
KbTitle.BackgroundTransparency = 1
KbTitle.Text = 'Keybinds'
KbTitle.TextColor3 = COLORS.TextSecondary
KbTitle.Font = Enum.Font.GothamBold
KbTitle.TextSize = 9
KbTitle.TextXAlignment = Enum.TextXAlignment.Left
KbTitle.Parent = KeybindsFrame

local Kb1 = Instance.new('TextButton')
Kb1.Name = 'KbAntiBat'
Kb1.Size = UDim2.new(0,35,0,16)
Kb1.Position = UDim2.new(0,6,0,19)
Kb1.BackgroundColor3 = COLORS.ButtonBase
Kb1.Text = tostring(Keybinds.AntiBat.Name)
Kb1.TextColor3 = COLORS.KeybindText
Kb1.Font = Enum.Font.GothamBold
Kb1.TextSize = 7
Kb1.AutoButtonColor = false
Kb1.Parent = KeybindsFrame
local Kb1Corner = Instance.new('UICorner')
Kb1Corner.CornerRadius = UDim.new(0,4)
Kb1Corner.Parent = Kb1
local Kb1Stroke = Instance.new('UIStroke')
Kb1Stroke.Color = COLORS.Stroke
Kb1Stroke.Thickness = 1
Kb1Stroke.Parent = Kb1

local Kb2 = Instance.new('TextButton')
Kb2.Name = 'KbInfJump'
Kb2.Size = UDim2.new(0,35,0,16)
Kb2.Position = UDim2.new(0,46,0,19)
Kb2.BackgroundColor3 = COLORS.ButtonBase
Kb2.Text = tostring(Keybinds.InfJump.Name)
Kb2.TextColor3 = COLORS.KeybindText
Kb2.Font = Enum.Font.GothamBold
Kb2.TextSize = 7
Kb2.AutoButtonColor = false
Kb2.Parent = KeybindsFrame
local Kb2Corner = Instance.new('UICorner')
Kb2Corner.CornerRadius = UDim.new(0,4)
Kb2Corner.Parent = Kb2
local Kb2Stroke = Instance.new('UIStroke')
Kb2Stroke.Color = COLORS.Stroke
Kb2Stroke.Thickness = 1
Kb2Stroke.Parent = Kb2

local SaveBtn = Instance.new('TextButton')
SaveBtn.Size = UDim2.new(0,35,0,16)
SaveBtn.Position = UDim2.new(0,86,0,19)
SaveBtn.BackgroundColor3 = COLORS.ButtonBase
SaveBtn.Text = 'SAVE'
SaveBtn.TextColor3 = COLORS.ButtonText
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 7
SaveBtn.AutoButtonColor = false
SaveBtn.Parent = KeybindsFrame
local SaveCorner = Instance.new('UICorner')
SaveCorner.CornerRadius = UDim.new(0,4)
SaveCorner.Parent = SaveBtn
local SaveStroke = Instance.new('UIStroke')
SaveStroke.Color = COLORS.Stroke
SaveStroke.Thickness = 1
SaveStroke.Parent = SaveBtn

local DCBtn = Instance.new('TextButton')
DCBtn.Size = UDim2.new(0,35,0,16)
DCBtn.Position = UDim2.new(1,-43,0,19)
DCBtn.BackgroundColor3 = COLORS.ButtonBase
DCBtn.Text = 'DC'
DCBtn.TextColor3 = COLORS.ButtonText
DCBtn.Font = Enum.Font.GothamBold
DCBtn.TextSize = 7
DCBtn.AutoButtonColor = false
DCBtn.Parent = KeybindsFrame
local DCCorner = Instance.new('UICorner')
DCCorner.CornerRadius = UDim.new(0,4)
DCCorner.Parent = DCBtn
local DCStroke = Instance.new('UIStroke')
DCStroke.Color = COLORS.Stroke
DCStroke.Thickness = 1
DCStroke.Parent = DCBtn

local Scale08 = Instance.new('TextButton')
Scale08.Size = UDim2.new(0,30,0,14)
Scale08.Position = UDim2.new(0,6,0,56)
Scale08.BackgroundColor3 = COLORS.ButtonBase
Scale08.Text = '0.8x'
Scale08.TextColor3 = COLORS.ButtonText
Scale08.Font = Enum.Font.GothamBold
Scale08.TextSize = 7
Scale08.AutoButtonColor = false
Scale08.Parent = KeybindsFrame
local S08Corner = Instance.new('UICorner')
S08Corner.CornerRadius = UDim.new(0,3)
S08Corner.Parent = Scale08
local S08Stroke = Instance.new('UIStroke')
S08Stroke.Color = COLORS.Stroke
S08Stroke.Thickness = 1
S08Stroke.Parent = Scale08

local Scale1 = Instance.new('TextButton')
Scale1.Size = UDim2.new(0,30,0,14)
Scale1.Position = UDim2.new(0,41,0,56)
Scale1.BackgroundColor3 = COLORS.ButtonSelected
Scale1.Text = '1x'
Scale1.TextColor3 = COLORS.TextPrimary
Scale1.Font = Enum.Font.GothamBold
Scale1.TextSize = 7
Scale1.AutoButtonColor = false
Scale1.Parent = KeybindsFrame
local S1Corner = Instance.new('UICorner')
S1Corner.CornerRadius = UDim.new(0,3)
S1Corner.Parent = Scale1
local S1Stroke = Instance.new('UIStroke')
S1Stroke.Color = COLORS.Stroke
S1Stroke.Thickness = 1
S1Stroke.Parent = Scale1

local Scale12 = Instance.new('TextButton')
Scale12.Size = UDim2.new(0,30,0,14)
Scale12.Position = UDim2.new(0,76,0,56)
Scale12.BackgroundColor3 = COLORS.ButtonBase
Scale12.Text = '1.2x'
Scale12.TextColor3 = COLORS.ButtonText
Scale12.Font = Enum.Font.GothamBold
Scale12.TextSize = 7
Scale12.AutoButtonColor = false
Scale12.Parent = KeybindsFrame
local S12Corner = Instance.new('UICorner')
S12Corner.CornerRadius = UDim.new(0,3)
S12Corner.Parent = Scale12
local S12Stroke = Instance.new('UIStroke')
S12Stroke.Color = COLORS.Stroke
S12Stroke.Thickness = 1
S12Stroke.Parent = Scale12

-- ==================== DRAGGABLE ====================
local function MakeDraggable(f)
    local dragging, dragInput, dragStart, startPos
    f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = f.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    f.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local d = i.Position - dragStart
            f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end
MakeDraggable(MainFrame)

-- ==================== TWEEN HELPER ====================
local function Tween(o, p, t, s, d)
    return TweenService:Create(o, TweenInfo.new(t or 0.3, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
end

-- ==================== HOVER EFFECTS ====================
local function addRowHover(row)
    row.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.2}, 0.15):Play()
    end)
    row.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = COLORS.RowBgTrans}, 0.15):Play()
    end)
end
addRowHover(AntiBatRow)
addRowHover(JumpRow)

local function addButtonHover(btn, ignoreIfSelected)
    btn.MouseEnter:Connect(function()
        if ignoreIfSelected and btn.BackgroundColor3 == COLORS.ButtonSelected then return end
        Tween(btn, {BackgroundColor3 = Color3.fromRGB(75,75,75)}, 0.15):Play()
    end)
    btn.MouseLeave:Connect(function()
        if ignoreIfSelected and btn.BackgroundColor3 == COLORS.ButtonSelected then return end
        Tween(btn, {BackgroundColor3 = COLORS.ButtonBase}, 0.15):Play()
    end)
end
addButtonHover(Kb1)
addButtonHover(Kb2)
addButtonHover(SaveBtn)
addButtonHover(DCBtn)
addButtonHover(Scale08, true)
addButtonHover(Scale1, true)
addButtonHover(Scale12, true)

-- ==================== EXPAND / COLLAPSE ====================
local isExpanded = true
ToggleBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        ToggleBtn.Text = '-'
        ContentContainer.Visible = true
        Tween(MainFrame, {Size = UDim2.new(0,240 * CurrentScale,0,280 * CurrentScale)}, 0.3):Play()
        Tween(ContentContainer, {Size = UDim2.new(1,0,0,230)}, 0.3):Play()
        Tween(ContentContainer, {Position = UDim2.new(0,0,0,50)}, 0.3):Play()
    else
        ToggleBtn.Text = '+'
        Tween(ContentContainer, {Size = UDim2.new(1,0,0,0)}, 0.2):Play()
        Tween(MainFrame, {Size = UDim2.new(0,240 * CurrentScale,0,50 * CurrentScale)}, 0.3):Play()
        task.wait(0.2)
        ContentContainer.Visible = false
    end
end)

-- ==================== TOGGLE BUTTON HOVER ====================
ToggleBtn.MouseEnter:Connect(function()
    Tween(ToggleBtn, {BackgroundColor3 = COLORS.Accent}, 0.15):Play()
    Tween(ToggleBtn, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.15):Play()
end)
ToggleBtn.MouseLeave:Connect(function()
    Tween(ToggleBtn, {BackgroundColor3 = COLORS.ButtonBase}, 0.15):Play()
    Tween(ToggleBtn, {TextColor3 = COLORS.Accent}, 0.15):Play()
end)

-- ==================== STATUS UPDATE ====================
local function updateUI()
    if AntiBatEnabled then
        AntiBatStatus.Text = 'ACTIVE'
        AntiBatStatus.TextColor3 = COLORS.StatusActive
    else
        AntiBatStatus.Text = 'OFF'
        AntiBatStatus.TextColor3 = COLORS.StatusOff
    end
    if InfJumpEnabled then
        JumpStatus.Text = 'ACTIVE'
        JumpStatus.TextColor3 = COLORS.StatusActive
    else
        JumpStatus.Text = 'OFF'
        JumpStatus.TextColor3 = COLORS.StatusOff
    end
end

-- ==================== KEYBIND EDITING ====================
local waitingForKey = false
local currentKeybindTarget = nil

local function resetKeybindButton(btn)
    btn.Text = '...'
    btn.TextColor3 = Color3.fromRGB(150,150,150)
end

local function setKeybindButton(btn, key)
    btn.Text = key.Name
    btn.TextColor3 = COLORS.KeybindText
end

Kb1.MouseButton1Click:Connect(function()
    if waitingForKey then
        if currentKeybindTarget then
            if currentKeybindTarget == 'AntiBat' then
                setKeybindButton(Kb1, Keybinds.AntiBat)
            elseif currentKeybindTarget == 'InfJump' then
                setKeybindButton(Kb2, Keybinds.InfJump)
            end
        end
        waitingForKey = false
        currentKeybindTarget = nil
        return
    end
    waitingForKey = true
    currentKeybindTarget = 'AntiBat'
    resetKeybindButton(Kb1)
end)

Kb2.MouseButton1Click:Connect(function()
    if waitingForKey then
        if currentKeybindTarget then
            if currentKeybindTarget == 'AntiBat' then
                setKeybindButton(Kb1, Keybinds.AntiBat)
            elseif currentKeybindTarget == 'InfJump' then
                setKeybindButton(Kb2, Keybinds.InfJump)
            end
        end
        waitingForKey = false
        currentKeybindTarget = nil
        return
    end
    waitingForKey = true
    currentKeybindTarget = 'InfJump'
    resetKeybindButton(Kb2)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if waitingForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key ~= Enum.KeyCode.Unknown then
            if currentKeybindTarget == 'AntiBat' then
                Keybinds.AntiBat = key
                setKeybindButton(Kb1, key)
            elseif currentKeybindTarget == 'InfJump' then
                Keybinds.InfJump = key
                setKeybindButton(Kb2, key)
            end
            saveKeybinds()
            waitingForKey = false
            currentKeybindTarget = nil
        end
    elseif not waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Keybinds.AntiBat then
                AntiBatEnabled = not AntiBatEnabled
                if AntiBatEnabled then startAntiBat() else stopAntiBat() end
                updateUI()
            elseif input.KeyCode == Keybinds.InfJump then
                InfJumpEnabled = not InfJumpEnabled
                updateUI()
            end
        end
    end
end)

-- ==================== TOGGLE CLICKS ====================
AntiBatClick.MouseButton1Click:Connect(function()
    AntiBatEnabled = not AntiBatEnabled
    if AntiBatEnabled then startAntiBat() else stopAntiBat() end
    updateUI()
    saveKeybinds()
end)

JumpClick.MouseButton1Click:Connect(function()
    InfJumpEnabled = not InfJumpEnabled
    updateUI()
end)

-- ==================== SAVE BUTTON ====================
SaveBtn.MouseButton1Click:Connect(function()
    saveKeybinds()
    Tween(SaveBtn, {BackgroundColor3 = COLORS.Accent}, 0.15):Play()
    Tween(SaveBtn, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.15):Play()
    task.wait(0.3)
    Tween(SaveBtn, {BackgroundColor3 = COLORS.ButtonBase}, 0.15):Play()
    Tween(SaveBtn, {TextColor3 = COLORS.ButtonText}, 0.15):Play()
end)

-- ==================== DC BUTTON ====================
DCBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("discord.gg/AMUDzpSFUd") end)
    StarterGui:SetCore('SendNotification', {
        Title = 'Spider Hub',
        Text = 'Discord link copied!',
        Duration = 3,
    })
end)

-- ==================== SCALE BUTTONS ====================
local function updateScaleButtons(selectedIndex)
    local btns = {Scale08, Scale1, Scale12}
    for i, btn in ipairs(btns) do
        if i == selectedIndex then
            Tween(btn, {BackgroundColor3 = COLORS.ButtonSelected}, 0.2):Play()
            Tween(btn, {TextColor3 = COLORS.TextPrimary}, 0.2):Play()
        else
            Tween(btn, {BackgroundColor3 = COLORS.ButtonBase}, 0.2):Play()
            Tween(btn, {TextColor3 = COLORS.ButtonText}, 0.2):Play()
        end
    end
end

Scale08.MouseButton1Click:Connect(function()
    CurrentScale = 0.8
    updateScaleButtons(1)
    local newSize = UDim2.new(0, 240 * CurrentScale, 0, 280 * CurrentScale)
    Tween(MainFrame, {Size = newSize}, 0.3):Play()
    local pos = MainFrame.Position
    local newX = 0.5 - (240 * CurrentScale / 2) / 1920
    Tween(MainFrame, {Position = UDim2.new(newX, 0, pos.Y.Scale, pos.Y.Offset)}, 0.3):Play()
end)

Scale1.MouseButton1Click:Connect(function()
    CurrentScale = 1
    updateScaleButtons(2)
    local newSize = UDim2.new(0, 240 * CurrentScale, 0, 280 * CurrentScale)
    Tween(MainFrame, {Size = newSize}, 0.3):Play()
    local pos = MainFrame.Position
    local newX = 0.5 - (240 * CurrentScale / 2) / 1920
    Tween(MainFrame, {Position = UDim2.new(newX, 0, pos.Y.Scale, pos.Y.Offset)}, 0.3):Play()
end)

Scale12.MouseButton1Click:Connect(function()
    CurrentScale = 1.2
    updateScaleButtons(3)
    local newSize = UDim2.new(0, 240 * CurrentScale, 0, 280 * CurrentScale)
    Tween(MainFrame, {Size = newSize}, 0.3):Play()
    local pos = MainFrame.Position
    local newX = 0.5 - (240 * CurrentScale / 2) / 1920
    Tween(MainFrame, {Position = UDim2.new(newX, 0, pos.Y.Scale, pos.Y.Offset)}, 0.3):Play()
end)

-- ==================== INITIALIZATION ====================
startAntiRagdoll()
setupInfJump()
updateUI()
updateScaleButtons(2)  -- 1x selected
setKeybindButton(Kb1, Keybinds.AntiBat)
setKeybindButton(Kb2, Keybinds.InfJump)

print("Best anti bat (Spider Hub Anti Bat) Loaded!")