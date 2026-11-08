local function nuiCallback(name, serverCallback)
    RegisterNUICallback(name, function(data, cb)
        local result = lib.callback.await(serverCallback, false, data)
        if result and result.ok then
            SendNUIMessage({ action = 'refresh', data = result.data })
        elseif result and result.error then
            lib.notify({ title = 'Supernoob Indonesia', description = result.error, type = 'error' })
        end
        cb(result or { ok = false, error = 'Request failed' })
    end)
end

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

nuiCallback('refresh', 'qbx_scrapyardjob:server:dashboard')
nuiCallback('buyAuction', 'qbx_scrapyardjob:server:buyAuction')
