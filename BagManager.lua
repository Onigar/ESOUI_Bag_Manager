--	----------------------------------------------------------------------
--	BagManager by Onigar
--	----------------------------------------------------------------------
-- This software is provided under the following CreativeCommons license,
--
-- Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
--
-- You are free to:
-- 	Share — copy and redistribute the material in any medium or format
-- 	Adapt — remix, transform, and build upon the material
--
-- The licensor cannot revoke these freedoms as long as you follow the
-- license terms.
--
-- Under the following terms:
--
-- 	Attribution — 	You must give appropriate credit, provide a link to the
-- 				  	license, and indicate if changes were made. You may do
--					so in any reasonable manner, but not in any way that
--					suggests the licensor endorses you or your use.
--
-- 	NonCommercial — You may not use the material for commercial purposes.
--
-- 	ShareAlike — 	If you remix, transform, or build upon the material,
--					you must distribute your contributions under the same
--					license as the original.
--
-- 	No additional restrictions —
--                  You may not apply legal terms or technological measures
--                  that legally restrict others from doing anything the
--                  license permits.
--
-- Notices:
-- You do not have to comply with the license for elements of the material in
-- the public domain or where your use is permitted by an applicable exception
-- or limitation.
--
-- No warranties are given. The license may not give you all of the permissions
-- necessary for your intended use. For example, other rights such as publicity,
-- privacy, or moral rights may limit how you use the material.
--
-- You can read the full license at,
-- https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
--
--	----------------------------------------------------------------------
--
-- 	Description:	This module contains the functions required to manage
-- 					automatic handling of Bankable Items in your Bag allowing
--					your characters maintain a Bag reserve controlled by you.
--
--	Fixed:			Each time you visit a Bank interface, your character's
-- 					specific Bag Items will be set to your predefined amount.
--
--	Empty:		    For characters you choose to not keep in your bag any
--					of a specific transferable item.
--
--	None:		    For characters you choose to not have any management for
--                  a specific transferable item.
--
--  Future:			check for TBD or TODO in comments
--
--
--	----------------------------------------------------------------------

-- Addon Common Definitions
local ADDON_NAME 		= "BagManager"
local ADDON_AUTHOR 		= "Onigar"
local ADDON_WEBSITE		= "http://www.esoui.com/downloads/info2091-BagManager.html#info"
local ADDON_VERSION		= "0.2.0"
-- Version = MajorVersion.MinorVersion.MiniFixes

local characterVar = {}
local charSettings = {}

-- Default Setting is to take no action allowing the User to define Currency Transfer Rules
local STRING_NONE = GetString(BM_CHAR_VAR_NONE)
local defaultCharacterVariables = {
		accountWide 				= false,
		soulGem_ItemLink 			= "|H1:item:33271:31:50:0:0:0:0:0:0:0:0:0:0:0:0:36:0:0:0:0:0|h|h",
		soulGem_ItemId				= 33271,
		soulGem_ManType	 			= STRING_NONE,
		soulGem_FixedAmount			= 100,
		soulGemEmpty_ItemLink 		= "|H1:item:33265:30:50:0:0:0:0:0:0:0:0:0:0:0:0:36:0:0:0:0:0|h|h",
		soulGemEmpty_ItemId			= 33265,
		soulGemEmpty_ManType		= STRING_NONE,
		soulGemEmpty_FixedAmount	= 200,
		debugOn						= false,
}

-- Design
-- 1. get bagsize backpack and bank
--    get number of free slots bag and bank
-- 2. loop through bag
--    find and store item, slot, stackquantity
--    keep count of sumItemBag
-- 3. loop through bank
--    find and store item, slot, stackquantity
--    keep count of sumItemBank
-- 4. get item stack quantity
-- 5. if sumItemBag > ItemFixedAmount then
--      transfer excess to bank
--      if less than 10 free slots pack bank
--    else if sumItemBag < ItemFixedAmount then
--      withdraw from bank to an empty backpack slot
--      if less than 10 free slots pack bag

