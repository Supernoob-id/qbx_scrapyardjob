CreateThread(function()
    while true do
        Wait(60000)
        local timestamp = os.time()
        local expired = MySQL.query.await('SELECT id, location_id, ownership_type, lease_expires_at, grace_expires_at, last_rent_payment_at, rental_price, bank_account_id FROM scrapyard_businesses WHERE ownership_type = ? AND status IN (?, ?)', { 'rental', 'active', 'suspended' }) or {}
        for _, business in ipairs(expired) do
            if tonumber(business.grace_expires_at) > 0 and timestamp >= tonumber(business.grace_expires_at) then
                MySQL.update.await('UPDATE scrapyard_businesses SET status = ? WHERE id = ? AND status IN (?, ?)', { 'expired', business.id, 'active', 'suspended' })
            elseif timestamp >= tonumber(business.lease_expires_at) and tonumber(business.last_rent_payment_at) < tonumber(business.lease_expires_at) then
                local ok, balance = pcall(function() return exports['Renewed-Banking']:getAccountMoney(business.bank_account_id) end)
                if ok and tonumber(balance) and tonumber(balance) >= tonumber(business.rental_price) then
                    local removedOk, removed = pcall(function() return exports['Renewed-Banking']:removeAccountMoney(business.bank_account_id, tonumber(business.rental_price)) end)
                    if removedOk and removed ~= false then
                        local renewedUntil = timestamp + Config.Business.defaultRentalDays * 86400
                        local updated = MySQL.update.await('UPDATE scrapyard_businesses SET lease_started_at = ?, lease_expires_at = ?, grace_expires_at = ?, last_rent_payment_at = ?, status = ? WHERE id = ? AND status = ? AND last_rent_payment_at < lease_expires_at', { timestamp, renewedUntil, renewedUntil + Config.Business.graceDays * 86400, timestamp, 'active', business.id, 'active' })
                        if not updated or updated < 1 then pcall(function() exports['Renewed-Banking']:addAccountMoney(business.bank_account_id, tonumber(business.rental_price)) end) end
                    end
                else
                    MySQL.update.await('UPDATE scrapyard_businesses SET status = ? WHERE id = ? AND status = ?', { 'suspended', business.id, 'active' })
                end
            end
        end
        MySQL.update.await('UPDATE scrapyard_auctions SET status = ? WHERE status = ? AND expires_at <= ?', { 'expired', 'available', timestamp })
    end
end)
