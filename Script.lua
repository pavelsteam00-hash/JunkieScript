local task_wait = task.wait
local task_spawn = task.spawn
local get_genv = getgenv
local math_random = math.random
local tick_count = tick
local pairs_iter = pairs
local table_insert = table.insert

local function Notify(title, text)
    task_spawn(function()
        task_wait(1)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = 5
            })
        end)
    end)
end

local env = get_genv()
local script_id = math_random(100000, 999999)

if env.ProjectSilver_Cleanup then pcall(env.ProjectSilver_Cleanup) end
Notify("Project SILVER", "Tools loaded")

local cloneref = cloneref or function(o) return o end
local ORIGINAL_HEAD_SIZE = Vector3.new(1, 1, 1)

local MaterialViewEnabled = false
local MaterialViewList = { Enum.Material.Cobblestone, Enum.Material.WoodPlanks, Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.Concrete, Enum.Material.Brick }
local OriginalMaterialProps = {}
local MaterialViewAlpha = 0.5
local MaterialViewKey = Enum.KeyCode.X

local WorldSettings = {
    BrightMode = false, BrightLevel = 1,
    SkyColorMode = false, SkyColor = Color3.fromRGB(120, 140, 160),
    SkyBrightness = 0.3, 
    OriginalAmbient = game:GetService("Lighting").Ambient,
    OriginalOutdoor = game:GetService("Lighting").OutdoorAmbient,
    ShowStone = false, ShowIron = false, ShowNitrate = false
}

local CrosshairSettings = {
    Active = false, Rotate = false, RotateSpeed = 5, Length = 10,
    Space = 5, Color = Color3.fromRGB(255, 255, 255),
    Width = 1.5, Angle = 0
}

local AimAssistSettings = {
    Active = false, ShowCircle = false, FillCircle = false, CircleFillAlpha = 0.2,
    CircleSize = 50, AssistSpeed = 6, TargetArea = "Head", TriggerButton = Enum.UserInputType.MouseButton2,
    Color = Color3.fromRGB(255, 255, 255), VisibilityCheck = false,
    ExpandTargetArea = false, AreaSize = 1
}

env.ProjectSilver_Session = script_id

local InputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local Lighting = cloneref(game:GetService("Lighting"))
local workspace = cloneref(game:GetService("Workspace"))
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HitMarkerSettings = {
    Active = true, Color = Color3.fromRGB(255, 255, 255),
    Size = 8, Width = 2.5, Duration = 1.5, LastHitTime = 0
}

local CameraSettings = {
    CustomViewActive = false, CustomViewValue = 70,
    OriginalView = workspace.CurrentCamera.FieldOfView, CurrentView = workspace.CurrentCamera.FieldOfView
}

local ZoomSettings = {
    ZoomActive = false, ZoomButton = Enum.KeyCode.Z, ZoomLevel = 30,
    ZoomHeld = false, ZoomEngaged = false, OriginalZoom = workspace.CurrentCamera.FieldOfView
}

env.SleeperFilter = false 
env.ObjectDisplayActive = false
env.ObjectDisplayDist = 1000
env.ObjectDisplayColor = Color3.fromRGB(255, 255, 255)

local Interface = {
    Visible = false, Moving = false, AccentColor = Color3.fromRGB(160, 170, 255),
    CurrentSection = "COMBAT", CurrentSubSection = "AimAssist",
    ScrollPositions = {}, UIComponents = {}, MenuComponents = {}, 
    Sections = {}, SubSections = {}, EventConnections = {},
    ColorPalette = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 200), 
        Color3.fromRGB(255, 60, 100), Color3.fromRGB(180, 100, 255), 
        Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 255, 0)
    }
}

env.ProjectSilver_Cleanup = function()
    env.ProjectSilver_Session = nil
    for _, conn in pairs_iter(Interface.EventConnections) do pcall(function() conn:Disconnect() end) end
    for _, el in pairs_iter(Interface.UIComponents) do pcall(function() el:Remove() end) end
end

