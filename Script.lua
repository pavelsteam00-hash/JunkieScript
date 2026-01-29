local task_wait = task.wait
local task_spawn = task.spawn
local math_floor = math.floor
local math_clamp = math.clamp
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove
local Vector2new = Vector2.new
local Color3fromRGB = Color3.fromRGB
local string_format = string.format

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local AimSettings = {
    Active = false,
    WallCheck = false,
    TargetArea = "Head",
    FOVSize = 80,
    Smoothness = 5,
    SleeperCheck = false,
    ShowFOV = true,
    FOVColor = Color3fromRGB(255, 255, 255)
}

local VisualSettings = {
    PlayerESP = false,
    BoxESP = false,
    InfoESP = false,
    HealthESP = false,
    SleeperCheck = false,
    StoneESP = false,
    IronESP = false,
    NitrateESP = false,
    MaxDistance = 1000,
    ESPColor = Color3fromRGB(180, 120, 255)
}

local Interface = {
    Visible = false,
    Moving = false,
    DraggingSlider = nil,
    ColorMenuOpen = false,
    Loaded = false,
    AccentColor = Color3fromRGB(180, 120, 255),
    BgColor = Color3fromRGB(10, 10, 12),
    SectionColor = Color3fromRGB(15, 15, 18),
    BorderColor = Color3fromRGB(30, 30, 35),
    TextColor = Color3fromRGB(255, 255, 255),
    MenuComponents = {left = {}, right = {}},
    UIComponents = {},
}

local ColorPalette = {
    Color3fromRGB(180, 120, 255), 
    Color3fromRGB(255, 70, 70),   
    Color3fromRGB(70, 255, 130),  
    Color3fromRGB(255, 255, 255), 
    Color3fromRGB(255, 180, 0)
}

local ESPStorage = {}
local ResourceStorage = {}
local PlayerCache = {}
local ResourceCache = {}
local ActiveNotifications = {}

local function CreateDrawing(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props) do pcall(function() obj[k] = v end) end
    table_insert(Interface.UIComponents, obj)
    return obj
end

local function CustomNotify(title, text)
    local purple = Color3fromRGB(180, 120, 255)
    for _, oldNotif in ipairs(ActiveNotifications) do
        oldNotif.Active = false
        pcall(function()
            for _, obj in ipairs(oldNotif.objs) do 
                obj.Visible = false 
                obj:Remove() 
            end
        end)
    end
    ActiveNotifications = {}
    local n = {Active = true, objs = {}}
    table_insert(ActiveNotifications, n)
    task_spawn(function()
        local screen = Camera.ViewportSize
        local nWidth, nHeight = 310, 75
        local targetPos = Vector2new(screen.X - 330, screen.Y - 120)
        local startPos = Vector2new(screen.X + 50, screen.Y - 120)
        local bg = Drawing.new("Square")
        bg.Size = Vector2new(nWidth, nHeight)
        bg.Color = Interface.BgColor
        bg.Filled = true
        bg.ZIndex = 30000
        bg.Visible = true
        local line = Drawing.new("Square")
        line.Size = Vector2new(4, nHeight)
        line.Color = purple
        line.Filled = true
        line.ZIndex = 30001
        line.Visible = true
        local tLabel = Drawing.new("Text")
        tLabel.Text = title:upper()
        tLabel.Size = 19
        tLabel.Font = 2
        tLabel.Color = purple
        tLabel.ZIndex = 30002
        tLabel.Visible = true
        local bLabel = Drawing.new("Text")
        bLabel.Text = text
        bLabel.Size = 15
        bLabel.Color = Color3fromRGB(210, 210, 210)
        bLabel.ZIndex = 30002
        bLabel.Visible = true
        n.objs = {bg, line, tLabel, bLabel}
        
        local t = 0
        while t < 1 and n.Active do
            t = t + (0.02 + math_random() * 0.02)
            local curPos = startPos:Lerp(targetPos, t)
            bg.Position = curPos
            line.Position = curPos
            tLabel.Position = curPos + Vector2new(20, 15)
            bLabel.Position = curPos + Vector2new(20, 42)
            RunService.Heartbeat:Wait()
        end
        
        task_wait(1.0 + math_random() * 0.5)
        
        while t > 0 and n.Active do
            t = t - (0.04 + math_random() * 0.02)
            local curPos = startPos:Lerp(targetPos, t)
            bg.Position = curPos
            line.Position = curPos
            tLabel.Position = curPos + Vector2new(20, 15)
            bLabel.Position = curPos + Vector2new(20, 42)
            RunService.Heartbeat:Wait()
        end
        if n.Active then for _, obj in ipairs(n.objs) do obj:Remove() end end
    end)
