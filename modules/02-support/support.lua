SupportModule = {}

-- load module events
dofiles('events')

local Panel = {
  CurrentHealthItem,
  SelectHealthItem,
  CurrentManaItem,
  SelectManaItem,
  RingToReplace,
  RingReplaceDisplay,
  SaveNameEdit,
  SaveButton,
  LoadList,
  LoadButton,
  AutoHeal,
  HealSpellText,
  HealthBar,
  AutoHealthItem,
  ItemHealthBar,
  AutoManaItem,
  ItemManaBar,
  AutoHaste,
  HasteSpellText,
  HasteHealthBar,
  AutoParalyzeHeal,
  ParalyzeHealText,
  AutoManaShield,
  AutoInvisible,
  AutoReplaceRing
}

local supportDir = CandyBot.getWriteDir().."/support"
local loadListIndex
local refreshEvent

function SupportModule.getPanel() return Panel end
function SupportModule.setPanel(panel) Panel = panel end

function SupportModule.init()
  -- create tab
  local botTabBar = CandyBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('Support'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('support.otui', tabBuffer)

  Panel.CurrentHealthItem = Panel:getChildById('CurrentHealthItem')
  Panel.SelectHealthItem = Panel:getChildById('SelectHealthItem')

  Panel.CurrentManaItem = Panel:getChildById('CurrentManaItem')
  Panel.SelectManaItem = Panel:getChildById('SelectManaItem')

  local ringComboBox = Panel:getChildById('RingToReplace')
  Panel.RingToReplace = ringComboBox

  local ringItemBox = Panel:getChildById('RingReplaceDisplay')
  Panel.RingReplaceDisplay = ringItemBox

  Panel.SaveNameEdit = Panel:recursiveGetChildById('SaveNameEdit')
  Panel.SaveButton = Panel:recursiveGetChildById('SaveButton')
  Panel.LoadList = Panel:recursiveGetChildById('LoadList')
  Panel.LoadButton = Panel:recursiveGetChildById('LoadButton')

  Panel.AutoHeal = Panel:recursiveGetChildById('AutoHeal')
  Panel.HealSpellText = Panel:recursiveGetChildById('HealSpellText')
  Panel.HealthBar = Panel:recursiveGetChildById('HealthBar')
  Panel.AutoHealthItem = Panel:recursiveGetChildById('AutoHealthItem')
  Panel.ItemHealthBar = Panel:recursiveGetChildById('ItemHealthBar')
  Panel.AutoManaItem = Panel:recursiveGetChildById('AutoManaItem')
  Panel.ItemManaBar = Panel:recursiveGetChildById('ItemManaBar')
  Panel.AutoHaste = Panel:recursiveGetChildById('AutoHaste')
  Panel.HasteSpellText = Panel:recursiveGetChildById('HasteSpellText')
  Panel.HasteHealthBar = Panel:recursiveGetChildById('HasteHealthBar')
  Panel.AutoParalyzeHeal = Panel:recursiveGetChildById('AutoParalyzeHeal')
  Panel.ParalyzeHealText = Panel:recursiveGetChildById('ParalyzeHealText')
  Panel.AutoManaShield = Panel:recursiveGetChildById('AutoManaShield')
  Panel.AutoInvisible = Panel:recursiveGetChildById('AutoInvisible')
  Panel.AutoReplaceRing = Panel:recursiveGetChildById('AutoReplaceRing')

  ringComboBox.onOptionChange = function(widget, text, data)
    CandyBot.changeOption(widget:getId(), widget:getCurrentOption().text)
    ringItemBox:setItemId(Helper.getRingIdByName(text))
  end
  for k,v in pairs(Rings) do
    ringComboBox:addOption(k)
  end

  connect(Panel.LoadList, {
    onChildFocusChange = function(self, focusedChild, unfocusedChild, reason)
        if reason == ActiveFocusReason then return end
        if focusedChild == nil then 
          Panel.LoadButton:setEnabled(false)
          loadListIndex = nil
        else
          Panel.LoadButton:setEnabled(true)
          Panel.SaveNameEdit:setText(string.gsub(focusedChild:getText(), ".otml", ""))
          loadListIndex = Panel.LoadList:getChildIndex(focusedChild)
        end
      end
    })
  
  SupportModule.parentUI = CandyBot.window

  -- setup resources
  if not g_resources.directoryExists(supportDir) then
    g_resources.makeDir(supportDir)
  end

  -- setup refresh event
  SupportModule.refresh()
  refreshEvent = cycleEvent(SupportModule.refresh, 8000)

  -- register module
  Modules.registerModule(SupportModule)
end

function SupportModule.terminate()
  if refreshEvent then
    refreshEvent:cancel()
    refreshEvent = nil
  end

  SupportModule.stop()
  
  Panel:destroy()
  Panel = nil
end

-- Item Selection Callbacks

function SupportModule.onChooseHealthItem(self, item)
  if item then
    Panel.CurrentHealthItem:setItemId(item:getId())
    CandyBot.changeOption('CurrentHealthItem', item:getId())
    CandyBot.show()
    return true
  end
end

function SupportModule.onChooseManaItem(self, item)
  if item then
    Panel.CurrentManaItem:setItemId(item:getId())
    CandyBot.changeOption('CurrentManaItem', item:getId())
    CandyBot.show()
    return true
  end
end

function SupportModule.addFile(file)
  local item = g_ui.createWidget('ListRowComplex', Panel.LoadList)
  item:setText(file)
  item:setTextAlign(AlignLeft)
  item:setId(file)

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removeFileWindow then return end

      local row = button:getParent()
      local fileName = row:getText()

      local yesCallback = function()
        g_resources.deleteFile(supportDir..'/'..fileName)
        row:destroy()

        removeFileWindow:destroy()
        removeFileWindow=nil
      end
      local noCallback = function()
        removeFileWindow:destroy()
        removeFileWindow=nil
      end

      removeFileWindow = displayGeneralBox(tr('Delete'), 
        tr('Delete '..fileName..'?'), {
        { text=tr('Yes'), callback=yesCallback },
        { text=tr('No'), callback=noCallback },
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  })
end

function SupportModule.refresh()
  -- refresh the files
  Panel.LoadList:destroyChildren()

  local files = g_resources.listDirectoryFiles(supportDir)
  for _,file in pairs(files) do
    SupportModule.addFile(file)
  end
  Panel.LoadList:focusChild(Panel.LoadList:getChildByIndex(loadListIndex), ActiveFocusReason)
end

function SupportModule.saveSupport(file)
  local path = supportDir.."/"..file..".otml"
  local config = g_configs.load(path)
  if config then
    local msg = "Are you sure you would like to save over "..file.."?"

    local yesCallback = function()
      writeSupport(config)
      
      saveOverWindow:destroy()
      saveOverWindow=nil

      Panel.SaveNameEdit:setText("")
    end

    local noCallback = function()
      saveOverWindow:destroy()
      saveOverWindow=nil
    end

    saveOverWindow = displayGeneralBox(tr('Overwite Save'), tr(msg), {
      { text=tr('Yes'), callback = yesCallback},
      { text=tr('No'), callback = noCallback},
      anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
  else
    config = g_configs.create(path)
    writeSupport(config)

    Panel.SaveNameEdit:setText("")
  end

  local formatedFile = file..".otml"
  if not Panel.LoadList:getChildById(formatedFile) then
    SupportModule.addFile(formatedFile)
  end
end

function SupportModule.loadSupport(file, force)
  BotLogger.debug("SupportModule.loadSupport("..file..")")
  local path = supportDir.."/"..file
  local config = g_configs.load(path)
  BotLogger.debug("SupportModule"..tostring(config))
  if config then
    local loadFunc = function()
      parseSupport(config)
    end

    if force then
      loadFunc()
    elseif not loadWindow then
      local msg = "Would you like to load "..file.."?"

      local yesCallback = function()
        loadFunc()

        loadWindow:destroy()
        loadWindow=nil
      end

      local noCallback = function()
        loadWindow:destroy()
        loadWindow=nil
      end

      loadWindow = displayGeneralBox(tr('Load Support'), tr(msg), {
        { text=tr('Yes'), callback = yesCallback},
        { text=tr('No'), callback = noCallback},
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  end
end

-- local functions

function writeSupport(config)
  if not config then return end

  local options = {}
  local support = {}
  support.options = options

  options.CurrentHealthItem = Panel.CurrentHealthItem:getItem() == nil and 266 or
    Panel.CurrentHealthItem:getItem():getId()
  options.CurrentManaItem = Panel.CurrentManaItem:getItem() == nil and 268 or
    Panel.CurrentManaItem:getItem():getId()
  options.AutoHeal = Panel.AutoHeal:isChecked()
  options.HealSpellText = Panel.HealSpellText:getText()
  options.HealthBar = Panel.HealthBar:getValue()
  options.AutoHealthItem = Panel.AutoHealthItem:isChecked()
  options.ItemHealthBar = Panel.ItemHealthBar:getValue()
  options.AutoManaItem = Panel.AutoManaItem:isChecked()
  options.ItemManaBar = Panel.ItemManaBar:getValue()
  options.AutoHaste = Panel.AutoHaste:isChecked()
  options.HasteSpellText = Panel.HasteSpellText:getText()
  options.HasteHealthBar = Panel.HasteHealthBar:getValue()
  options.AutoParalyzeHeal = Panel.AutoParalyzeHeal:isChecked()
  options.ParalyzeHealText = Panel.ParalyzeHealText:getText()
  options.AutoManaShield = Panel.AutoManaShield:isChecked()
  options.AutoInvisible = Panel.AutoInvisible:isChecked()
  options.AutoReplaceRing = Panel.AutoReplaceRing:isChecked()
  options.RingToReplace = Panel.RingToReplace:getText()

  config:setNode('Support', support)
  config:save()

  BotLogger.debug("Saved ".."supportConfig" .." to "..config:getFileName())
end

function parseSupport(config)
  if not config then return end

  local support = config:getNode("Support")

  local options = support.options

  Panel.CurrentHealthItem:setItemId(options.CurrentHealthItem)
  Panel.CurrentManaItem:setItemId(options.CurrentManaItem)
  Panel.AutoHeal:setChecked(options.AutoHeal)
  Panel.HealSpellText:setText(options.HealSpellText)
  Panel.HealthBar:setValue(options.HealthBar)
  Panel.AutoHealthItem:setChecked(options.AutoHealthItem)
  Panel.ItemHealthBar:setValue(options.ItemHealthBar)
  Panel.AutoManaItem:setChecked(options.AutoManaItem)
  Panel.ItemManaBar:setValue(options.ItemManaBar)
  Panel.AutoHaste:setChecked(options.AutoHaste)
  Panel.HasteSpellText:setText(options.HasteSpellText)
  Panel.HasteHealthBar:setValue(options.HasteHealthBar)
  Panel.AutoParalyzeHeal:setChecked(options.AutoParalyzeHeal)
  Panel.ParalyzeHealText:setText(options.ParalyzeHealText)
  Panel.AutoManaShield:setChecked(options.AutoManaShield)
  Panel.AutoInvisible:setChecked(options.AutoInvisible)
  Panel.AutoReplaceRing:setChecked(options.AutoReplaceRing)
  Panel.RingToReplace:setText(options.RingToReplace)

end

return SupportModule
