--[[
  @Authors: Ben Dol (BeniS)
  @Details: Afk bot module logic methods and main body.
]]

AfkModule = {}

-- load module events
dofiles('events')

local Panel = {
  CreatureAlert,
  CreatureAlertList,
  AutoEat,
  AutoEatSelect,
  AutoFishing,
  AutoFishingCheckCap,
  RuneMake,
  RuneSpellText,
  RuneMakeOpenContainer,
  AutoReplaceWeapon,
  AutoReplaceWeaponSelect,
  ItemToReplace,
  SelectReplaceItem,
  MagicTrain,
  MagicTrainSpellText,
  MagicTrainManaRequired,
  AntiKick,
  AutoGold,
  AutoStack,
  SaveNameEdit,
  SaveButton,
  LoadList,
  LoadButton
}

local afkDir = CandyBot.getWriteDir().."/afk"
local loadListIndex
local refreshEvent
local alertListWindow

function AfkModule.getPanel() return Panel end
function AfkModule.setPanel(panel) Panel = panel end

function AfkModule.init()
  g_sounds.preload('alert.ogg')

  dofile('alertlist.lua')
  AlertList.init()
  alertListWindow = AlertList.getPanel()

  -- create tab
  local botTabBar = CandyBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('AFK'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('afk.otui', tabBuffer)

  Panel.CreatureAlert = Panel:getChildById('CreatureAlert')
  Panel.CreatureAlertList = Panel:getChildById('CreatureAlertList')

  Panel.AutoEat = Panel:getChildById('AutoEat')
  Panel.AutoEatSelect = Panel:getChildById('AutoEatSelect')

  Panel.AutoFishing = Panel:getChildById('AutoFishing')
  Panel.AutoFishingCheckCap = Panel:getChildById('AutoFishingCheckCap')

  Panel.RuneMake = Panel:getChildById('RuneMake')
  Panel.RuneSpellText = Panel:getChildById('RuneSpellText')
  Panel.RuneMakeOpenContainer = Panel:getChildById('RuneMakeOpenContainer')

  Panel.AutoReplaceWeapon = Panel:getChildById('AutoReplaceWeapon')
  Panel.AutoReplaceWeaponSelect = Panel:getChildById('AutoReplaceWeaponSelect')
  Panel.ItemToReplace = Panel:getChildById('ItemToReplace')
  Panel.SelectReplaceItem = Panel:getChildById('SelectReplaceItem')

  Panel.MagicTrain = Panel:getChildById('MagicTrain')
  Panel.MagicTrainSpellText = Panel:getChildById('MagicTrainSpellText')
  Panel.MagicTrainManaRequired = Panel:getChildById('MagicTrainManaRequired')

  Panel.AntiKick = Panel:getChildById('AntiKick')
  Panel.AutoGold = Panel:getChildById('AutoGold')
  Panel.AutoStack = Panel:getChildById('AutoStack')

  local autoEatSelect = Panel:getChildById('AutoEatSelect')
  for name, food in pairs(Foods) do
    autoEatSelect:addOption(name)
  end

  Panel.SaveNameEdit = Panel:recursiveGetChildById('SaveNameEdit')
  Panel.SaveButton = Panel:recursiveGetChildById('SaveButton')
  Panel.LoadList = Panel:recursiveGetChildById('LoadList')
  Panel.LoadButton = Panel:recursiveGetChildById('LoadButton')

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

  AfkModule.parentUI = CandyBot.window

  -- setup resources
  if not g_resources.directoryExists(afkDir) then
    g_resources.makeDir(afkDir)
  end

  -- setup refresh event
  AfkModule.refresh()
  refreshEvent = cycleEvent(AfkModule.refresh, 8000)

  -- register module
  Modules.registerModule(AfkModule)
end

function AfkModule.terminate()
  if refreshEvent then
    refreshEvent:cancel()
    refreshEvent = nil
  end
  AlertList.terminate()
  AfkModule.stop()

  Panel:destroy()
  Panel = nil
end

--@UsedExternally
function AfkModule.onModuleStop()
  AfkModule.CreatureAlert.stopAlert()
end

--@UsedExternally
function AfkModule.onStopEvent(event)
  if event == AfkModule.creatureAlertEvent then
    AfkModule.CreatureAlert.stopAlert()
  end
end

function AfkModule.onChooseReplaceItem(self, item)
  if item then
    Panel.ItemToReplace:setItemId(item:getId())
    CandyBot.changeOption('ItemToReplace', item:getId())
    CandyBot.show()
    return true
  end
end

function AfkModule.toggleAlertList()
  if g_game.isOnline() then
    AlertList:toggle()
  end
end

function AfkModule.addFile(file)
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
        g_resources.deleteFile(afkDir..'/'..fileName)
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

function AfkModule.refresh()
  -- refresh the files
  Panel.LoadList:destroyChildren()

  local files = g_resources.listDirectoryFiles(afkDir)
  for _,file in pairs(files) do
    AfkModule.addFile(file)
  end
  Panel.LoadList:focusChild(Panel.LoadList:getChildByIndex(loadListIndex), ActiveFocusReason)
end

function AfkModule.saveAfk(file)
  local path = afkDir.."/"..file..".otml"
  local config = g_configs.load(path)
  if config then
    local msg = "Are you sure you would like to save over "..file.."?"

    local yesCallback = function()
      writeAfk(config)
      
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
    writeAfk(config)

    Panel.SaveNameEdit:setText("")
  end

  local formatedFile = file..".otml"
  if not Panel.LoadList:getChildById(formatedFile) then
    AfkModule.addFile(formatedFile)
  end
end

function AfkModule.loadAfk(file, force)
  BotLogger.debug("AfkModule.loadAfk("..file..")")
  local path = afkDir.."/"..file
  local config = g_configs.load(path)
  BotLogger.debug("AfkModule"..tostring(config))
  if config then
    local loadFunc = function()
      parseAfk(config)
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

      loadWindow = displayGeneralBox(tr('Load Afk'), tr(msg), {
        { text=tr('Yes'), callback = yesCallback},
        { text=tr('No'), callback = noCallback},
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  end
end

-- local functions

function writeAfk(config)
  if not config then return end

  local options = {}
  local afk = {}
  afk.options = options

  -- options.CreatureAlert = Panel.CreatureAlert:isChecked()
  -- options.CreatureAlertList = Panel.CreatureAlertList
  options.AutoEat = Panel.AutoEat:isChecked()
  options.AutoEatSelect = Panel.AutoEatSelect:getText()
  options.AutoFishing = Panel.AutoFishing:isChecked()
  options.AutoFishingCheckCap = Panel.AutoFishingCheckCap:isChecked()
  options.RuneMake = Panel.RuneMake:isChecked()
  options.RuneSpellText = Panel.RuneSpellText:getText()
  options.RuneMakeOpenContainer = Panel.RuneMakeOpenContainer:isChecked()
  options.AutoReplaceWeapon = Panel.AutoReplaceWeapon:isChecked()
  options.AutoReplaceWeaponSelect = Panel.AutoReplaceWeaponSelect:getText()
  options.ItemToReplace = Panel.ItemToReplace:getItem()
  options.MagicTrain = Panel.MagicTrain:isChecked()
  options.RuneSpellText = Panel.RuneSpellText:getText()
  options.MagicTrainSpellText = Panel.MagicTrainSpellText:isChecked()
  options.MagicTrainManaRequired = Panel.MagicTrainManaRequired:getValue()

  config:setNode('Afk', afk)
  config:save()

  BotLogger.debug("Saved ".."afkConfig" .." to "..config:getFileName())
end

function parseAfk(config)
  if not config then return end

  local afk = config:getNode("Afk")

  local options = afk.options

  Panel.CreatureAlert:setChecked(false)
  -- Panel.CreatureAlertList
  Panel.AutoEat:setChecked(options.AutoEat)
  Panel.AutoEatSelect:setText(options.AutoEatSelect)
  Panel.AutoFishing:setChecked(options.AutoFishing)
  Panel.AutoFishingCheckCap:setChecked(options.AutoFishingCheckCap)
  Panel.RuneMake:setChecked(options.RuneMake)
  Panel.RuneSpellText:setText(options.RuneSpellText)
  Panel.RuneMakeOpenContainer:setChecked(options.RuneMakeOpenContainer)
  Panel.AutoReplaceWeapon:setChecked(options.AutoReplaceWeapon)
  Panel.AutoReplaceWeaponSelect:setText(options.AutoReplaceWeaponSelect)
  Panel.ItemToReplace:setItemId(options.ItemToReplace)
  Panel.MagicTrain:setChecked(options.MagicTrain)
  Panel.RuneSpellText:setText(options.RuneSpellText)
  Panel.MagicTrainSpellText:setChecked(options.MagicTrainSpellText)
  Panel.MagicTrainManaRequired:setValue(options.MagicTrainManaRequired)

end

return AfkModule
