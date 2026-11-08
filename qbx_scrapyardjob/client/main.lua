local function notify(message, kind)
    lib.notify({ title = 'Supernoob Indonesia', description = message, type = kind or 'inform' })
end

local function locationConfigured(locationId)
    for _, location in ipairs(Config.Locations) do
        if location.id == locationId and location.enabled and location.coords then return true end
    end
    return false
end

CreateThread(function()
    for _, location in ipairs(Config.Locations) do
        if location.enabled and location.coords then
            exports.ox_target:addSphereZone({
                coords = location.coords, radius = 1.5,
                options = {{ name = 'qbx_scrapyard_' .. location.id, icon = 'fa-solid fa-recycle', label = 'Open scrapyard business',
                    onSelect = function() TriggerEvent('qbx_scrapyardjob:client:open', location.id) end }}
            })
        end
    end
end)

RegisterNetEvent('qbx_scrapyardjob:client:open', function(locationId)
    if not locationConfigured(locationId) then notify(Locales.en.unavailable, 'error'); return end
    local data = lib.callback.await('qbx_scrapyardjob:server:dashboard', false, locationId)
    if not data then notify(Locales.en.unavailable, 'error'); return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNetEvent('qbx_scrapyardjob:client:notify', function(message, kind) notify(message, kind) end)
