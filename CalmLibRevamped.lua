-- V2 Fixed

local module = {}

local function safeCloneref(instance)
    if cloneref then
        return cloneref(instance)
    end

    return instance
end

local ts = safeCloneref(game:GetService("TweenService"))
local cg = safeCloneref(game:GetService("CoreGui"))
local ui = safeCloneref(game:GetService("UserInputService"))

local toggleRefs = {}
local sliderRefs = {}
local textboxRefs = {}

local function safeCallback(cb, ...)
    if not cb then return end

    local args = table.pack(...)
    task.spawn(function()
        local success, err = pcall(cb, table.unpack(args, 1, args.n))
        if not success then
            warn("[CalmLib] Callback error:", err)
        end
    end)
end

function module:win(title)
    local window = game:GetObjects("rbxassetid://96576283085736")[1]
    local elements = game:GetObjects("rbxassetid://83539751566719")[1]

    if not window then
        error("[CalmLib] Window asset failed to load")
    end

    if not elements then
        error("[CalmLib] Elements asset failed to load")
    end

    local hui = gethui or get_hidden_gui
    if hui then
        window.Parent = hui()
    else
        window.Parent = cg
    end

    local topbar = window.Frame.topbar
    topbar.title.Text = title

    local closeBtn = topbar.btns.Close
    local miniBtn = topbar.btns.Minimize
    local toggleCon

    local function fadebtn(btn, isIn)
        ts:Create(btn, TweenInfo.new(0.15), {
            BackgroundTransparency = isIn and 0.8 or 1
        }):Play()
    end

    local function togglewin(isIn)
        ts:Create(window.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            GroupTransparency = isIn and 0 or 1
        }):Play()

        ts:Create(window.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = isIn and UDim2.new(0.37, 0, 0.407, 0) or UDim2.new(0.37, 0, 0.376, 0)
        }):Play()

        window.Frame.Interactable = isIn
    end

    local function fadetopbar(isIn)
        ts:Create(topbar, TweenInfo.new(0.15), {
            BackgroundTransparency = isIn and 0.7 or 0.8
        }):Play()
    end

    closeBtn.MouseEnter:Connect(function()
        fadebtn(closeBtn, true)
    end)

    miniBtn.MouseEnter:Connect(function()
        fadebtn(miniBtn, true)
    end)

    closeBtn.MouseLeave:Connect(function()
        fadebtn(closeBtn, false)
    end)

    miniBtn.MouseLeave:Connect(function()
        fadebtn(miniBtn, false)
    end)

    topbar.MouseEnter:Connect(function()
        fadetopbar(true)
    end)

    topbar.MouseLeave:Connect(function()
        fadetopbar(false)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        window:Destroy()
        elements:Destroy()

        if toggleCon then
            toggleCon:Disconnect()
        end
    end)

    miniBtn.MouseButton1Click:Connect(function()
        togglewin(false)
    end)

    toggleCon = ui.InputBegan:Connect(function(keyc, gamep)
        if not gamep and keyc.KeyCode == Enum.KeyCode.K then
            togglewin(not window.Frame.Interactable)
        end
    end)

    local sections = {}
    local curSelected
    local dragging = false
    local dragInput
    local mousePos
    local framePos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = window.Frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    ui.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            window.Frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)

    local function toggletab(tab, isIn)
        ts:Create(tab, TweenInfo.new(0.25), {
            GroupTransparency = isIn and 0 or 1
        }):Play()

        ts:Create(tab, TweenInfo.new(0.25), {
            Position = isIn and UDim2.new(0.5, 0, 1, 0) or UDim2.new(0.5, 0, 1.1, 0)
        }):Play()

        tab.Interactable = isIn
    end

    local function fadeelement(which, isIn)
        ts:Create(which, TweenInfo.new(0.15), {
            BackgroundTransparency = isIn and 0.7 or 0.8
        }):Play()
    end

    function sections:tab(tabTitle, ico)
        local newBtn = elements.tabelement:Clone()
        newBtn.Name = tabTitle
        newBtn.Image = ico
        newBtn.title.Text = tabTitle
        newBtn.Parent = window.Frame.tabscontainer

        local newSect = elements.sectioncanvas:Clone()
        newSect.Parent = window.Frame.sectionsholder
        newSect.GroupTransparency = 1
        newSect.Position = UDim2.new(0.5, 0, 1.1, 0)
        newSect.Interactable = false

        local function fadetab(isIn)
            ts:Create(newBtn, TweenInfo.new(0.15), {
                ImageTransparency = isIn and 0.25 or 0.5
            }):Play()

            ts:Create(newBtn.title, TweenInfo.new(0.15), {
                TextTransparency = isIn and 0.5 or 1
            }):Play()
        end

        newBtn.MouseEnter:Connect(function()
            fadetab(true)
        end)

        newBtn.MouseLeave:Connect(function()
            fadetab(false)
        end)

        newBtn.MouseButton1Click:Connect(function()
            if curSelected == newSect then return end

            if curSelected then
                toggletab(curSelected, false)
            end

            toggletab(newSect, true)
            curSelected = newSect
        end)

        local contents = {}

        function contents:label(labelTitle)
            local newLabel = elements.LabelElement:Clone()
            newLabel.lbl.Text = labelTitle
            newLabel.Parent = newSect.sectioncontainer
            return newLabel
        end

        function contents:button(buttonTitle, cb)
            local newButton = elements.ButtonElement:Clone()
            newButton.btn.lbl.Text = buttonTitle
            newButton.Parent = newSect.sectioncontainer

            newButton.btn.MouseEnter:Connect(function()
                fadeelement(newButton.btn, true)
            end)

            newButton.btn.MouseLeave:Connect(function()
                fadeelement(newButton.btn, false)
            end)

            newButton.btn.MouseButton1Click:Connect(function()
                safeCallback(cb)
            end)

            return newButton
        end

        function contents:toggle(toggleTitle, default, cb)
            local toggled = default == true
            local newToggle = elements.ToggleElement:Clone()
            newToggle.btn.lbl.Text = toggleTitle
            newToggle.Parent = newSect.sectioncontainer

            local togglebg = newToggle.btn.togglebg
            local sidetog = togglebg.Frame

            local function setVisual(state)
                ts:Create(sidetog, TweenInfo.new(0.15), {
                    AnchorPoint = state and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
                }):Play()

                ts:Create(sidetog, TweenInfo.new(0.15), {
                    Position = state and UDim2.new(1, 0, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
                }):Play()

                togglebg.BackgroundColor3 = state and Color3.fromRGB(74, 255, 89) or Color3.fromRGB(255, 75, 75)
            end

            local function setState(state, callCallback)
                toggled = state == true
                setVisual(toggled)

                if callCallback then
                    safeCallback(cb, toggled)
                end
            end

            toggleRefs[toggleTitle] = {
                element = newToggle,
                getState = function()
                    return toggled
                end,
                setState = setState,
                callback = cb
            }

            newToggle.btn.MouseEnter:Connect(function()
                fadeelement(newToggle.btn, true)
            end)

            newToggle.btn.MouseLeave:Connect(function()
                fadeelement(newToggle.btn, false)
            end)

            setVisual(toggled)

            if toggled then
                safeCallback(cb, toggled)
            end

            newToggle.btn.MouseButton1Click:Connect(function()
                setState(not toggled, true)
            end)

            return newToggle
        end

        function contents:textbox(textboxTitle, default, autoEnter, cb)

            if typeof(autoEnter) == "function" then
                cb = autoEnter
                autoEnter = false
            end


            autoEnter = autoEnter == true
            cb = cb or function() end

            local newtb = elements.TextboxElement:Clone()
            newtb.frame.lbl.Text = textboxTitle
            newtb.Parent = newSect.sectioncontainer

            

           textboxRefs[title] = newtb

            local inp = newtb.frame.inp.lbl
            inp.Text = tostring(default)

            if default ~= "" then
                safeCallback(cb, tostring(default))
            end

            inp.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    safeCallback(cb, inp.Text)
                end
            end)

            return newtb
        end

        function contents:slider(sliderTitle, min, max, default, cb)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            default = tonumber(default) or min

            local newsl = elements.SliderElement:Clone()
            newsl.Parent = newSect.sectioncontainer

            local slbtn = newsl.btn
            local prog = slbtn.prog
            local draggingSlider = false
            local currentValue = default

            local function setValue(value, callCallback)
                value = tonumber(value) or min
                value = math.clamp(value, min, max)
                value = math.floor(value + 0.5)

                currentValue = value

                local alpha = 0
                if max ~= min then
                    alpha = (value - min) / (max - min)
                end

                alpha = math.clamp(alpha, 0, 1)
                prog.Size = UDim2.new(alpha, 0, 1, 0)
                newsl.lbl.Text = sliderTitle .. " : " .. tostring(value)

                if callCallback then
                    safeCallback(cb, value)
                end
            end

            local function updateFromInput(x)
                local rel = (x - slbtn.AbsolutePosition.X) / slbtn.AbsoluteSize.X
                rel = math.clamp(rel, 0, 1)

                local value = min + (max - min) * rel
                setValue(value, false)
            end

            sliderRefs[sliderTitle] = {
                element = newsl,
                callback = cb,
                min = min,
                max = max,
                getValue = function()
                    return currentValue
                end,
                setValue = setValue
            }

            setValue(default, false)

            slbtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    updateFromInput(input.Position.X)
                end
            end)

            ui.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input.Position.X)
                end
            end)

            ui.InputEnded:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    draggingSlider = false
                    safeCallback(cb, currentValue)
                end
            end)

            return newsl
        end

        return contents
    end

    return sections
end

function module:setToggle(name, state, callCallback)
    local data = toggleRefs[name]
    if not data then return end

    if data.getState() ~= (state == true) then
        data.setState(state == true, callCallback ~= false)
    end
end

function module:setSlider(name, value, callCallback)
    local data = sliderRefs[name]
    if not data then return end

    data.setValue(value, callCallback ~= false)
end

function module:setTextbox(name, value, callCallback)
    local data = textboxRefs[name]
    if not data then return end

    value = value or ""
    data.element.frame.inp.lbl.Text = tostring(value)

    if callCallback then
        safeCallback(data.callback, tostring(value))
    end
end

function module:getToggle(name)
    local data = toggleRefs[name]
    if not data then return nil end
    return data.getState()
end

function module:getSlider(name)
    local data = sliderRefs[name]
    if not data then return nil end
    return data.getValue()
end

function module:getTextbox(name)
    local data = textboxRefs[name]
    if not data then return nil end
    return data.element.frame.inp.lbl.Text
end

return module
