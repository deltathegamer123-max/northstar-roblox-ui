, 280), MaxSize = Vector2.new(620, 420)})
    local searchInput = create("TextBox", searchPanel, {
        Position = UDim2.new(0, 16, 0, 15), Size = UDim2.new(1, -32, 0, 42),
        BackgroundColor3 = Theme.Card, Text = "", PlaceholderText = "Search tabs, controls, and actions…",
        TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
        Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62,
    })
    corner(searchInput, 8)
    create("UIPadding", searchInput, {PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13)})
    local searchResults = create("ScrollingFrame", searchPanel, {
        Position = UDim2.new(0, 10, 0, 68), Size = UDim2.new(1, -20, 1, -80),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    create("UIListLayout", searchResults, {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", searchResults, {PaddingBottom = UDim.new(0, 4)})
    local function closeSearch()
        if not searchOverlay.Visible then return end
        searchOverlay.Visible = false
        searchOverlay.BackgroundTransparency = 1
        searchPanel.Position = UDim2.fromScale(0.5, 0.44)
    end
    local updateSearch
    local function openSearch()
        if Window._destroyed then return end
        searchOverlay.Visible = true
        searchOverlay.BackgroundTransparency = 1
        searchPanel.Position = UDim2.fromScale(0.5, 0.44)
        Window:_Tween(searchOverlay, 0.16, {BackgroundTransparency = 0.38})
        Window:_Tween(searchPanel, 0.18, {Position = UDim2.fromScale(0.5, 0.47)})
        searchInput.Text = ""
        if updateSearch then updateSearch() end
        task.defer(function() if searchInput.Parent then searchInput:CaptureFocus() end end)
    end
    Window.OpenSearch = openSearch

    local function clearSearchResults()
        for _, child in ipairs(searchResults:GetChildren()) do
            if child:IsA("TextButton") or child.Name == "EmptySearch" then child:Destroy() end
        end
    end
    updateSearch = function()
        clearSearchResults()
        local query = string.lower(searchInput.Text)
        local results = {}
        for _, entry in ipairs(Window._searchEntries) do
            if query == "" or string.find(string.lower(entry.Name), query, 1, true) then
                table.insert(results, entry)
            end
        end
        for i, entry in ipairs(results) do
            local row = create("TextButton", searchResults, {
                Name = "SearchResult", Size = UDim2.new(1, -2, 0, 39),
                BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.15,
                Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 62,
            })
            corner(row, 7)
            local primary = label(row, entry.Name, 12, Theme.Text, Enum.Font.GothamMedium)
            primary.Position, primary.Size, primary.ZIndex = UDim2.fromOffset(12, 0), UDim2.new(1, -92, 1, 0), 63
            local category = label(row, entry.Category or "Control", 10, Theme.Muted, Enum.Font.Gotham)
            category.Position, category.Size, category.TextXAlignment, category.ZIndex = UDim2.new(1, -80, 0, 0), UDim2.fromOffset(68, 39), Enum.TextXAlignment.Right, 63
            -- These rows are rebuilt on every query; their own destruction
            -- disconnects these handlers without retaining them in the window.
            row.MouseEnter:Connect(function() Window:_Tween(row, 0.1, {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0}) end)
            row.MouseLeave:Connect(function() Window:_Tween(row, 0.1, {BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.15}) end)
            row.Activated:Connect(function()
                if entry.Tab then activateTab(entry.Tab) end
                if entry.Target and entry.Tab then
                    task.defer(function()
                        local page = entry.Tab.Page
                        local relativeY = entry.Target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
                        page.CanvasPosition = Vector2.new(0, math.max(0, relativeY - 14))
                    end)
                end
                closeSearch()
                if type(entry.Callback) == "function" then Window:_Call(entry.Callback) end
            end)
        end
        if #results == 0 then
            local empty = label(searchResults, "No matches found", 12, Theme.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
            empty.Name, empty.Size = "EmptySearch", UDim2.new(1, 0, 0, 44)
        end
    end
    Window:_Connect(searchInput:GetPropertyChangedSignal("Text"), updateSearch)
    updateSearch()
    Window:_Connect(searchOverlay.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Position then
            local p, s = searchPanel.AbsolutePosition, searchPanel.AbsoluteSize
            local inside = input.Position.X >= p.X and input.Position.X <= p.X + s.X and input.Position.Y >= p.Y and input.Position.Y <= p.Y + s.Y
            if not inside then closeSearch() end
        end
    end)
    Window:_Connect(UserInputService.InputBegan, function(input, processed)
        if input.KeyCode == Enum.KeyCode.Escape and searchOverlay.Visible then
            closeSearch()
            return
        end
        if processed then return end
        if input.KeyCode == Window._toggleKey then
            Window._isVisible = not Window._isVisible
            if Window._isVisible then
                main.Visible, shadow.Visible = true, true
                scale.Scale = 0.96
                main.GroupTransparency = 1
                main.Position = UDim2.fromScale(0.5, 0.51)
                Window:_Tween(scale, 0.22, {Scale = 1}, Enum.EasingStyle.Back)
                Window:_Tween(main, 0.2, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)})
            else
                Window:_Tween(scale, 0.15, {Scale = 0.96})
                Window:_Tween(main, 0.15, {GroupTransparency = 1, Position = UDim2.fromScale(0.5, 0.51)})
                task.delay(0.16, function() if main.Parent and not Window._isVisible then main.Visible, shadow.Visible = false, false end end)
            end
        elseif input.KeyCode == Window._searchKey then
            openSearch()
        elseif input.KeyCode == Enum.KeyCode.Return and searchOverlay.Visible then
            local first = searchResults:FindFirstChild("SearchResult")
            if first then first:Activate() end
        end
    end)

    Window:_Connect(searchButton.MouseButton1Click, openSearch)
    Window:_Connect(minimizeButton.MouseButton1Click, function()
        Window._isMinimized = not Window._isMinimized
        body.Visible = not Window._isMinimized
        if Window._isMinimized then
            local width = main.AbsoluteSize.X
            Window:_Tween(main, 0.22, {Size = UDim2.fromOffset(width, 58)})
            shadow.Size = UDim2.fromOffset(width + 46, 104)
        else
            local targetSize = Window._restingSize or UDim2.fromOffset(main.AbsoluteSize.X, 460)
            shadow.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset + 46, targetSize.Y.Scale, targetSize.Y.Offset + 46)
            Window:_Tween(main, 0.22, {Size = targetSize})
        end
    end)
    Window:_Connect(closeButton.MouseButton1Click, function()
        Window:Destroy()
    end)
    Window:_Connect(collapseButton.MouseButton1Click, function()
        Window:SetSidebarCollapsed(not Window._collapsed)
    end)

    -- Drag from the header surface; avoid beginning a drag over the window controls.
    local dragging, dragStart, startPosition, activeInput
    Window:_Connect(header.InputBegan, function(input)
        local kind = input.UserInputType
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
        if input.Position.X > header.AbsolutePosition.X + header.AbsoluteSize.X - 150 then return end
        dragging, dragStart, startPosition, activeInput = true, input.Position, main.Position, input
    end)
    Window:_Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            shadow.Position = main.Position
        end
    end)
    Window:_Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, activeInput = false, nil
        end
    end)
    Window:_Connect(main:GetPropertyChangedSignal("Position"), function()
        if shadow.Parent and shadow.Position ~= main.Position then shadow.Position = main.Position end
    end)

    function Window:SetLoading(isLoading, text)
        local overlay = self._loadingOverlay
        if isLoading then
            if not overlay then
                overlay = create("Frame", main, {
                    Name = "LoadingOverlay", Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.2,
                    ZIndex = 40,
                })
                corner(overlay, 13)
                self._loadingOverlay = overlay
                local spinnerLabel = create("TextLabel", overlay, {
                    Size = UDim2.fromOffset(38, 38), Position = UDim2.new(0.5, -19, 0.5, -34),
                    BackgroundTransparency = 1, Text = "◌", TextColor3 = Theme.Accent,
                    Font = Enum.Font.Gotham, TextSize = 32, ZIndex = 41,
                })
                self._loadingSpinner = spinnerLabel
                local active = true
                self._stopLoadingSpin = function() active = false end
                task.spawn(function()
                    while active and spinnerLabel.Parent do
                        local spin = tween(spinnerLabel, 0.65, {Rotation = spinnerLabel.Rotation + 180}, Enum.EasingStyle.Linear)
                        if spin then spin.Completed:Wait() else break end
                    end
                end)
                self._loadingText = label(overlay, text or "Loading…", 12, Theme.Secondary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
                self._loadingText.Position, self._loadingText.Size, self._loadingText.ZIndex = UDim2.new(0, 0, 0.5, 10), UDim2.new(1, 0, 0, 20), 41
            elseif self._loadingText then
                self._loadingText.Text = text or "Loading…"
            end
        elseif overlay then
            if self._stopLoadingSpin then self._stopLoadingSpin() end
            overlay:Destroy()
            self._loadingOverlay, self._loadingSpinner, self._loadingText = nil, nil, nil
        end
    end

    function Window:CreateTab(tabName, iconAsset)
        if self._destroyed then return nil end
        if type(tabName) == "table" then
            local config = tabName
            tabName, iconAsset = config.Name or config.Title or "Tab", config.Icon
        end
        tabName, iconAsset = tostring(tabName or "Tab"), iconAsset or Library.Icons.Home
        local entry = {Name = tabName}
        -- Control constructors keep using the window's shared connection,
        -- tween, and callback helpers while exposing a lightweight Tab object.
        entry._Connect = function(_, ...) return Window:_Connect(...) end
        entry._Tween = function(_, ...) return Window:_Tween(...) end
        entry._Call = function(_, ...) return Window:_Call(...) end
        entry._ShowTooltip = function(_, ...) return Window:_ShowTooltip(...) end
        entry._HideTooltip = function(_, ...) return Window:_HideTooltip(...) end
        entry._keybinds = Window._keybinds
        local tabButton = create("TextButton", tabContainer, {
            Name = "Tab_" .. tabName, Size = UDim2.new(1, -16, 0, 38),
            BackgroundColor3 = Theme.Elevated, BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, LayoutOrder = #self._tabs + 1,
        })
        corner(tabButton, 8)
        local tabIcon = create("ImageLabel", tabButton, {
            Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 13, 0.5, -9),
            BackgroundTransparency = 1, Image = iconAsset, ImageColor3 = Theme.Muted,
        })
        local tabLabel = label(tabButton, tabName, 12, Theme.Secondary, Enum.Font.GothamMedium)
        tabLabel.Position, tabLabel.Size = UDim2.fromOffset(42, 0), UDim2.new(1, -50, 1, 0)
        local page = create("CanvasGroup", contentArea, {
            Name = "Page_" .. tabName, Size = UDim2.new(1, -24, 1, -20),
            Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1,
            Visible = false, GroupTransparency = 0,
        })
        local scroll = create("ScrollingFrame", page, {
            Name = "Scroll", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })
        local contentLayout = create("UIListLayout", scroll, {
            Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
        })
        create("UIPadding", scroll, {
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 6),
        })
        entry.Button, entry.Icon, entry.Label, entry.Page, entry.Scroll, entry.Layout = tabButton, tabIcon, tabLabel, page, scroll, contentLayout
        table.insert(self._tabs, entry)
        table.insert(self._searchEntries, {Name = tabName, Category = "Tab", Tab = entry})
        self:_Connect(tabButton.MouseEnter, function()
            if activeTab ~= entry then
                self:_Tween(tabButton, 0.12, {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.35})
                tabIcon.ImageColor3 = Theme.Text
            end
        end)
        self:_Connect(tabButton.MouseLeave, function()
            if activeTab ~= entry then
                self:_Tween(tabButton, 0.12, {BackgroundTransparency = 1})
                tabIcon.ImageColor3 = Theme.Muted
            end
        end)
        self:_Connect(tabButton.MouseButton1Click, function() activateTab(entry) end)
        self:_Connect(tabButton.MouseEnter, function()
            if self._collapsed then self:_ShowTooltip(tabButton, tabName) end
        end)
        self:_Connect(tabButton.MouseLeave, function() self:_HideTooltip() end)
        if #self._tabs == 1 then
            activeTab = entry
            page.Visible = true
            tabButton.BackgroundTransparency, tabButton.BackgroundColor3 = 0.22, Theme.Elevated
            tabIcon.ImageColor3, tabLabel.TextColor3, tabLabel.Font = Theme.Accent, Theme.Text, Enum.Font.GothamSemibold
            activeIndicator.Visible = true
            activeIndicator.Position = UDim2.new(0, 7, 0, 59)
        end

        local order = 0
        local function cardBase(height)
            order += 1
            local card = create("Frame", scroll, {
                Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0, LayoutOrder = order,
            })
            corner(card, 9)
            local cardStroke = stroke(card, Theme.Text, 0.94)
            table.insert(Window._themeUpdaters, function()
                if card.Parent then
                    card.BackgroundColor3 = Theme.Card
                    cardStroke.Color = Theme.Text
                end
            end)
            return card, cardStroke
        end
        local function register(name, target, category, callback)
            table.insert(Window._searchEntries, {Name = tostring(name), Category = category or "Control", Tab = entry, Target = target, Callback = callback})
        end
        local function setCardHover(card, outline)
            Window:_Connect(card.MouseEnter, function()
                Window:_Tween(card, 0.13, {BackgroundColor3 = Theme.Elevated})
                if outline then Window:_Tween(outline, 0.13, {Transparency = 0.89}) end
            end)
            Window:_Connect(card.MouseLeave, function()
                Window:_Tween(card, 0.13, {BackgroundColor3 = Theme.Card})
                if outline then Window:_Tween(outline, 0.13, {Transparency = 0.94}) end
            end)
        end

        function entry:CreateSection(sectionTitle, description, icon)
            if type(sectionTitle) == "table" then
                local config = sectionTitle
                sectionTitle, description, icon = config.Title or config.Name, config.Description, config.Icon
            end
            order += 1
            local section = create("Frame", scroll, {
                Name = "Section", Size = UDim2.new(1, 0, 0, description and 52 or 34),
                BackgroundTransparency = 1, LayoutOrder = order,
            })
            local sectionIcon
            local sectionName
            if icon then
                sectionIcon = create("ImageLabel", section, {
                    Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 1, 0, 7),
                    BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Accent,
                })
                sectionName = label(section, tostring(sectionTitle or "Section"), 12, Theme.Text, Enum.Font.GothamBold)
                sectionName.Position, sectionName.Size = UDim2.new(0, 26, 0, 2), UDim2.new(1, -28, 0, 23)
            else
                sectionName = label(section, string.upper(tostring(sectionTitle or "Section")), 11, Theme.Text, Enum.Font.GothamBold)
                sectionName.Position, sectionName.Size = UDim2.new(0, 1, 0, 1), UDim2.new(1, -2, 0, 20)
            end
            local detail
            if description then
                detail = label(section, tostring(description), 11, Theme.Muted)
                detail.Position, detail.Size = UDim2.new(0, icon and 26 or 1, 0, 23), UDim2.new(1, -28, 0, 22)
            end
            table.insert(Window._themeUpdaters, function()
                if section.Parent then
                    sectionName.TextColor3 = Theme.Text
                    if detail then detail.TextColor3 = Theme.Muted end
                    if sectionIcon then sectionIcon.ImageColor3 = Theme.Accent end
                end
            end)
            return section
        end

        function entry:CreateCard(config)
            config = type(config) == "table" and config or {Title = tostring(config)}
            local titleText = config.Title or "Card"
            local desc = config.Description or ""
            local card, outline = cardBase(config.Height or (desc ~= "" and 80 or 56))
            local titleLabel = label(card, titleText, 13, Theme.Text, Enum.Font.GothamSemibold)
            titleLabel.Position, titleLabel.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 21)
            local descriptionLabel = label(card, desc, 11, Theme.Secondary)
            descriptionLabel.Position, descriptionLabel.Size = UDim2.fromOffset(14, 34), UDim2.new(1, -28, 0, 34)
            descriptionLabel.TextWrapped, descriptionLabel.TextYAlignment = true, Enum.TextYAlignment.Top
            local cardIcon
            if config.Icon then
                cardIcon = create("ImageLabel", card, {
                    Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -32, 0, 13),
                    BackgroundTransparency = 1, Image = config.Icon, ImageColor3 = Theme.Accent,
                })
                titleLabel.Size = UDim2.new(1, -60, 0, 21)
            end
            table.insert(Window._themeUpdaters, function()
                if card.Parent then
                    titleLabel.TextColor3 = Theme.Text
                    descriptionLabel.TextColor3 = Theme.Secondary
                    if cardIcon then cardIcon.ImageColor3 = Theme.Accent end
                end
            end)
            setCardHover(card, outline)
            register(titleText, card, "Card")
            return card
        end

        function entry:CreateButton(config, callback)
            if type(config) ~= "table" then config = {Title = tostring(config or "Action"), Callback = callback} end
            local titleText = config.Title or config.Text or "Action"
            local desc = config.Description
            local height = desc and 62 or 48
            local button, outline = cardBase(height)
            button.Name = "Button_" .. tostring(titleText)
            button.ClipsDescendants = true
            local icon
            if config.Icon then
                icon = create("ImageLabel", button, {
                    Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 14, 0.5, -9),
                    BackgroundTransparency = 1, Image = config.Icon, ImageColor3 = Theme.Accent,
                })
            end
            local left = icon and 43 or 14
            local titleLabel = label(button, titleText, 12, Theme.Text, Enum.Font.GothamSemibold)
            titleLabel.Position, titleLabel.Size = UDim2.new(0, left, 0, desc and 9 or 0), UDim2.new(1, -left - 46, 1, desc and -25 or 0)
            if desc then
                local detail = label(button, desc, 10, Theme.Muted)
                detail.Position, detail.Size = UDim2.new(0, left, 0, 32), UDim2.new(1, -left - 46, 0, 18)
            end
            local trailing = label(button, config.RightText or "→", 16, Theme.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
            trailing.Position, trailing.Size = UDim2.new(1, -38, 0.5, -15), UDim2.fromOffset(24, 30)
            local busy = false
            local disabled = config.Disabled == true
            local stateObject = {}
            local function setDisabled(value)
                disabled = value == true
                button.Active = not disabled
                button.BackgroundTransparency = disabled and 0.35 or 0
                titleLabel.TextTransparency = disabled and 0.45 or 0
            end
            function stateObject:SetDisabled(value) setDisabled(value) end
            function stateObject:SetLoading(value)
                busy = value == true
                trailing.Text = busy and "…" or (config.RightText or "→")
                button.Active = not busy and not disabled
            end
            function stateObject:SetState(value)
                local map = {Success = Theme.Success, Error = Theme.Error, Idle = Theme.Muted}
                trailing.TextColor3 = map[value] or Theme.Muted
                if value == "Success" then trailing.Text = "✓" elseif value == "Error" then trailing.Text = "!" end
            end
            table.insert(Window._themeUpdaters, function()
                if button.Parent then
                    titleLabel.TextColor3 = Theme.Text
                    trailing.TextColor3 = Theme.Muted
                end
            end)
            button.Activated:Connect(function()
                if disabled or busy then return end
                Window:_Tween(button, 0.08, {BackgroundColor3 = Theme.Hover})
                task.delay(0.09, function() if button.Parent then Window:_Tween(button, 0.12, {BackgroundColor3 = Theme.Elevated}) end end)
                Window:_Call(config.Callback)
            end)
            setCardHover(button, outline)
            register(titleText, button, "Button")
            return stateObject
        end

        function entry:CreateToggle(config, default, callback)
            if type(config) ~= "table" then
                config = {Title = tostring(config or "Toggle"), Default = default, Callback = callback}
            end
            local titleText = config.Title or config.Text or "Toggle"
            local desc = config.Description
            local frame, outline = cardBase(desc and 62 or 48)
            frame.Name = "Toggle_" .. tostring(titleText)
            local titleLabel = label(frame, titleText, 12, Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Position, titleLabel.Size = UDim2.fromOffset(14, desc and 8 or 0), UDim2.new(1, -82, 1, desc and -22 or 0)
            if desc then
                local detail = label(frame, desc, 10, Theme.Muted)
                detail.Position, detail.Size = UDim2.fromOffset(14, 33), UDim2.new(1, -82, 0, 17)
            end
            local switch = create("TextButton", frame, {
                Size = UDim2.fromOffset(38, 22), Position = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = Theme.Elevated, Text = "", AutoButtonColor = false,
            })
            corner(switch, 12)
            local thumb = create("Frame", switch, {
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Theme.Text, BorderSizePixel = 0,
            })
            corner(thumb, 9)
            local value = config.Default == true
            local disabled = config.Disabled == true
            local function apply(animate, shouldCall)
                switch.BackgroundColor3 = value and Theme.Accent or Theme.Elevated
                local target = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                if animate then
                    Window:_Tween(switch, 0.18, {BackgroundColor3 = value and Theme.Accent or Theme.Elevated})
                    Window:_Tween(thumb, 0.2, {Position = target}, Enum.EasingStyle.Quart)
                else
                    thumb.Position = target
                end
                switch.Active = not disabled
                if shouldCall then Window:_Call(config.Callback, value) end
            end
            Window:_Connect(switch.Activated, function()
                if disabled then return end
                value = not value
                apply(true, true)
            end)
            table.insert(Window._themeUpdaters, function()
                if frame.Parent then
                    titleLabel.TextColor3 = Theme.Text
                    thumb.BackgroundColor3 = Theme.Text
                    switch.BackgroundColor3 = value and Theme.Accent or Theme.Elevated
                end
            end)
            setCardHover(frame, outline)
            local object = {}
            function object:GetValue() return value end
            function object:SetValue(nextValue, fireCallback)
                value = nextValue == true
                apply(true, fireCallback == true)
            end
            function object:SetDisabled(nextValue)
                disabled = nextValue == true
                switch.Active = not disabled
                frame.BackgroundTransparency = disabled and 0.3 or 0
            end
            apply(false, false)
            register(titleText, frame, "Toggle")
            return object
        end

        function entry:CreateSlider(config, min, max, default, callback)
            if type(config) ~= "table" then
                config = {Title = tostring(config or "Slider"), Min = min, Max = max, Default = default, Callback = callback}
            end
            local titleText = config.Title or config.Text or "Slider"
            local minValue = tonumber(config.Min) or 0
            local maxValue = tonumber(config.Max) or 100
            if maxValue <= minValue then maxValue = minValue + 1 end
            local step = math.max(0.000001, tonumber(config.Step) or 1)
            local decimals = math.clamp(tonumber(config.Decimals) or (step < 1 and 1 or 0), 0, 4)
            local suffix = config.Suffix or ""
            local frame, outline = cardBase(config.Description and 82 or 70)
            frame.Name = "Slider_" .. tostring(titleText)
            local titleLabel = label(frame, titleText, 12, Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Position, titleLabel.Size = UDim2.fromOffset(14, 7), UDim2.new(1, -112, 0, 20)
            local valueLabel = label(frame, "", 11, Theme.Accent, Enum.Font.GothamSemibold, Enum.TextXAlignment.Right)
            valueLabel.Position, valueLabel.Size = UDim2.new(1, -92, 0, 7), UDim2.fromOffset(78, 20)
            local value = minValue
            local disabled = config.Disabled == true
            local track = create("TextButton", frame, {
                Size = UDim2.new(1, -28, 0, 8), Position = UDim2.new(0, 14, 0, config.Description and 58 or 48),
                BackgroundColor3 = Theme.Elevated, Text = "", AutoButtonColor = false,
                Selectable = true,
            })
            corner(track, 5)
            local fill = create("Frame", track, {
                Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
            })
            corner(fill, 5)
            local gradient = create("UIGradient", fill, {
                Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
            })
            local knob = create("Frame", track, {
                Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Theme.Text, BorderSizePixel = 0,
            })
            corner(knob, 8)
            stroke(knob, Theme.Accent, 0.5)
            local function format(valueToFormat)
                return string.format("%." .. tostring(decimals) .. "f", valueToFormat) .. suffix
            end
            local function quantize(raw)
                local stepped = minValue + math.floor(((raw - minValue) / step) + 0.5) * step
                local factor = 10 ^ decimals
                return math.clamp(math.floor(stepped * factor + 0.5) / factor, minValue, maxValue)
            end
            local function setValue(nextValue, shouldCall, animate)
                value = quantize(math.clamp(tonumber(nextValue) or minValue, minValue, maxValue))
                local pct = (value - minValue) / (maxValue - minValue)
                valueLabel.Text = format(value)
                local size = UDim2.new(pct, 0, 1, 0)
                local position = UDim2.new(pct, 0, 0.5, 0)
                if animate then
                    Window:_Tween(fill, 0.08, {Size = size})
                    Window:_Tween(knob, 0.08, {Position = position})
                else
                    fill.Size, knob.Position = size, position
                end
                if shouldCall then Window:_Call(config.Callback, value) end
            end
            local function fromX(x)
                local width = math.max(1, track.AbsoluteSize.X)
                local pct = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
                setValue(minValue + (maxValue - minValue) * pct, true, true)
            end
            local isDragging = false
            self:_Connect(track.InputBegan, function(input)
                if disabled then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    fromX(input.Position.X)
                    Window:_Tween(knob, 0.1, {Size = UDim2.fromOffset(17, 17)})
                end
            end)
            self:_Connect(UserInputService.InputChanged, function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    fromX(input.Position.X)
                end
            end)
            self:_Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                    if knob.Parent then Window:_Tween(knob, 0.1, {Size = UDim2.fromOffset(14, 14)}) end
                end
            end)
            self:_Connect(UserInputService.InputBegan, function(input, processed)
                if processed or disabled or not track:IsFocused() then return end
                if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Down then setValue(value - step, true, true)
                elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Up then setValue(value + step, true, true) end
            end)
            setCardHover(frame, outline)
            table.insert(Window._themeUpdaters, function()
                if frame.Parent then
                    titleLabel.TextColor3 = Theme.Text
                    valueLabel.TextColor3 = Theme.Accent
                    fill.BackgroundColor3 = Theme.Accent
                    gradient.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
                    track.BackgroundColor3 = Theme.Elevated
                end
            end)
            local object = {}
            function object:GetValue() return value end
            function object:SetValue(nextValue, fireCallback) setValue(nextValue, fireCallback == true, true) end
            function object:SetDisabled(nextValue)
                disabled = nextValue == true
                track.Active = not disabled
                frame.BackgroundTransparency = disabled and 0.3 or 0
            end
            setValue(config.Default or minValue, false, false)
            register(titleText, frame, "Slider")
            return object
        end

        function entry:CreateTextbox(config, callback)
            if type(config) ~= "table" then config = {Placeholder = tostring(config or ""), Callback = callback} end
            local placeholder = config.Placeholder or config.Title or "Type something…"
            local titleText = config.Title or placeholder
            local frame, outline = cardBase(config.Description and 82 or 54)
            frame.Name = "Textbox_" .. tostring(titleText)
            if config.Title and config.Title ~= placeholder then
                local titleLabel = label(frame, config.Title, 11, Theme.Secondary, Enum.Font.GothamMedium)
                titleLabel.Position, titleLabel.Size = UDim2.fromOffset(13, 4), UDim2.new(1, -26, 0, 17)
            end
            if config.Description then
                local detail = label(frame, config.Description, 10, Theme.Muted)
                detail.Position, detail.Size = UDim2.fromOffset(13, 19), UDim2.new(1, -26, 0, 15)
            end
            local input = create("TextBox", frame, {
                Position = UDim2.new(0, 10, 1, -42), Size = UDim2.new(1, -20, 0, 32),
                BackgroundColor3 = Theme.Elevated, Text = config.Default or "",
                PlaceholderText = placeholder, PlaceholderColor3 = Theme.Muted,
                TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
                ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
            })
            corner(input, 7)
            create("UIPadding", input, {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 34)})
            local clear = create("TextButton", input, {
                Size = UDim2.fromOffset(26, 28), Position = UDim2.new(1, -29, 0, 2),
                BackgroundTransparency = 1, Text = "×", TextColor3 = Theme.Muted,
                Font = Enum.Font.Gotham, TextSize = 17, AutoButtonColor = false,
                Visible = config.Clearable ~= false,
            })
            local validationLabel
            local function validate()
                local valid, message = true, nil
                if type(config.Validate) == "function" then
                    local ok, result, resultMessage = pcall(config.Validate, input.Text)
                    valid, message = ok and result ~= false, resultMessage
                    if not ok then message = "Validation failed" end
                end
                outline.Color = valid and Theme.Accent or Theme.Error
                outline.Transparency = valid and 0.55 or 0.25
                if config.ValidationMessage then
                    validationLabel = validationLabel or label(frame, "", 10, Theme.Error)
                    validationLabel.Position, validationLabel.Size = UDim2.new(0, 12, 1, -16), UDim2.new(1, -24, 0, 13)
                    validationLabel.Text = valid and (message or "") or (message or config.ValidationMessage)
                    validationLabel.TextColor3 = valid and Theme.Success or Theme.Error
                end
                return valid
            end
            table.insert(Window._themeUpdaters, function()
                if frame.Parent then
                    input.BackgroundColor3 = Theme.Elevated
                    input.TextColor3 = Theme.Text
                    input.PlaceholderColor3 = Theme.Muted
                    clear.TextColor3 = Theme.Muted
                end
            end)
            self:_Connect(input.Focused, function()
                Window:_Tween(outline, 0.14, {Color = Theme.Accent, Transparency = 0.35})
                Window:_Tween(input, 0.14, {BackgroundColor3 = Theme.Hover})
            end)
            self:_Connect(input.FocusLost, function(enterPressed)
                local valid = validate()
                Window:_Tween(input, 0.14, {BackgroundColor3 = Theme.Elevated})
                if valid then Window:_Call(config.Callback, input.Text, enterPressed) end
            end)
            self:_Connect(clear.Activated, function() input.Text = "" input:CaptureFocus() end)
            setCardHover(frame, outline)
            local object = {}
            function object:GetValue() return input.Text end
            function object:SetValue(value, fireCallback)
                input.Text = tostring(value or "")
                if fireCallback then Window:_Call(config.Callback, input.Text, false) end
            end
            function object:Validate() return validate() end
            register(titleText, frame, "Input")
            return object
        end

        function entry:CreateDropdown(config, options, defaultOption, callback)
            if type(config) ~= "table" then
                config = {Title = tostring(config or "Dropdown"), Options = options, Default = defaultOption, Callback = callback}
            end
            local titleText = config.Title or config.Text or "Dropdown"
            local values = config.Options or {}
            local selected = config.Default
            if selected == nil then selected = values[1] or "Select…" end
            local maxVisible = tonumber(config.MaxVisible) or 5
            local rowHeight, itemHeight = 46, 30
            local frame, outline = cardBase(rowHeight)
            frame.Name = "Dropdown_" .. tostring(titleText)
            frame.ClipsDescendants = false
            frame.ZIndex = 2
            local headerBtn = create("TextButton", frame, {
                Size = UDim2.new(1, 0, 0, rowHeight), BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false, ZIndex = 3,
            })
            local titleLabel = label(headerBtn, titleText, 12, Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Position, titleLabel.Size, titleLabel.ZIndex = UDim2.fromOffset(14, 0), UDim2.new(0.52, -12, 1, 0), 4
            local selectedLabel = label(headerBtn, tostring(selected), 11, Theme.Accent, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
            selectedLabel.Position, selectedLabel.Size, selectedLabel.ZIndex = UDim2.new(0.48, 0, 0, 0), UDim2.new(0.44, -34, 1, 0), 4
            local arrow = create("ImageLabel", headerBtn, {
                Size = UDim2.fromOffset(15, 15), Position = UDim2.new(1, -28, 0.5, -7),
                BackgroundTransparency = 1, Image = Library.Icons.ChevronDown,
                ImageColor3 = Theme.Muted, ZIndex = 4,
            })
            local opened = false
            local needsSearch = config.Searchable == true or #values > 8
            local listHeight = math.min(#values, maxVisible) * (itemHeight + 4) + 8 + (needsSearch and 32 or 0)
            local searchBox
            local list = create("ScrollingFrame", frame, {
                Name = "Options", Position = UDim2.new(0, 8, 0, rowHeight - 1),
                Size = UDim2.new(1, -16, 0, 0), BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false, ZIndex = 8,
            })
            corner(list, 8)
            stroke(list, Theme.Text, 0.91)
            local optionLayout = create("UIListLayout", list, {
                Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder,
            })
            create("UIPadding", list, {
                PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
            })
            if needsSearch then
                searchBox = create("TextBox", list, {
                    Name = "OptionSearch", Size = UDim2.new(1, 0, 0, 29),
                    BackgroundColor3 = Theme.Card, Text = "", PlaceholderText = "Filter options…",
                    TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
                    Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, ZIndex = 9,
                })
                corner(searchBox, 6)
                create("UIPadding", searchBox, {PaddingLeft = UDim.new(0, 9)})
            end
            local optionButtons = {}
            local function repaintOptions(query)
                query = string.lower(query or "")
                for _, item in ipairs(optionButtons) do
                    local match = query == "" or string.find(string.lower(tostring(item.Value)), query, 1, true) ~= nil
                    item.Button.Visible = match
                    local isSelected = item.Value == selected
                    item.NameLabel.TextColor3 = isSelected and Theme.Accent or Theme.Secondary
                    item.Check.Visible = isSelected
                end
            end
            local function makeOption(option, index)
                local row = create("TextButton", list, {
                    Size = UDim2.new(1, 0, 0, itemHeight), BackgroundColor3 = Theme.Card,
                    BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
                    LayoutOrder = index, ZIndex = 9,
                })
                corner(row, 6)
                local optionLabel = label(row, tostring(option), 11, Theme.Secondary, Enum.Font.Gotham)
                optionLabel.Position, optionLabel.Size, optionLabel.ZIndex = UDim2.fromOffset(9, 0), UDim2.new(1, -35, 1, 0), 10
                local check = label(row, "✓", 12, Theme.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
                check.Position, check.Size, check.ZIndex = UDim2.new(1, -28, 0, 0), UDim2.fromOffset(22, itemHeight), 10
                Window:_Connect(row.MouseEnter, function() Window:_Tween(row, 0.1, {BackgroundTransparency = 0.2}) end)
                Window:_Connect(row.MouseLeave, function() Window:_Tween(row, 0.1, {BackgroundTransparency = 1}) end)
                table.insert(optionButtons, {Button = row, Value = option, NameLabel = optionLabel, Check = check})
                Window:_Connect(row.Activated, function()
                    selected = option
                    selectedLabel.Text = tostring(selected)
                    repaintOptions(searchBox and searchBox.Text or "")
                    opened = false
                    arrow.Rotation = 0
                    Window:_Tween(frame, 0.18, {Size = UDim2.new(1, 0, 0, rowHeight)})
                    Window:_Tween(list, 0.16, {Size = UDim2.new(1, -16, 0, 0)})
                    task.delay(0.16, function() if list.Parent then list.Visible = false end end)
                    Window:_Call(config.Callback, selected)
                end)
                table.insert(Window._themeUpdaters, function()
                    if row.Parent then
                        optionLabel.TextColor3 = option == selected and Theme.Accent or Theme.Secondary
                        check.TextColor3 = Theme.Accent
                    end
                end)
            end
            for index, option in ipairs(values) do
                makeOption(option, index)
            end
            if searchBox then self:_Connect(searchBox:GetPropertyChangedSignal("Text"), function() repaintOptions(searchBox.Text) end) end
            repaintOptions("")
            table.insert(Window._themeUpdaters, function()
                if frame.Parent then
                    titleLabel.TextColor3 = Theme.Text
                    selectedLabel.TextColor3 = Theme.Accent
                    arrow.ImageColor3 = Theme.Muted
                    list.BackgroundColor3 = Theme.Surface
                    if searchBox then searchBox.BackgroundColor3, searchBox.TextColor3 = Theme.Card, Theme.Text end
                end
            end)
            self:_Connect(headerBtn.Activated, function()
                opened = not opened
                if opened then
                    list.Visible = true
                    list.Size = UDim2.new(1, -16, 0, 0)
                    Window:_Tween(frame, 0.2, {Size = UDim2.new(1, 0, 0, rowHeight + listHeight)})
                    Window:_Tween(list, 0.2, {Size = UDim2.new(1, -16, 0, listHeight)})
                    Window:_Tween(arrow, 0.18, {Rotation = 180})
                else
                    Window:_Tween(frame, 0.18, {Size = UDim2.new(1, 0, 0, rowHeight)})
                    Window:_Tween(list, 0.16, {Size = UDim2.new(1, -16, 0, 0)})
                    Window:_Tween(arrow, 0.18, {Rotation = 0})
                    task.delay(0.17, function() if list.Parent and not opened then list.Visible = false end end)
                end
            end)
            local object = {}
            function object:GetValue() return selected end
            function object:SetValue(nextValue, fireCallback)
                selected = nextValue
                selectedLabel.Text = tostring(selected)
                repaintOptions(searchBox and searchBox.Text or "")
                if fireCallback then Window:_Call(config.Callback, selected) end
            end
            function object:SetOptions(nextOptions)
                values = nextOptions or {}
                for _, item in ipairs(optionButtons) do item.Button:Destroy() end
                optionButtons = {}
                for index, option in ipairs(values) do
                    makeOption(option, index)
                end
                if not table.find(values, selected) then selected = values[1] or "Select…" end
                selectedLabel.Text = tostring(selected)
                listHeight = math.min(#values, maxVisible) * (itemHeight + 4) + 8 + (needsSearch and 32 or 0)
                if opened then list.Size = UDim2.new(1, -16, 0, listHeight) end
                repaintOptions(searchBox and searchBox.Text or "")
            end
            register(titleText, frame, "Dropdown")
            return object
        end

        function entry:CreateKeybind(config, defaultKey, callback)
            if type(config) ~= "table" then
                config = {Title = tostring(config or "Keybind"), Default = defaultKey, Callback = callback}
            end
            local titleText = config.Title or config.Text or "Keybind"
            local currentKey = config.Default or Enum.KeyCode.E
            local listening = false
            local frame, outline = cardBase(48)
            frame.Name = "Keybind_" .. tostring(titleText)
            local titleLabel = label(frame, titleText, 12, Theme.Text, Enum.Font.GothamMedium)
            titleLabel.Position, titleLabel.Size = UDim2.fromOffset(14, 0), UDim2.new(1, -116, 1, 0)
            local keyButton = create("TextButton", frame, {
                Size = UDim2.fromOffset(88, 28), Position = UDim2.new(1, -101, 0.5, -14),
                BackgroundColor3 = Theme.Elevated, Text = normalizeKey(currentKey),
                TextColor3 = Theme.Accent, Font = Enum.Font.GothamSemibold,
                TextSize = 11, AutoButtonColor = false,
            })
            corner(keyButton, 7)
            local function displayKey(key)
                if key == nil then return "None" end
                if typeof(key) == "EnumItem" and key.EnumType == Enum.UserInputType then
                    return key.Name:gsub("MouseButton", "Mouse ")
                end
                return normalizeKey(key)
            end
            local function beginListening()
                listening = true
                keyButton.Text = "Press a key…"
                keyButton.TextColor3 = Theme.Warning
                outline.Color, outline.Transparency = Theme.Warning, 0.45
            end
            self:_Connect(keyButton.Activated, beginListening)
            self:_Connect(UserInputService.InputBegan, function(input, processed)
                if listening then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        listening = false
                        keyButton.Text = displayKey(currentKey)
                        keyButton.TextColor3 = Theme.Accent
                        outline.Color, outline.Transparency = Theme.Text, 0.94
                        return
                    end
                    if input.KeyCode == Enum.KeyCode.Backspace then
                        currentKey = nil
                    elseif input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                        currentKey = input.UserInputType
                    else
                        return
                    end
                    listening = false
                    for _, bind in ipairs(self._keybinds) do
                        if bind ~= object and bind:GetValue() == currentKey then
                            bind:SetValue(nil, false)
                        end
                    end
                    keyButton.Text = displayKey(currentKey)
                    keyButton.TextColor3 = Theme.Accent
                    outline.Color, outline.Transparency = Theme.Text, 0.94
                    Window:_Call(config.Callback, currentKey)
                    return
                end
                if processed or currentKey == nil then return end
                local matches = input.KeyCode == currentKey or input.UserInputType == currentKey
                if matches then Window:_Call(config.Callback, currentKey, input) end
            end)
            local object = {}
            function object:GetValue() return currentKey end
            function object:SetValue(nextValue, fireCallback)
                currentKey = nextValue
                keyButton.Text = displayKey(currentKey)
                if fireCallback then Window:_Call(config.Callback, currentKey) end
            end
            function object:Listen() beginListening() end
            table.insert(self._keybinds, object)
            register(titleText, frame, "Keybind")
            return object
        end

        function entry:CreateEmptyState(config)
            config = type(config) == "table" and config or {Title = tostring(config or "Nothing here yet")}
            local empty, outline = cardBase(config.Height or 142)
            local image = create("ImageLabel", empty, {
                Size = UDim2.fromOffset(24, 24), Position = UDim2.new(0.5, -12, 0, 20),
                BackgroundTransparency = 1, Image = config.Icon or Library.Icons.Bell,
                ImageColor3 = Theme.Muted,
            })
            local titleLabel = label(empty, config.Title or "Nothing here yet", 13, Theme.Text, Enum.Font.GothamSemibold, Enum.TextXAlignment.Center)
            titleLabel.Position, titleLabel.Size = UDim2.new(0, 12, 0, 52), UDim2.new(1, -24, 0, 22)
            local detail = label(empty, config.Description or "There is nothing to show here right now.", 11, Theme.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
            detail.Position, detail.Size = UDim2.new(0, 22, 0, 77), UDim2.new(1, -44, 0, 34)
            detail.TextWrapped = true
            table.insert(Window._themeUpdaters, function()
                if empty.Parent then
                    titleLabel.TextColor3 = Theme.Text
                    detail.TextColor3 = Theme.Muted
                    image.ImageColor3 = Theme.Muted
                end
            end)
            setCardHover(empty, outline)
            return empty
        end

        function entry:GetPage() return page end
        function entry:Select() activateTab(entry) end
        function entry:_RegisterCommand(name, target, callback)
            register(name, target, "Action", callback)
        end

        local themeRefresh = function()
            tabButton.BackgroundColor3 = Theme.Elevated
            tabIcon.ImageColor3 = activeTab == entry and Theme.Accent or Theme.Muted
            tabLabel.TextColor3 = activeTab == entry and Theme.Text or Theme.Secondary
            scroll.ScrollBarImageColor3 = Theme.Accent
        end
        table.insert(self._themeUpdaters, themeRefresh)
        refreshBounds()
        return entry
    end

    function Window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        self._isVisible = false
        self:_HideTooltip()
        if self._stopLoadingSpin then self._stopLoadingSpin() end
        for _, connection in ipairs(self._connections) do
            if connection and connection.Connected then connection:Disconnect() end
        end
        for _, activeTween in ipairs(table.clone(self._tweens)) do
            pcall(function() activeTween:Cancel() end)
        end
        tween(main, 0.16, {GroupTransparency = 1})
        tween(scale, 0.16, {Scale = 0.96})
        task.delay(0.18, function()
            if screen.Parent then screen:Destroy() end
            if shadow.Parent then shadow:Destroy() end
        end)
        for index, item in ipairs(windows) do
            if item == self then table.remove(windows, index) break end
        end
    end

    local themeRefresh = function()
        main.BackgroundColor3 = Theme.Background
        mainStroke.Color = Theme.Text
        header.BackgroundColor3, headerFix.BackgroundColor3 = Theme.Surface, Theme.Surface
        title.TextColor3, subtitle.TextColor3 = Theme.Text, Theme.Muted
        appBadge.BackgroundColor3 = Theme.Elevated
        logo.ImageColor3 = Theme.Accent
        sidebar.BackgroundColor3 = Theme.Sidebar
        profile.BackgroundColor3 = Theme.Card
        profileName.TextColor3, profileHandle.TextColor3 = Theme.Text, Theme.Muted
        contentArea.BackgroundColor3 = Theme.Background
        activeIndicator.BackgroundColor3 = Theme.Accent
        searchPanel.BackgroundColor3 = Theme.Surface
        searchInput.BackgroundColor3 = Theme.Card
        searchInput.TextColor3 = Theme.Text
        if Window._loadingOverlay then Window._loadingOverlay.BackgroundColor3 = Theme.Background end
    end
    table.insert(Window._themeUpdaters, themeRefresh)

    -- Theme refreshers for common header controls.
    table.insert(Window._themeUpdaters, function()
        statusText.TextColor3 = Theme.Secondary
        statusDot.BackgroundColor3 = Theme.Success
        collapseButton.BackgroundColor3 = Theme.Card
    end)

    function Window:CreateModal(config)
        config = config or {}
        local overlay = create("Frame", screen, {
            Name = "ModalOverlay", Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
            ZIndex = 70,
        })
        local panel = create("Frame", overlay, {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47),
            Size = UDim2.new(0.78, 0, 0, config.Height or 220),
            BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 71,
        })
        corner(panel, 12)
        stroke(panel, Theme.Text, 0.87)
        create("UISizeConstraint", panel, {MinSize = Vector2.new(290, 180), MaxSize = Vector2.new(500, 380)})
        local titleLabel = label(panel, config.Title or "Confirm action", 15, Theme.Text, Enum.Font.GothamBold)
        titleLabel.Position, titleLabel.Size, titleLabel.ZIndex = UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 24), 72
        local description = label(panel, config.Content or config.Description or "", 12, Theme.Secondary)
        description.Position, description.Size, description.ZIndex = UDim2.fromOffset(20, 52), UDim2.new(1, -40, 0, 70), 72
        description.TextWrapped, description.TextYAlignment = true, Enum.TextYAlignment.Top
        local closeModal
        local function makeAction(text, x, isPrimary, callback)
            local button = create("TextButton", panel, {
                Size = UDim2.fromOffset(100, 34), Position = UDim2.new(1, x, 1, -50),
                BackgroundColor3 = isPrimary and Theme.Accent or Theme.Card,
                Text = text, TextColor3 = Theme.Text, Font = Enum.Font.GothamSemibold,
                TextSize = 11, AutoButtonColor = false, ZIndex = 72,
            })
            corner(button, 7)
            Window:_Connect(button.MouseEnter, function()
                Window:_Tween(button, 0.12, {BackgroundColor3 = isPrimary and Theme.Accent2 or Theme.Hover})
            end)
            Window:_Connect(button.MouseLeave, function()
                Window:_Tween(button, 0.12, {BackgroundColor3 = isPrimary and Theme.Accent or Theme.Card})
            end)
            Window:_Connect(button.Activated, function()
                if callback then Window:_Call(callback) end
                closeModal()
            end)
            return button
        end
        closeModal = function()
            if not overlay.Parent then return end
            Window:_Tween(overlay, 0.15, {BackgroundTransparency = 1})
            Window:_Tween(panel, 0.15, {Position = UDim2.fromScale(0.5, 0.46)})
            task.delay(0.16, function() if overlay.Parent then overlay:Destroy() end end)
        end
        makeAction(config.CancelText or "Cancel", -220, false, config.OnCancel)
        makeAction(config.ConfirmText or "Confirm", -116, true, config.Callback or config.OnConfirm)
        Window:_Tween(overlay, 0.18, {BackgroundTransparency = 0.42})
        Window:_Tween(panel, 0.2, {Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Back)
        return {Close = closeModal, Instance = overlay}
    end

    local function themeMenu(tab)
        local themeNames = {"Midnight", "Purple", "Blue", "Red", "Emerald", "Rose", "Monochrome"}
        tab:CreateSection("Appearance", "Adjust the shared interface accent and surface palette.", Library.Icons.Settings)
        tab:CreateDropdown({
            Title = "Color theme", Options = themeNames, Default = "Midnight",
            Searchable = false,
            Callback = function(name) Library:SetTheme(name) end,
        })
        tab:CreateButton({
            Title = "Reset theme", Description = "Return all components to the Midnight palette.",
            Icon = Library.Icons.Zap,
            Callback = function() Library:SetTheme("Midnight") end,
        })
    end
    Window.CreateThemeControls = function(_, tab)
        return themeMenu(tab)
    end

    -- Initial entrance: quick fade, small scale-up, and slight vertical settle.
    task.defer(function()
        if Window._destroyed or not main.Parent then return end
        refreshBounds()
        Window:_Tween(scale, 0.26, {Scale = 1}, Enum.EasingStyle.Back)
        Window:_Tween(main, 0.23, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quart)
    end)
    return Window
end

function Library:Confirm(config)
    config = config or {}
    local window = config.Window
    if not window or window._destroyed then
        for _, candidate in ipairs(windows) do
            if not candidate._destroyed then window = candidate break end
        end
    end
    if not window then
        self:Notify({Type = "Warning", Title = "No window available", Content = "Create a window before opening a dialog.", Duration = 3})
        return nil
    end
    return window:CreateModal(config)
end

function Library:SetLoading(isLoading, text)
    local window
    for _, candidate in ipairs(windows) do
        if not candidate._destroyed then window = candidate break end
    end
    if window then window:SetLoading(isLoading, text) end
end

return Library