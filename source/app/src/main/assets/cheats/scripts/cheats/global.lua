local types = require('openmw.types')
local world = require('openmw.world')

return {
    eventHandlers = {
        OMWCheatsAddGold = function(data)
            if not data.actor or not data.actor:isValid() then
                return
            end
            local money = world.createObject('gold_001', data.amount)
            money:moveInto(types.Actor.inventory(data.actor))
        end,
    },
}