end

task_spawn(function()
    local screen = Camera.ViewportSize
    local center = screen / 2
    local purple_theme = Color3fromRGB(180, 120, 255)
    
    local black_out = Drawing.new("Square")
    black_out.Size = screen
    black_out.Color = Color3fromRGB(0, 0, 0)
    black_out.Filled = true
    black_out.Transparency = 0
    black_out.Visible = true
    black_out.ZIndex = 19000
    
    local lines = {}
    for i = 1, 20 do
        local l = Drawing.new("Square")
        l.Size = Vector2new(1, math_random(30, 80))
        l.Position = Vector2new(math_random(0, screen.X), math_random(0, screen.Y))
        l.Color = Interface.AccentColor
        l.Transparency = 0
        l.Filled = true
        l.Visible = true
        l.ZIndex = 19001
        table_insert(lines, l)
    end
    
    local load_circle = Drawing.new("Circle")
    load_circle.Position = center
    load_circle.Radius = 50
    load_circle.Thickness = 2
    load_circle.Color = Interface.AccentColor
    load_circle.Transparency = 0
    load_circle.Visible = true
    load_circle.ZIndex = 20000
    
    local load_text = Drawing.new("Text")
    load_text.Text = "SILVER"
    load_text.Size = 35
    load_text.Font = 2
    load_text.Center = true
    load_text.Position = center - Vector2new(0, 18)
    load_text.Color = purple_theme
    load_text.Transparency = 0
    load_text.Visible = true
    load_text.ZIndex = 20001
    
    local status = Drawing.new("Text")
    status.Text = "LOADING..."
    status.Size = 14
    status.Center = true
    status.Position = center + Vector2new(0, 75)
    status.Color = Interface.AccentColor
    status.Transparency = 0
    status.Visible = true
    status.ZIndex = 20001

    for i = 0, 1, 0.05 do
        black_out.Transparency = i * 0.85
        load_circle.Transparency = i
        load_text.Transparency = i
        status.Transparency = i
        for _, l in ipairs(lines) do l.Transparency = i * 0.4 end
        RunService.Heartbeat:Wait()
    end

    local start = tick()
    while tick() - start < 4 do
        local prog = (tick() - start) / 4
        status.Text = "INITIALIZING SYSTEM: " .. math_floor(prog * 100) .. "%"
        load_circle.Radius = 50 + (math.sin(tick() * 5) * 5)
        for _, l in ipairs(lines) do
            l.Position = l.Position + Vector2new(0, 8)
            if l.Position.Y > screen.Y then l.Position = Vector2new(math_random(0, screen.X), -100) end
        end
        task_wait()
    end

    for i = 1, 0, -0.05 do
        black_out.Transparency = i * 0.85
        load_circle.Transparency = i
        load_text.Transparency = i
        status.Transparency = i
        for _, l in ipairs(lines) do l.Transparency = i * 0.4 end
        RunService.Heartbeat:Wait()
    end
    
    black_out:Remove() load_circle:Remove() load_text:Remove() status:Remove()
    for _, l in ipairs(lines) do l:Remove() end
    Interface.Loaded = true
    Interface.Visible = true
    CustomNotify("SUCCESS", "Silver Private Premium Active")
end)

local menuPosition = Vector2new(350, 250)
local menuDimensions = Vector2new(500, 440)
local dragStartOffset = Vector2new(0, 0)
local MainFrame, BorderLine, Header, HeaderTitle, LeftPane, RightPane