local function CreateDrawingObject(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs_iter(props) do obj[k] = v end
    table_insert(Interface.UIComponents, obj)
    return obj
end

local function ToggleMaterialView(enable)
    MaterialViewEnabled = enable
    if enable then
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                local isTargetMaterial = false
                for _, mat in ipairs(MaterialViewList) do
                    if part.Material == mat then isTargetMaterial = true break end
                end
                if isTargetMaterial then
                    if OriginalMaterialProps[part] == nil then OriginalMaterialProps[part] = part.Transparency end
                    part.Transparency = MaterialViewAlpha
                end
            end
        end
    else
        for part, trans in pairs(OriginalMaterialProps) do
            if part and part.Parent then part.Transparency = trans end
        end
        OriginalMaterialProps = {}
    end
end

local MenuBorder, Background, MainPanel, LeftPanel, RightPanel, TopBar, SubBar, AccentBar, MainTitle, SubTitle

local function CreateSection(name)
    local btn = CreateDrawingObject("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(150, 150, 150), Visible = false, ZIndex = 104})
    Interface.Sections[name] = btn
end

local function AddToggle(section, subsection, name, callback, default)
    local id = section .. subsection
    if not Interface.MenuComponents[id] then Interface.MenuComponents[id] = {} Interface.ScrollPositions[id] = 0 end
    local box = CreateDrawingObject("Square", {Size = Vector2.new(12, 12), Color = Color3.fromRGB(30, 30, 40), Filled = true, Visible = false, ZIndex = 104})
    local boxOut = CreateDrawingObject("Square", {Size = Vector2.new(12, 12), Color = Color3.fromRGB(60, 60, 80), Filled = false, Thickness = 1, Visible = false, ZIndex = 105})
    local lbl = CreateDrawingObject("Text", {Text = name, Size = 14, Font = 2, Color = Color3.fromRGB(220, 220, 230), Visible = false, ZIndex = 104})
    local data = {type = "Toggle", bg = box, out = boxOut, lbl = lbl, cb = callback, state = default or false, height = 28}
    table_insert(Interface.MenuComponents[id], data)
    return data
end

local function AddSlider(section, subsection, name, min, max, default, callback)
    local id = section .. subsection
    if not Interface.MenuComponents[id] then Interface.MenuComponents[id] = {} Interface.ScrollPositions[id] = 0 end
    local lbl = CreateDrawingObject("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(180, 180, 190), Visible = false, ZIndex = 104})
    local valLbl = CreateDrawingObject("Text", {Size = 13, Font = 2, Color = Interface.AccentColor, Visible = false, ZIndex = 104})
    local sBg = CreateDrawingObject("Square", {Size = Vector2.new(220, 3), Color = Color3.fromRGB(40, 40, 50), Filled = true, Visible = false, ZIndex = 104})
    local sFill = CreateDrawingObject("Square", {Size = Vector2.new(0, 3), Color = Interface.AccentColor, Filled = true, Visible = false, ZIndex = 105})
    table_insert(Interface.MenuComponents[id], {type = "Slider", lbl = lbl, valLbl = valLbl, sBg = sBg, sFill = sFill, min = min, max = max, val = default, cb = callback, height = 45})
end

local function AddColor(section, subsection, name, colorCallback, defaultColor)
    local id = section .. subsection
    if not Interface.MenuComponents[id] then Interface.MenuComponents[id] = {} Interface.ScrollPositions[id] = 0 end
    local lbl = CreateDrawingObject("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(140, 140, 150), Visible = false, ZIndex = 104})
    local picker = CreateDrawingObject("Square", {Size = Vector2.new(22, 10), Color = defaultColor, Filled = true, Visible = false, ZIndex = 105})
    table_insert(Interface.MenuComponents[id], {type = "Color", lbl = lbl, picker = picker, cb = colorCallback, height = 28})
end

local function AddKeybind(section, subsection, name, default, callback)
    local id = section .. subsection
    if not Interface.MenuComponents[id] then Interface.MenuComponents[id] = {} Interface.ScrollPositions[id] = 0 end
    local lbl = CreateDrawingObject("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(180, 180, 190), Visible = false, ZIndex = 104})
    local btn = CreateDrawingObject("Text", {Text = "[" .. default.Name .. "]", Size = 13, Font = 2, Color = Interface.AccentColor, Visible = false, ZIndex = 104})
    table_insert(Interface.MenuComponents[id], {type = "Bind", lbl = lbl, btn = btn, key = default, cb = callback, height = 28, binding = false})
end

local menuPosition = Vector2.new(150, 150)
local menuDimensions = Vector2.new(540, 420)
local dragStartOffset = Vector2.new(0, 0)

task.delay(1, function()
    MenuBorder = CreateDrawingObject("Square", {Size = menuDimensions + Vector2.new(1, 1), Color = Interface.AccentColor, Filled = false, Thickness = 1, Transparency = 0.6, Visible = true, ZIndex = 110})
    Background = CreateDrawingObject("Square", {Size = menuDimensions, Color = Color3.fromRGB(5, 5, 7), Filled = true, Visible = true, ZIndex = 99})
    MainPanel = CreateDrawingObject("Square", {Size = menuDimensions, Color = Color3.fromRGB(15, 15, 20), Filled = true, Visible = true, ZIndex = 100})
    LeftPanel = CreateDrawingObject("Square", {Size = Vector2.new(255, 305), Color = Color3.fromRGB(22, 22, 28), Filled = true, Visible = true, ZIndex = 101})
    RightPanel = CreateDrawingObject("Square", {Size = Vector2.new(255, 305), Color = Color3.fromRGB(22, 22, 28), Filled = true, Visible = true, ZIndex = 101})
    TopBar = CreateDrawingObject("Square", {Size = Vector2.new(menuDimensions.X, 35), Color = Color3.fromRGB(20, 20, 28), Filled = true, Visible = true, ZIndex = 101})
    SubBar = CreateDrawingObject("Square", {Size = Vector2.new(menuDimensions.X, 30), Color = Color3.fromRGB(18, 18, 24), Filled = true, Visible = true, ZIndex = 101})
    AccentBar = CreateDrawingObject("Square", {Size = Vector2.new(menuDimensions.X, 1), Color = Interface.AccentColor, Filled = true, Transparency = 0.6, Visible = true, ZIndex = 102})
    MainTitle = CreateDrawingObject("Text", {Text = "PROJECT", Size = 20, Font = 3, Color = Color3.new(0.9,0.9,0.9), Visible = true, ZIndex = 103})
    SubTitle = CreateDrawingObject("Text", {Text = "SILVER", Size = 20, Font = 3, Color = Interface.AccentColor, Visible = true, ZIndex = 103})

    CreateSection("COMBAT")
    CreateSection("VISUAL")
    CreateSection("SETTINGS")

    AddToggle("COMBAT", "AimAssist", "Aim Assist", function(v) AimAssistSettings.Active = v end)
    AddToggle("COMBAT", "AimAssist", "Show FOV", function(v) AimAssistSettings.ShowCircle = v end)
    AddToggle("COMBAT", "AimAssist", "Filled FOV", function(v) AimAssistSettings.FillCircle = v end)
    AddSlider("COMBAT", "AimAssist", "FOV Fill Alpha", 0, 1, 0.2, function(v) AimAssistSettings.CircleFillAlpha = v end)
    AddToggle("COMBAT", "AimAssist", "Visibility Check", function(v) AimAssistSettings.VisibilityCheck = v end)
    AddToggle("COMBAT", "AimAssist", "Target Body", function(v) AimAssistSettings.TargetArea = v and "LowerTorso" or "Head" end)
    AddSlider("COMBAT", "AimAssist", "FOV Size", 30, 200, 50, function(v) AimAssistSettings.CircleSize = v end)
    AddSlider("COMBAT", "AimAssist", "Smoothness", 1, 10, 5, function(v) AimAssistSettings.AssistSpeed = v end)
    AddToggle("COMBAT", "AimAssist", "HitBox", function(v) AimAssistSettings.ExpandTargetArea = v end)
    AddSlider("COMBAT", "AimAssist", "HitBox Size", 1, 4, 1, function(v) AimAssistSettings.AreaSize = v end)
    AddColor("COMBAT", "AimAssist", "FOV Color", function(c) AimAssistSettings.Color = c end, AimAssistSettings.Color)

    AddToggle("COMBAT", "Visual", "Hit Marker", function(v) HitMarkerSettings.Active = v end, true)
    AddSlider("COMBAT", "Visual", "Hit Marker Size", 4, 20, 8, function(v) HitMarkerSettings.Size = v end)
    AddColor("COMBAT", "Visual", "Hit Marker Color", function(c) HitMarkerSettings.Color = c end, HitMarkerSettings.Color)

    AddToggle("VISUAL", "Objects", "Player ESP", function(v) env.ObjectDisplayActive = v end)
    AddToggle("VISUAL", "Objects", "Filter Sleepers", function(v) env.SleeperFilter = v end)
    AddSlider("VISUAL", "Objects", "Max View Distance", 100, 1000, 1000, function(v) env.ObjectDisplayDist = v end)
    AddColor("VISUAL", "Objects", "ESP Color", function(c) env.ObjectDisplayColor = c end, env.ObjectDisplayColor)
    AddToggle("VISUAL", "Objects", "Stone ESP", function(v) WorldSettings.ShowStone = v end)
    AddToggle("VISUAL", "Objects", "Iron ESP", function(v) WorldSettings.ShowIron = v end)
    AddToggle("VISUAL", "Objects", "Nitrate ESP", function(v) WorldSettings.ShowNitrate = v end)

    AddToggle("VISUAL", "Objects", "Camera FOV", function(v) 
        CameraSettings.CustomViewActive = v 
        if not v and not ZoomSettings.ZoomHeld then Camera.FieldOfView = CameraSettings.OriginalView end
    end)
    AddSlider("VISUAL", "Objects", "FOV Value", 70, 120, 70, function(v) CameraSettings.CustomViewValue = v end)

    AddToggle("VISUAL", "Objects", "Zoom Mode", function(v) 
        ZoomSettings.ZoomActive = v 
        if not v then
            ZoomSettings.ZoomHeld = false
            if not CameraSettings.CustomViewActive then Camera.FieldOfView = CameraSettings.OriginalView end
        end
    end)
    AddSlider("VISUAL", "Objects", "Zoom Level", 30, 70, 30, function(v) ZoomSettings.ZoomLevel = v end)
    AddKeybind("VISUAL", "Objects", "Zoom Button", Enum.KeyCode.Z, function(k) ZoomSettings.ZoomButton = k end)

    AddToggle("VISUAL", "World", "Crosshair", function(v) CrosshairSettings.Active = v end)
    AddToggle("VISUAL", "World", "Rotate Crosshair", function(v) CrosshairSettings.Rotate = v end)
    AddSlider("VISUAL", "World", "Rotation Speed", 1, 5, 1, function(v) CrosshairSettings.RotateSpeed = v end)
    AddSlider("VISUAL", "World", "Crosshair Length", 5, 10, 5, function(v) CrosshairSettings.Length = v end)
    AddSlider("VISUAL", "World", "Crosshair Space", 0, 5, 1, function(v) CrosshairSettings.Space = v end)
    AddColor("VISUAL", "World", "Crosshair Color", function(c) CrosshairSettings.Color = c end, CrosshairSettings.Color)
    AddToggle("VISUAL", "World", "FullBright Mode", function(v) WorldSettings.BrightMode = v end)
    AddSlider("VISUAL", "World", "Brightness Level", 1, 10, 1, function(v) WorldSettings.BrightLevel = v end)
    AddToggle("VISUAL", "World", "Sky Color Mode", function(v) WorldSettings.SkyColorMode = v end)
    AddSlider("VISUAL", "World", "Sky Brightness", 0, 1, 0.3, function(v) WorldSettings.SkyBrightness = v end)
    AddColor("VISUAL", "World", "Sky Color", function(c) WorldSettings.SkyColor = c end, WorldSettings.SkyColor)
    
    local materialToggle = AddToggle("VISUAL", "World", "Material View", function(v) ToggleMaterialView(v) end)
    AddKeybind("VISUAL", "World", "Material View Button", Enum.KeyCode.X, function(k) MaterialViewKey = k end)

    AddColor("SETTINGS", "Main", "Interface Accent", function(c) Interface.AccentColor = c end, Interface.AccentColor)
    Interface.Visible = true
end)

local CircleDisplay = CreateDrawingObject("Circle", {Thickness = 2, Color = AimAssistSettings.Color, Transparency = 1, Filled = false, Visible = false, NumSides = 64, ZIndex = 999})
local HitMarkerLines = {CreateDrawingObject("Line",{ZIndex = 999}), CreateDrawingObject("Line",{ZIndex = 999}), CreateDrawingObject("Line",{ZIndex = 999}), CreateDrawingObject("Line",{ZIndex = 999})}
local CrosshairLines = {CreateDrawingObject("Line",{ZIndex = 1000}), CreateDrawingObject("Line",{ZIndex = 1000}), CreateDrawingObject("Line",{ZIndex = 1000}), CreateDrawingObject("Line",{ZIndex = 1000})}

local function IdentifyObjectType(model)
    local mesh = model:FindFirstChildOfClass("MeshPart")
    if mesh and mesh.MeshId == "rbxassetid://12939036056" then
        if #model:GetChildren() == 1 then return "Stone", mesh, Color3.fromRGB(150, 150, 150) end
        for _, part in pairs_iter(model:GetChildren()) do
            if part:IsA("BasePart") then
                if part.Color == Color3.fromRGB(248, 248, 248) then return "Nitrate", part, Color3.fromRGB(255, 255, 255) end
                if part.Color == Color3.fromRGB(199, 172, 120) then return "Iron", part, Color3.fromRGB(255, 130, 50) end
            end
        end
    end
    return nil
end

local function CheckWallVisibility(part)
    if not AimAssistSettings.VisibilityCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    local rayResult = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
    return not rayResult
end

local function IsSleeper(model)
    if not env.SleeperFilter then return false end
    local lowerPart = model:FindFirstChild("LowerTorso")
    if lowerPart then
        local rootJoint = lowerPart:FindFirstChild("RootRig")
        if rootJoint and typeof(rootJoint.CurrentAngle) == "number" and rootJoint.CurrentAngle ~= 0 then return true end
    end
    return false
end

table_insert(Interface.EventConnections, workspace.ChildAdded:Connect(function(child)
    if HitMarkerSettings.Active and (child.Name == "PlayerHit2" or child.Name == "Dink" or child.Name == "PlayerHitHeadshot") then 
        HitMarkerSettings.LastHitTime = tick_count()
    end
end))

table_insert(Interface.EventConnections, RunService.Heartbeat:Connect(function()
    if env.ProjectSilver_Session ~= script_id then return end
    if WorldSettings.BrightMode then
        local brightnessValue = WorldSettings.BrightLevel / 5
        Lighting.Ambient = Color3.new(brightnessValue, brightnessValue, brightnessValue)
        Lighting.OutdoorAmbient = Color3.new(brightnessValue, brightnessValue, brightnessValue)
        Lighting.GlobalShadows = false
        Lighting.ClockTime = 12
    elseif WorldSettings.SkyColorMode then
        local softColor = WorldSettings.OriginalAmbient:Lerp(WorldSettings.SkyColor, WorldSettings.SkyBrightness)
        Lighting.Ambient = softColor
        Lighting.OutdoorAmbient = softColor
    end
end))

local ESPStorage = {}
local ResourceStorage = {}
local CachedPlayersList = {}
local CachedResourcesList = {}

task_spawn(function()
    while task_wait(0.5) do
        if env.ProjectSilver_Session ~= script_id then break end
        local playerList, resourceList = {}, {}
        for _, obj in pairs_iter(workspace:GetChildren()) do
            if obj:IsA("Model") then
                if (obj:FindFirstChild("LowerTorso") or obj:FindFirstChild("HumanoidRootPart")) and obj.Name ~= LocalPlayer.Name then
                    table_insert(playerList, obj)
                else
                    local objType, objPart, objColor = IdentifyObjectType(obj)
                    if objType then table_insert(resourceList, {model = obj, part = objPart, type = objType, color = objColor}) end
                end
            end
        end
        CachedPlayersList, CachedResourcesList = playerList, resourceList
    end
end)

task_spawn(function()
    while task_wait(0.2) do
        if env.ProjectSilver_Session ~= script_id then break end
        for i = 1, #CachedPlayersList do
            local obj = CachedPlayersList[i]
            local headPart = obj and obj:FindFirstChild("Head")
            if headPart then
                if AimAssistSettings.ExpandTargetArea then
                    local sizeModifier = AimAssistSettings.AreaSize + (math_random(-10, 10) / 100) 
                    headPart.Size = Vector3.new(sizeModifier, sizeModifier, sizeModifier)
                    headPart.Transparency = 0.4 headPart.CanCollide = false
                elseif headPart.Size ~= ORIGINAL_HEAD_SIZE then
                    headPart.Size = ORIGINAL_HEAD_SIZE headPart.Transparency = 0
                end
            end
        end
    end
end)

table_insert(Interface.EventConnections, RunService.RenderStepped:Connect(function()
    if env.ProjectSilver_Session ~= script_id then 
        for _, v in pairs_iter(Interface.UIComponents) do pcall(function() v:Remove() end) end 
        return 
    end
    
    local mousePosition = InputService:GetMouseLocation()
    if Interface.Moving and Interface.Visible then menuPosition = mousePosition + dragStartOffset end

    local isInterfaceVisible = Interface.Visible
    if MenuBorder then
        MenuBorder.Position, MenuBorder.Color, MenuBorder.Visible = menuPosition, Interface.AccentColor, isInterfaceVisible
        Background.Position, Background.Visible = menuPosition, isInterfaceVisible
        MainPanel.Position, MainPanel.Visible = menuPosition, isInterfaceVisible
        TopBar.Position, TopBar.Visible = menuPosition, isInterfaceVisible
        SubBar.Position, SubBar.Visible = menuPosition + Vector2.new(0, 35), isInterfaceVisible
        AccentBar.Position, AccentBar.Color, AccentBar.Visible = menuPosition + Vector2.new(0, 65), Interface.AccentColor, isInterfaceVisible
        MainTitle.Position, MainTitle.Visible = menuPosition + Vector2.new(15, 8), isInterfaceVisible
        SubTitle.Position, SubTitle.Color, SubTitle.Visible = MainTitle.Position + Vector2.new(MainTitle.TextBounds.X + 5, 0), Interface.AccentColor, isInterfaceVisible
        LeftPanel.Position, LeftPanel.Visible = menuPosition + Vector2.new(10, 100), isInterfaceVisible
        RightPanel.Position, RightPanel.Visible = menuPosition + Vector2.new(275, 100), isInterfaceVisible
    end
    
    local sectionOrder = {"COMBAT", "VISUAL", "SETTINGS"}
    for i, name in ipairs(sectionOrder) do
        local btn = Interface.Sections[name]
        if btn then
            btn.Visible = isInterfaceVisible
            btn.Position = menuPosition + Vector2.new(20 + (i-1) * 100, 43)
            btn.Color = Interface.CurrentSection == name and Interface.AccentColor or Color3.fromRGB(130, 130, 140)
        end
    end

    local subsectionList = (Interface.CurrentSection == "COMBAT" and {"AimAssist", "Visual"}) or (Interface.CurrentSection == "VISUAL" and {"Objects", "World"}) or {"Main"}
    for _, s in pairs_iter(Interface.SubSections) do s.Visible = false end
    for i, name in ipairs(subsectionList) do
        if not Interface.SubSections[name] then Interface.SubSections[name] = CreateDrawingObject("Text", {Size = 14, Font = 2, ZIndex = 104}) end
        local sbtn = Interface.SubSections[name]
        sbtn.Visible, sbtn.Text = isInterfaceVisible, name
        sbtn.Position = menuPosition + Vector2.new(20 + (i-1)*120, 73)
        sbtn.Color = Interface.CurrentSubSection == name and Interface.AccentColor or Color3.fromRGB(80, 80, 90)
    end

    for id, elements in pairs_iter(Interface.MenuComponents) do
        local isCurrentSection = (id == Interface.CurrentSection .. Interface.CurrentSubSection)
        if isCurrentSection then
            local middleIndex = math.ceil(#elements / 2)
            for i, el in ipairs(elements) do
                local column = (i <= middleIndex) and 0 or 1
                local indexInColumn = (i <= middleIndex) and (i - 1) or (i - middleIndex - 1)
                local startX = (column == 0) and 25 or 290
                local offsetY = 115 + (indexInColumn * 35) + (Interface.ScrollPositions[id] or 0)
                local showElement = isInterfaceVisible and (offsetY >= 105 and offsetY <= 380)
                
                if el.type == "Toggle" then
                    el.bg.Position, el.out.Position, el.lbl.Position = menuPosition+Vector2.new(startX, offsetY+3), menuPosition+Vector2.new(startX, offsetY+3), menuPosition+Vector2.new(startX+22, offsetY)
                    el.bg.Color = el.state and Interface.AccentColor or Color3.fromRGB(30, 30, 40)
                    el.bg.Visible, el.out.Visible, el.lbl.Visible = showElement, showElement, showElement
                elseif el.type == "Slider" then
                    el.lbl.Position, el.sBg.Position, el.sFill.Position = menuPosition+Vector2.new(startX, offsetY-5), menuPosition+Vector2.new(startX, offsetY+15), menuPosition+Vector2.new(startX, offsetY+15)
                    if showElement and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        local mousePos = InputService:GetMouseLocation()
                        if mousePos.X > el.sBg.Position.X and mousePos.X < el.sBg.Position.X + 220 and mousePos.Y > el.sBg.Position.Y - 8 and mousePos.Y < el.sBg.Position.Y + 12 then
                            el.val = el.min + (el.max-el.min) * math.clamp((mousePos.X-el.sBg.Position.X)/220, 0, 1) el.cb(el.val)
                        end
                    end
                    el.sFill.Size, el.sFill.Color = Vector2.new(220*((el.val-el.min)/(el.max-el.min)), 3), Interface.AccentColor
                    el.valLbl.Text, el.valLbl.Position = string.format("%.1f", el.val), menuPosition+Vector2.new(startX+220-el.valLbl.TextBounds.X, offsetY-5)
                    el.valLbl.Visible, el.lbl.Visible, el.sBg.Visible, el.sFill.Visible = showElement, showElement, showElement, showElement
                elseif el.type == "Color" then
                    el.lbl.Position, el.picker.Position = menuPosition+Vector2.new(startX, offsetY), menuPosition+Vector2.new(startX+200, offsetY+3)
                    el.lbl.Visible, el.picker.Visible = showElement, showElement
                elseif el.type == "Bind" then
                    el.lbl.Position, el.btn.Position = menuPosition+Vector2.new(startX, offsetY), menuPosition+Vector2.new(startX+200, offsetY)
                    el.btn.Text = el.binding and "[...]" or "[" .. el.key.Name .. "]"
                    el.lbl.Visible, el.btn.Visible = showElement, showElement
                end
            end
        else
            for _, el in pairs_iter(elements) do
                el.lbl.Visible = false
                if el.bg then el.bg.Visible = false el.out.Visible = false end
                if el.sBg then el.sBg.Visible = false el.sFill.Visible = false el.valLbl.Visible = false end
                if el.picker then el.picker.Visible = false end
                if el.btn then el.btn.Visible = false end
            end
        end
    end

    CircleDisplay.Visible = AimAssistSettings.Active and AimAssistSettings.ShowCircle
    CircleDisplay.Radius = AimAssistSettings.CircleSize
    CircleDisplay.Position = mousePosition
    CircleDisplay.Color = AimAssistSettings.Color
    CircleDisplay.Filled = AimAssistSettings.FillCircle
    CircleDisplay.Transparency = AimAssistSettings.FillCircle and (1 - AimAssistSettings.CircleFillAlpha) or 1
    
    if CrosshairSettings.Active then
        if CrosshairSettings.Rotate then CrosshairSettings.Angle = CrosshairSettings.Angle + (CrosshairSettings.RotateSpeed / 100) end
        for i, line in ipairs(CrosshairLines) do
            local angleValue = CrosshairSettings.Angle + (i-1) * (math.pi/2)
            line.Visible, line.Color = true, CrosshairSettings.Color
            line.From = mousePosition + Vector2.new(math.cos(angleValue) * CrosshairSettings.Space, math.sin(angleValue) * CrosshairSettings.Space)
            line.To = mousePosition + Vector2.new(math.cos(angleValue) * (CrosshairSettings.Space + CrosshairSettings.Length), math.sin(angleValue) * (CrosshairSettings.Space + CrosshairSettings.Length))
        end
    else for _,l in pairs_iter(CrosshairLines) do l.Visible = false end end

    local timeSinceHit = tick_count() - HitMarkerSettings.LastHitTime
    if timeSinceHit < HitMarkerSettings.Duration then
        local alphaValue = math.clamp(1 - (timeSinceHit / HitMarkerSettings.Duration), 0, 1)
        local sizeVal, gapVal = HitMarkerSettings.Size, 4
        local lineData = {
            {Vector2.new(-sizeVal, -sizeVal), Vector2.new(-gapVal, -gapVal)}, 
            {Vector2.new(sizeVal, -sizeVal), Vector2.new(gapVal, -gapVal)}, 
            {Vector2.new(-sizeVal, sizeVal), Vector2.new(-gapVal, gapVal)}, 
            {Vector2.new(sizeVal, sizeVal), Vector2.new(gapVal, gapVal)}
        }
        for i = 1, 4 do
            local line = HitMarkerLines[i]
            line.Visible, line.Transparency, line.Color, line.Thickness = true, alphaValue, HitMarkerSettings.Color, HitMarkerSettings.Width
            line.From = mousePosition + lineData[i][1]
            line.To = mousePosition + lineData[i][2]
        end
    else for _,l in pairs_iter(HitMarkerLines) do l.Visible = false end end

    for obj, drawings in pairs_iter(ESPStorage) do if not obj or not obj.Parent then for _, d in pairs_iter(drawings) do d.Visible = false d:Remove() end ESPStorage[obj] = nil end end
    for obj, drawings in pairs_iter(ResourceStorage) do if not obj or not obj.Parent then for _, d in pairs_iter(drawings) do d.Visible = false d:Remove() end ResourceStorage[obj] = nil end end

    for i = 1, #CachedPlayersList do
        local obj = CachedPlayersList[i]
        local rootPart = obj and obj:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen and env.ObjectDisplayActive and distance <= env.ObjectDisplayDist and not IsSleeper(obj) then
                if not ESPStorage[obj] then ESPStorage[obj] = {Box = CreateDrawingObject("Square", {Thickness = 1, Visible = false, ZIndex = 1}), Name = CreateDrawingObject("Text", {Size = 13, Center = true, Visible = false, ZIndex = 1}), Dist = CreateDrawingObject("Text", {Size = 11, Center = true, Visible = false, ZIndex = 1})} end
                local d = ESPStorage[obj]
                local boxSizeX, boxSizeY = 2200/screenPos.Z, 3500/screenPos.Z
                d.Box.Visible, d.Box.Size, d.Box.Position, d.Box.Color = true, Vector2.new(boxSizeX, boxSizeY), Vector2.new(screenPos.X - boxSizeX/2, screenPos.Y - boxSizeY/2), env.ObjectDisplayColor
                d.Name.Visible, d.Name.Text, d.Name.Position, d.Name.Color = true, obj.Name, Vector2.new(screenPos.X, screenPos.Y - boxSizeY/2 - 16), env.ObjectDisplayColor
                d.Dist.Visible, d.Dist.Text, d.Dist.Position, d.Dist.Color = true, math.floor(distance).."m", Vector2.new(screenPos.X, screenPos.Y + boxSizeY/2 + 2), env.ObjectDisplayColor
            elseif ESPStorage[obj] then ESPStorage[obj].Box.Visible = false ESPStorage[obj].Name.Visible = false ESPStorage[obj].Dist.Visible = false end
        end
    end

    for i = 1, #CachedResourcesList do
        local resource = CachedResourcesList[i]
        local displayEnabled = (resource.type == "Stone" and WorldSettings.ShowStone) or (resource.type == "Iron" and WorldSettings.ShowIron) or (resource.type == "Nitrate" and WorldSettings.ShowNitrate)
        if displayEnabled and resource.model and resource.model.Parent then
            local screenPos, onScreen = Camera:WorldToViewportPoint(resource.part.Position)
            local distance = (Camera.CFrame.Position - resource.part.Position).Magnitude
            if onScreen and distance < 1500 then
                if not ResourceStorage[resource.model] then ResourceStorage[resource.model] = {Name = CreateDrawingObject("Text", {Size = 13, Center = true, Visible = false, ZIndex = 0})} end
                local d = ResourceStorage[resource.model]
                d.Name.Visible, d.Name.Text, d.Name.Position, d.Name.Color = true, resource.type .. " [" .. math.floor(distance) .. "m]", Vector2.new(screenPos.X, screenPos.Y), resource.color
            elseif ResourceStorage[resource.model] then ResourceStorage[resource.model].Name.Visible = false end
        elseif ResourceStorage[resource.model] then ResourceStorage[resource.model].Name.Visible = false end
    end

    if AimAssistSettings.Active and InputService:IsMouseButtonPressed(AimAssistSettings.TriggerButton) then
        local targetPosition, closestDistance = nil, AimAssistSettings.CircleSize
        for i = 1, #CachedPlayersList do
            local obj = CachedPlayersList[i]
            local targetPart = obj and obj.Parent and obj:FindFirstChild(AimAssistSettings.TargetArea)
            if targetPart and CheckWallVisibility(targetPart) and not IsSleeper(obj) then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distanceFromMouse = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude
                    if distanceFromMouse < closestDistance then closestDistance = distanceFromMouse targetPosition = screenPoint end
                end
            end
        end
        if targetPosition then
            local distanceFactor = math.clamp(closestDistance / AimAssistSettings.CircleSize, 0.1, 1)
            local adaptiveSmoothness = AimAssistSettings.AssistSpeed * (1 + (1 - distanceFactor))
            mousemoverel((targetPosition.X - mousePosition.X) / adaptiveSmoothness, (targetPosition.Y - mousePosition.Y) / adaptiveSmoothness) 
        end
    end
end))

table_insert(Interface.EventConnections, RunService.RenderStepped:Connect(function()
    if env.ProjectSilver_Session ~= script_id then return end
    if ZoomSettings.ZoomActive and ZoomSettings.ZoomHeld then
        if Camera.FieldOfView ~= ZoomSettings.ZoomLevel then Camera.FieldOfView = ZoomSettings.ZoomLevel end
    elseif CameraSettings.CustomViewActive then
        if Camera.FieldOfView ~= CameraSettings.CustomViewValue then Camera.FieldOfView = CameraSettings.CustomViewValue end
    end
end))

table_insert(Interface.EventConnections, InputService.InputBegan:Connect(function(input)
    if not InputService:GetFocusedTextBox() then
        if input.KeyCode == MaterialViewKey then
            ToggleMaterialView(not MaterialViewEnabled)
            local id = "VISUALWorld"
            if Interface.MenuComponents[id] then
                for _, el in pairs_iter(Interface.MenuComponents[id]) do
                    if el.lbl.Text == "Material View" then el.state = MaterialViewEnabled end
                end
            end
        end

        if input.KeyCode == ZoomSettings.ZoomButton and ZoomSettings.ZoomActive then
            ZoomSettings.ZoomHeld = true
            if CameraSettings.CustomViewActive then CameraSettings.CurrentView = Camera.FieldOfView end
        end
    end

    if not Interface.Visible then if input.KeyCode == Enum.KeyCode.RightShift then Interface.Visible = true end return end
    local mousePos = InputService:GetMouseLocation()
    
    local id = Interface.CurrentSection .. Interface.CurrentSubSection
    if Interface.MenuComponents[id] then
        for _, el in pairs_iter(Interface.MenuComponents[id]) do
            if el.type == "Bind" and el.binding then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    el.key = input.KeyCode
                    el.binding = false
                    el.cb(input.KeyCode)
                    return
                end
            end
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if mousePos.X > menuPosition.X and mousePos.X < menuPosition.X + menuDimensions.X and mousePos.Y > menuPosition.Y and mousePos.Y < menuPosition.Y + 35 then Interface.Moving = true dragStartOffset = menuPosition - mousePos return end
        for name, btn in pairs_iter(Interface.Sections) do if mousePos.X > btn.Position.X - 5 and mousePos.X < btn.Position.X + btn.TextBounds.X + 5 and mousePos.Y > btn.Position.Y - 2 and mousePos.Y < btn.Position.Y + 15 then Interface.CurrentSection = name Interface.CurrentSubSection = (name == "COMBAT" and "AimAssist" or name == "VISUAL" and "Objects" or "Main") return end end
        for name, btn in pairs_iter(Interface.SubSections) do if btn.Visible and mousePos.X > btn.Position.X - 5 and mousePos.X < btn.Position.X + btn.TextBounds.X + 5 and mousePos.Y > btn.Position.Y - 2 and mousePos.Y < btn.Position.Y + 15 then Interface.CurrentSubSection = name return end end
        
        if Interface.MenuComponents[id] then
            for _, el in pairs_iter(Interface.MenuComponents[id]) do
                if el.lbl.Visible then
                    if el.type == "Toggle" then if mousePos.X > el.bg.Position.X - 2 and mousePos.X < el.bg.Position.X + 250 and mousePos.Y > el.bg.Position.Y - 2 and mousePos.Y < el.bg.Position.Y + 16 then el.state = not el.state el.cb(el.state) end
                    elseif el.type == "Color" then if mousePos.X > el.picker.Position.X - 2 and mousePos.X < el.picker.Position.X + 26 and mousePos.Y > el.picker.Position.Y - 2 and mousePos.Y < el.picker.Position.Y + 14 then local currentIndex = 1 for i, v in ipairs(Interface.ColorPalette) do if v == el.picker.Color then currentIndex = i break end end local newColor = Interface.ColorPalette[currentIndex + 1] or Interface.ColorPalette[1] el.picker.Color = newColor el.cb(newColor) end
                    elseif el.type == "Bind" then if mousePos.X > el.btn.Position.X - 5 and mousePos.X < el.btn.Position.X + el.btn.TextBounds.X + 5 and mousePos.Y > el.btn.Position.Y - 2 and mousePos.Y < el.btn.Position.Y + 15 then el.binding = true end end
                end
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.RightShift then Interface.Visible = false end
end))

table_insert(Interface.EventConnections, InputService.InputChanged:Connect(function(input)
    if Interface.Visible and input.UserInputType == Enum.UserInputType.MouseWheel then
        local mousePos = InputService:GetMouseLocation()
        if mousePos.X >= menuPosition.X and mousePos.X <= menuPosition.X + menuDimensions.X and mousePos.Y >= menuPosition.Y and mousePos.Y <= menuPosition.Y + menuDimensions.Y then
            local id = Interface.CurrentSection .. Interface.CurrentSubSection
            Interface.ScrollPositions[id] = math.clamp((Interface.ScrollPositions[id] or 0) + (input.Position.Z > 0 and 20 or -20), -500, 0)
        end
    end
end))

table_insert(Interface.EventConnections, InputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then Interface.Moving = false end
    if input.KeyCode == ZoomSettings.ZoomButton then
        ZoomSettings.ZoomHeld = false
        if not CameraSettings.CustomViewActive then Camera.FieldOfView = CameraSettings.OriginalView end
    end
end))
