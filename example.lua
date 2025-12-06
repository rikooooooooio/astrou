local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mc4121ban/Fluriore-UI/main/source.lua"))()

local Window = Library:MakeGui({
    NameHub = "Example Hub",
    Description = "Fluriore UI Example",
    Color = Color3.fromRGB(255,0,255)
})

local Tab = Window:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://16932740082"
})

local Section = Tab:AddSection("Main Features")

Section:AddParagraph({
    Title = "Information",
    Content = "This is a full example for Fluriore UI."
})

Section:AddButton({
    Title = "Click Me",
    Content = "Prints text and sends notify",
    Callback = function()
        print("Button clicked")
        Library:MakeNotify({
            Title = "Notification",
            Description = "Button",
            Content = "You clicked the button."
        })
    end
})

Section:AddToggle({
    Title = "Toggle Example",
    Content = "Enable or disable",
    Default = false,
    Callback = function(state)
        print("Toggle:", state)
    end
})

Section:AddSlider({
    Title = "WalkSpeed",
    Content = "Adjust your speed",
    Min = 10,
    Max = 50,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

Section:AddInput({
    Title = "Text Input",
    Content = "Type something",
    Placeholder = "Type here",
    Callback = function(text)
        print("Input:", text)
    end
})

Section:AddDropdown({
    Title = "Select Difficulty",
    Content = "Choose one",
    Multi = false,
    Options = {"Easy", "Medium", "Hard"},
    Default = {},
    Callback = function(selected)
        print("Selected:", selected)
    end
})

Section:AddDropdown({
    Title = "Select Multiple",
    Content = "Choose multiple options",
    Multi = true,
    Options = {"A","B","C","D"},
    Default = {},
    Callback = function(selected)
        for i,v in pairs(selected) do
            print("Selected:", v)
        end
    end
})