task_spawn(function()
    while not Interface.Loaded do task_wait(0.1) end
    MainFrame = CreateDrawing("Square", { Size = menuDimensions, Color = Interface.BgColor, Filled = true, Visible = false, ZIndex = 10 })
    BorderLine = CreateDrawing("Square", { Size = menuDimensions, Color = Interface.BorderColor, Filled = false, Thickness = 1, Visible = false, ZIndex = 11 })
    Header = CreateDrawing("Square", { Size = Vector2new(menuDimensions.X, 3), Color = Interface.AccentColor, Filled = true, Visible = false, ZIndex = 15 })
    HeaderTitle = CreateDrawing("Text", { Text = "SILVER PRIVATE", Size = 16, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 16 })
    LeftPane = CreateDrawing("Square", { Size = Vector2new(235, 380), Color = Interface.SectionColor, Filled = true, Visible = false, ZIndex = 12 })
    RightPane = CreateDrawing("Square", { Size = Vector2new(235, 380), Color = Interface.SectionColor, Filled = true, Visible = false, ZIndex = 12 })

    local function AddToggle(name, default, callback, column, ypos)
        local toggle = {
            type = "toggle", name = name, state = default, callback = callback,
            bg = CreateDrawing("Square", {Size = Vector2new(12, 12), Color = Color3fromRGB(30, 30, 35), Filled = true, Visible = false, ZIndex = 16}),
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 16}),
            ypos = ypos, column = column
        }
        table_insert(Interface.MenuComponents[column], toggle)
    end
    local function AddSlider(name, min, max, default, callback, column, ypos)
        local slider = {
            type = "slider", name = name, min = min, max = max, value = default, callback = callback,
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Color = Color3fromRGB(180, 180, 180), Visible = false, ZIndex = 16}),
            valueText = CreateDrawing("Text", {Text = tostring(default), Size = 13, Font = 2, Color = Interface.AccentColor, Visible = false, ZIndex = 16}),
            bg = CreateDrawing("Square", {Size = Vector2new(200, 3), Color = Color3fromRGB(25, 25, 30), Filled = true, Visible = false, ZIndex = 16}),
            fill = CreateDrawing("Square", {Size = Vector2new(0, 3), Color = Interface.AccentColor, Filled = true, Visible = false, ZIndex = 17}),
            ypos = ypos, column = column
        }
        table_insert(Interface.MenuComponents[column], slider)
    end
    local function AddButton(name, callback, column, ypos)
        local btn = {
            type = "button", name = name, callback = callback,
            bg = CreateDrawing("Square", {Size = Vector2new(200, 20), Color = Color3fromRGB(25, 25, 30), Filled = true, Visible = false, ZIndex = 16}),
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Center = true, Color = Interface.TextColor, Visible = false, ZIndex = 17}),
            ypos = ypos, column = column
        }
        table_insert(Interface.MenuComponents[column], btn)
    end
    local function AddColorPicker(name, callback, column, ypos)
        local cp = {
            type = "colorpicker", name = name, callback = callback,
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 16}),
            preview = CreateDrawing("Square", {Size = Vector2new(20, 10), Color = VisualSettings.ESPColor, Filled = true, Visible = false, ZIndex = 17}),
            selectorBg = CreateDrawing("Square", {Size = Vector2new(150, 30), Color = Interface.BgColor, Filled = true, Visible = false, ZIndex = 50}),
            boxes = {}, ypos = ypos, column = column
        }
        for _, color in ipairs(ColorPalette) do
            table_insert(cp.boxes, CreateDrawing("Square", {Size = Vector2new(20, 15), Color = color, Filled = true, Visible = false, ZIndex = 51}))
        end
        table_insert(Interface.MenuComponents[column], cp)
    end

    AddToggle("Aimbot Master", false, function(v) 
        AimSettings.Active = v 
        CustomNotify("AIMBOT", v and "ENABLED" or "DISABLED")
    end, "left", 60)
    AddToggle("Wall Check", false, function(v) AimSettings.WallCheck = v end, "left", 85)
    AddToggle("Ignore Sleepers", false, function(v) AimSettings.SleeperCheck = v end, "left", 110)
    AddButton("Target: " .. AimSettings.TargetArea, function(obj) 
        AimSettings.TargetArea = (AimSettings.TargetArea == "Head") and "LowerTorso" or "Head"
        obj.label.Text = "Target: " .. AimSettings.TargetArea
    end, "left", 140)
    AddSlider("FOV Diameter", 20, 400, 80, function(v) AimSettings.FOVSize = v end, "left", 180)
    AddSlider("Smooth Factor", 1, 30, 5, function(v) AimSettings.Smoothness = v end, "left", 230)

    AddToggle("Player ESP", false, function(v) 
        VisualSettings.PlayerESP = v 
        CustomNotify("PLAYER ESP", v and "ENABLED" or "DISABLED")
    end, "right", 60)
    AddToggle("Box ESP", false, function(v) VisualSettings.BoxESP = v end, "right", 85)
    AddToggle("Info ESP", false, function(v) VisualSettings.InfoESP = v end, "right", 110)
    AddToggle("Health ESP", false, function(v) VisualSettings.HealthESP = v end, "right", 135)
    AddToggle("Hide Sleepers", false, function(v) VisualSettings.SleeperCheck = v end, "right", 160)
    
    AddToggle("Stone ESP", false, function(v) 
        VisualSettings.StoneESP = v 
    end, "right", 195)
    AddToggle("Iron ESP", false, function(v) 
        VisualSettings.IronESP = v 
    end, "right", 220)
    AddToggle("Nitrate ESP", false, function(v) 
        VisualSettings.NitrateESP = v 
    end, "right", 245)
    AddColorPicker("Cheat Color (ESP)", function(c) VisualSettings.ESPColor = c end, "right", 275)
