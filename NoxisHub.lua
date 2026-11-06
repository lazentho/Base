--[[
    NOXIS HUB · menu base  (single file, no assets required)

    Usage
        local Hub = loadstring(game:HttpGet('<raw url>'))()

        local page = Hub:Page('Shop', 'SH')
        page:Sub('Buy dice and upgrades')
        local sec = page:Section('DICE SHOP')

        sec:Toggle  ({ title = 'Auto buy', desc = 'Buys the best affordable dice', value = false, callback = function(v) end })
        sec:Button  ({ title = 'Buy now', desc = 'One manual purchase', text = 'BUY', callback = function() end })
        sec:Input   ({ title = 'Max price', placeholder = '1000', numeric = true, callback = function(v) end })
        sec:Slider  ({ title = 'Interval', min = 0.3, max = 3, step = 0.1, value = 0.8, suffix = 's', callback = function(v) end })
        sec:Dropdown({ title = 'Mode', options = { 'A', 'B' }, value = 'A', callback = function(v) end })
        sec:Keybind ({ title = 'Hotkey', value = Enum.KeyCode.B, callback = function(k) end })
        sec:Label   ({ title = 'Status', value = 'idle' })

        Hub:Notify('Loaded', 'success')
        Hub:Destroy()

    Everything below the DEMO line is sample content. Replace it with per-game pages.
]]

local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

local LP = Players.LocalPlayer

local previous = getgenv().NOXIS
if previous and type(previous.Destroy) == 'function' then
    pcall(previous.Destroy, previous)
end

local NOXIS, Page, Section = {}, {}, {}
NOXIS.__index = NOXIS
Page.__index = Page
Section.__index = Section

local C = {
    window  = Color3.fromRGB(13, 10, 20),
    sidebar = Color3.fromRGB(17, 13, 27),
    card    = Color3.fromRGB(24, 19, 36),
    cardHi  = Color3.fromRGB(30, 24, 45),
    field   = Color3.fromRGB(12, 9, 19),
    navBg   = Color3.fromRGB(27, 21, 48),
    line    = Color3.fromRGB(40, 32, 58),
    text    = Color3.fromRGB(236, 233, 245),
    dim     = Color3.fromRGB(150, 144, 170),
    faint   = Color3.fromRGB(98, 91, 118),
    accent  = Color3.fromRGB(139, 102, 255),
    accent2 = Color3.fromRGB(196, 167, 255),
    gradA   = Color3.fromRGB(160, 118, 255),
    gradB   = Color3.fromRGB(103, 76, 255),
    teal    = Color3.fromRGB(63, 216, 190),
    amber   = Color3.fromRGB(250, 190, 80),
    red     = Color3.fromRGB(255, 96, 110),
    white   = Color3.fromRGB(255, 255, 255),
}

local F = {
    black = Enum.Font.GothamBlack,
    bold  = Enum.Font.GothamBold,
    med   = Enum.Font.GothamMedium,
    text  = Enum.Font.Gotham,
    mono  = Enum.Font.Code,
}