-- assumptions, bag and backpack have space (spare slots)
-- we can get much smarter with slot usage later after it is basically working TODO





--GetBankItem(slotIndex, bagId)


local function FindTargetSlotId(targetItemId, bagId)

    for slotId = 0, GetBagSize(bagId) do

        local itemId = GetItemId(bagId, slotId)

        if itemId == targetItemId then

			return slotId
		end
    end
end



-- TBD - will implement uncached solution first and then look at this
-- local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
	-- --For each item in that bag
	-- for _, data in pairs(bagCache) do
		-- local bagId     = data.bagId
		-- local slotIndex = data.slotIndex
		-- --do your stuff here
	-- end
-- end

-- initial code development, can be tidied up and optimized after it is working TODO
-- then when working fine can be modified to a generic function
-- single item being used as an example; Soul Gems

local function TransferMiscellaneous()

	local bagSize 				= GetBagSize(BAG_BACKPACK)
	local bankSize				= GetBagSize(BAG_BANK)
	local slotIdItemBank	    = 0
	local maxStackItem			= 0									-- Max stackable size for the item

	local depositItems			= false
	local withdrawItems			= false
    local depositAmount 		= 0
    local withdrawAmount 		= 0
    local itemQty_InBagSlot 	= 0
    local itemQty_InBankSlot	= 0
    local itemQty_InBagTotal 	= 0
    local itemQty_InBankTotal 	= 0

	-- find total quantity of "item" in Bag
	local function GetItemQuantityInBag()
	
		itemQty_InBagTotal = 0
	
		for slotIdBag = 0, bagSize do

			local itemId  = GetItemId(BAG_BACKPACK, slotIdBag)
			local itemQty = 0

			if characterVar.soulGem_ItemId == itemId then

				itemQty, maxStackItem = GetSlotStackSize(BAG_BACKPACK, slotIdBag)

				-- Rolling Total of the item in Bag
				itemQty_InBagTotal = itemQty_InBagTotal + itemQty

			end
		end
	end

	-- find total quantity of "item" in Bank
	local function GetItemQuantityInBank()
	
		itemQty_InBankTotal = 0
		
		for slotIdBank = 0, bankSize do

			local itemId  = GetItemId(BAG_BANK, slotIdBank)
			local itemQty = 0
			
			if characterVar.soulGem_ItemId == itemId then

				itemQty, maxStackItem = GetSlotStackSize(BAG_BANK, slotIdBank)

				-- Rolling Total of the item in Bank
				itemQty_InBankTotal = itemQty_InBankTotal + itemQty

			end
		end
	end

	-- find item and calculate tranfer quantity
	for slotIdBag = 0, bagSize do

		local itemId = GetItemId(BAG_BACKPACK, slotIdBag)

		-- Soul Gem Management
		if characterVar.soulGem_ItemId == itemId then      													-- item is found in BAG_BACKPACK

			if characterVar.soulGem_ManType ~= GetString(BM_CHAR_VAR_NONE) then								-- A Management Type has been selected in Settings

				itemQty_InBagSlot   = GetSlotStackSize(BAG_BACKPACK, slotIdBag)
				depositItems		= false
				withdrawItems		= false
				depositAmount 		= 0
				withdrawAmount 		= 0

				if characterVar.soulGem_ManType == GetString(BM_CHAR_VAR_FIXED) then						-- "Fixed" Management Type has been selected

					-- a bit overkill running these each loop for the managed item, will optimise later		-- TODO
					GetItemQuantityInBag()
					GetItemQuantityInBank()
		
					if characterVar.debugOn then															-- Debug
						d("1: Fixed Management Type")
						d("slotIdBag            = " .. slotIdBag)
						d("soulGem_FixedAmount  = " .. tonumber(characterVar.soulGem_FixedAmount))
						d("itemQty_InBagSlot    = " .. itemQty_InBagSlot)
						d("itemQty_InBagTotal   = " .. itemQty_InBagTotal)
						d("itemQty_InBankTotal  = " .. itemQty_InBankTotal)
					end

					if itemQty_InBagTotal > tonumber(characterVar.soulGem_FixedAmount) then					-- We need to deposit some in the Bank

						if characterVar.debugOn then														-- Debug
							d("2: We need to deposit some in the Bank")
						end

						-- calc Quantity to deposit in bank
						depositAmount = itemQty_InBagTotal - tonumber(characterVar.soulGem_FixedAmount)

						if depositAmount > itemQty_InBagSlot then

							depositAmount = itemQty_InBagSlot												-- Any remaining amount to transfer will be processed in the next iteration of the loop

						end
						
						if characterVar.debugOn then														-- Debug
							d("depositAmount       = " .. depositAmount)
							d("itemQty_InBagSlot   = " .. itemQty_InBagSlot)
							d("itemQty_InBagTotal  = " .. itemQty_InBagTotal)
						end

						depositItems = true

					elseif itemQty_InBagTotal < tonumber(characterVar.soulGem_FixedAmount) then				-- We need to withdraw some from the Bank

						if characterVar.debugOn then														-- Debug
							d("3: We need to withdraw some from the Bank")
						end

						-- need to check there is some in the Bank
						if itemQty_InBankTotal > 0 then
						
							for slotIdBank = 0, bankSize do

								if characterVar.soulGem_ItemId == itemId then

									itemQty_InBankSlot 	= GetSlotStackSize(BAG_BANK, slotIdBank)

									slotIdItemBank = slotIdBank

								end
							end
						end

						-- calc Quantity to withdraw from Bank
						withdrawAmount = tonumber(characterVar.soulGem_FixedAmount) - itemQty_InBagTotal

						if withdrawAmount > itemQty_InBankSlot then

							withdrawAmount = itemQty_InBankSlot

						end

						if characterVar.debugOn then														-- Debug
							d("withdrawAmount       = " .. withdrawAmount)
							d("itemQty_InBagSlot    = " .. itemQty_InBagSlot)
							d("itemQty_InBagTotal   = " .. itemQty_InBagTotal)
							d("itemQty_InBankSlot   = " .. itemQty_InBankSlot)
							d("itemQty_InBankTotal  = " .. itemQty_InBankTotal)
						end

						withdrawItems = true

					end

				else    -- soulGem_ManType == GetString(BM_CHAR_VAR_EMPTY) -- this means "All in BAG_BACKPACK to Bank"  -- code not complete !!!!!!!

					if characterVar.debugOn then
						d("4:  Empty Management Type - All in Bag to Bank")
					end
					-- calc Qty to deposit in bank
					depositAmount = itemQty_InBagSlot

					if characterVar.debugOn then															-- Debug
						d("depositAmount      = " .. depositAmount)
						d("itemQty_InBagSlot  = " .. itemQty_InBagSlot)
					end

					if depositAmount > 0 then

						depositItems = true

					end
				end

				if depositItems or withdrawItems then  														-- There is an item transfer to do

					local targetBankSlot = nil

					if characterVar.debugOn then															-- Debug
						d("5: There is an item transfer to do")
						d("slotIdBag       = " .. slotIdBag)
					end

					if depositItems then

						local numFreeSlotsInBank = GetNumBagFreeSlots(BAG_BANK)

						if characterVar.debugOn then														-- Debug
							d("6: depositItems")
						end

						if numFreeSlotsInBank > 0 then
					
							-- set target slot to first free Bank slot.
							targetBankSlot = FindFirstEmptySlotInBag(BAG_BANK)

						else
							-- calc if some of item can still be transferred								-- when Bank is stacked then the lowest Quantity should be found first
							targetBankSlot = FindTargetSlotId(itemId, BAG_BANK)

							if targetBankSlot then
							
								itemQty_InBankSlot, maxStackItem = GetSlotStackSize(BAG_BANK, targetBankSlot)
								
								if (maxStackItem - itemQty_InBankSlot) < depositAmount then
								
									depositAmount = maxStackItem - itemQty_InBankSlot
								
								end
							end
						end
						
						if targetBankSlot then  -- there is an empty slot in the Bank or item is found and has space for transfer
						
							if characterVar.debugOn then													-- Debug
								d("targetBankSlot     = " .. targetBankSlot)
								d("itemQty_InBankSlot = " .. itemQty_InBankSlot)
								d("depositAmount      = " .. depositAmount)
							end

							-- This function is protected and can only be used out of combat.
							-- RequestMoveItem(number Bag sourceBag, number sourceSlot, number Bag destBag, number destSlot, number stackCount)

							if IsProtectedFunction("RequestMoveItem") then
								CallSecureProtected("RequestMoveItem", BAG_BACKPACK, slotIdBag, BAG_BANK, targetBankSlot, depositAmount)
							else
								RequestMoveItem(BAG_BACKPACK, slotIdBag, BAG_BANK, targetBankSlot, depositAmount)
							end

						else
							-- there is no empty slot or no space in item slot for transfer
							d("[BM] The Bank is full. " ..  GetString(soulGem_ItemLink) .. " could not be transferred")

						end

					elseif withdrawItems then

						if characterVar.debugOn then														-- Debug
							d("7: withdrawItems")
						end

						if targetBankSlot then  -- item is found in the bank (not "nul" was returned)
