-- Illegal missions are deliberately locked until vehicle ownership, police dispatch and spawn
-- integrations have been configured and reviewed for this server.
lib.callback.register('qbx_scrapyardjob:server:startIllegalJob', function(src)
    if not Config.Illegal.enabled or not Config.Illegal.missionStart or not Config.Illegal.delivery or #Config.Illegal.vehicleModels == 0 then
        return { ok = false, error = 'Illegal scrapyard missions are disabled until server configuration is complete.' }
    end
    return { ok = false, error = 'Mission adapter is not configured; no mission or reward was started.' }
end)