end)

local FOVCircle = CreateDrawing("Circle", { Thickness = 1, Color = AimSettings.FOVColor, Transparency = 0.5, Filled = false, Visible = false, NumSides = 64, ZIndex = 999 })

local function RemoveESP(obj)
    if ESPStorage[obj] then
        pcall(function() 
            ESPStorage[obj].Box.Visible = false
            ESPStorage[obj].Fill.Visible = false
            ESPStorage[obj].Dist.Visible = false
            ESPStorage[obj].HealthBg.Visible = false
            ESPStorage[obj].HealthBar.Visible = false
            ESPStorage[obj].Box:Remove() 
            ESPStorage[obj].Fill:Remove() 
            ESPStorage[obj].Dist:Remove() 
            ESPStorage[obj].HealthBg:Remove()
            ESPStorage[obj].HealthBar:Remove()
        end)
        ESPStorage[obj] = nil
    end
end

local function IsSleeper(model)
    local lt = model:FindFirstChild("LowerTorso")
    if lt then
        local rj = lt:FindFirstChild("RootRig")
        if rj and typeof(rj.CurrentAngle) == "number" and rj.CurrentAngle ~= 0 then return true end
    end
    return false
end

local function GetTridentHealth(model)
    local folders = {"Stats", "Data", "HealthFolder", "Values"}
    for _, fName in ipairs(folders) do
        local folder = model:FindFirstChild(fName)
        if folder then
            local hp = folder:FindFirstChild("Health") or folder:FindFirstChild("HP")
            local mhp = folder:FindFirstChild("MaxHealth") or folder:FindFirstChild("MaxHP")
            if hp and hp:IsA("NumberValue") then
                return hp.Value, (mhp and mhp.Value or 100)
            end
        end
    end
    local directHP = model:FindFirstChild("Health") or model:FindFirstChild("hp")
    if directHP and directHP:IsA("NumberValue") then
        return directHP.Value, 100
    end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health, hum.MaxHealth
    end
    return 100, 100
end

local function CheckWall(part)
    if not AimSettings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    local cast = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return not cast
end

