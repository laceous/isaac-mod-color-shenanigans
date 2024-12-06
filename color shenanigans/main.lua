local mod = RegisterMod('Color Shenanigans', 1)
local game = Game()

if REPENTOGON then
  mod.evaluatePlayerCache = false
  mod.resetColorModifierMenu = false
  mod.lastActiveMenu = -1
  
  function mod:onRender()
    mod:RemoveCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.onRender)
    mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
    mod:setupImGui()
  end
  
  function mod:onMainMenuRender()
    local activeMenu = MenuManager.GetActiveMenu()
    
    if activeMenu ~= mod.lastActiveMenu and mod.resetColorModifierMenu then
      local defaults = mod:getDefaults('colorModifier')
      MenuManager.SetColorModifier(ColorModifier(defaults.r, defaults.g, defaults.b, defaults.a, defaults.brightness, defaults.contrast), true, 0.015)
      mod.resetColorModifierMenu = false
    end
    
    mod.lastActiveMenu = activeMenu
  end
  
  function mod:onGameExit()
    mod.evaluatePlayerCache = false
    mod.resetColorModifierMenu = false
    mod.lastActiveMenu = -1
  end
  
  function mod:onNewRoom()
    -- player cache doesn't update on its own
    if mod.evaluatePlayerCache then
      for _, player in ipairs(PlayerManager.GetPlayers()) do
        player:AddCacheFlags(CacheFlag.CACHE_COLOR)
        player:EvaluateItems()
      end
      
      mod.evaluatePlayerCache = false
    end
  end
  
  function mod:getKeys(tbl, val)
    local keys = {}
    
    for k, v in pairs(tbl) do
      if v == val then
        table.insert(keys, k)
      end
    end
    
    table.sort(keys)
    return keys
  end
  
  function mod:setupImGui()
    if not ImGui.ElementExists('shenanigansMenu') then
      ImGui.CreateMenu('shenanigansMenu', '\u{f6d1} Shenanigans')
    end
    ImGui.AddElement('shenanigansMenu', 'shenanigansMenuItemColor', ImGuiElement.MenuItem, '\u{f53f} Color Shenanigans')
    ImGui.CreateWindow('shenanigansWindowColor', 'Color Shenanigans')
    ImGui.LinkWindowToElement('shenanigansWindowColor', 'shenanigansMenuItemColor')
    
    ImGui.AddTabBar('shenanigansWindowColor', 'shenanigansTabBarColor')
    ImGui.AddTab('shenanigansTabBarColor', 'shenanigansTabColorRoom', 'Room')
    ImGui.AddTab('shenanigansTabBarColor', 'shenanigansTabColorWater', 'Water')
    ImGui.AddTab('shenanigansTabBarColor', 'shenanigansTabColorEntities', 'Entities')
    ImGui.AddTab('shenanigansTabBarColor', 'shenanigansTabColorFx', 'FX')
    
    local backdropTypes = {}
    for i = 0, BackdropType.NUM_BACKDROPS - 1 do -- sequential 0-60
      local key = mod:getKeys(BackdropType, i)[1] or ''
      table.insert(backdropTypes, i .. '.' .. key)
    end
    local cmbBackdropTypeId = 'shenanigansCmbColorBackdropType'
    ImGui.AddElement('shenanigansTabColorRoom', '', ImGuiElement.SeparatorText, 'Backdrop Type')
    ImGui.AddCombobox('shenanigansTabColorRoom', cmbBackdropTypeId, '', nil, backdropTypes, BackdropType.BACKDROP_NULL, false)
    ImGui.SetHelpmarker(cmbBackdropTypeId, 'Warning: Some of these may crash the game!')
    ImGui.AddCallback(cmbBackdropTypeId, ImGuiCallback.Edited, function(i)
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        room:SetBackdropType(i, 1) -- 2nd param is unknown, but it can't be 0
      end
    end)
    ImGui.AddCallback(cmbBackdropTypeId, ImGuiCallback.Render, function()
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        ImGui.UpdateData(cmbBackdropTypeId, ImGuiData.Value, room:GetBackdropType())
      end
    end)
    
    ImGui.AddElement('shenanigansTabColorRoom', '', ImGuiElement.SeparatorText, 'Floor Color')
    mod:doColor('shenanigansTabColorRoom', 'shenanigansClrColorFloorTint', 'shenanigansClrColorFloorOffset', 'shenanigansClrColorFloorColorize', 'shenanigansBtnColorFloorReset', function(color)
      local room = game:GetRoom()
      room:SetFloorColor(Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO, color.RC, color.GC, color.BC, color.AC))
    end, 'floorColor')
    
    ImGui.AddElement('shenanigansTabColorRoom', '', ImGuiElement.SeparatorText, 'Wall Color')
    mod:doColor('shenanigansTabColorRoom', 'shenanigansClrColorWallTint', 'shenanigansClrColorWallOffset', 'shenanigansClrColorWallColorize', 'shenanigansBtnColorWallReset', function(color)
      local room = game:GetRoom()
      room:SetWallColor(Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO, color.RC, color.GC, color.BC, color.AC))
    end, 'wallColor')
    
    local fltWaterAmountId = 'shenanigansFltColorWaterAmount'
    ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SeparatorText, 'Water Amount')
    for i, v in ipairs({
                        { id = 'shenanigansBtnColorWaterAmountOn' , label = 'On' , amount = 1 },
                        { id = 'shenanigansBtnColorWaterAmountOff', label = 'Off', amount = 0 },
                      })
    do
      if i > 1 then
        ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SameLine, '')
      end
      ImGui.AddButton('shenanigansTabColorWater', v.id, v.label, function()
        ImGui.UpdateData(fltWaterAmountId, ImGuiData.Value, v.amount)
        
        if Isaac.IsInGame() then
          local room = game:GetRoom()
          room:SetWaterAmount(v.amount)
        end
      end, true)
    end
    ImGui.AddDragFloat('shenanigansTabColorWater', fltWaterAmountId, '', nil, 0.0, 0.02, 0.0, 25.0, '%.2f')
    ImGui.AddCallback(fltWaterAmountId, ImGuiCallback.Edited, function(f)
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        room:SetWaterAmount(f)
      end
    end)
    ImGui.AddCallback(fltWaterAmountId, ImGuiCallback.Render, function()
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        ImGui.UpdateData(fltWaterAmountId, ImGuiData.Value, room:GetWaterAmount())
      end
    end)
    
    local waterCurrent = { X = 0, Y = 0 }
    local fltWaterCurrentHorizId = 'shenanigansFltColorWaterCurrentHoriz'
    local fltWaterCurrentVertId = 'shenanigansFltColorWaterCurrentVert'
    ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SeparatorText, 'Water Current')
    for i, v in ipairs({
                        { id = 'shenanigansBtnColorWaterCurrentLeft' , label = 'Left' , x = -1, y = 0 },
                        { id = 'shenanigansBtnColorWaterCurrentRight', label = 'Right', x = 1 , y = 0 },
                        { id = 'shenanigansBtnColorWaterCurrentUp'   , label = 'Up'   , x = 0 , y = -1 },
                        { id = 'shenanigansBtnColorWaterCurrentDown' , label = 'Down' , x = 0 , y = 1 },
                        { id = 'shenanigansBtnColorWaterCurrentOff'  , label = 'Off'  , x = 0 , y = 0 },
                      })
    do
      if i > 1 then
        ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SameLine, '')
      end
      ImGui.AddButton('shenanigansTabColorWater', v.id, v.label, function()
        waterCurrent.X = v.x
        waterCurrent.Y = v.y
        ImGui.UpdateData(fltWaterCurrentHorizId, ImGuiData.Value, waterCurrent.X)
        ImGui.UpdateData(fltWaterCurrentVertId, ImGuiData.Value, waterCurrent.Y)
        
        if Isaac.IsInGame() then
          local room = game:GetRoom()
          room:SetWaterCurrent(Vector(waterCurrent.X, waterCurrent.Y))
        end
      end, true)
    end
    for _, v in ipairs({
                        { id = fltWaterCurrentHorizId, field = 'X', label = 'Horizontal' },
                        { id = fltWaterCurrentVertId , field = 'Y', label = 'Vertical' },
                      })
    do
      ImGui.AddDragFloat('shenanigansTabColorWater', v.id, v.label, nil, 0.0, 0.01, -5.0, 5.0, '%.2f')
      ImGui.AddCallback(v.id, ImGuiCallback.Edited, function(f)
        waterCurrent[v.field] = f
        
        if Isaac.IsInGame() then
          local room = game:GetRoom()
          room:SetWaterCurrent(Vector(waterCurrent.X, waterCurrent.Y))
        end
      end)
      ImGui.AddCallback(v.id, ImGuiCallback.Render, function()
        if Isaac.IsInGame() then
          local room = game:GetRoom()
          waterCurrent[v.field] = room:GetWaterCurrent()[v.field]
          ImGui.UpdateData(v.id, ImGuiData.Value, waterCurrent[v.field])
        end
      end)
    end
    
    ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SeparatorText, 'Water Color')
    mod:doKColor('shenanigansTabColorWater', 'shenanigansClrColorWater', 'shenanigansBtnColorWaterReset', function(color)
      local room = game:GetRoom()
      room:SetWaterColor(KColor(color.R, color.G, color.B, color.A)) -- FXParams.WaterColor is also settable, but can be overwritten by this
    end, 'waterColor')
    
    ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SeparatorText, 'Water Color Multiplier')
    mod:doKColor('shenanigansTabColorWater', 'shenanigansClrColorWaterMultiplier', 'shenanigansBtnColorWaterMultiplierReset', function(color)
      local room = game:GetRoom()
      room:SetWaterColorMultiplier(KColor(color.R, color.G, color.B, color.A)) -- FXParams.WaterColorMultiplier
    end, 'waterColorMultiplier')
    
    -- FXParams.UseWaterV2 doesn't seem to do anything?
    ImGui.AddElement('shenanigansTabColorWater', '', ImGuiElement.SeparatorText, 'Water Effect Color')
    mod:doColor('shenanigansTabColorWater', 'shenanigansClrColorFxWaterEffectTint', 'shenanigansClrColorFxWaterEffectOffset', 'shenanigansClrColorFxWaterEffectColorize', 'shenanigansBtnColorFxWaterEffectReset', function(color)
      local room = game:GetRoom()
      room:GetFXParams().WaterEffectColor = Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO, color.RC, color.GC, color.BC, color.AC)
    end, 'waterEffectColor')
    
    ImGui.AddElement('shenanigansTabColorEntities', '', ImGuiElement.SeparatorText, 'Entity Color')
    mod:doColor('shenanigansTabColorEntities', 'shenanigansClrColorEntityTint', 'shenanigansClrColorEntityOffset', 'shenanigansClrColorEntityColorize', 'shenanigansBtnColorEntityReset', function(color)
      for _, v in ipairs(Isaac.GetRoomEntities()) do
        if v.Type ~= EntityType.ENTITY_EFFECT then
          v.Color = Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO, color.RC, color.GC, color.BC, color.AC) -- v:GetSprite().Color
        end
      end
      
      mod.evaluatePlayerCache = true
    end)
    
    ImGui.AddElement('shenanigansTabColorEntities', '', ImGuiElement.SeparatorText, 'Effect Color')
    mod:doColor('shenanigansTabColorEntities', 'shenanigansClrColorEffectTint', 'shenanigansClrColorEffectOffset', 'shenanigansClrColorEffectColorize', 'shenanigansBtnColorEffectReset', function(color)
      for _, v in ipairs(Isaac.GetRoomEntities()) do
        if v.Type == EntityType.ENTITY_EFFECT then
          v.Color = Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO, color.RC, color.GC, color.BC, color.AC)
        end
      end
    end)
    
    ImGui.AddElement('shenanigansTabColorEntities', '', ImGuiElement.SeparatorText, 'Grid Entity Color')
    mod:doColor('shenanigansTabColorEntities', 'shenanigansClrColorGridEntityTint', 'shenanigansClrColorGridEntityOffset', 'shenanigansClrColorGridEntityColorize', 'shenanigansBtnColorGridEntityReset', function(color)
      local room = game:GetRoom()
      
      for i = 0, room:GetGridSize() - 1 do
        local gridEntity = room:GetGridEntity(i)
        if gridEntity then
          gridEntity:GetSprite().Color = Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO, color.RC, color.GC, color.BC, color.AC)
        end
      end
    end)
    
    ImGui.AddElement('shenanigansTabColorFx', '', ImGuiElement.SeparatorText, 'Color Modifier')
    mod:doColorModifier('shenanigansTabColorFx', 'shenanigansClrColorFxModifier', 'shenanigansFltColorFxModifierStrength', 'shenanigansFltColorFxModifierBrightness', 'shenanigansFltColorFxModifierContrast', 'shenanigansChkColorFxModifierProcess', 'shenanigansBtnColorFxModifierReset', function(color)
      if Isaac.IsInGame() then
        local room = game:GetRoom() -- game:SetColorModifier
        room:GetFXParams().ColorModifier = ColorModifier(color.R, color.G, color.B, color.A, color.Brightness, color.Contrast)
        room:UpdateColorModifier(color.Process, not (game:IsPaused() and ImGui.IsVisible()), 0.015)
      else
        local gotActiveMenu, activeMenu = pcall(MenuManager.GetActiveMenu)
        if gotActiveMenu then
          MenuManager.SetColorModifier(ColorModifier(color.R, color.G, color.B, color.A, color.Brightness, color.Contrast), not ImGui.IsVisible(), 0.015)
          mod.resetColorModifierMenu = true
        end
      end
    end, 'colorModifier')
    
    ImGui.AddElement('shenanigansTabColorFx', '', ImGuiElement.SeparatorText, 'Light Color')
    mod:doKColor('shenanigansTabColorFx', 'shenanigansClrColorFxLight', 'shenanigansBtnColorFxLightReset', function(color)
      local room = game:GetRoom()
      room:GetFXParams().LightColor = KColor(color.R, color.G, color.B, color.A)
    end, 'lightColor')
    
    local fltShadowAlphaId = 'shenanigansFltColorFxShadowAlpha'
    ImGui.AddElement('shenanigansTabColorFx', '', ImGuiElement.SeparatorText, 'Shadow Alpha')
    ImGui.AddButton('shenanigansTabColorFx', 'shenanigansBtnColorFxShadowAlphaReset', 'Reset', function()
      local defaults = mod:getDefaults('shadowAlpha')
      ImGui.UpdateData(fltShadowAlphaId, ImGuiData.Value, defaults)
      
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        room:GetFXParams().ShadowAlpha = defaults
      end
    end, true)
    ImGui.AddDragFloat('shenanigansTabColorFx', fltShadowAlphaId, '', nil, mod:getDefaults('shadowAlpha'), 0.01, 0.0, 5.0, '%.2f')
    ImGui.AddCallback(fltShadowAlphaId, ImGuiCallback.Edited, function(f)
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        room:GetFXParams().ShadowAlpha = f
      end
    end)
    ImGui.AddCallback(fltShadowAlphaId, ImGuiCallback.Render, function(f)
      if Isaac.IsInGame() then
        local room = game:GetRoom()
        ImGui.UpdateData(fltShadowAlphaId, ImGuiData.Value, room:GetFXParams().ShadowAlpha)
      end
    end)
    
    ImGui.AddElement('shenanigansTabColorFx', '', ImGuiElement.SeparatorText, 'Shadow Color')
    mod:doKColor('shenanigansTabColorFx', 'shenanigansClrColorFxShadow', 'shenanigansBtnColorFxShadowReset', function(color)
      local room = game:GetRoom()
      room:GetFXParams().ShadowColor = KColor(color.R, color.G, color.B, color.A)
    end, 'shadowColor')
  end
  
  function mod:doColorModifier(tab, clrId, fltStrengthId, fltBrightnessId, fltContrastId, chkProcessId, btnResetId, func, defaultsName)
    local defaults = mod:getDefaults(defaultsName)
    local color = {
      R = defaults.r or 1,
      G = defaults.g or 1,
      B = defaults.b or 1,
      A = defaults.a or 0,
      Brightness = defaults.brightness or 0,
      Contrast = defaults.contrast or 1,
      Process = true
    }
    
    ImGui.AddButton(tab, btnResetId, 'Reset', function()
      local defaults = mod:getDefaults(defaultsName)
      color.R = defaults.r or 1
      color.G = defaults.g or 1
      color.B = defaults.b or 1
      color.A = defaults.a or 0
      color.Brightness = defaults.brightness or 0
      color.Contrast = defaults.contrast or 1
      color.Process = true
      ImGui.UpdateData(clrId, ImGuiData.ColorValues, { color.R, color.G, color.B })
      ImGui.UpdateData(fltStrengthId, ImGuiData.Value, color.A)
      ImGui.UpdateData(fltBrightnessId, ImGuiData.Value, color.Brightness)
      ImGui.UpdateData(fltContrastId, ImGuiData.Value, color.Contrast)
      ImGui.UpdateData(chkProcessId, ImGuiData.Value, color.Process)
      
      func(color)
    end, true)
    ImGui.AddInputColor(tab, clrId, 'Color', function(r, g, b)
      color.R = r
      color.G = g
      color.B = b
      
      func(color)
    end, color.R, color.G, color.B)
    ImGui.SetHelpmarker(clrId, 'Available in-game and in the menu!')
    ImGui.AddDragFloat(tab, fltStrengthId, 'Strength', function(f)
      color.A = f
      
      func(color)
    end, color.A, 0.02, -25.0, 25.0, '%.2f')
    ImGui.AddDragFloat(tab, fltBrightnessId, 'Brightness', function(f)
      color.Brightness = f
      
      func(color)
    end, color.Brightness, 0.01, -5.0, 5.0, '%.2f')
    ImGui.AddDragFloat(tab, fltContrastId, 'Contrast', function(f)
      color.Contrast = f
      
      func(color)
    end, color.Contrast, 0.01, -5.0, 5.0, '%.2f')
    ImGui.AddCheckbox(tab, chkProcessId, 'Extra processing?', function(b)
      color.Process = b
      
      func(color)
    end, color.Process)
    ImGui.SetHelpmarker(chkProcessId, 'Additional modifications for lava and the abandoned mineshaft')
  end
  
  function mod:doKColor(tab, clrId, btnResetId, inGameFunc, defaultsName)
    local defaults = mod:getDefaults(defaultsName)
    local color = {
      R = defaults.r or 1,
      G = defaults.g or 1,
      B = defaults.b or 1,
      A = defaults.a or 1
    }
    
    ImGui.AddButton(tab, btnResetId, 'Reset', function()
      local defaults = mod:getDefaults(defaultsName)
      color.R = defaults.r or 1
      color.G = defaults.g or 1
      color.B = defaults.b or 1
      color.A = defaults.a or 1
      ImGui.UpdateData(clrId, ImGuiData.ColorValues, { color.R, color.G, color.B, color.A })
      
      if Isaac.IsInGame() then
        inGameFunc(color)
      end
    end, true)
    ImGui.AddInputColor(tab, clrId, '', function(r, g, b, a)
      color.R = r
      color.G = g
      color.B = b
      color.A = a
      
      if Isaac.IsInGame() then
        inGameFunc(color)
      end
    end, color.R, color.G, color.B, color.A)
  end
  
  function mod:doColor(tab, clrTintId, clrOffsetId, clrColorizeId, btnResetId, inGameFunc, defaultsName)
    local defaults = mod:getDefaults(defaultsName)
    local color = {
      R = defaults.r or 1,
      G = defaults.g or 1,
      B = defaults.b or 1,
      A = defaults.a or 1,
      RO = 0,
      GO = 0,
      BO = 0,
      RC = 0,
      GC = 0,
      BC = 0,
      AC = 0
    }
    
    ImGui.AddButton(tab, btnResetId, 'Reset', function()
      local defaults = mod:getDefaults(defaultsName)
      color.R = defaults.r or 1
      color.G = defaults.g or 1
      color.B = defaults.b or 1
      color.A = defaults.a or 1
      color.RO = 0
      color.GO = 0
      color.BO = 0
      color.RC = 0
      color.GC = 0
      color.BC = 0
      color.AC = 0
      
      if Isaac.IsInGame() then
        local level = game:GetLevel()
        local roomDesc = level:GetCurrentRoomDesc()
        
        if roomDesc.Flags & RoomDescriptor.FLAG_RED_ROOM == RoomDescriptor.FLAG_RED_ROOM then
          if defaultsName == 'floorColor' then
            color.RC = 1
            color.GC = 0
            color.BC = 0
            color.AC = 0.3
          elseif defaultsName == 'wallColor' then
            color.RC = 1
            color.GC = 0.2
            color.BC = 0.2
            color.AC = 0.8
          end
        end
      end
      
      ImGui.UpdateData(clrTintId, ImGuiData.ColorValues, { color.R, color.G, color.B, color.A })
      ImGui.UpdateData(clrOffsetId, ImGuiData.ColorValues, { color.RO, color.GO, color.BO })
      ImGui.UpdateData(clrColorizeId, ImGuiData.ColorValues, { color.RC, color.GC, color.BC, color.AC })
      
      if Isaac.IsInGame() then
        inGameFunc(color)
      end
    end, true)
    ImGui.AddInputColor(tab, clrTintId, 'Tint', function(r, g, b, a)
      color.R = r
      color.G = g
      color.B = b
      color.A = a
      
      if Isaac.IsInGame() then
        inGameFunc(color)
      end
    end, color.R, color.G, color.B, color.A)
    ImGui.AddInputColor(tab, clrOffsetId, 'Offset', function(r, g, b)
      color.RO = r
      color.GO = g
      color.BO = b
      
      if Isaac.IsInGame() then
        inGameFunc(color)
      end
    end, color.RO, color.GO, color.BO)
    ImGui.AddInputColor(tab, clrColorizeId, 'Colorize', function(r, g, b, a)
      color.RC = r
      color.GC = g
      color.BC = b
      color.AC = a
      
      if Isaac.IsInGame() then
        inGameFunc(color)
      end
    end, color.RC, color.GC, color.BC, color.AC)
  end
  
  function mod:tblNew(tblOne, tblTwo)
    local tblThree = {}
    
    for k, v in pairs(tblOne) do
      tblThree[k] = v
    end
    for k, v in pairs(tblTwo) do
      tblThree[k] = v
    end
    
    return tblThree
  end
  
  -- values taken from fxlayers.xml
  -- Basement=1, Caves=2, Depths=3, Womb=4, Blue Womb=5, Sheol=6, Chest=7, Void=8, Home=9
  -- altStages: Bitmask of 1 << (Original: 0, WOTL: 1, Afterbirth: 2, UNUSED (was Greed Mode): 3, Repentance: 4, Repentance Alt: 5)
  function mod:getDefaults(name)
    local defaults = {
      waterv2 = false,
      shadowAlpha = 0.5,
      shadowColor = { r = 0.06, g = 0.08, b = 0.13, a = 1 },
      lightColor = { r = 1, g = 1, b = 1, a = 0.6 },
      waterColor = { r = 0.04, g = 0.04, b = 0.04, a = 0.6, rMul = 1, gMul = 1, bMul = 1, aMul = 1 },
      waterEffectColor = { r = 1, g = 1, b = 1, a = 1 },
      colorModifier = { r = 1, g = 1, b = 1, a = 0, brightness = 0, contrast = 1 },
      colorModifierTainted = { r = 1, g = 1.03, b = 1.1, a = 0.3, brightness = -0.15, contrast = 0.9 },
    }
    local fxParams = {
      { -- basement/cellar
        stage = 1, altStages = 3,
        shadowAlpha = 0.4,
      },
      { -- burning basement
        stage = 1, altStages = 4,
        shadowAlpha = 0.5,
        colorModifier = { r = -1, g = 0.1, b = 0.5, a = -0.2, brightness = 0, contrast = 1.05 },
      },
      { -- flooded caves
        stage = 2, altStages = 4,
        colorModifier = { r = 1, g = 1.2, b = 3, a = 0.15, brightness = -0.08, contrast = 0.82 },
        shadowColor = { r = 0.06, g = 0.1, b = 0.1, a = 1 },
        waterColor = { r = 0.08, g = 0.25, b = 0.45, a = 0.6, rMul = 1, gMul = 1, bMul = 1 },
      },
      { -- dank depths
        stage = 3, altStages = 4,
        colorModifier = { r = 2, g = 1.6, b = 3, a = 0.15, brightness = 0, contrast = 1.03 },
        shadowColor = { r = 0.04, g = 0.03, b = 0.04, a = 1 },
        lightColor = { r = 0.8, g = 1, b = 0.6, a = 1 },
      },
      { -- womb
        stage = 4, altStages = 1,
        shadowAlpha = 0.3,
        shadowColor = { r = 0.1, g = 0.04, b = 0.04, a = 1 },
        waterColor = { r = 0.08, g = 0.01, b = 0.01, a = 0.6, rMul = 0.8, gMul = 0.1, bMul = 0.1 },
        waterEffectColor = { r = 1.0, g = 0.1, b = 0.1, a = 1 },
      },
      { -- utero
        stage = 4, altStages = 2,
        shadowAlpha = 0.3,
        colorModifier = { r = 1, g = 0, b = 0, a = 0.15, brightness = 0, contrast = 1.03 },
        shadowColor = { r = 0.1, g = 0.04, b = 0.04, a = 1 },
        waterColor = { r = 0.08, g = 0.01, b = 0.01, a = 0.6, rMul = 0.8, gMul = 0.1, bMul = 0.1 },
        waterEffectColor = { r = 1.0, g = 0.1, b = 0.1, a = 1 },
      },
      { -- scarred womb
        stage = 4, altStages = 4,
        colorModifier = { r = 1, g = -0.95, b = -0.95, a = 0.04, brightness = 0, contrast = 1.03 },
        shadowColor = { r = 0.1, g = 0.04, b = 0.04, a = 1 },
        lightColor = { r = 1, g = 0.7, b = 0.7, a = 0.6 },
        waterColor = { r = 0.08, g = 0.01, b = 0.01, a = 0.6, rMul = 0.8, gMul = 0.1, bMul = 0.1 },
        waterEffectColor = { r = 1.0, g = 0.1, b = 0.1, a = 1 },
      },
      { -- cathedral
        stage = 6, altStages = 2,
        shadowAlpha = 0.3,
      },
      { -- chest
        stage = 7, altStages = 2,
        shadowAlpha = 0.2,
        shadowColor = { r = 0.05, g = 0.03, b = 0.03, a = 1 },
        lightColor = { r = 1, g = 0.9, b = 0.7, a = 1 },
      },
      { -- dark room
        stage = 7, altStages = 1,
        shadowAlpha = 0.2,
        shadowColor = { r = 0.05, g = 0.03, b = 0.03, a = 1 },
        lightColor = { r = 0.5, g = 0.1, b = 1.0, a = 1 },
      },
      { -- downpour
        stage = 1, altStages = 16,
        waterv2 = true,
        colorModifier = { r = 1, g = 1.2, b = 4, a = 0.15, brightness = 0, contrast = 1 },
        lightColor = { r = 0.6, g = 0.6, b = 1, a = 0.8 },
      },
      { -- dross
        stage = 1, altStages = 32,
        waterv2 = true,
        colorModifier = { r = 1.5, g = 2, b = 1, a = 0.15, brightness = 0, contrast = 1 },
        shadowColor = { r = 0.06, g = 0.1, b = 0.04, a = 1 },
        waterColor = { r = 0.02, g = 0.08, b = 0.01, a = 0.5, rMul = 1.0, gMul = 0.8, bMul = 0.7 },
        lightColor = { r = 1, g = 0.8, b = 0.3, a = 0.8 },
        waterEffectColor = { r = 0.5, g = 0.4, b = 0.2, a = 1 },
      },
      { -- mines
        stage = 2, altStages = 16,
        shadowColor = { r = 0.1, g = 0.12, b = 0.16, a = 1.0 },
        colorModifier = { r = -1.2, g = -0.8, b = 0, a = -0.15, brightness = -0.03, contrast = 1 },
      },
      { -- ashpit
        stage = 2, altStages = 32,
        shadowColor = { r = 0.12, g = 0.05, b = 0.05, a = 1.0 },
        colorModifier = { r = 1, g = 1, b = 0.9, a = 0.1, brightness = 0.03, contrast = 1.1 },
      },
      { -- mausoleum
        stage = 3, altStages = 16,
        shadowColor = { r = 0.035, g = 0.04, b = 0.03, a = 1.0 },
        lightColor = { r = 1, g = 0.8, b = 1, a = 1 },
        colorModifier = { r = 0, g = 1, b = -0.8, a = -0.08, brightness = 0, contrast = 1 },
      },
      { -- mausoleum (minifloor)
        stage = 3, altStages = 16, backdrop = 41,
        shadowColor = { r = 0.035, g = 0.09, b = 0.03, a = 1.0 },
        lightColor = { r = 0.6, g = 0.4, b = 1.5, a = 1 },
        colorModifier = { r = 0, g = 0.3, b = -1, a = -0.25, brightness = 0, contrast = 1.05 },
      },
      { -- mausoleum (post mom's heart)
        stage = 3, altStages = 16, backdrop = 39,
        shadowColor = { r = 0.1, g = 0.04, b = 0, a = 1.0 },
        lightColor = { r = 1, g = 1, b = 1, a = 0 },
        colorModifier = { r = 1, g = 0.5, b = 0, a = 0.45, brightness = 0, contrast = 1 },
      },
      { -- gehenna
        stage = 3, altStages = 32,
        shadowColor = { r = 0.04, g = 0.04, b = 0.03, a = 1.0 },
        lightColor = { r = 1, g = 0.8, b = 0.8, a = 1 },
        colorModifier = { r = 0, g = 1, b = 1, a = -0.4, brightness = 0, contrast = 1 },
      },
      { -- corpse
        stage = 4, altStages = 16,
        shadowColor = { r = 0.1, g = 0.02, b = 0.02, a = 1 },
        lightColor = { r = 1, g = 0.7, b = 0.7, a = 0.6 },
        waterColor = { r = 0.08, g = 0.01, b = 0.01, a = 0.6, rMul = 0.8, gMul = 0.2, bMul = 0.2 },
        waterEffectColor = { r = 1.0, g = 0.1, b = 0.1, a = 1 },
        colorModifier = { r = 0.8, g = 1.2, b = 0.8, a = 0.2, brightness = 0, contrast = 1 }
      },
      { -- home
        stage = 9, altStages = 1,
        shadowAlpha = 0.5,
        lightColor = { r = 0.8, g = 0.75, b = 0.7, a = 1 },
        colorModifier = { r = 1, g = 1, b = 1, a = -0.1, brightness = 0, contrast = 1 },
      },
      { -- home (dark)
        stage = 9, altStages = 2,
        shadowAlpha = 0.7,
        lightColor = { r = 1, g = 1, b = 1, a = 1 },
        shadowColor = { r = 0.02, g = 0, b = 0.1, a = 1 },
        colorModifier = { r = 0, g = 0.2, b = 1, a = 0.3, brightness = 0, contrast = 1 },
      },
      { -- beast
        backdrop = 57,
        shadowAlpha = 1,
        shadowColor = { r = 0, g = 0, b = 0, a = 1 },
      },
      --[[
      { -- backwards
        stage = 5, altStages = 16,
        shadowAlpha = 0.3,
        lightColor = { r = 1, g = 1, b = 1, a = 1 },
        shadowColor = { r = 0.12, g = 0.05, b = 0.05, a = 1.0 },
        colorModifier = { r = 1, g = 0.7, b = 0.5, a = 0.5, brightness = 0.04, contrast = 1 },
      },
      --]]
      { -- abandoned mineshaft
        stage = 2, altStages = 64,
        shadowColor = { r = 0.1, g = 0.12, b = 0.16, a = 1.0 },
        colorModifier = { r = 0.0, g = 0.4, b = -0.4, a = -0.45, brightness = -0.03, contrast = 1 },
      },
    }
    local stageMap = {
      [LevelStage.STAGE1_1] = 1,
      [LevelStage.STAGE1_2] = 1,
      [LevelStage.STAGE2_1] = 2,
      [LevelStage.STAGE2_2] = 2,
      [LevelStage.STAGE3_1] = 3,
      [LevelStage.STAGE3_2] = 3,
      [LevelStage.STAGE4_1] = 4,
      [LevelStage.STAGE4_2] = 4,
      [LevelStage.STAGE4_3] = 5,
      [LevelStage.STAGE5]   = 6,
      [LevelStage.STAGE6]   = 7,
      [LevelStage.STAGE7]   = 8,
      [LevelStage.STAGE8]   = 9,
    }
    local greedStageMap = {
      [LevelStage.STAGE1_GREED] = 1,
      [LevelStage.STAGE2_GREED] = 2,
      [LevelStage.STAGE3_GREED] = 3,
      [LevelStage.STAGE4_GREED] = 4,
      [LevelStage.STAGE5_GREED] = 5,
      [LevelStage.STAGE6_GREED] = 1, -- cellar?
      [LevelStage.STAGE7_GREED] = 1, -- cellar?
      [8]                       = 1,
      [9]                       = 1,
      [10]                      = 1,
      [11]                      = 1,
    }
    
    local fxParam = nil
    
    if Isaac.IsInGame() then
      local level = game:GetLevel()
      local stageType = level:GetStageType()
      local room = level:GetCurrentRoom()
      local backdrop = room:GetBackdropType()
      local configStage = room:GetRoomConfigStage()
      
      local stage
      if game:IsGreedMode() then
        stage = greedStageMap[level:GetStage()]
      else
        stage = stageMap[level:GetStage()]
        
        if level:GetStage() == LevelStage.STAGE7 then -- the void
          -- SPECIAL_ROOMS/THE_VOID/ASCENT
          if configStage == StbType.BASEMENT then
            stage = 1
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.CELLAR then
            stage = 1
            stageType = StageType.STAGETYPE_WOTL
          elseif configStage == StbType.BURNING_BASEMENT then
            stage = 1
            stageType = StageType.STAGETYPE_AFTERBIRTH
          elseif configStage == StbType.CAVES then
            stage = 2
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.CATACOMBS then
            stage = 2
            stageType = StageType.STAGETYPE_WOTL
          elseif configStage == StbType.FLOODED_CAVES then
            stage = 2
            stageType = StageType.STAGETYPE_AFTERBIRTH
          elseif configStage == StbType.DEPTHS then
            stage = 3
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.NECROPOLIS then
            stage = 3
            stageType = StageType.STAGETYPE_WOTL
          elseif configStage == StbType.DANK_DEPTHS then
            stage = 3
            stageType = StageType.STAGETYPE_AFTERBIRTH
          elseif configStage == StbType.WOMB then
            stage = 4
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.UTERO then
            stage = 4
            stageType = StageType.STAGETYPE_WOTL
          elseif configStage == StbType.SCARRED_WOMB then
            stage = 4
            stageType = StageType.STAGETYPE_AFTERBIRTH
          elseif configStage == StbType.BLUE_WOMB then
            stage = 5
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.SHEOL then
            stage = 6
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.CATHEDRAL then
            stage = 6
            stageType = StageType.STAGETYPE_WOTL
          elseif configStage == StbType.DARK_ROOM then
            stage = 7
            stageType = StageType.STAGETYPE_ORIGINAL
          elseif configStage == StbType.CHEST then
            stage = 7
            stageType = StageType.STAGETYPE_WOTL
          elseif configStage == StbType.DOWNPOUR then
            stage = 1
            stageType = StageType.STAGETYPE_REPENTANCE
          elseif configStage == StbType.DROSS then
            stage = 1
            stageType = StageType.STAGETYPE_REPENTANCE_B
          elseif configStage == StbType.MINES then
            stage = 2
            stageType = StageType.STAGETYPE_REPENTANCE
          elseif configStage == StbType.ASHPIT then
            stage = 2
            stageType = StageType.STAGETYPE_REPENTANCE_B
          elseif configStage == StbType.MAUSOLEUM then
            stage = 3
            stageType = StageType.STAGETYPE_REPENTANCE
          elseif configStage == StbType.GEHENNA then
            stage = 3
            stageType = StageType.STAGETYPE_REPENTANCE_B
          elseif configStage == StbType.CORPSE then
            stage = 4
            stageType = StageType.STAGETYPE_REPENTANCE
          elseif configStage == StbType.MORTIS then
            stage = 4
            stageType = StageType.STAGETYPE_REPENTANCE_B
          elseif configStage == StbType.HOME then
            stage = 9
            stageType = StageType.STAGETYPE_ORIGINAL -- STAGETYPE_WOTL
          end
        end
      end
      if not stage then
        stage = -1
      end
      
      -- look for stage/altStages/backdrop match
      for _, v in ipairs(fxParams) do
        if v.stage == stage and v.altStages & 1<<stageType ~= 0 and v.backdrop == backdrop then
          fxParam = v
          break
        end
      end
      
      -- look for backdrop match
      if not fxParam then
        for _, v in ipairs(fxParams) do
          if v.stage == nil and v.altStages == nil and v.backdrop == backdrop then
            fxParam = v
            break
          end
        end
      end
      
      -- look for stage/altStages match
      if not fxParam then
        for _, v in ipairs(fxParams) do
          if v.stage == stage and v.altStages & 1<<stageType ~= 0 and v.backdrop == nil then
            fxParam = v
            break
          end
        end
      end
    end
    
    local doWaterColorMultiplier = false
    if name == 'waterColorMultiplier' then
      doWaterColorMultiplier = true
      name = 'waterColor'
    end
    
    if not fxParam and name == 'colorModifier' then
      local gotCharMenu, charMenu = pcall(CharacterMenu.GetSelectedCharacterMenu)
      if gotCharMenu and charMenu == 1 then -- 0 = regular, 1 = tainted
        name = 'colorModifierTainted'
      end
    end
    
    local toReturn = defaults[name] or {}
    
    if fxParam and fxParam[name] then
      if type(fxParam[name]) == 'table' then
        toReturn = mod:tblNew(defaults[name], fxParam[name])
      else
        toReturn = fxParam[name]
      end
    end
    
    if doWaterColorMultiplier then
      toReturn = { r = toReturn.rMul, g = toReturn.gMul, b = toReturn.bMul, a = toReturn.aMul }
    end
    
    return toReturn
  end
  
  mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.onRender)
  mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
  mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.onMainMenuRender)
  mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
  mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
end