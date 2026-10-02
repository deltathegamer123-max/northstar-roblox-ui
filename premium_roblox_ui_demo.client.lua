--[[
    Northstar UI showcase.
    Place this source in a LocalScript beside a ModuleScript named PremiumRobloxUI.
    All callbacks are harmless examples; connect your own game logic as needed.
]]

local Library = require(script.Parent:WaitForChild("PremiumRobloxUI"))

local Window = Library:CreateWindow("Northstar", "Premium interface · v3.0", {Status = "Ready"})
local HomeTab = Window:CreateTab("Overview", Library.Icons.Home)
local PlayerTab = Window:CreateTab("Player", Library.Icons.User)
local SettingsTab = Window:CreateTab("Settings", Library.Icons.Settings)

HomeTab:CreateSection("Workspace", "A compact control surface for your own Roblox experience.", Library.Icons.Zap)
HomeTab:CreateCard({
    Title = "Everything in one place",
    Description = "Organize actions, player preferences, and configuration in a responsive interface.",
    Icon = Library.Icons.Globe,
})
HomeTab:CreateButton({
    Title = "Run a sample action", Description = "Demonstrates the button interaction and toast system.",
    Icon = Library.Icons.Zap,
    Callback = function()
        Library:Notify({Type = "Success", Title = "Action complete", Content = "Your sample action ran successfully.", Duration = 3.5})
    end,
})
HomeTab:CreateToggle({
    Title = "Enable notifications", Description = "A showcase toggle with a programmatic state API.",
    Default = true,
    Callback = function(enabled)
        print("Notifications enabled:", enabled)
    end,
})
HomeTab:CreateButton({
    Title = "Open confirmation", Description = "Preview the reusable confirmation modal.",
    Callback = function()
        Library:Confirm({
            Window = Window, Title = "Continue?",
            Content = "This is a reusable dialog. Attach the confirm callback to your own action.",
            ConfirmText = "Continue", CancelText = "Not now",
            Callback = function()
                Library:Notify({Type = "Info", Title = "Confirmed", Content = "The dialog callback ran.", Duration = 3})
            end,
        })
    end,
})

PlayerTab:CreateSection("Preferences", "Control presentation-only settings for this demo.", Library.Icons.User)
PlayerTab:CreateSlider({
    Title = "Interface scale", Min = 80, Max = 120, Default = 100, Step = 5, Suffix = "%",
    Callback = function(value) print("Demo scale preference:", value) end,
})
PlayerTab:CreateDropdown({
    Title = "Notification style", Options = {"Info", "Success", "Warning", "Error"},
    Default = "Info", Searchable = true,
    Callback = function(value)
        Library:Notify({Type = value, Title = value .. " preview", Content = "This toast previews the selected status style.", Duration = 3})
    end,
})
PlayerTab:CreateTextbox({
    Title = "Display label", Placeholder = "Enter a short label…",
    Description = "Input includes focus styling and a clear action.",
    Validate = function(value)
        return #value <= 32, "Keep the label under 33 characters."
    end,
    ValidationMessage = "Keep the label under 33 characters.",
    Callback = function(value) print("Display label:", value) end,
})
PlayerTab:CreateKeybind({
    Title = "Demo keybind", Default = Enum.KeyCode.K,
    Callback = function(key, input)
        if input then print("Demo key pressed:", key.Name) end
    end,
})

SettingsTab:CreateSection("Configuration", "Personalize the palette and explore navigation.", Library.Icons.Settings)
Window:CreateThemeControls(SettingsTab)
SettingsTab:CreateButton({
    Title = "Search controls", Description = "Open the command palette with RightShift or this button.",
    Icon = Library.Icons.Search, Callback = function() Window:OpenSearch() end,
})
SettingsTab:CreateEmptyState({
    Title = "Ready for your settings",
    Description = "Add your own configuration controls here. The page scrolls as content grows.",
})

Library:Notify({
    Type = "Success", Title = "Northstar UI is ready",
    Content = "Press RightControl to show or hide the window. Press RightShift to search.",
    Duration = 4, Icon = Library.Icons.Zap,
})