task_spawn(function()
    while true do
        local p_tmp, r_tmp = {}, {}
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("LowerTorso")
                if root and obj.Name ~= LocalPlayer.Name then table_insert(p_tmp, obj) end
                local mesh = obj:FindFirstChildOfClass("MeshPart")
                if mesh and (mesh.MeshId == "rbxassetid://12939036056" or mesh.MeshId == "rbxassetid://13425026915") then
                    local isFound = false
                    for _, child in pairs(obj:GetChildren()) do
                        if child:IsA("BasePart") then
                            if child.Color == Color3fromRGB(248, 248, 248) then
                                table_insert(r_tmp, {model = obj, part = child, type = "Nitrate", color = Color3fromRGB(255, 255, 255)})
                                isFound = true break
                            elseif child.Color == Color3fromRGB(199, 172, 120) or child.Color == Color3fromRGB(255, 170, 80) then
                                table_insert(r_tmp, {model = obj, part = child, type = "Iron", color = Color3fromRGB(255, 170, 80)})
                                isFound = true break
                            end
                        end
                    end
                    if not isFound then table_insert(r_tmp, {model = obj, part = mesh, type = "Stone", color = Color3fromRGB(200, 200, 200)}) end
                end
            end
        end
        PlayerCache, ResourceCache = p_tmp, r_tmp
        task_wait(2.0 + math_random())
    end
end)