d("a")
							if itemQty_InBankSlot < withdrawAmount then
d("b")
								withdrawAmount = itemQty_InBankSlot

								-- print chat message, "only nnn amount in bank"
								d("[BM] Only Qty " .. itemQty_InBankSlot .. GetString(soulGem_ItemLink) .. " in Bank but need to withdraw " .. withdrawAmount)

							end

							if IsProtectedFunction("RequestMoveItem") then
d("c")
								CallSecureProtected("RequestMoveItem", BAG_BANK, targetBankSlot, BAG_BACKPACK, slotIdItemBank, withdrawAmount)
							else
								RequestMoveItem(BAG_BANK, targetBankSlot, BAG_BACKPACK, slotIdItemBank, withdrawAmount)
							end

							-- Update Rolling Total of amount of the item in Bag
							--itemQty_InBagTotal = itemQty_InBagTotal + withdrawAmount
							--d("itemQty_InBagTotal  = " .. itemQty_InBagTotal)
						else
							-- need to withdraw but none found in Bank
							d("need to withdraw but none found in Bank")

						end
					end

						-- keep the bag tidy (maybe optimise this later and only call regularly if free space is low)		-- TBD
						StackBag(BAG_BACKPACK)
						StackBag(BAG_BANK)

				end
			end
		end
	end
