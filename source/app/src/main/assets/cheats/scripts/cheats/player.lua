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

    -- Events only carry plain GameObject references, not the openmw.self proxy.
    core.sendGlobalEvent('OMWCheatsAddGold', { actor = self.object, amount = amount })
end

settings:subscribe(async:callback(function(_, key)
    if key ~= 'giveGold' or not settings:get('giveGold') then
        return
    end
    -- Reset first: the global handler runs on the next frame, so a second tap
    -- before its reply arrives must not be ignored as "no change".
    settings:set('giveGold', false)

    local ok, err = pcall(giveGold)
    if not ok then
        ui.showMessage(l10n('cheatError', { error = tostring(err) }))
    end
end))

return {
    eventHandlers = {
        -- Sent by scripts/cheats/global.lua once the gold has actually been added.
        OMWCheatsGoldResult = function(data)
            if data.ok then
                ui.showMessage(l10n('goldAdded', { amount = tostring(data.amount) }))
            else
                ui.showMessage(l10n('cheatError', { error = tostring(data.error) }))
            end
        end,
    },
}