local KEY_SHORT = {
    RightShift = 'RShift', LeftShift = 'LShift',
    RightControl = 'RCtrl', LeftControl = 'LCtrl',
    RightAlt = 'RAlt', LeftAlt = 'LAlt',
    Backspace = 'Bksp', Return = 'Enter', Escape = 'Esc',
    CapsLock = 'Caps', Space = 'Space', Insert = 'Ins',
    Delete = 'Del', PageUp = 'PgUp', PageDown = 'PgDn',
}

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(parent, radius)
    local c = make('UICorner', {}, parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = make('UIStroke', {}, parent)
    s.Color = color or C.line
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function tween(inst, time, props, style)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(time or 0.14, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function label(props, parent)
    local base = {
        BackgroundTransparency = 1,
        Font = F.med,
        TextSize = 12,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = '',
        RichText = false,
    }
    for k, v in pairs(props or {}) do base[k] = v end
    return make('TextLabel', base, parent)
end

local function hex(color)
    return string.format('%02X%02X%02X',
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5))
end

local function keyName(key)
    if not key then return '—' end
    return KEY_SHORT[key.Name] or tostring(key.Name)
end

local function inside(gui, pos)
    if not gui or not gui.Visible then return false end
    local ap = gui.AbsolutePosition
    local sz = gui.AbsoluteSize
    return pos.X >= ap.X and pos.X <= ap.X + sz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + sz.Y
end

local function fire(cb, ...)
    if type(cb) ~= 'function' then return end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn('[NOXIS] callback error: ' .. tostring(err))
    end
end

local function viewport()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X > 0 then
        return cam.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

function NOXIS.new(config)
    local cfg = config or {}
    local self = setmetatable({}, NOXIS)

    self.Name = cfg.Name or 'NOXIS'
    self.Subtitle = cfg.Subtitle or 'HUB'
    self.Version = cfg.Version or 'v1.0'
    self.W = cfg.Width or 840
    self.H = cfg.Height or 560
    self.Key = cfg.Key or Enum.KeyCode.RightShift
    self.NotifyDuration = cfg.NotifyDuration or 3.5
    self.ScalePref = 1
    self.NoNotifications = false

    self._conns = {}
    self._store = {}
    self._pages = {}
    self._pageById = {}
    self._openPopup = nil
    self._listening = nil
    self._notifSlot = 0
    self._destroyed = false

    local clean = (tostring(self.Name):gsub('%s+', '_'):gsub('[^%w_]', ''))
    self._file = 'NOXIS_' .. clean .. '.cfg'

    self:_loadStore()

    if self._store.__key then
        local want = Enum.KeyCode[self._store.__key]
        if want then self.Key = want end
    end

    self:_build()
    return self
end

function NOXIS:_conn(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self._conns, c)
    return c
end

function NOXIS:_loadStore()
    pcall(function()
        if type(isfile) ~= 'function' or type(readfile) ~= 'function' then return end
        if not isfile(self._file) then return end
        local raw = readfile(self._file)
        if type(raw) ~= 'string' then return end
        for line in raw:gmatch('[^\r\n]+') do
            local k, v = line:match('^([%w_%-%.]+)=(.*)$')
            if k then
                self._store[k] = (v:match('^%s*(.-)%s*$'))
            end
        end
    end)
end

function NOXIS:_save()
    pcall(function()
        if type(writefile) ~= 'function' then return end
        local keys = {}
        for k in pairs(self._store) do table.insert(keys, k) end
        table.sort(keys)
        local out = {}
        for _, k in ipairs(keys) do
            table.insert(out, tostring(k) .. '=' .. tostring(self._store[k]))
        end
        writefile(self._file, table.concat(out, '\n'))
    end)
end

function NOXIS:_build()
    local vp = viewport()

    local gui = make('ScreenGui', {
        Name = 'NOXIS_HUB',
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 10000,
        IgnoreGuiInset = false,
    }, (function()
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
        return LP:WaitForChild('PlayerGui')
    end)())
    self.Gui = gui

    local win = make('Frame', {
        Name = 'Window',
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(math.floor(vp.X / 2), math.floor(vp.Y / 2)),
        Size = UDim2.fromOffset(self.W, self.H),
        BackgroundColor3 = C.window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    corner(win, 16)
    stroke(win, C.line, 1, 0.15)
    self.Window = win

    self.Scale = make('UIScale', { Scale = 1 }, win)

    local cam = workspace.CurrentCamera
    if cam then
        self:_conn(cam:GetPropertyChangedSignal('ViewportSize'), function()
            self:_fit()
        end)
    end

    self:_buildSidebar()
    self:_buildContent()
    self:_buildNotifs()
    self:_bindInput()
    self:_fit()

    task.defer(function()
        self:_center()
    end)
end

function NOXIS:_center()
    if self._destroyed or not self.Window then return end
    local vp = viewport()
    self.Window.Position = UDim2.fromOffset(math.floor(vp.X / 2), math.floor(vp.Y / 2))
end

function NOXIS:_fit()
    local vp = viewport()
    local base = math.clamp(math.min(vp.X / 1000, vp.Y / 700), 0.7, 1.05)
    self.Scale.Scale = base * (self.ScalePref or 1)
end

function NOXIS:SetScale(mult)
    self.ScalePref = tonumber(mult) or 1
    self:_fit()
end

function NOXIS:_buildSidebar()
    local side = make('Frame', {
        Name = 'Sidebar',
        Size = UDim2.fromOffset(218, self.H),
        BackgroundColor3 = C.sidebar,
        BorderSizePixel = 0,
    }, self.Window)

    local sideCorner = make('UICorner', {}, side)
    sideCorner.TopLeftRadius = UDim.new(0, 16)
    sideCorner.BottomLeftRadius = UDim.new(0, 16)
    sideCorner.TopRightRadius = UDim.new(0, 0)
    sideCorner.BottomRightRadius = UDim.new(0, 0)

    make('Frame', {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
    }, side)

    local brand = make('Frame', {
        Name = 'Brand',
        Size = UDim2.new(1, -32, 0, 44),
        Position = UDim2.fromOffset(16, 14),
        BackgroundTransparency = 1,
        Active = true,
    }, side)
    self.Brand = brand

    local logo = make('Frame', {
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = C.gradA,
        BorderSizePixel = 0,
    }, brand)
    corner(logo, 12)
    make('UIGradient', {
        Color = ColorSequence.new(C.gradA, C.gradB),
        Rotation = 0,
    }, logo)
    stroke(logo, C.white, 1, 0.82)
    label({
        Text = 'N',
        Font = F.black,
        TextSize = 19,
        TextColor3 = C.white,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, logo)

    local title = label({
        Text = string.format('<font color="#%s">%s</font> <font color="#%s">%s</font>',
            hex(C.text), self.Name, hex(C.accent2), self.Subtitle),
        RichText = true,
        Font = F.bold,
        TextSize = 17,
        Size = UDim2.new(1, -52, 0, 20),
        Position = UDim2.fromOffset(52, 3),
    }, brand)
    self.TitleLabel = title

    self.BrandSub = label({
        Text = string.upper(('%s %s · %s'):format(self.Name, self.Subtitle, self.Version)),
        Font = F.med,
        TextSize = 9,
        TextColor3 = C.faint,
        Size = UDim2.new(1, -52, 0, 14),
        Position = UDim2.fromOffset(52, 24),
    }, brand)

    make('Frame', {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.fromOffset(16, 72),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
    }, side)

    local nav = make('ScrollingFrame', {
        Name = 'Nav',
        Size = UDim2.new(1, -24, 1, -174),
        Position = UDim2.fromOffset(12, 84),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, side)
    make('UIListLayout', {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, nav)
    self.Nav = nav

    local foot = make('Frame', {
        Size = UDim2.new(1, -32, 0, 66),
        Position = UDim2.new(0, 16, 1, -76),
        BackgroundTransparency = 1,
    }, side)

    make('Frame', {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
    }, foot)

    local keycap = make('Frame', {
        Size = UDim2.fromOffset(46, 20),
        Position = UDim2.fromOffset(0, 16),
        BackgroundColor3 = C.field,
        BorderSizePixel = 0,
    }, foot)
    corner(keycap, 6)
    stroke(keycap, C.line, 1, 0.3)
    self.KeycapLabel = label({
        Text = keyName(self.Key),
        Font = F.bold,
        TextSize = 9,
        TextColor3 = C.dim,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, keycap)

    label({
        Text = 'to hide / show',
        Font = F.med,
        TextSize = 10,
        TextColor3 = C.faint,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.fromOffset(56, 16),
    }, foot)

    local unload = make('TextButton', {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 42),
        BackgroundTransparency = 1,
        Text = 'Unload menu',
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = F.med,
        TextSize = 10,
        TextColor3 = C.faint,
        AutoButtonColor = false,
    }, foot)
    self:_conn(unload.MouseEnter, function()
        unload.TextColor3 = C.red
    end)
    self:_conn(unload.MouseLeave, function()
        unload.TextColor3 = C.faint
    end)
    unload.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    self:_drag(brand)
end

function NOXIS:_buildContent()
    local head = make('Frame', {
        Name = 'Header',
        Size = UDim2.new(1, -218, 0, 96),
        Position = UDim2.fromOffset(218, 0),
        BackgroundTransparency = 1,
        Active = true,
    }, self.Window)
    self.Header = head

    self.HeadTitle = label({
        Text = '—',
        Font = F.bold,
        TextSize = 23,
        TextColor3 = C.text,
        Size = UDim2.new(1, -230, 0, 30),
        Position = UDim2.fromOffset(26, 18),
    }, head)

    self.HeadSub = label({
        Text = '',
        Font = F.med,
        TextSize = 11,
        TextColor3 = C.dim,
        Size = UDim2.new(1, -230, 0, 16),
        Position = UDim2.fromOffset(26, 50),
    }, head)

    local chip = make('Frame', {
        Size = UDim2.fromOffset(108, 26),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -26, 0, 30),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
    }, head)
    corner(chip, 13)
    stroke(chip, C.line, 1, 0.35)

    local dot = make('Frame', {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.fromOffset(13, 10),
        BackgroundColor3 = C.teal,
        BorderSizePixel = 0,
    }, chip)
    corner(dot, 3)

    self.VersionChip = label({
        Text = 'LIVE · ' .. self.Version,
        Font = F.bold,
        TextSize = 9,
        TextColor3 = C.dim,
        Size = UDim2.new(1, -26, 1, 0),
        Position = UDim2.fromOffset(25, 0),
    }, chip)

    make('Frame', {
        Size = UDim2.new(1, -218, 0, 1),
        Position = UDim2.fromOffset(218, 95),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
    }, self.Window)

    local holder = make('Frame', {
        Name = 'Pages',
        Size = UDim2.new(1, -218, 1, -96),
        Position = UDim2.fromOffset(218, 96),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, self.Window)
    self.PageHolder = holder

    self:_drag(head)
end

function NOXIS:_drag(region)
    local dragging, startMouse, startPos = false, nil, nil
    local win = self.Window

    region.Active = true
    self:_conn(region.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startMouse = input.Position
            startPos = win.Position
        end
    end)

    self:_conn(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local d = input.Position - startMouse
        local sz = win.AbsoluteSize
        local vp = viewport()
        local cx = startPos.X.Offset + d.X
        local cy = startPos.Y.Offset + d.Y
        local minX = math.floor(sz.X / 2) + 8
        local minY = math.floor(sz.Y / 2) + 8
        cx = math.clamp(cx, minX, math.max(minX, vp.X - minX))
        cy = math.clamp(cy, minY, math.max(minY, vp.Y - minY))
        win.Position = UDim2.fromOffset(cx, cy)
    end)

    self:_conn(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function NOXIS:_buildNotifs()
    self.Toasts = {}
    for i = 1, 4 do
        local y = 64 + (i - 1) * 76
        local group = make('CanvasGroup', {
            Size = UDim2.fromOffset(304, 62),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 340, 0, y),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            Visible = false,
            ZIndex = 900,
        }, self.Gui)

        local bg = make('Frame', {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = C.window,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, group)
        corner(bg, 10)
        stroke(bg, C.line, 1, 0.35)

        local bar = make('Frame', {
            Size = UDim2.fromOffset(3, 38),
            Position = UDim2.fromOffset(0, 12),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, group)
        corner(bar, 3)

        local head = label({
            Text = 'INFO',
            Font = F.bold,
            TextSize = 9,
            TextColor3 = C.accent2,
            Size = UDim2.new(1, -30, 0, 14),
            Position = UDim2.fromOffset(16, 10),
            ZIndex = 2,
        }, group)

        local body = label({
            Text = '',
            Font = F.med,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(198, 192, 216),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, -30, 0, 30),
            Position = UDim2.fromOffset(16, 26),
            ZIndex = 2,
        }, group)

        self.Toasts[i] = {
            group = group, bar = bar, head = head, body = body,
            token = 0, y = y,
        }
    end
end

function NOXIS:_bindInput()
    self:_conn(UserInputService.InputBegan, function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local owner = self._popupOwner
            if self._openPopup
                and not inside(self._openPopup, input.Position)
                and not (owner and inside(owner, input.Position)) then
                self:ClosePopup()
            end
        end

        if gameProcessed or self._listening then return end
        if input.KeyCode == self.Key then
            self:Toggle()
        end
    end)
end

function NOXIS:Toggle()
    self:SetVisible(not self.Gui.Enabled)
end

function NOXIS:SetVisible(visible)
    self.Gui.Enabled = visible and true or false
    if not visible then
        self:ClosePopup()
    end
end

function NOXIS:SetKey(key)
    if typeof(key) ~= 'EnumItem' then return end
    self.Key = key
    self.KeycapLabel.Text = keyName(key)
    self._store.__key = key.Name
    self:_save()
end

function NOXIS:Notify(message, kind)
    if self.NoNotifications or self._destroyed or not self.Toasts then return end
    kind = kind or 'info'

    local palette = { info = C.accent, success = C.teal, warn = C.amber, error = C.red }
    local headings = { info = 'INFO', success = 'SUCCESS', warn = 'WARNING', error = 'ERROR' }
    local color = palette[kind] or C.accent

    local slot = self.Toasts[(self._notifSlot % #self.Toasts) + 1]
    self._notifSlot += 1
    slot.token += 1
    local token = slot.token

    slot.bar.BackgroundColor3 = color
    slot.head.TextColor3 = color
    slot.head.Text = headings[kind] or headings.info
    slot.body.Text = tostring(message or '')
    slot.group.Visible = true
    slot.group.GroupTransparency = 1
    slot.group.Position = UDim2.new(1, 340, 0, slot.y)

    tween(slot.group, 0.22, {
        GroupTransparency = 0,
        Position = UDim2.new(1, -18, 0, slot.y),
    }, Enum.EasingStyle.Quint)

    task.delay(self.NotifyDuration or 3.5, function()
        if self._destroyed or slot.token ~= token then return end
        tween(slot.group, 0.2, {
            GroupTransparency = 1,
            Position = UDim2.new(1, 40, 0, slot.y),
        })
        task.delay(0.22, function()
            if slot.token == token and not self._destroyed then
                slot.group.Visible = false
            end
        end)
    end)
end

function NOXIS:ClosePopup()
    if self._openPopup then
        self._openPopup.Visible = false
        self._openPopup = nil
        self._popupOwner = nil
    end
end

function NOXIS:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, c in ipairs(self._conns) do
        pcall(function() c:Disconnect() end)
    end
    self._conns = {}
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
    if getgenv().NOXIS == self then
        getgenv().NOXIS = nil
    end
end

function NOXIS:Page(title, icon)
    local page = setmetatable({
        Hub = self,
        Title = title,
        Icon = string.upper(icon or title:sub(1, 2)),
        Subtitle = nil,
        Sections = {},
        Count = 0,
    }, Page)

    local group = make('CanvasGroup', {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Visible = false,
        ClipsDescendants = true,
    }, self.PageHolder)

    local scroll = make('ScrollingFrame', {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        ScrollBarImageTransparency = 0.45,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, group)
    make('UIPadding', {
        PaddingTop = UDim.new(0, 22),
        PaddingBottom = UDim.new(0, 26),
        PaddingLeft = UDim.new(0, 26),
        PaddingRight = UDim.new(0, 18),
    }, scroll)
    make('UIListLayout', {
        Padding = UDim.new(0, 16),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)

    page.Group = group
    page.Scroll = scroll
    page.Nav = self:_navItem(page, #self._pages + 1)

    table.insert(self._pages, page)
    self._pageById[title] = page

    if #self._pages == 1 then
        self:ShowPage(title)
    end
    return page
end

function NOXIS:_navItem(page, order)
    local btn = make('Frame', {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        LayoutOrder = order,
    }, self.Nav)
    corner(btn, 10)

    local bar = make('Frame', {
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.fromOffset(0, 12),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Visible = false,
    }, btn)
    corner(bar, 3)

    local icon = make('Frame', {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(10, 8),
        BackgroundColor3 = C.navBg,
        BorderSizePixel = 0,
    }, btn)
    corner(icon, 8)

    local mark = label({
        Text = page.Icon,
        Font = F.bold,
        TextSize = 9,
        TextColor3 = C.faint,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, icon)

    local text = label({
        Text = page.Title,
        Font = F.med,
        TextSize = 12,
        TextColor3 = C.dim,
        Size = UDim2.new(1, -62, 1, 0),
        Position = UDim2.fromOffset(46, 0),
    }, btn)

    local dot = make('Frame', {
        Size = UDim2.fromOffset(5, 5),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Visible = false,
    }, btn)
    corner(dot, 3)

    self:_conn(btn.MouseEnter, function()
        if self._current ~= page.Title then
            tween(btn, 0.12, { BackgroundTransparency = 0.55 })
        end
    end)
    self:_conn(btn.MouseLeave, function()
        if self._current ~= page.Title then
            tween(btn, 0.12, { BackgroundTransparency = 1 })
        end
    end)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self:ShowPage(page.Title)
        end
    end)

    return { btn = btn, bar = bar, icon = icon, mark = mark, text = text, dot = dot }
end

function NOXIS:_paintNav(page, active)
    local nav = page.Nav
    if not nav then return end
    if active then
        nav.btn.BackgroundTransparency = 0
        nav.bar.Visible = true
        nav.dot.Visible = true
        nav.text.TextColor3 = C.text
        nav.icon.BackgroundColor3 = C.accent
        nav.icon.BackgroundTransparency = 0.78
        nav.mark.TextColor3 = C.accent2
    else
        nav.btn.BackgroundTransparency = 1
        nav.bar.Visible = false
        nav.dot.Visible = false
        nav.text.TextColor3 = C.dim
        nav.icon.BackgroundColor3 = C.navBg
        nav.icon.BackgroundTransparency = 0
        nav.mark.TextColor3 = C.faint
    end
end

function NOXIS:ShowPage(title)
    local page = self._pageById[title]
    if not page then return end
    self._current = title

    for _, p in ipairs(self._pages) do
        local active = p == page
        p.Group.Visible = active
        self:_paintNav(p, active)
        if active then
            p.Group.GroupTransparency = 1
            tween(p.Group, 0.2, { GroupTransparency = 0 })
        end
    end

    self.HeadTitle.Text = page.Title
    self.HeadSub.Text = page.Subtitle or ('NOXIS HUB · ' .. string.upper(page.Title))
    self:ClosePopup()
end

function Page:Sub(value)
    self.Subtitle = tostring(value or '')
    if self.Hub._current == self.Title then
        self.Hub.HeadSub.Text = self.Subtitle
    end
    return self
end

function Page:Section(title)
    local holder = make('Frame', {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, self.Scroll)

    local list = make('UIListLayout', {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, holder)

    local head = make('Frame', {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    }, holder)

    local dash = make('Frame', {
        Size = UDim2.fromOffset(3, 10),
        Position = UDim2.fromOffset(0, 5),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, head)
    corner(dash, 2)

    label({
        Text = string.upper(title),
        Font = F.bold,
        TextSize = 10,
        TextColor3 = C.faint,
        Size = UDim2.new(1, -160, 0, 20),
        Position = UDim2.fromOffset(10, 0),
    }, head)

    make('Frame', {
        Size = UDim2.new(1, -160, 0, 1),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
    }, head)

    local sec = setmetatable({
        Hub = self.Hub,
        Page = self,
        Holder = holder,
        Layout = list,
        Order = 0,
    }, Section)

    table.insert(self.Sections, sec)
    return sec
end

function Section:_id(opts)
    local raw = opts.id or (tostring(self.Page.Title) .. '_' .. tostring(opts.title))
    return (raw:gsub('%s+', '_'):gsub('[^%w_%.%-]', ''))
end

function Section:_card(opts, reserve)
    self.Order += 1
    local height = opts.desc and 58 or 50

    local card = make('Frame', {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        Active = true,
        LayoutOrder = self.Order,
    }, self.Holder)
    corner(card, 12)
    stroke(card, C.line, 1, 0.55)

    self.Hub:_conn(card.MouseEnter, function()
        tween(card, 0.12, { BackgroundColor3 = C.cardHi })
    end)
    self.Hub:_conn(card.MouseLeave, function()
        tween(card, 0.12, { BackgroundColor3 = C.card })
    end)

    local icon = make('Frame', {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(0, 14, 0.5, -16),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
    }, card)
    corner(icon, 9)

    local keys = opts.icon or opts.title:sub(1, 2)
    label({
        Text = string.upper(keys),
        Font = F.bold,
        TextSize = 9,
        TextColor3 = C.accent2,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, icon)

    local textWidth = UDim2.new(1, -(60 + 14 + (reserve or 0) + 8), 0, 0)
    if opts.desc then
        label({
            Text = tostring(opts.title),
            Font = F.bold,
            TextSize = 12,
            TextColor3 = C.text,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = textWidth + UDim2.fromOffset(0, 16),
            Position = UDim2.fromOffset(60, 10),
        }, card)
        label({
            Text = tostring(opts.desc),
            Font = F.med,
            TextSize = 10,
            TextColor3 = C.dim,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = textWidth + UDim2.fromOffset(0, 14),
            Position = UDim2.fromOffset(60, 28),
        }, card)
    else
        label({
            Text = tostring(opts.title),
            Font = F.bold,
            TextSize = 12,
            TextColor3 = C.text,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = textWidth + UDim2.fromOffset(0, height),
            Position = UDim2.fromOffset(60, 0),
        }, card)
    end

    return card
end

function Section:Toggle(opts)
    local hub = self.Hub
    local card = self:_card(opts, 62)
    local id = self:_id(opts)
    local state = opts.value == true
    if hub._store[id] ~= nil then
        state = hub._store[id] == '1'
    end

    local box = make('Frame', {
        Size = UDim2.fromOffset(46, 30),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        BackgroundTransparency = 1,
        Active = true,
    }, card)

    local track = make('Frame', {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.fromOffset(1, 3),
        BackgroundColor3 = Color3.fromRGB(43, 36, 60),
        BorderSizePixel = 0,
    }, box)
    corner(track, 12)

    local grad = make('UIGradient', {
        Color = ColorSequence.new(C.gradA, C.gradB),
        Enabled = false,
    }, track)

    local knob = make('Frame', {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 9)

    local function paint(animate)
        track.BackgroundColor3 = state and C.gradA or Color3.fromRGB(43, 36, 60)
        grad.Enabled = state
        local x = state and 23 or 3
        if animate then
            tween(knob, 0.16, { Position = UDim2.fromOffset(x, 3) })
        else
            knob.Position = UDim2.fromOffset(x, 3)
        end
    end

    local function set(value, silent)
        state = value and true or false
        paint(true)
        hub._store[id] = state and '1' or '0'
        hub:_save()
        if not silent then
            fire(opts.callback, state)
        end
    end

    paint(false)

    box.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            set(not state)
        end
    end)

    if opts.apply then fire(opts.apply, state) end

    return {
        Object = box,
        Set = function(_, v, silent) set(v, silent) end,
        Get = function() return state end,
    }
end

function Section:Button(opts)
    local card = self:_card(opts, 110)

    local btn = make('TextButton', {
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(34, 26, 54),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = tostring(opts.text or 'RUN'),
        Font = F.bold,
        TextSize = 10,
        TextColor3 = C.accent2,
    }, card)
    corner(btn, 8)
    stroke(btn, C.accent, 1, 0.7)
    make('UIPadding', {
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    }, btn)

    self.Hub:_conn(btn.MouseEnter, function()
        btn.BackgroundColor3 = Color3.fromRGB(42, 32, 66)
    end)
    self.Hub:_conn(btn.MouseLeave, function()
        btn.BackgroundColor3 = Color3.fromRGB(34, 26, 54)
    end)
    btn.MouseButton1Click:Connect(function()
        fire(opts.callback)
    end)

    return btn
end

function Section:Input(opts)
    local hub = self.Hub
    local card = self:_card(opts, 184)
    local id = self:_id(opts)

    local wrap = make('Frame', {
        Size = UDim2.fromOffset(170, 30),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundColor3 = C.field,
        BorderSizePixel = 0,
    }, card)
    corner(wrap, 8)
    local edge = stroke(wrap, C.line, 1, 0.3)

    local box = make('TextBox', {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = '',
        PlaceholderText = tostring(opts.placeholder or ''),
        PlaceholderColor3 = C.faint,
        TextColor3 = C.text,
        TextSize = 11,
        Font = F.med,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, wrap)

    local current = opts.value ~= nil and tostring(opts.value) or ''

    local function format(v)
        if opts.numeric == false then return v end
        local n = tonumber(v)
        if not n then return current end
        if opts.min then n = math.max(n, opts.min) end
        if opts.max then n = math.min(n, opts.max) end
        if opts.decimals then
            return string.format('%.' .. tostring(opts.decimals) .. 'f', n)
        end
        return tostring(math.floor(n))
    end

    local function applyText(raw)
        local value = raw
        if opts.numeric ~= false then
            local n = tonumber(raw)
            if not n then
                box.Text = current
                return
            end
            value = format(raw)
        end
        current = value
        box.Text = current
        hub._store[id] = tostring(current)
        hub:_save()
        fire(opts.callback, current)
    end

    if hub._store[id] ~= nil then
        current = hub._store[id]
    end
    box.Text = current

    self.Hub:_conn(box.Focused, function()
        edge.Transparency = 0.75
        edge.Color = C.accent
    end)
    self.Hub:_conn(box.FocusLost, function()
        edge.Transparency = 0.3
        edge.Color = C.line
        applyText(box.Text)
    end)
    self.Hub:_conn(box.ReturnPressedFromOnScreenKeyboard, function()
        box:ReleaseFocus()
    end)

    if opts.apply then fire(opts.apply, current) end

    return {
        Object = box,
        Set = function(_, v, silent)
            current = tostring(v)
            box.Text = current
            hub._store[id] = current
            hub:_save()
            if not silent then fire(opts.callback, current) end
        end,
        Get = function() return current end,
    }
end

function Section:Slider(opts)
    local hub = self.Hub
    local card = self:_card(opts, 214)
    local id = self:_id(opts)

    local min = tonumber(opts.min) or 0
    local max = tonumber(opts.max) or 100
    if max <= min then max = min + 1 end
    local step = tonumber(opts.step) or 1
    local value = tonumber(opts.value) or min
    if hub._store[id] ~= nil then
        value = tonumber(hub._store[id]) or value
    end
    value = math.clamp(value, min, max)

    local wrap = make('Frame', {
        Size = UDim2.fromOffset(200, 30),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundTransparency = 1,
    }, card)

    local track = make('Frame', {
        Size = UDim2.fromOffset(134, 6),
        Position = UDim2.fromOffset(0, 12),
        BackgroundColor3 = Color3.fromRGB(39, 32, 54),
        BorderSizePixel = 0,
    }, wrap)
    corner(track, 3)

    local fill = make('Frame', {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 3)
    make('UIGradient', {
        Color = ColorSequence.new(C.gradA, C.gradB),
        Rotation = 0,
    }, fill)

    local knob = make('Frame', {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(-7, -4),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 7)

    local readout = label({
        Text = '',
        Font = F.bold,
        TextSize = 10,
        TextColor3 = C.accent2,
        Size = UDim2.fromOffset(62, 20),
        Position = UDim2.fromOffset(138, 5),
    }, wrap)

    local hit = make('Frame', {
        Size = UDim2.fromOffset(134, 26),
        Position = UDim2.fromOffset(0, 2),
        BackgroundTransparency = 1,
        Active = true,
    }, wrap)

    local function formatValue(v)
        if opts.format then
            local ok, out = pcall(opts.format, v)
            if ok then return tostring(out) end
        end
        local text
        if step < 1 then
            text = string.format('%.2f', v)
        else
            text = tostring(math.floor(v + 0.5))
        end
        return text .. tostring(opts.suffix or '')
    end

    local function paint()
        local pct = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(pct, 1)
        knob.Position = UDim2.new(pct, -7, 0.5, -7)
        readout.Text = formatValue(value)
    end

    local function commit(v, silent)
        v = math.clamp(v, min, max)
        local steps = math.floor((v - min) / step + 0.5)
        value = math.clamp(min + steps * step, min, max)
        value = tonumber(string.format('%.4f', value)) or value
        paint()
        hub._store[id] = tostring(value)
        hub:_save()
        if not silent then fire(opts.callback, value) end
    end

    local dragging = false
    self.Hub:_conn(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pct = math.clamp(
                (input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X),
                0, 1)
            commit(min + pct * (max - min))
        end
    end)
    self.Hub:_conn(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local pct = math.clamp(
            (input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X),
            0, 1)
        commit(min + pct * (max - min))
    end)
    self.Hub:_conn(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    paint()
    if opts.apply then fire(opts.apply, value) end

    return {
        Object = hit,
        Set = function(_, v, silent) commit(tonumber(v) or value, silent) end,
        Get = function() return value end,
    }
end

function Section:Dropdown(opts)
    local hub = self.Hub
    local card = self:_card(opts, 174)
    local id = self:_id(opts)

    local labels, values = {}, {}
    for i, opt in ipairs(opts.options or {}) do
        if type(opt) == 'table' then
            labels[i] = tostring(opt.label or opt.value)
            values[i] = opt.value ~= nil and opt.value or opt.label
        else
            labels[i] = tostring(opt)
            values[i] = opt
        end
    end

    local index = 1
    if hub._store[id] ~= nil then
        for i, v in ipairs(values) do
            if tostring(v) == hub._store[id] then index = i break end
        end
    elseif opts.value ~= nil then
        for i, v in ipairs(values) do
            if tostring(v) == tostring(opts.value) then index = i break end
        end
    end

    local wrap = make('TextButton', {
        Size = UDim2.fromOffset(160, 30),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundColor3 = C.field,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = '',
    }, card)
    corner(wrap, 8)
    local edge = stroke(wrap, C.line, 1, 0.3)

    local readout = label({
        Text = labels[index] or '—',
        Font = F.med,
        TextSize = 10,
        TextColor3 = C.text,
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, wrap)

    label({
        Text = '▾',
        Font = F.bold,
        TextSize = 10,
        TextColor3 = C.faint,
        Size = UDim2.fromOffset(20, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, wrap)

    local height = 9 + math.max(1, #labels) * 28 + 6
    local popup = make('Frame', {
        Size = UDim2.fromOffset(176, height),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 1000,
    }, hub.Gui)
    corner(popup, 10)
    stroke(popup, C.line, 1, 0.2)
    make('UIPadding', {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    }, popup)
    make('UIListLayout', {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, popup)

    local rows = {}
    for i, name in ipairs(labels) do
        local row = make('TextButton', {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = C.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = '',
            LayoutOrder = i,
            ZIndex = 1001,
        }, popup)
        corner(row, 7)
        make('UIPadding', {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }, row)

        local rowLabel = label({
            Text = name,
            Font = F.med,
            TextSize = 10,
            TextColor3 = C.dim,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 1002,
        }, row)

        table.insert(rows, rowLabel)

        row.MouseButton1Click:Connect(function()
            index = i
            readout.Text = labels[i]
            hub._store[id] = tostring(values[i])
            hub:_save()
            hub:ClosePopup()
            for r, rowText in ipairs(rows) do
                rowText.TextColor3 = (r == index) and C.accent2 or C.dim
            end
            fire(opts.callback, values[i])
        end)
    end

    local function paint()
        for r, rowText in ipairs(rows) do
            rowText.TextColor3 = (r == index) and C.accent2 or C.dim
        end
        readout.Text = labels[index] or '—'
    end

    wrap.MouseButton1Click:Connect(function()
        local ap, as = wrap.AbsolutePosition, wrap.AbsoluteSize
        local vp = viewport()
        local w = 176
        local x = math.clamp(ap.X + as.X - w, 8, math.max(8, vp.X - w - 8))
        local y = ap.Y + as.Y + 6
        if y + height > vp.Y - 8 then
            y = ap.Y - height - 6
        end
        popup.Position = UDim2.fromOffset(x, y)
        if hub._openPopup == popup then
            hub:ClosePopup()
            return
        end
        hub:ClosePopup()
        popup.Visible = true
        hub._openPopup = popup
        hub._popupOwner = wrap
        paint()
    end)

    self.Hub:_conn(wrap.MouseEnter, function()
        edge.Transparency = 0.65
        edge.Color = C.accent
    end)
    self.Hub:_conn(wrap.MouseLeave, function()
        edge.Transparency = 0.3
        edge.Color = C.line
    end)

    paint()
    if opts.apply then fire(opts.apply, values[index]) end

    return {
        Object = wrap,
        Set = function(_, v, silent)
            for i, value in ipairs(values) do
                if tostring(value) == tostring(v) then
                    index = i
                    break
                end
            end
            paint()
            hub._store[id] = tostring(values[index])
            hub:_save()
            if not silent then fire(opts.callback, values[index]) end
        end,
        Get = function() return values[index] end,
    }
end

function Section:Keybind(opts)
    local hub = self.Hub
    local card = self:_card(opts, 106)
    local id = self:_id(opts)

    local key = opts.value or Enum.KeyCode.RightShift
    if hub._store[id] ~= nil then
        local saved = Enum.KeyCode[hub._store[id]]
        if saved then key = saved end
    end

    local btn = make('TextButton', {
        Size = UDim2.fromOffset(92, 28),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundColor3 = C.field,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = keyName(key),
        Font = F.bold,
        TextSize = 9,
        TextColor3 = C.dim,
    }, card)
    corner(btn, 7)
    local edge = stroke(btn, C.line, 1, 0.3)

    local function paint()
        btn.Text = keyName(key)
    end

    self.Hub:_conn(btn.MouseEnter, function()
        edge.Transparency = 0.65
        edge.Color = C.accent
    end)
    self.Hub:_conn(btn.MouseLeave, function()
        edge.Transparency = 0.3
        edge.Color = C.line
    end)

    btn.MouseButton1Click:Connect(function()
        if hub._listening then return end
        hub:ClosePopup()
        hub._listening = btn
        btn.Text = 'press key'
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if gameProcessed then return end
            hub._listening = nil
            conn:Disconnect()
            if input.KeyCode == Enum.KeyCode.Escape then
                paint()
                return
            end
            key = input.KeyCode
            paint()
            hub._store[id] = key.Name
            hub:_save()
            fire(opts.callback, key)
        end)
        table.insert(hub._conns, conn)
    end)

    paint()
    if opts.apply then fire(opts.apply, key) end

    return {
        Object = btn,
        Set = function(_, v, silent)
            if typeof(v) ~= 'EnumItem' then return end
            key = v
            paint()
            hub._store[id] = key.Name
            hub:_save()
            if not silent then fire(opts.callback, key) end
        end,
        Get = function() return key end,
    }
end

function Section:Label(opts)
    local card = self:_card(opts, 184)
    local value = opts.value ~= nil and tostring(opts.value) or ''

    local readout = label({
        Text = value,
        Font = F.bold,
        TextSize = 10,
        TextColor3 = opts.color or C.dim,
        Size = UDim2.fromOffset(170, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    return {
        Object = readout,
        Set = function(_, v)
            value = tostring(v)
            readout.Text = value
        end,
        Get = function() return value end,
    }
end

-- ============================================================
-- DEMO CONTENT — replace with per-game pages
-- ============================================================

local Hub = NOXIS.new(getgenv().NOXIS_CFG or { Name = 'NOXIS', Subtitle = 'HUB', Version = 'v1.0' })
getgenv().NOXIS = Hub

-- game scripts set getgenv().NOXIS_DEMO = false to build their own pages
if getgenv().NOXIS_DEMO == false then
    print('[NOXIS] hub built')
    return Hub
end

local home = Hub:Page('Home', 'HM')
home:Sub('Overview · quick actions · session info')

home:Section('WELCOME'):Label({
    title = 'NOXIS HUB',
    desc = 'Sidebar-first menu base · single file · no assets',
    value = 'v1.0',
    color = C.accent2,
    icon = 'NX',
})

local quick = home:Section('QUICK START')

quick:Button({
    title = 'Open Shop',
    desc = 'Jump to the shop page',
    text = 'OPEN',
    icon = 'SH',
    callback = function()
        Hub:ShowPage('Shop')
    end,
})

quick:Button({
    title = 'Open Auto Sell',
    desc = 'Configure the sell threshold',
    text = 'OPEN',
    icon = 'AS',
    callback = function()
        Hub:ShowPage('Auto Sell')
    end,
})

local session = home:Section('SESSION')

session:Label({
    title = 'Toggle keybind',
    desc = 'Hide or show the menu at any time',
    value = 'RShift',
    icon = 'KB',
})

session:Label({
    title = 'Settings file',
    desc = 'Saved values are reloaded on execute',
    value = Hub._file,
    icon = 'SV',
})

session:Label({
    title = 'Unload',
    desc = 'Use the footer button or Hub:Destroy()',
    value = 'ready',
    icon = 'UL',
    color = C.teal,
})

local shop = Hub:Page('Shop', 'SH')
shop:Sub('Dice shop · purchase rules · behavior')

shop:Section('DICE SHOP'):Toggle({
    title = 'Auto-buy dice',
    desc = 'Buys the best affordable dice from the shop',
    icon = 'AB',
    callback = function(v)
        Hub:Notify('Auto-buy dice ' .. (v and 'enabled' or 'disabled'), v and 'success' or 'info')
    end,
})

shop:Section('DICE SHOP'):Dropdown({
    title = 'Buy priority',
    desc = 'How the next purchase is chosen',
    icon = 'PR',
    options = { 'Luck per money', 'Cheapest first', 'Highest rarity' },
    value = 'Luck per money',
})

shop:Section('DICE SHOP'):Input({
    title = 'Max price',
    desc = 'Skip purchases above this amount',
    icon = 'MP',
    placeholder = '1000',
    value = '1000',
    numeric = true,
})

shop:Section('DICE SHOP'):Button({
    title = 'Buy selected dice',
    desc = 'One manual purchase attempt',
    text = 'BUY',
    icon = 'BY',
    callback = function()
        Hub:Notify('Hook your dice purchase call in the button callback.', 'warn')
    end,
})

shop:Section('BEHAVIOR'):Toggle({
    title = 'Skip owned dice',
    desc = 'Never buy a dice the account already owns',
    value = true,
    icon = 'SO',
})

shop:Section('BEHAVIOR'):Slider({
    title = 'Buy interval',
    desc = 'Delay between purchase attempts',
    icon = 'IV',
    min = 0.3,
    max = 3,
    step = 0.1,
    value = 0.8,
    suffix = 's',
})

shop:Section('BEHAVIOR'):Label({
    title = 'Queue',
    desc = 'Purchases waiting to run',
    value = 'idle',
    icon = 'QU',
})

local upgrades = Hub:Page('Upgrades', 'UP')
upgrades:Sub('Upgrade buying · order · limits')

upgrades:Section('UPGRADES'):Toggle({
    title = 'Auto-buy upgrades',
    desc = 'Buys available upgrades when affordable',
    icon = 'AU',
    callback = function(v)
        Hub:Notify('Auto-buy upgrades ' .. (v and 'enabled' or 'disabled'), v and 'success' or 'info')
    end,
})

upgrades:Section('UPGRADES'):Toggle({
    title = 'Cheapest first',
    desc = 'Always take the lowest priced available upgrade',
    value = true,
    icon = 'CF',
})

upgrades:Section('UPGRADES'):Input({
    title = 'Spend cap',
    desc = 'Keep this much currency untouched',
    icon = 'SC',
    placeholder = '0',
    value = '0',
    numeric = true,
})

upgrades:Section('UPGRADES'):Button({
    title = 'Buy next upgrade',
    desc = 'One manual purchase attempt',
    text = 'BUY',
    icon = 'BN',
    callback = function()
        Hub:Notify('Hook your upgrade purchase call in the button callback.', 'warn')
    end,
})

upgrades:Section('CONTROL'):Keybind({
    title = 'Buy hotkey',
    desc = 'Manual purchase while the menu is closed',
    icon = 'HK',
    value = Enum.KeyCode.B,
})

upgrades:Section('CONTROL'):Label({
    title = 'Last purchase',
    desc = 'Updated by your upgrade logic',
    value = '—',
    icon = 'LP',
})

local sell = Hub:Page('Auto Sell', 'AS')
sell:Sub('Sell threshold · presets · safety')

sell:Section('AUTO SELL'):Toggle({
    title = 'Enable Auto Sell',
    desc = 'Sells units below the configured chance',
    icon = 'EN',
    callback = function(v)
        Hub:Notify('Auto Sell ' .. (v and 'enabled' or 'disabled'), v and 'success' or 'info')
    end,
})

sell:Section('AUTO SELL'):Input({
    title = 'Sell below 1 in',
    desc = 'Units rarer than this are kept',
    icon = 'TH',
    placeholder = '1000',
    value = '1000',
    numeric = true,
    callback = function(v)
        Hub:Notify('Threshold set to 1 in ' .. tostring(v), 'info')
    end,
})

sell:Section('AUTO SELL'):Dropdown({
    title = 'Threshold preset',
    desc = 'Quick values for common cutoffs',
    icon = 'PS',
    options = { 'Off', '1 in 100', '1 in 1k', '1 in 10k', '1 in 100k' },
    value = 'Off',
})

sell:Section('AUTO SELL'):Button({
    title = 'Apply threshold',
    desc = 'Push the configured value to the game',
    text = 'APPLY',
    icon = 'AP',
    callback = function()
        Hub:Notify('Hook your sell threshold call in the button callback.', 'warn')
    end,
})

sell:Section('SAFETY'):Toggle({
    title = 'Pause while menu open',
    desc = 'Hold sells while you are configuring',
    icon = 'PZ',
})

sell:Section('SAFETY'):Label({
    title = 'Current value',
    desc = 'Reported by the game',
    value = '1 in 1000',
    icon = 'CV',
    color = C.accent2,
})

local settings = Hub:Page('Settings', 'SE')
settings:Sub('Menu behavior · scale · saved data')

settings:Section('MENU'):Keybind({
    title = 'Toggle menu',
    desc = 'Keybind used to hide or show the hub',
    icon = 'TK',
    value = Hub.Key,
    apply = function(key)
        Hub:SetKey(key)
    end,
    callback = function(key)
        Hub:SetKey(key)
        Hub:Notify('Menu keybind set to ' .. keyName(key), 'success')
    end,
})

settings:Section('MENU'):Slider({
    title = 'Interface scale',
    desc = 'Overall size of the window',
    icon = 'IS',
    min = 0.7,
    max = 1.2,
    step = 0.05,
    value = 1,
    suffix = 'x',
    apply = function(v)
        Hub:SetScale(v)
    end,
    callback = function(v)
        Hub:SetScale(v)
    end,
})

settings:Section('MENU'):Slider({
    title = 'Toast duration',
    desc = 'How long notifications stay on screen',
    icon = 'TD',
    min = 1.5,
    max = 8,
    step = 0.5,
    value = 3.5,
    suffix = 's',
    apply = function(v)
        Hub.NotifyDuration = v
    end,
    callback = function(v)
        Hub.NotifyDuration = v
    end,
})

settings:Section('MENU'):Toggle({
    title = 'Show notifications',
    desc = 'Slide-in messages in the top right corner',
    value = true,
    icon = 'NT',
    apply = function(v)
        Hub.NoNotifications = not v
    end,
    callback = function(v)
        Hub.NoNotifications = not v
    end,
})

settings:Section('DATA'):Button({
    title = 'Reset saved settings',
    desc = 'Clears the local config file',
    text = 'RESET',
    icon = 'RS',
    callback = function()
        Hub._store = {}
        Hub:_save()
        Hub:Notify('Saved settings cleared · reload to reset controls', 'warn')
    end,
})

settings:Section('DATA'):Button({
    title = 'Unload menu',
    desc = 'Remove the interface and disconnect events',
    text = 'UNLOAD',
    icon = 'UN',
    callback = function()
        Hub:Destroy()
    end,
})

Hub:ShowPage('Home')
Hub:Notify('NOXIS HUB loaded · base v1.0', 'success')

print('[NOXIS] hub built')

return Hub
