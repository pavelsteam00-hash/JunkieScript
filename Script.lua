-- Параметры безопасности: инициализация
local task_wait = task.wait
local task_spawn = task.spawn
local get_genv = getgenv
local math_random = math.random
local tick_count = tick
local pairs_iter = pairs
local table_insert = table.insert

-- Проверка на легитимность места
if game.PlaceId ~= 13253735473 then 
    return 
end

-- Динамическая защита: обфускация уведомлений
local function Notify(title, text)
    task_spawn(function()
        task_wait(math_random(1, 2)) 
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

-- Полная очистка предыдущих сессий
if env.Trident_Cleanup then
    pcall(env.Trident_Cleanup)
end

Notify("Project Silver", "Secure Bypass Loaded")

-- Использование клонированных ссылок (Anti-Index)
local cloneref = (cloneref or function(o) return o end)
local ORIGINAL_HEAD_SIZE = Vector3.new(1, 1, 1)
local ORIGINAL_TRANSPARENCY = 0

local WorldSettings = {
    Fullbright = false, Intensity = 1,
    SkyColorEnabled = false, SkyColor = Color3.fromRGB(120, 140, 160),
    SkyIntensity = 0.3, 
    OriginalAmbient = game:GetService("Lighting").Ambient,
    OriginalOutdoor = game:GetService("Lighting").OutdoorAmbient,
    StoneESP = false, IronESP = false, NitrateESP = false
}

local CrosshairSettings = {
    Enabled = false, Spinning = false, SpinSpeed = 5, Size = 10,
    Gap = 5, Color = Color3.fromRGB(255, 255, 255),
    Thickness = 1.5, Rotation = 0
}

local AimSettings = {
    Enabled = false, 
    ShowFOV = false, 
    FilledFOV = false, 
    FOVFillTransparency = 0.2,
    FOV = 50, 
    Smoothness = 6,
    TargetPart = "Head", 
    Key = Enum.UserInputType.MouseButton2,
    Color = Color3.fromRGB(255, 255, 255), 
    WallCheck = false,
    HitboxEnabled = false, 
    HitboxSize = 1,
    HumanizedLogic = true 
}

env.Trident_SessionID = script_id

-- Безопасные сервисы
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local Lighting = cloneref(game:GetService("Lighting"))
local workspace = cloneref(game:GetService("Workspace"))

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Функция очеловеченного движения мыши (Anti-Cheat Bypass)
local function HumanoidMove(targetX, targetY, smooth)
    local mouse = UserInputService:GetMouseLocation()
    local diffX = (targetX - mouse.X)
    local diffY = (targetY - mouse.Y)
    local randomization = AimSettings.HumanizedLogic and (math_random(-2, 2)) or 0
    local relX = (diffX / smooth) + randomization
    local relY = (diffY / smooth) + randomization
    
    if typeof(mousemoverel) == "function" then
        mousemoverel(relX, relY)
    end
end

local HitmarkerSettings = {
    Enabled = true, Color = Color3.fromRGB(255, 255, 255),
    Size = 8, Thickness = 2.5, Duration = 1.5, LastHit = 0
}

env.SleeperCheck = false 
env.ESP_Enabled = false
env.ESP_Dist = 1000
env.ESP_Color = Color3.fromRGB(255, 255, 255)

local UI = {
    Visible = false, 
    Dragging = false, Accent = Color3.fromRGB(160, 170, 255),
    CurrentTab = "COMBAT", CurrentSubTab = "Aimbot",
    ScrollOffset = {}, Elements = {}, MenuElements = {}, 
    Tabs = {}, SubTabs = {}, Connections = {},
    Colors = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 200), 
        Color3.fromRGB(255, 60, 100), Color3.fromRGB(180, 100, 255), 
        Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 255, 0)
    }
}

-- Деструктор сессии (Safety Cleanup)
env.Trident_Cleanup = function()
    env.Trident_SessionID = nil
    for _, conn in pairs_iter(UI.Connections) do pcall(function() conn:Disconnect() end) end
    for _, el in pairs_iter(UI.Elements) do pcall(function() el:Remove() end) end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            p.Character.Head.Size = ORIGINAL_HEAD_SIZE
            p.Character.Head.Transparency = ORIGINAL_TRANSPARENCY
        end
    end