RunService.Heartbeat:Connect(function()
    if not Interface.Loaded then return end
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Visible = AimSettings.Active and AimSettings.ShowFOV
    FOVCircle.Radius = AimSettings.FOVSize
    FOVCircle.Position = mousePos
    FOVCircle.Color = AimSettings.FOVColor

    if Interface.Visible then
        if Interface.Moving then menuPosition = mousePos + dragStartOffset end
        if Interface.DraggingSlider then
            local el = Interface.DraggingSlider
            local sliderX = menuPosition.X + ((el.column == "left") and 20 or 265)
            local p = math_clamp((mousePos.X - sliderX) / 200, 0, 1)
            el.value = math_floor(el.min + (el.max - el.min) * p)
            el.valueText.Text = tostring(el.value)
            el.callback(el.value)
        end
        MainFrame.Position = menuPosition MainFrame.Visible = true
        BorderLine.Position = menuPosition BorderLine.Visible = true
        Header.Position = menuPosition Header.Visible = true
        HeaderTitle.Position = menuPosition + Vector2new(15, 10) HeaderTitle.Visible = true
        LeftPane.Position = menuPosition + Vector2new(10, 45) LeftPane.Visible = true
        RightPane.Position = menuPosition + Vector2new(255, 45) RightPane.Visible = true
        for col, elements in pairs(Interface.MenuComponents) do
            local xOff = (col == "left") and 20 or 265
            for _, el in ipairs(elements) do
                local pos = menuPosition + Vector2new(xOff, el.ypos)
                if el.type == "toggle" then
                    el.bg.Position = pos + Vector2new(0, 1)
                    el.label.Position = pos + Vector2new(20, 0)
                    el.bg.Color = el.state and Interface.AccentColor or Color3fromRGB(40, 40, 45)
                    el.bg.Visible, el.label.Visible = true, true
                elseif el.type == "slider" then
                    el.label.Position = pos
                    el.valueText.Position = pos + Vector2new(200 - el.valueText.TextBounds.X, 0)
                    el.bg.Position = pos + Vector2new(0, 18)
                    el.fill.Position = pos + Vector2new(0, 18)
                    el.fill.Size = Vector2new(((el.value - el.min) / (el.max - el.min)) * 200, 3)
                    el.label.Visible, el.valueText.Visible, el.bg.Visible, el.fill.Visible = true, true, true, true
                elseif el.type == "button" then
                    el.bg.Position = pos el.label.Position = pos + Vector2new(100, 2)
                    el.bg.Visible, el.label.Visible = true, true
                elseif el.type == "colorpicker" then
                    el.label.Position = pos el.preview.Position = pos + Vector2new(200 - 20, 2)
                    el.preview.Color = VisualSettings.ESPColor
                    el.label.Visible, el.preview.Visible = true, true
                    if Interface.ColorMenuOpen then
                        el.selectorBg.Position = el.preview.Position + Vector2new(-130, 15)
                        el.selectorBg.Visible = true
                        for i, box in ipairs(el.boxes) do
                            box.Position = el.selectorBg.Position + Vector2new(5 + (i-1) * 28, 7)
                            box.Visible = true
                        end
                    else el.selectorBg.Visible = false for _, b in ipairs(el.boxes) do b.Visible = false end end
                end
            end
        end
    else for _, obj in ipairs(Interface.UIComponents) do if obj ~= FOVCircle then obj.Visible = false end end end

    if not VisualSettings.PlayerESP then
        for p, _ in pairs(ESPStorage) do RemoveESP(p) end
    else
        for p, _ in pairs(ESPStorage) do
            if not p or not p.Parent or not (p:FindFirstChild("LowerTorso") or p:FindFirstChild("HumanoidRootPart")) then
                RemoveESP(p)
            end
        end

        for _, p in ipairs(PlayerCache) do
            local root = p:FindFirstChild("LowerTorso") or p:FindFirstChild("HumanoidRootPart")
            if root and root.Parent then
                local sleeper = IsSleeper(p)
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                if dist < VisualSettings.MaxDistance and not (VisualSettings.SleeperCheck and sleeper) then
                    local sPos, onS = Camera:WorldToViewportPoint(root.Position)
                    if onS then
                        if not ESPStorage[p] then
                            ESPStorage[p] = {
                                Box = CreateDrawing("Square", {Thickness = 1, Filled = false, ZIndex = 2}),
                                Fill = CreateDrawing("Square", {Thickness = 0, Filled = true, Transparency = 0.3, ZIndex = 1}),
                                Dist = CreateDrawing("Text", {Size = 13, Center = true, ZIndex = 3}),
                                HealthBg = CreateDrawing("Square", {Thickness = 1, Filled = true, Color = Color3fromRGB(0,0,0), ZIndex = 2}),
                                HealthBar = CreateDrawing("Square", {Thickness = 1, Filled = true, Color = Color3fromRGB(0,255,0), ZIndex = 3})
                            }
                        end
                        local esp = ESPStorage[p]
                        local bX, bY = 3200/sPos.Z, 4800/sPos.Z
                        local bPos = Vector2new(sPos.X - bX/2, sPos.Y - bY/2)
                        
                        esp.Box.Visible = VisualSettings.BoxESP
                        esp.Box.Size = Vector2new(bX, bY)
                        esp.Box.Position = bPos
                        esp.Box.Color = VisualSettings.ESPColor
                        
                        esp.Fill.Visible = VisualSettings.BoxESP
                        esp.Fill.Size = esp.Box.Size
                        esp.Fill.Position = esp.Box.Position
                        esp.Fill.Color = VisualSettings.ESPColor
                        
                        esp.Dist.Visible = VisualSettings.InfoESP
                        esp.Dist.Text = string_format("[%dm]%s", dist, sleeper and " SLEEP" or "")
                        esp.Dist.Position = Vector2new(sPos.X, sPos.Y + bY/2 + 2)
                        esp.Dist.Color = VisualSettings.ESPColor
                        
                        local curH, maxH = GetTridentHealth(p)
                        local healthPercent = math_clamp(curH / maxH, 0, 1)
                        
                        esp.HealthBg.Visible = VisualSettings.HealthESP
                        esp.HealthBg.Size = Vector2new(2, bY)
                        esp.HealthBg.Position = bPos - Vector2new(5, 0)
                        
                        esp.HealthBar.Visible = VisualSettings.HealthESP
                        esp.HealthBar.Size = Vector2new(1, bY * healthPercent)
                        esp.HealthBar.Position = esp.HealthBg.Position + Vector2new(1, bY - (bY * healthPercent))
                        esp.HealthBar.Color = Color3fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
                        
                    elseif ESPStorage[p] then 
                        ESPStorage[p].Box.Visible = false 
                        ESPStorage[p].Fill.Visible = false 
                        ESPStorage[p].Dist.Visible = false 
                        ESPStorage[p].HealthBg.Visible = false
                        ESPStorage[p].HealthBar.Visible = false
                    end
                elseif ESPStorage[p] then RemoveESP(p) end
            elseif ESPStorage[p] then RemoveESP(p) end
        end
    end

    for _, res in ipairs(ResourceCache) do
        local enabled = (res.type == "Stone" and VisualSettings.StoneESP) or (res.type == "Iron" and VisualSettings.IronESP) or (res.type == "Nitrate" and VisualSettings.NitrateESP)
        if enabled then
            local dist = (Camera.CFrame.Position - res.part.Position).Magnitude
            if dist < VisualSettings.MaxDistance then
                local sPos, onS = Camera:WorldToViewportPoint(res.part.Position)
                if onS then
                    if not ResourceStorage[res.part] then ResourceStorage[res.part] = CreateDrawing("Text", {Size = 13, Center = true, Color = res.color, Outline = false, ZIndex = 1}) end
                    ResourceStorage[res.part].Visible = true
                    ResourceStorage[res.part].Text = string_format("%s [%dm]", res.type, dist)
                    ResourceStorage[res.part].Position = Vector2new(sPos.X, sPos.Y)
                elseif ResourceStorage[res.part] then ResourceStorage[res.part].Visible = false end
            elseif ResourceStorage[res.part] then ResourceStorage[res.part].Visible = false end
        elseif ResourceStorage[res.part] then ResourceStorage[res.part].Visible = false end
    end

    if AimSettings.Active and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target, minMag = nil, AimSettings.FOVSize
        for _, p in ipairs(PlayerCache) do
            if p.Parent and not (AimSettings.SleeperCheck and IsSleeper(p)) then
                local part = p:FindFirstChild(AimSettings.TargetArea)
                if part then
                    local targetPos = part.Position
                    if AimSettings.TargetArea == "LowerTorso" then
                        targetPos = targetPos + Vector3.new(0, 0.6, 0)
                    end
                    local sPos, onS = Camera:WorldToViewportPoint(targetPos)
                    if onS then
                        local mag = (Vector2new(sPos.X, sPos.Y) - mousePos).Magnitude
                        if mag < minMag and CheckWall(part) then minMag = mag target = sPos end
                    end
                end
            end
        end
        if target then 
            local smooth = (AimSettings.Smoothness * 2) + (math_random(-20, 20) / 10)
            mousemoverel((target.X - mousePos.X)/smooth, (target.Y - mousePos.Y)/smooth) 
        end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then Interface.Visible = not Interface.Visible end
    if not Interface.Visible then return end
    local m = UserInputService:GetMouseLocation()
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if m.Y < menuPosition.Y + 40 then Interface.Moving = true dragStartOffset = menuPosition - m return end
        for col, elements in pairs(Interface.MenuComponents) do
            for _, el in ipairs(elements) do
                local pos = menuPosition + Vector2new((col == "left" and 20 or 265), el.ypos)
                if el.type == "toggle" and m.X > pos.X and m.X < pos.X + 200 and m.Y > pos.Y and m.Y < pos.Y + 15 then
                    el.state = not el.state el.callback(el.state)
                elseif el.type == "slider" and m.X > pos.X and m.X < pos.X + 200 and m.Y > pos.Y + 15 and m.Y < pos.Y + 25 then
                    Interface.DraggingSlider = el
                elseif el.type == "button" and m.X > pos.X and m.X < pos.X + 200 and m.Y > pos.Y and m.Y < pos.Y + 20 then
                    el.callback(el)
                elseif el.type == "colorpicker" then
                    if m.X > pos.X + 170 and m.X < pos.X + 200 and m.Y > pos.Y and m.Y < pos.Y + 15 then 
                        Interface.ColorMenuOpen = not Interface.ColorMenuOpen 
                    elseif Interface.ColorMenuOpen then
                        for i, box in ipairs(el.boxes) do
                            if m.X > box.Position.X and m.X < box.Position.X + 20 and m.Y > box.Position.Y and m.Y < box.Position.Y + 15 then
                                el.callback(box.Color) Interface.ColorMenuOpen = false return
                            end
                        end
                    end
                end
            end
        end
    end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Interface.Moving = false Interface.DraggingSlider = nil end end)
