--[[
  @Authors: Ben Dol (BeniS)
  @Details: Auto replace hands event logic
]]

AfkModule.AutoReplaceHands = {}
AutoReplaceHands = AfkModule.AutoReplaceHands

function AutoReplaceHands.Event(event)
  if g_game.isOnline() then
    local player = g_game.getLocalPlayer()

    local selectedItem = AfkModule.getPanel():getChildById('ItemToReplace'):getItem():getId()
    local item = player:getItemInContainers(selectedItem)
    
    local hand = InventorySlotOther
    if AfkModule.getPanel():getChildById('AutoReplaceWeaponSelect'):getText() == "Left Hand" then
      hand = InventorySlotLeft
    elseif AfkModule.getPanel():getChildById('AutoReplaceWeaponSelect'):getText() == "Right Hand" then
      hand = InventorySlotRight
    else
      hand = InventorySlotAmmo
    end
    local handPos = {['x'] = 65535, ['y'] = hand, ['z'] = 0}

    local handItem = player:getInventoryItem(hand)
    if hand~=InventorySlotAmmo and handItem and handItem:getCount() > 3 then
      return 10000
    end
    if hand==InventorySlotAmmo and handItem and handItem:getCount() > 50 then
      return 10000
    end

    if item then --and (not handItem or handItem:getId() ~= item:getId()) then
      amountToMove = item:getCount()
      if handItem~=nil and item:getCount() + handItem:getCount() > 100 then
        amountToMove = 100 - handItem:getCount()
      end
      BotLogger.debug("AutoReplaceHands.Event: moving amount " .. tostring(amountToMove))
      g_game.move(item, handPos, amountToMove)
    end
  end

  return Helper.safeDelay(500, 1500)
end