end

local function draw(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs_iter(props) do obj[k] = v end
    table_insert(UI.Elements, obj)
    return obj
end

local MenuOutline, Shadow, MainFrame, LeftColumnBg, RightColumnBg, Header, SubBar, AccentLine, Title, TitleS

local function CreateTab(name)
    local btn = draw("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(150, 150, 150), Visible = false, ZIndex = 104})
    UI.Tabs[name] = btn
end

local function AddToggle(tab, sub, name, callback, default)
    local id = tab .. sub
    if not UI.MenuElements[id] then UI.MenuElements[id] = {} UI.ScrollOffset[id] = 0 end
    local box = draw("Square", {Size = Vector2.new(12, 12), Color = Color3.fromRGB(30, 30, 40), Filled = true, Visible = false, ZIndex = 104})
    local boxOut = draw("Square", {Size = Vector2.new(12, 12), Color = Color3.fromRGB(60, 60, 80), Filled = false, Thickness = 1, Visible = false, ZIndex = 105})
    local lbl = draw("Text", {Text = name, Size = 14, Font = 2, Color = Color3.fromRGB(220, 220, 230), Visible = false, ZIndex = 104})
    table_insert(UI.MenuElements[id], {type = "Toggle", bg = box, out = boxOut, lbl = lbl, cb = callback, state = default or false, height = 28})
end

local function AddSlider(tab, sub, name, min, max, default, callback)
    local id = tab .. sub
    if not UI.MenuElements[id] then UI.MenuElements[id] = {} UI.ScrollOffset[id] = 0 end
    local lbl = draw("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(180, 180, 190), Visible = false, ZIndex = 104})
    local valLbl = draw("Text", {Size = 13, Font = 2, Color = UI.Accent, Visible = false, ZIndex = 104})
    local sBg = draw("Square", {Size = Vector2.new(220, 3), Color = Color3.fromRGB(40, 40, 50), Filled = true, Visible = false, ZIndex = 104})
    local sFill = draw("Square", {Size = Vector2.new(0, 3), Color = UI.Accent, Filled = true, Visible = false, ZIndex = 105})
    table_insert(UI.MenuElements[id], {type = "Slider", lbl = lbl, valLbl = valLbl, sBg = sBg, sFill = sFill, min = min, max = max, val = default, cb = callback, height = 45})
end

local function AddColor(tab, sub, name, colorCallback, defaultColor)
    local id = tab .. sub
    if not UI.MenuElements[id] then UI.MenuElements[id] = {} UI.ScrollOffset[id] = 0 end
    local lbl = draw("Text", {Text = name, Size = 13, Font = 2, Color = Color3.fromRGB(140, 140, 150), Visible = false, ZIndex = 104})
    local picker = draw("Square", {Size = Vector2.new(22, 10), Color = defaultColor, Filled = true, Visible = false, ZIndex = 105})
    table_insert(UI.MenuElements[id], {type = "Color", lbl = lbl, picker = picker, cb = colorCallback, height = 28})
end

local menuPos = Vector2.new(150, 150)
local menuSize = Vector2.new(540, 420)
local dragOffset = Vector2.new(0, 0)

-- ЗАДЕРЖКА 1 СЕКУНДА ПЕРЕД ПОЯВЛЕНИЕМ МЕНЮ
task.delay(1.0, function()
    MenuOutline = draw("Square", {Size = menuSize + Vector2.new(1, 1), Color = UI.Accent, Filled = false, Thickness = 1, Transparency = 0.6, Visible = true, ZIndex = 110})
    Shadow = draw("Square", {Size = menuSize, Color = Color3.fromRGB(5, 5, 7), Filled = true, Visible = true, ZIndex = 99})
    MainFrame = draw("Square", {Size = menuSize, Color = Color3.fromRGB(15, 15, 20), Filled = true, Visible = true, ZIndex = 100})
    LeftColumnBg = draw("Square", {Size = Vector2.new(255, 305), Color = Color3.fromRGB(22, 22, 28), Filled = true, Visible = true, ZIndex = 101})
    RightColumnBg = draw("Square", {Size = Vector2.new(255, 305), Color = Color3.fromRGB(22, 22, 28), Filled = true, Visible = true, ZIndex = 101})
    Header = draw("Square", {Size = Vector2.new(menuSize.X, 35), Color = Color3.fromRGB(20, 20, 28), Filled = true, Visible = true, ZIndex = 101})
    SubBar = draw("Square", {Size = Vector2.new(menuSize.X, 30), Color = Color3.fromRGB(18, 18, 24), Filled = true, Visible = true, ZIndex = 101})
    AccentLine = draw("Square", {Size = Vector2.new(menuSize.X, 1), Color = UI.Accent, Filled = true, Transparency = 0.6, Visible = true, ZIndex = 102})
    Title = draw("Text", {Text = "PROJECT", Size = 20, Font = 3, Color = Color3.new(0.9,0.9,0.9), Visible = true, ZIndex = 103})
    TitleS = draw("Text", {Text = "SILVER", Size = 20, Font = 3, Color = UI.Accent, Visible = true, ZIndex = 103})

    CreateTab("COMBAT")
    CreateTab("VISUALS")
    CreateTab("MENU")

    AddToggle("COMBAT", "Aimbot", "Aimbot Enabled", function(v) AimSettings.Enabled = v end)
    AddToggle("COMBAT", "Aimbot", "Humanized Smoothing", function(v) AimSettings.HumanizedLogic = v end, true)
    AddToggle("COMBAT", "Aimbot", "Show FOV Circle", function(v) AimSettings.ShowFOV = v end, false)
    AddToggle("COMBAT", "Aimbot", "Fill FOV Circle", function(v) AimSettings.FilledFOV = v end, false)
    AddSlider("COMBAT", "Aimbot", "FOV Fill Transparency", 0, 1, 0.2, function(v) AimSettings.FOVFillTransparency = v end)
    AddToggle("COMBAT", "Aimbot", "Wall Check", function(v) AimSettings.WallCheck = v end, false)
    AddToggle("COMBAT", "Aimbot", "Target Body", function(v) AimSettings.TargetPart = v and "LowerTorso" or "Head" end)
    AddSlider("COMBAT", "Aimbot", "FOV Size", 30, 200, 50, function(v) AimSettings.FOV = v end)
    AddSlider("COMBAT", "Aimbot", "Smoothness", 1, 10, 5, function(v) AimSettings.Smoothness = v end)
    AddToggle("COMBAT", "Aimbot", "Hitbox Expander", function(v) AimSettings.HitboxEnabled = v end)
    AddSlider("COMBAT", "Aimbot", "Hitbox Size", 1, 4, 1, function(v) AimSettings.HitboxSize = v end)
    AddColor("COMBAT", "Aimbot", "FOV Color", function(c) AimSettings.Color = c end, AimSettings.Color)

    AddToggle("COMBAT", "Settings", "Hitmarker", function(v) HitmarkerSettings.Enabled = v end, true)
    AddSlider("COMBAT", "Settings", "Hitmarker Size", 4, 20, 8, function(v) HitmarkerSettings.Size = v end)
    AddColor("COMBAT", "Settings", "Hitmarker Color", function(c) HitmarkerSettings.Color = c end, HitmarkerSettings.Color)

    AddToggle("VISUALS", "Players", "Enable ESP", function(v) env.ESP_Enabled = v end)
    AddToggle("VISUALS", "Players", "Filter Sleepers", function(v) env.SleeperCheck = v end)
    AddSlider("VISUALS", "Players", "Max Distance", 100, 1000, 1000, function(v) env.ESP_Dist = v end)
    AddColor("VISUALS", "Players", "ESP Color", function(c) env.ESP_Color = c end, env.ESP_Color)
    AddToggle("VISUALS", "Players", "Stone ESP", function(v) WorldSettings.StoneESP = v end)
    AddToggle("VISUALS", "Players", "Iron ESP", function(v) WorldSettings.IronESP = v end)
    AddToggle("VISUALS", "Players", "Nitrate ESP", function(v) WorldSettings.NitrateESP = v end)

    AddToggle("VISUALS", "World", "Crosshair Enabled", function(v) CrosshairSettings.Enabled = v end)
    AddToggle("VISUALS", "World", "Spinning Crosshair", function(v) CrosshairSettings.Spinning = v end)
    AddSlider("VISUALS", "World", "Spin Speed", 1, 5, 1, function(v) CrosshairSettings.SpinSpeed = v end)
    AddSlider("VISUALS", "World", "Crosshair Size", 5, 10, 5, function(v) CrosshairSettings.Size = v end)
    AddSlider("VISUALS", "World", "Crosshair Gap", 0, 5, 1, function(v) CrosshairSettings.Gap = v end)
    AddColor("VISUALS", "World", "Crosshair Color", function(c) CrosshairSettings.Color = c end, CrosshairSettings.Color)
    AddToggle("VISUALS", "World", "Fullbright", function(v) WorldSettings.Fullbright = v end)
    AddSlider("VISUALS", "World", "Brightness Intensity", 1, 10, 1, function(v) WorldSettings.Intensity = v end)
    AddToggle("VISUALS", "World", "Sky Color Enabled", function(v) WorldSettings.SkyColorEnabled = v end)
    AddSlider("VISUALS", "World", "Sky Intensity", 0, 1, 0.3, function(v) WorldSettings.SkyIntensity = v end)
    AddColor("VISUALS", "World", "Sky Color", function(c) WorldSettings.SkyColor = c end, WorldSettings.SkyColor)

    AddColor("MENU", "Main", "Menu Accent", function(c) UI.Accent = c end, UI.Accent)
    UI.Visible = true
end)

local FOVCircle = draw("Circle", {Thickness = 2, Color = AimSettings.Color, Transparency = 1, Filled = false, Visible = false, NumSides = 64, ZIndex = 999})
local HitLines = {draw("Line",{ZIndex = 999}), draw("Line",{ZIndex = 999}), draw("Line",{ZIndex = 999}), draw("Line",{ZIndex = 999})}
local CrosshairLines = {draw("Line",{ZIndex = 1000}), draw("Line",{ZIndex = 1000}), draw("Line",{ZIndex = 1000}), draw("Line",{ZIndex = 1000})}

local function identifyModel(model)
    local mesh = model:FindFirstChildOfClass("MeshPart")
    if mesh and mesh.MeshId == "rbxassetid://12939036056" then
        if #model:GetChildren() == 1 then return "Stone", mesh, Color3.fromRGB(150, 150, 150)
        else
            for _, part in pairs_iter(model:GetChildren()) do
                if part:IsA("BasePart") then
                    if part.Color == Color3.fromRGB(248, 248, 248) then return "Nitrate", part, Color3.fromRGB(255, 255, 255)
                    elseif part.Color == Color3.fromRGB(199, 172, 120) then return "Iron", part, Color3.fromRGB(255, 130, 50) end
                end
            end
        end
    end
    return nil
end

local function IsVisible(part)
    if not AimSettings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), params)
    return not result
end

local function IsSleeper(model)
    if not env.SleeperCheck then return false end
    local lt = model:FindFirstChild("LowerTorso")
    if lt then
        local rr = lt:FindFirstChild("RootRig")
        if rr and typeof(rr.CurrentAngle) == "number" and rr.CurrentAngle ~= 0 then return true end
    end
    return false
end

table_insert(UI.Connections, workspace.ChildAdded:Connect(function(c)
    if HitmarkerSettings.Enabled and (c.Name == "PlayerHit2" or c.Name == "Dink" or c.Name == "PlayerHitHeadshot") then 
        HitmarkerSettings.LastHit = tick_count()
    end
end))

table_insert(UI.Connections, RunService.Heartbeat:Connect(function()
    if env.Trident_SessionID ~= script_id then return end
    if WorldSettings.Fullbright then
        local brightVal = WorldSettings.Intensity / 5
        Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows, Lighting.ClockTime = Color3.new(brightVal, brightVal, brightVal), Color3.new(brightVal, brightVal, brightVal), false, 12
    elseif WorldSettings.SkyColorEnabled then
        local softColor = WorldSettings.OriginalAmbient:Lerp(WorldSettings.SkyColor, WorldSettings.SkyIntensity)
        Lighting.Ambient, Lighting.OutdoorAmbient = softColor, softColor
    end
end))

local ESP_Storage = {}
local Ores_Storage = {}
local CachedPlayers = {}
local CachedOres = {}

task_spawn(function()
    while true do
        task_wait(0.2)
        if env.Trident_SessionID ~= script_id then break end
        local pList, oList = {}, {}
        pcall(function()
            for _, obj in pairs_iter(workspace:GetChildren()) do
                if obj:IsA("Model") then
                    if (obj:FindFirstChild("LowerTorso") or obj:FindFirstChild("HumanoidRootPart")) and obj.Name ~= LocalPlayer.Name then table_insert(pList, obj)
                    else local type, part, col = identifyModel(obj) if type then table_insert(oList, {model = obj, part = part, type = type, color = col}) end end
                end
            end
        end)
        CachedPlayers, CachedOres = pList, oList
    end
end)

task_spawn(function()
    while true do
        task_wait(0.1)
        if env.Trident_SessionID ~= script_id then break end
        for i = 1, #CachedPlayers do
            local obj = CachedPlayers[i]
            local head = obj and obj:FindFirstChild("Head")
            if head then
                if AimSettings.HitboxEnabled then
                    head.Size, head.Transparency, head.CanCollide = Vector3.new(AimSettings.HitboxSize, AimSettings.HitboxSize, AimSettings.HitboxSize), 0.4, false
                elseif head.Size ~= ORIGINAL_HEAD_SIZE then
                    head.Size, head.Transparency = ORIGINAL_HEAD_SIZE, ORIGINAL_TRANSPARENCY
                end
            end
        end
    end
end)

table_insert(UI.Connections, RunService.RenderStepped:Connect(function()
    if env.Trident_SessionID ~= script_id then return end
    local mouse_loc = UserInputService:GetMouseLocation()
    if UI.Dragging and UI.Visible then menuPos = mouse_loc + dragOffset end
    
    if MenuOutline then
        local isVisible = UI.Visible
        MenuOutline.Position, MenuOutline.Color, MenuOutline.Visible = menuPos, UI.Accent, isVisible
        Shadow.Position, Shadow.Visible = menuPos, isVisible
        MainFrame.Position, MainFrame.Visible = menuPos, isVisible
        Header.Position, Header.Visible = menuPos, isVisible
        SubBar.Position, SubBar.Visible = menuPos + Vector2.new(0, 35), isVisible
        AccentLine.Position, AccentLine.Color, AccentLine.Visible = menuPos + Vector2.new(0, 65), UI.Accent, isVisible
        Title.Position, Title.Visible = menuPos + Vector2.new(15, 8), isVisible
        TitleS.Position, TitleS.Color, TitleS.Visible = Title.Position + Vector2.new(Title.TextBounds.X + 5, 0), UI.Accent, isVisible
        LeftColumnBg.Position, LeftColumnBg.Visible = menuPos + Vector2.new(10, 100), isVisible
        RightColumnBg.Position, RightColumnBg.Visible = menuPos + Vector2.new(275, 100), isVisible
        
        local tabOrder = {"COMBAT", "VISUALS", "MENU"}
        for i, name in ipairs(tabOrder) do
            local btn = UI.Tabs[name]
            if btn then
                btn.Visible, btn.Position, btn.Color = isVisible, menuPos + Vector2.new(20 + (i-1) * 100, 43), UI.CurrentTab == name and UI.Accent or Color3.fromRGB(130, 130, 140)
            end
        end

        local subList = (UI.CurrentTab == "COMBAT" and {"Aimbot", "Settings"}) or (UI.CurrentTab == "VISUALS" and {"Players", "World"}) or {"Main"}
        for _, s in pairs_iter(UI.SubTabs) do s.Visible = false end
        for i, name in ipairs(subList) do
            if not UI.SubTabs[name] then UI.SubTabs[name] = draw("Text", {Size = 14, Font = 2, ZIndex = 104}) end
            local sbtn = UI.SubTabs[name]
            sbtn.Visible, sbtn.Text, sbtn.Position, sbtn.Color = isVisible, name, menuPos + Vector2.new(20 + (i-1)*120, 73), UI.CurrentSubTab == name and UI.Accent or Color3.fromRGB(80, 80, 90)
        end

        for id, elements in pairs_iter(UI.MenuElements) do
            local isCurrent = (id == UI.CurrentTab .. UI.CurrentSubTab)
            if isCurrent then
                local mid = math.ceil(#elements / 2)
                for i, el in ipairs(elements) do
                    local col, indexInCol = (i <= mid) and 0 or 1, (i <= mid) and (i - 1) or (i - mid - 1)
                    local startX, offY = (col == 0) and 25 or 290, 115 + (indexInCol * 35) + (UI.ScrollOffset[id] or 0)
                    local show = isVisible and (offY >= 105 and offY <= 380)
                    if el.type == "Toggle" then
                        el.bg.Position, el.out.Position, el.lbl.Position, el.bg.Color = menuPos+Vector2.new(startX, offY+3), menuPos+Vector2.new(startX, offY+3), menuPos+Vector2.new(startX+22, offY), el.state and UI.Accent or Color3.fromRGB(30, 30, 40)
                        el.bg.Visible, el.out.Visible, el.lbl.Visible = show, show, show
                    elseif el.type == "Slider" then
                        el.lbl.Position, el.sBg.Position, el.sFill.Position = menuPos+Vector2.new(startX, offY-5), menuPos+Vector2.new(startX, offY+15), menuPos+Vector2.new(startX, offY+15)
                        if show and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            local m = UserInputService:GetMouseLocation()
                            if m.X > el.sBg.Position.X and m.X < el.sBg.Position.X + 220 and m.Y > el.sBg.Position.Y - 8 and m.Y < el.sBg.Position.Y + 12 then
                                el.val = el.min + (el.max-el.min) * math.clamp((m.X-el.sBg.Position.X)/220, 0, 1) el.cb(el.val)
                            end
                        end
                        el.sFill.Size, el.sFill.Color, el.valLbl.Text, el.valLbl.Position = Vector2.new(220*((el.val-el.min)/(el.max-el.min)), 3), UI.Accent, string.format("%.1f", el.val), menuPos+Vector2.new(startX+220-el.valLbl.TextBounds.X, offY-5)
                        el.valLbl.Visible, el.lbl.Visible, el.sBg.Visible, el.sFill.Visible = show, show, show, show
                    elseif el.type == "Color" then
                        el.lbl.Position, el.picker.Position = menuPos+Vector2.new(startX, offY), menuPos+Vector2.new(startX+200, offY+3)
                        el.lbl.Visible, el.picker.Visible = show, show
                    end
                end
            else
                for _, el in pairs_iter(elements) do
                    if el.type == "Toggle" then el.bg.Visible, el.out.Visible, el.lbl.Visible = false, false, false
                    elseif el.type == "Slider" then el.valLbl.Visible, el.lbl.Visible, el.sBg.Visible, el.sFill.Visible = false, false, false, false
                    elseif el.type == "Color" then el.lbl.Visible, el.picker.Visible = false, false end
                end
            end
        end
    end

    FOVCircle.Visible, FOVCircle.Radius, FOVCircle.Position, FOVCircle.Color = AimSettings.Enabled and AimSettings.ShowFOV, AimSettings.FOV, mouse_loc, AimSettings.Color
    
    if CrosshairSettings.Enabled then
        if CrosshairSettings.Spinning then CrosshairSettings.Rotation = CrosshairSettings.Rotation + (CrosshairSettings.SpinSpeed / 100) end
        for i, line in ipairs(CrosshairLines) do
            local angle = CrosshairSettings.Rotation + (i-1) * (math.pi/2)
            line.Visible, line.Color = true, CrosshairSettings.Color
            line.From, line.To = mouse_loc + Vector2.new(math.cos(angle) * CrosshairSettings.Gap, math.sin(angle) * CrosshairSettings.Gap), mouse_loc + Vector2.new(math.cos(angle) * (CrosshairSettings.Gap + CrosshairSettings.Size), math.sin(angle) * (CrosshairSettings.Gap + CrosshairSettings.Size))
        end
    end

    local hitDiff = tick_count() - HitmarkerSettings.LastHit
    if hitDiff < HitmarkerSettings.Duration then
        local alpha = math.clamp(1 - (hitDiff / HitmarkerSettings.Duration), 0, 1)
        for i = 1, 4 do
            local line, s, g = HitLines[i], HitmarkerSettings.Size, 4
            line.Visible, line.Transparency, line.Color = true, alpha, HitmarkerSettings.Color
            if i==1 then line.From, line.To = mouse_loc+Vector2.new(-s,-s), mouse_loc+Vector2.new(-g,-g)
            elseif i==2 then line.From, line.To = mouse_loc+Vector2.new(s,-s), mouse_loc+Vector2.new(g,-g)
            elseif i==3 then line.From, line.To = mouse_loc+Vector2.new(-s,s), mouse_loc+Vector2.new(-g,g)
            elseif i==4 then line.From, line.To = mouse_loc+Vector2.new(s,s), mouse_loc+Vector2.new(g,g) end
        end
    end

    for i = 1, #CachedPlayers do
        local obj = CachedPlayers[i]
        local root = obj and obj:FindFirstChild("HumanoidRootPart")
        local isAlive = obj and obj.Parent == workspace and root
        
        if isAlive then
            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen and env.ESP_Enabled and dist <= env.ESP_Dist and not IsSleeper(obj) then
                if not ESP_Storage[obj] then ESP_Storage[obj] = {Box = draw("Square", {Thickness = 1, Visible = false}), Name = draw("Text", {Size = 13, Center = true, Visible = false}), Dist = draw("Text", {Size = 11, Center = true, Visible = false})} end
                local d, sX, sY = ESP_Storage[obj], 2200/pos.Z, 3500/pos.Z
                d.Box.Visible, d.Box.Size, d.Box.Position, d.Box.Color = true, Vector2.new(sX, sY), Vector2.new(pos.X - sX/2, pos.Y - sY/2), env.ESP_Color
                d.Name.Visible, d.Name.Text, d.Name.Position, d.Name.Color = true, obj.Name, Vector2.new(pos.X, pos.Y - sY/2 - 16), env.ESP_Color
                d.Dist.Visible, d.Dist.Text, d.Dist.Position, d.Dist.Color = true, math.floor(dist).."m", Vector2.new(pos.X, pos.Y + sY/2 + 2), env.ESP_Color
            elseif ESP_Storage[obj] then ESP_Storage[obj].Box.Visible, ESP_Storage[obj].Name.Visible, ESP_Storage[obj].Dist.Visible = false, false, false end
        elseif ESP_Storage[obj] then
            pcall(function()
                ESP_Storage[obj].Box:Remove()
                ESP_Storage[obj].Name:Remove()
                ESP_Storage[obj].Dist:Remove()
            end)
            ESP_Storage[obj] = nil
        end
    end

    for i = 1, #CachedOres do
        local ore = CachedOres[i]
        local enabled = (ore.type == "Stone" and WorldSettings.StoneESP) or (ore.type == "Iron" and WorldSettings.IronESP) or (ore.type == "Nitrate" and WorldSettings.NitrateESP)
        if enabled and ore.model and ore.model.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(ore.part.Position)
            local dist = (Camera.CFrame.Position - ore.part.Position).Magnitude
            if onScreen and dist < 1500 then
                if not Ores_Storage[ore.model] then Ores_Storage[ore.model] = {Name = draw("Text", {Size = 13, Center = true, Visible = false})} end
                local d = Ores_Storage[ore.model]
                d.Name.Visible, d.Name.Text, d.Name.Position, d.Name.Color = true, ore.type .. " [" .. math.floor(dist) .. "m]", Vector2.new(pos.X, pos.Y), ore.color
            elseif Ores_Storage[ore.model] then Ores_Storage[ore.model].Name.Visible = false end
        elseif Ores_Storage[ore.model] then Ores_Storage[ore.model].Name.Visible = false end
    end

    if AimSettings.Enabled and UserInputService:IsMouseButtonPressed(AimSettings.Key) then
        local target, short = nil, AimSettings.FOV
        for i = 1, #CachedPlayers do
            local obj = CachedPlayers[i]
            local t = obj and obj.Parent == workspace and obj:FindFirstChild(AimSettings.TargetPart)
            if t and IsVisible(t) and not IsSleeper(obj) then
                local p, on = Camera:WorldToViewportPoint(t.Position)
                if on then local mag = (Vector2.new(p.X, p.Y) - mouse_loc).Magnitude if mag < short then short = mag target = p end end
            end
        end
        if target then HumanoidMove(target.X, target.Y, AimSettings.Smoothness) end
    end
end))

table_insert(UI.Connections, UserInputService.InputBegan:Connect(function(input)
    if not UI.Visible then if input.KeyCode == Enum.KeyCode.RightShift then UI.Visible = true end return end
    local m = UserInputService:GetMouseLocation()
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if m.X > menuPos.X and m.X < menuPos.X + menuSize.X and m.Y > menuPos.Y and m.Y < menuPos.Y + 35 then UI.Dragging = true dragOffset = menuPos - m return end
        for name, btn in pairs_iter(UI.Tabs) do if m.X > btn.Position.X - 5 and m.X < btn.Position.X + btn.TextBounds.X + 5 and m.Y > btn.Position.Y - 2 and m.Y < btn.Position.Y + 15 then UI.CurrentTab = name UI.CurrentSubTab = (name == "COMBAT" and "Aimbot" or name == "VISUALS" and "Players" or "Main") return end end
        for name, btn in pairs_iter(UI.SubTabs) do if btn.Visible and m.X > btn.Position.X - 5 and m.X < btn.Position.X + btn.TextBounds.X + 5 and m.Y > btn.Position.Y - 2 and m.Y < btn.Position.Y + 15 then UI.CurrentSubTab = name return end end
        local id = UI.CurrentTab .. UI.CurrentSubTab
        if UI.MenuElements[id] then
            for _, el in pairs_iter(UI.MenuElements[id]) do
                if el.lbl.Visible then
                    if el.type == "Toggle" then if m.X > el.bg.Position.X - 2 and m.X < el.bg.Position.X + 250 and m.Y > el.bg.Position.Y - 2 and m.Y < el.bg.Position.Y + 16 then el.state = not el.state el.cb(el.state) end
                    elseif el.type == "Color" then if m.X > el.picker.Position.X - 2 and m.X < el.picker.Position.X + 26 and m.Y > el.picker.Position.Y - 2 and m.Y < el.picker.Position.Y + 14 then local curIdx = 1 for i, v in ipairs(UI.Colors) do if v == el.picker.Color then curIdx = i break end end local newCol = UI.Colors[curIdx + 1] or UI.Colors[1] el.picker.Color = newCol el.cb(newCol) end end
                end
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.RightShift then UI.Visible = false end
end))

table_insert(UI.Connections, UserInputService.InputChanged:Connect(function(input)
    if UI.Visible and input.UserInputType == Enum.UserInputType.MouseWheel then
        local id = UI.CurrentTab .. UI.CurrentSubTab
        UI.ScrollOffset[id] = math.clamp((UI.ScrollOffset[id] or 0) + (input.Position.Z > 0 and 20 or -20), -500, 0)
    end
end))

table_insert(UI.Connections, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then UI.Dragging = false end end))
