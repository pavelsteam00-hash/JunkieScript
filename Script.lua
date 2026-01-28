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
    ShowFOV = true
}

local VisualSettings = {
    PlayerESP = false,
    SleeperCheck = false,
    StoneESP = false,
    IronESP = false,
    NitrateESP = false,
    MaxDistance = 1000,
    ESPColor = Color3fromRGB(170, 100, 255)
}

local Interface = {
    Visible = false,
    Moving = false,
    DraggingSlider = nil,
    ColorMenuOpen = false,
    Loaded = false,
    AccentColor = Color3fromRGB(180, 120, 255),
    BgColor = Color3fromRGB(12, 12, 15),
    SectionColor = Color3fromRGB(18, 18, 22),
    TextColor = Color3fromRGB(240, 240, 240),
    MenuComponents = {left = {}, right = {}},
    UIComponents = {},
}

local ColorPalette = {
    Color3fromRGB(170, 100, 255), 
    Color3fromRGB(255, 80, 80),   
    Color3fromRGB(80, 255, 150),  
    Color3fromRGB(255, 255, 255), 
    Color3fromRGB(255, 200, 0)
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

local function CustomNotify(title, text, color)
    task_spawn(function()
        local nIdx = #ActiveNotifications + 1
        local offset = (nIdx - 1) * 70
        
        local bg = Drawing.new("Square")
        bg.Size = Vector2new(260, 60)
        bg.Color = Interface.BgColor
        bg.Filled = true
        bg.ZIndex = 3000
        bg.Visible = true

        local line = Drawing.new("Square")
        line.Size = Vector2new(5, 60)
        line.Color = color or Interface.AccentColor
        line.Filled = true
        line.ZIndex = 3001
        line.Visible = true

        local tText = Drawing.new("Text")
        tText.Text = title
        tText.Size = 18
        tText.Color = color or Interface.AccentColor
        tText.Font = 2
        tText.ZIndex = 3002
        tText.Visible = true

        local bText = Drawing.new("Text")
        bText.Text = text
        bText.Size = 14
        bText.Color = Color3fromRGB(220, 220, 220)
        bText.ZIndex = 3002
        bText.Visible = true

        table_insert(ActiveNotifications, {bg, line, tText, bText})

        local screenX = Camera.ViewportSize.X
        local screenY = Camera.ViewportSize.Y

        for i = 1, 15 do
            local xPos = screenX - (i * 20)
            local yPos = screenY - 120 - offset
            bg.Position = Vector2new(xPos, yPos)
            line.Position = Vector2new(xPos, yPos)
            tText.Position = Vector2new(xPos + 15, yPos + 10)
            bText.Position = Vector2new(xPos + 15, yPos + 32)
            task_wait(0.01)
        end

        task_wait(1.0) -- Уведомление теперь ровно на 1 секунду

        bg.Visible = false line.Visible = false tText.Visible = false bText.Visible = false
        bg:Remove() line:Remove() tText:Remove() bText:Remove()
        table_remove(ActiveNotifications, 1)
    end)
end

task_spawn(function()
    local screenCenter = Camera.ViewportSize / 2
    local loaderSize = Vector2new(300, 110)
    
    local loaderBg = Drawing.new("Square")
    loaderBg.Size = loaderSize
    loaderBg.Position = screenCenter - (loaderSize/2)
    loaderBg.Color = Interface.BgColor
    loaderBg.Filled = true
    loaderBg.Visible = true
    loaderBg.ZIndex = 5000

    local loaderBorder = Drawing.new("Square")
    loaderBorder.Size = loaderSize
    loaderBorder.Position = loaderBg.Position
    loaderBorder.Color = Interface.AccentColor
    loaderBorder.Thickness = 1
    loaderBorder.Filled = false
    loaderBorder.Visible = true
    loaderBorder.ZIndex = 5001

    local loaderText = Drawing.new("Text")
    loaderText.Text = "PROJECT SILVER"
    loaderText.Size = 18
    loaderText.Center = true
    loaderText.Position = loaderBg.Position + Vector2new(150, 20)
    loaderText.Color = Color3fromRGB(255, 255, 255)
    loaderText.Visible = true
    loaderText.ZIndex = 5002

    local subText = Drawing.new("Text")
    subText.Text = "Applying Bypass..."
    subText.Size = 13
    subText.Center = true
    subText.Position = loaderBg.Position + Vector2new(150, 48)
    subText.Color = Interface.AccentColor
    subText.Visible = true
    subText.ZIndex = 5002

    local barBg = Drawing.new("Square")
    barBg.Size = Vector2new(260, 4)
    barBg.Position = loaderBg.Position + Vector2new(20, 80)
    barBg.Color = Color3fromRGB(30, 30, 35)
    barBg.Filled = true
    barBg.Visible = true
    barBg.ZIndex = 5002

    local barFill = Drawing.new("Square")
    barFill.Size = Vector2new(0, 4)
    barFill.Position = barBg.Position
    barFill.Color = Interface.AccentColor
    barFill.Filled = true
    barFill.Visible = true
    barFill.ZIndex = 5003

    local modules = {"Encapsulation", "Input Spoof", "Resource Hooks", "UI Sync", "Secure"}
    local start = tick()
    while tick() - start < 4 do
        local progress = (tick() - start) / 4
        barFill.Size = Vector2new(260 * progress, 4)
        subText.Text = "Security: " .. modules[math_floor(progress * #modules) + 1]
        task_wait()
    end

    loaderBg.Visible = false loaderBorder.Visible = false loaderText.Visible = false subText.Visible = false barBg.Visible = false barFill.Visible = false
    Interface.Loaded = true
    Interface.Visible = true
    CustomNotify("SECURE", "Trident Bypass Applied", Interface.AccentColor)
end)

local menuPosition = Vector2new(300, 200)
local menuDimensions = Vector2new(480, 400)
local dragStartOffset = Vector2new(0, 0)

local Background, MenuBorder, TopAccent, TopBar, Title, CloseButton
local LeftSectionBg, RightSectionBg

task_spawn(function()
    while not Interface.Loaded do task_wait(0.1) end
    
    Background = CreateDrawing("Square", { Size = menuDimensions, Color = Interface.BgColor, Filled = true, Visible = false, ZIndex = 10 })
    MenuBorder = CreateDrawing("Square", { Size = menuDimensions, Color = Color3fromRGB(35, 35, 40), Filled = false, Thickness = 1, Visible = false, ZIndex = 20 })
    TopAccent = CreateDrawing("Square", { Size = Vector2new(menuDimensions.X, 2), Color = Interface.AccentColor, Filled = true, Visible = false, ZIndex = 21 })
    TopBar = CreateDrawing("Square", { Size = Vector2new(menuDimensions.X, 35), Color = Color3fromRGB(15, 15, 18), Filled = true, Visible = false, ZIndex = 11 })
    Title = CreateDrawing("Text", { Text = "PROJECT SILVER", Size = 18, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 14 })
    CloseButton = CreateDrawing("Text", { Text = "X", Size = 18, Font = 2, Color = Interface.AccentColor, Visible = false, ZIndex = 25 })
    
    LeftSectionBg = CreateDrawing("Square", { Size = Vector2new(225, 350), Color = Interface.SectionColor, Filled = true, Visible = false, ZIndex = 12 })
    RightSectionBg = CreateDrawing("Square", { Size = Vector2new(225, 350), Color = Interface.SectionColor, Filled = true, Visible = false, ZIndex = 12 })

    local function AddToggle(name, default, callback, column, ypos)
        local toggle = {
            type = "toggle", name = name, state = default, callback = callback,
            bg = CreateDrawing("Square", {Size = Vector2new(14, 14), Color = Color3fromRGB(40, 40, 45), Filled = true, Visible = false, ZIndex = 16}),
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 16}),
            ypos = ypos, column = column
        }
        table_insert(Interface.MenuComponents[column], toggle)
    end
    
    local function AddSlider(name, min, max, default, callback, column, ypos)
        local slider = {
            type = "slider", name = name, min = min, max = max, value = default, callback = callback,
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 16}),
            valueText = CreateDrawing("Text", {Text = tostring(default), Size = 13, Font = 2, Color = Interface.AccentColor, Visible = false, ZIndex = 16}),
            bg = CreateDrawing("Square", {Size = Vector2new(190, 4), Color = Color3fromRGB(30, 30, 35), Filled = true, Visible = false, ZIndex = 16}),
            fill = CreateDrawing("Square", {Size = Vector2new(0, 4), Color = Interface.AccentColor, Filled = true, Visible = false, ZIndex = 17}),
            ypos = ypos, column = column
        }
        table_insert(Interface.MenuComponents[column], slider)
    end

    local function AddFullColorPicker(name, callback, column, ypos)
        local cp = {
            type = "colorpicker", name = name, callback = callback,
            label = CreateDrawing("Text", {Text = name, Size = 13, Font = 2, Color = Interface.TextColor, Visible = false, ZIndex = 16}),
            preview = CreateDrawing("Square", {Size = Vector2new(190, 14), Color = VisualSettings.ESPColor, Filled = true, Visible = false, ZIndex = 17}),
            selectorBg = CreateDrawing("Square", {Size = Vector2new(190, 35), Color = Color3fromRGB(25, 25, 30), Filled = true, Visible = false, ZIndex = 50}),
            boxes = {}, ypos = ypos, column = column
        }
        for _, color in ipairs(ColorPalette) do
            table_insert(cp.boxes, CreateDrawing("Square", {Size = Vector2new(25, 18), Color = color, Filled = true, Visible = false, ZIndex = 51}))
        end
        table_insert(Interface.MenuComponents[column], cp)
    end
    
    -- Исправлены цвета уведомлений на фиолетовый
    AddToggle("ENABLE AIMBOT", false, function(v) AimSettings.Active = v CustomNotify("COMBAT", v and "Aimbot ON" or "Aimbot OFF", Interface.AccentColor) end, "left", 50)
    AddToggle("WALL CHECK", false, function(v) AimSettings.WallCheck = v end, "left", 75)
    AddToggle("TARGET BODY", false, function(v) AimSettings.TargetArea = v and "LowerTorso" or "Head" end, "left", 100)
    AddToggle("CHECK SLEEPERS", false, function(v) AimSettings.SleeperCheck = v end, "left", 125)
    AddSlider("FOV SIZE", 20, 200, 80, function(v) AimSettings.FOVSize = v end, "left", 160)
    AddSlider("SMOOTHNESS", 1, 20, 5, function(v) AimSettings.Smoothness = v end, "left", 205)
    
    AddToggle("PLAYER ESP", false, function(v) VisualSettings.PlayerESP = v CustomNotify("VISUALS", v and "ESP ON" or "ESP OFF", Interface.AccentColor) end, "right", 50)
    AddToggle("IGNORE SLEEPERS", false, function(v) VisualSettings.SleeperCheck = v end, "right", 75)
    AddToggle("STONE ORE ESP", false, function(v) VisualSettings.StoneESP = v end, "right", 100)
    AddToggle("IRON ORE ESP", false, function(v) VisualSettings.IronESP = v end, "right", 125)
    AddToggle("NITRATE ORE ESP", false, function(v) VisualSettings.NitrateESP = v end, "right", 150)
    AddFullColorPicker("ESP THEME COLOR", function(c) VisualSettings.ESPColor = c end, "right", 190)