end


local function CreateSettingsMenu()

	local LAM = LibStub("LibAddonMenu-2.0")

	local panelData = {
		type = "panel",
		-- name = the title you see in the list of addons when displayed by "Settings, Addons"
		name = "Oni's " .. GetString(BM_ADDON_LONG_NAME),
		-- displayName = the title at the top of the addon panel
		displayName = "|c4a9300" .. GetString(BM_ADDON_LONG_NAME) .. "|r",
		author = ADDON_AUTHOR,
		version = ADDON_VERSION,
		registerForRefresh = true,
		registerForDefaults = true,
		website = ADDON_WEBSITE
	}
	LAM:RegisterAddonPanel("BagManagerPanel", panelData)

	local optionsData = {

		{
            type = "description",
			text = ZO_HIGHLIGHT_TEXT:Colorize(GetString(BM_ADDON_DESCRIPTION)),
            width = "full"
        },


		-- Account Wide Settings
		-- divider
        {	type = "divider", width = "full" },
		{
			type = "checkbox",
			name = GetString(BM_ACCOUNT_WIDE_TITLE),
			tooltip = GetString(BM_ACCOUNT_WIDE_TIP),
			default = defaultCharacterVariables.accountWide,
			getFunc = 	function()
							return charSettings.byAccount.accountWide
						end,
			setFunc = 	function(value)
							charSettings.byAccount.accountWide = value
						end,
			requiresReload = true,
		},

		-- -- TBD - add expandable header for "Miscellaneous" Items

		-- Soul Gem Management
		-- divider
        {	type = "divider", width = "full" },
		{
			type = "dropdown",
			name = "|cffff24" .. GetString(BM_SOUL_GEMS_TITLE_PRE) .. "|r" .. GetString(BM_MAN_TYPE_POST),
			tooltip = GetString(BM_MAN_TYPE_TIP),
			default = defaultCharacterVariables.soulGem_ManType,
			choices = {GetString(BM_CHAR_VAR_FIXED), GetString(BM_CHAR_VAR_EMPTY), GetString(BM_CHAR_VAR_NONE)},

			getFunc = 	function()
							return characterVar.soulGem_ManType
						end,
			setFunc = 	function(choice)
							characterVar.soulGem_ManType = choice
						end,
		},
		{
			type = "editbox",
			name = "|cffff24" .. GetString(BM_SOUL_GEMS_TITLE_PRE) .. "|r" .. GetString(BM_FIXED_AMOUNT_POST),
			tooltip = GetString(BM_SOUL_GEMS_FIXED_AMOUNT_TIP),
			default = defaultCharacterVariables.soulGem_FixedAmount,

			getFunc = 	function()
							return characterVar.soulGem_FixedAmount
						end,
			setFunc = 	function(choice)
							characterVar.soulGem_FixedAmount = choice
						end,
		},

		-- Show Debug Messages
		-- divider
        {	type = "divider", width = "full" },
		{
			type = "checkbox",
			name = GetString(BM_SHOW_DEBUG_MESSAGES),
			tooltip = GetString(BM_SHOW_DEBUG_MESSAGES_TIP),
			default = defaultCharacterVariables.debugOn,
			getFunc = 	function()
							return characterVar.debugOn
						end,
			setFunc = 	function(value)
							characterVar.debugOn = value
						end,
			requiresReload = true,
		},
	}
	LAM:RegisterOptionControls("BagManagerPanel", optionsData)
