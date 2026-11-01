local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local async = require('openmw.async')

local l10n = core.l10n('OMWCheats')
local settings = storage.playerSection('SettingsOMWCheats')

local MIN_AMOUNT = 1
local MAX_AMOUNT = 1000000

local function giveGold()
    local amount = math.floor(tonumber(settings:get('amount')) or 0)
    amount = math.max(MIN_AMOUNT, math.min(amount, MAX_AMOUNT))

    core.sendGlobalEvent('OMWCheatsAddGold', { actor = self, amount = amount })
    ui.showMessage(l10n('goldAdded', { amount = tostring(amount) }))
end

settings:subscribe(async:callback(function(_, key)
    if key == 'giveGold' and settings:get('giveGold') then
        -- Reset first: moveInto() in the global handler runs on the next frame,
        -- so a second tap before then must not be ignored as "no change".
        settings:set('giveGold', false)
        giveGold()
    end
end))