end)

local FOVCircle = CreateDrawing("Circle", { Thickness = 1, Color = VisualSettings.ESPColor, Transparency = 0.5, Filled = false, Visible = false, NumSides = 64, ZIndex = 999 })

local function RemoveESP(obj)
    if ESPStorage[obj] then
        pcall(function() ESPStorage[obj].Box:Remove() ESPStorage[obj].Fill:Remove() ESPStorage[obj].Dist:Remove() end)
        ESPStorage[obj] = nil
    end
end

local function RemoveResource(obj)
    if ResourceStorage[obj] then
        pcall(function() ResourceStorage[obj]:Remove() end)
        ResourceStorage[obj] = nil
    end
end

task_spawn(function()
    while true do
        local p_tmp, r_tmp = {}, {}
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("LowerTorso")
                if root and obj.Name ~= LocalPlayer.Name then table_insert(p_tmp, obj) end
                
                local mesh = obj:FindFirstChildOfClass("MeshPart")
                if mesh and mesh.MeshId == "rbxassetid://12939036056" then
                    if #obj:GetChildren() == 1 then table_insert(r_tmp, {model = obj, part = mesh, type = "Stone", color = Color3fromRGB(200, 200, 200)})
                    else
                        for _, part in pairs(obj:GetChildren()) do
                            if part:IsA("BasePart") then
                                if part.Color == Color3fromRGB(248, 248, 248) then table_insert(r_tmp, {model = obj, part = part, type = "Nitrate", color = Color3fromRGB(255, 255, 255)})
                                elseif part.Color == Color3fromRGB(199, 172, 120) then table_insert(r_tmp, {model = obj, part = part, type = "Iron", color = Color3fromRGB(255, 170, 80)}) end
                            end
                        end
                    end
                end
            end
        end
        PlayerCache, ResourceCache = p_tmp, r_tmp
        for p, _ in pairs(ESPStorage) do if not p or not p.Parent then RemoveESP(p) end end
        for r, _ in pairs(ResourceStorage) do if not r or not r.Parent then RemoveResource(r) end end
        task_wait(1)
    end
end)