end


local function OnBankOpen(event, bagId)

	if IsHouseBankBag(bagId) then
		-- House Storage Coffer, it has no interface for currency transfer
		return
	else
		TransferMiscellaneous()
	end
end


local function getSettings()
	if charSettings.byAccount.accountWide then
		return charSettings.byAccount
	else
		return charSettings.byChar
	end
end


local function Initialize()
	--	Connect with Account Wide saved Variables
	--  ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
	charSettings.byAccount = ZO_SavedVars:NewAccountWide("BagManagerSettings", 3, nil, defaultCharacterVariables)

	--	Connect with Character Based saved Variables
	--  ZO_SavedVars:NewCharacterNameSettings(savedVariableTable, version, namespace, defaults, profile)
	--  ZO_SavedVars:NewCharacterIdSettings(savedVariableTable, version, namespace, defaults, profile)
	--  Note:
	--  NewCharacterNameSettings saves readable char name in the addon saved var file
	--  NewCharacterIdSettings saves a numeric id instead of the char name in the addon saved var file
	charSettings.byChar = ZO_SavedVars:NewCharacterNameSettings("BagManagerSettings", 3, nil, defaultCharacterVariables)

	-- Use Character or Account Wide Settings
	characterVar = getSettings()

	--	Generate Settings Menu
	CreateSettingsMenu()

	--	Register listener(s) for event(s)
	EVENT_MANAGER:RegisterForEvent("BagManagerBankOpen", EVENT_OPEN_BANK, OnBankOpen)

	--	Cleanup:
	--	After our event has loaded, do not need to listen for further calls.
	EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

end


local function OnAddOnLoaded(event, addonLoading)
	if addonLoading == ADDON_NAME then
		Initialize()
	end
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
