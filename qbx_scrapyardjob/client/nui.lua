local function nuiCallback(name, serverCallback, payloadTransform)
    RegisterNUICallback(name, function(data, cb)
        local payload = payloadTransform and payloadTransform(data or {}) or data
        local ok, result = pcall(function()
            return lib.callback.await(serverCallback, false, payload)
        end)
        if not ok then
            cb({ ok = false, error = 'Server request failed.' })
            return
        end
        if result and result.ok and result.data then
            SendNUIMessage({ action = 'refresh', data = result.data, isAdminPanel = result.data.isRootAdmin == true })
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

nuiCallback('refresh', 'qbx_scrapyardjob:server:dashboard', function(data) return data.location end)
nuiCallback('buyAuction', 'qbx_scrapyardjob:server:buyAuction')
nuiCallback('adminRefresh', 'qbx_scrapyardjob:server:adminDashboard')
nuiCallback('adminAction', 'qbx_scrapyardjob:server:adminAction')