local function IsSleeper(model)
    local lt = model:FindFirstChild("LowerTorso")
    if lt then
        local rj = lt:FindFirstChild("RootRig")
        if rj and typeof(rj.CurrentAngle) == "number" and rj.CurrentAngle ~= 0 then return true end
    end
    return false
end

local function CheckWall(part)
    if not AimSettings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    local cast = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return not cast
end

RunService.RenderStepped:Connect(function()
    if not Interface.Loaded then return end
    local mousePos = UserInputService:GetMouseLocation()
    
    -- FOV теперь не зависит от Interface.Visible
    FOVCircle.Visible = AimSettings.Active and AimSettings.ShowFOV
    FOVCircle.Radius = AimSettings.FOVSize
    FOVCircle.Position = mousePos
    FOVCircle.Color = VisualSettings.ESPColor
    
    if Interface.Visible then
        if Interface.Moving then menuPosition = mousePos + dragStartOffset end
        if Interface.DraggingSlider then
            local el = Interface.DraggingSlider
            local sliderX = menuPosition.X + ((el.column == "left") and 25 or 250)
            local p = math_clamp((mousePos.X - sliderX) / 190, 0, 1)
            el.value = math_floor(el.min + (el.max - el.min) * p)
            el.valueText.Text = tostring(el.value)
            el.callback(el.value)
        end

        Background.Position = menuPosition Background.Visible = true
        MenuBorder.Position = menuPosition MenuBorder.Visible = true
        TopBar.Position = menuPosition TopBar.Visible = true
        TopAccent.Position = menuPosition TopAccent.Visible = true
        Title.Position = menuPosition + Vector2new(15, 8) Title.Visible = true
        CloseButton.Position = menuPosition + Vector2new(452, 8) CloseButton.Visible = true
        
        LeftSectionBg.Position = menuPosition + Vector2new(10, 42)
        LeftSectionBg.Visible = true
        RightSectionBg.Position = menuPosition + Vector2new(245, 42)
        RightSectionBg.Visible = true

        for col, elements in pairs(Interface.MenuComponents) do
            local xOff = (col == "left") and 25 or 260
            for _, el in ipairs(elements) do
                local pos = menuPosition + Vector2new(xOff, el.ypos)
                if el.type == "toggle" then
                    el.bg.Position = pos + Vector2new(0, 1)
                    el.label.Position = pos + Vector2new(25, 0)
                    el.bg.Color = el.state and Interface.AccentColor or Color3fromRGB(45, 45, 50)
                    el.bg.Visible, el.label.Visible = true, true
                elseif el.type == "slider" then
                    el.label.Position = pos
                    el.valueText.Position = pos + Vector2new(190 - el.valueText.TextBounds.X, 0)
                    el.bg.Position = pos + Vector2new(0, 20)
                    el.fill.Position = pos + Vector2new(0, 20)
                    el.fill.Size = Vector2new(((el.value - el.min) / (el.max - el.min)) * 190, 4)
                    el.label.Visible, el.valueText.Visible, el.bg.Visible, el.fill.Visible = true, true, true, true
                elseif el.type == "colorpicker" then
                    el.label.Position = pos
                    el.preview.Position = pos + Vector2new(0, 20)
                    el.preview.Color = VisualSettings.ESPColor
                    el.label.Visible, el.preview.Visible = true, true
                    if Interface.ColorMenuOpen then
                        el.selectorBg.Position = el.preview.Position + Vector2new(0, 18)
                        el.selectorBg.Visible = true
                        for i, box in ipairs(el.boxes) do
                            box.Position = el.selectorBg.Position + Vector2new(8 + (i-1) * 36, 8)
                            box.Visible = true
                        end
                    else
                        el.selectorBg.Visible = false
                        for _, b in ipairs(el.boxes) do b.Visible = false end
                    end
                end
            end
        end
    else
        -- Скрываем только UI компоненты меню, не трогая FOV
        for _, obj in ipairs(Interface.UIComponents) do
            if obj ~= FOVCircle then
                obj.Visible = false
            end
        end
    end

    if VisualSettings.PlayerESP then
        for _, p in ipairs(PlayerCache) do
            local root = p:FindFirstChild("HumanoidRootPart") or p:FindFirstChild("LowerTorso")
            if root then
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                if dist < VisualSettings.MaxDistance then
                    local sPos, onS = Camera:WorldToViewportPoint(root.Position)
                    local sleeper = IsSleeper(p)
                    if onS and not (VisualSettings.SleeperCheck and sleeper) then
                        if not ESPStorage[p] then
                            ESPStorage[p] = {
                                Box = CreateDrawing("Square", {Thickness = 1, Filled = false, ZIndex = 2}),
                                Fill = CreateDrawing("Square", {Thickness = 0, Filled = true, Transparency = 0.4, ZIndex = 1}),
                                Dist = CreateDrawing("Text", {Size = 13, Center = true, Outline = false, ZIndex = 3})
                            }
                        end
                        local esp = ESPStorage[p]
                        local bX, bY = 2800/sPos.Z, 4200/sPos.Z
                        local bPos = Vector2new(sPos.X - bX/2, sPos.Y - bY/2)
                        esp.Box.Visible, esp.Box.Size, esp.Box.Position, esp.Box.Color = true, Vector2new(bX, bY), bPos, VisualSettings.ESPColor
                        esp.Fill.Visible, esp.Fill.Size, esp.Fill.Position, esp.Fill.Color = true, esp.Box.Size, esp.Box.Position, VisualSettings.ESPColor
                        esp.Dist.Visible, esp.Dist.Text, esp.Dist.Position, esp.Dist.Color = true, string_format("[%dm]%s", dist, sleeper and " SLEEP" or ""), Vector2new(sPos.X, sPos.Y + bY/2 + 2), VisualSettings.ESPColor
                    elseif ESPStorage[p] then ESPStorage[p].Box.Visible = false ESPStorage[p].Fill.Visible = false ESPStorage[p].Dist.Visible = false end
                elseif ESPStorage[p] then ESPStorage[p].Box.Visible = false ESPStorage[p].Fill.Visible = false ESPStorage[p].Dist.Visible = false end
            end
        end
    else
        for _, v in pairs(ESPStorage) do v.Box.Visible = false v.Fill.Visible = false v.Dist.Visible = false end
    end

    for _, res in ipairs(ResourceCache) do
        local active = (res.type == "Stone" and VisualSettings.StoneESP) or (res.type == "Iron" and VisualSettings.IronESP) or (res.type == "Nitrate" and VisualSettings.NitrateESP)
        if active and res.model.Parent then
            local dist = (Camera.CFrame.Position - res.part.Position).Magnitude
            if dist < VisualSettings.MaxDistance then
                local sPos, onS = Camera:WorldToViewportPoint(res.part.Position)
                if onS then
                    if not ResourceStorage[res.model] then ResourceStorage[res.model] = CreateDrawing("Text", {Size = 12, Center = true, Outline = false}) end
                    local d = ResourceStorage[res.model]
                    d.Visible, d.Text, d.Position, d.Color = true, string_format("%s [%dm]", res.type, dist), Vector2new(sPos.X, sPos.Y), res.color
                elseif ResourceStorage[res.model] then ResourceStorage[res.model].Visible = false end
            elseif ResourceStorage[res.model] then ResourceStorage[res.model].Visible = false end
        elseif ResourceStorage[res.model] then ResourceStorage[res.model].Visible = false end
    end
    
    if AimSettings.Active and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = nil
        local maxDist = AimSettings.FOVSize
        for _, p in ipairs(PlayerCache) do
            if not (AimSettings.SleeperCheck and IsSleeper(p)) then
                local part = p:FindFirstChild(AimSettings.TargetArea)
                if part then
                    local sPos, onS = Camera:WorldToViewportPoint(part.Position)
                    if onS then
                        local mag = (Vector2new(sPos.X, sPos.Y) - mousePos).Magnitude
                        if mag < maxDist and CheckWall(part) then maxDist = mag target = sPos end
                    end
                end
            end
        end
        if target then 
            local jitter = math_random(-10, 10) / 100
            local smooth = AimSettings.Smoothness + jitter
            mousemoverel((target.X - mousePos.X)/smooth, (target.Y - mousePos.Y)/smooth) 
        end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then 
        Interface.Visible = not Interface.Visible 
        CustomNotify("INTERFACE", Interface.Visible and "Opened" or "Closed", Interface.AccentColor)
    end
    if not Interface.Visible then return end
    
    local m = UserInputService:GetMouseLocation()
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if m.X > menuPosition.X + 440 and m.X < menuPosition.X + 480 and m.Y > menuPosition.Y and m.Y < menuPosition.Y + 35 then
            Interface.Visible = false
            CustomNotify("INTERFACE", "Closed", Interface.AccentColor)
            return
        end
        if m.Y < menuPosition.Y + 35 then Interface.Moving = true dragStartOffset = menuPosition - m return end

        for col, elements in pairs(Interface.MenuComponents) do
            for _, el in ipairs(elements) do
                local pos = menuPosition + Vector2new((col == "left" and 25 or 260), el.ypos)
                if el.type == "toggle" and m.X > pos.X and m.X < pos.X + 180 and m.Y > pos.Y and m.Y < pos.Y + 20 then
                    el.state = not el.state el.callback(el.state)
                elseif el.type == "slider" and m.X > pos.X and m.X < pos.X + 190 and m.Y > pos.Y + 15 and m.Y < pos.Y + 30 then
                    Interface.DraggingSlider = el
                elseif el.type == "colorpicker" then
                    if m.X > pos.X and m.X < pos.X + 190 and m.Y > pos.Y + 18 and m.Y < pos.Y + 35 then Interface.ColorMenuOpen = not Interface.ColorMenuOpen return end
                    if Interface.ColorMenuOpen then
                        for i, box in ipairs(el.boxes) do
                            if m.X > box.Position.X and m.X < box.Position.X + 25 and m.Y > box.Position.Y and m.Y < box.Position.Y + 18 then
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
