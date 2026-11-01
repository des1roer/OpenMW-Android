local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local async = require('openmw.async')

local l10n = core.l10n('OMWCheats')
local settings = storage.playerSection('SettingsOMWCheats')

local MIN_AMOUNT = 1
local MAX_AMOUNT = 1000000

settings:subscribe(async:callback(function(_, key)
    if key ~= 'giveGold' or not settings:get('giveGold') then
        return
    end

    local amount = math.floor(tonumber(settings:get('amount')) or 0)
    amount = math.max(MIN_AMOUNT, math.min(amount, MAX_AMOUNT))

    -- Events only carry plain GameObject references, not the openmw.self proxy.
    local ok, err = pcall(core.sendGlobalEvent, 'OMWCheatsAddGold', { actor = self.object, amount = amount })
    if not ok then
        -- Nothing will reply if sending the event itself failed, so reset now.
        -- Otherwise scripts/cheats/global.lua resets it when its reply arrives;
        -- doing that here instead would write to this same key from within its
        -- own change notification, which this storage API does not document
        -- as safe, and in testing produced no visible effect at all.
        settings:set('giveGold', false)
        ui.showMessage(l10n('cheatError', { error = tostring(err) }))
    end
end))

return {
    eventHandlers = {
        -- Sent by scripts/cheats/global.lua once it has processed the request.
        OMWCheatsGoldResult = function(data)
            settings:set('giveGold', false)
            if data.ok then
                ui.showMessage(l10n('goldAdded', { amount = tostring(data.amount) }))
            else
                ui.showMessage(l10n('cheatError', { error = tostring(data.error) }))
            end
        end,
    },
}
