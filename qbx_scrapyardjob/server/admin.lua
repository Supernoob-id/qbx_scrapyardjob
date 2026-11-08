-- Root administrator access is deliberately ACE-only and checked server-side for every callback.
function ScrapyardIsRootAdmin(source)
    if type(source) ~= 'number' or source <= 0 then return false end
    local permission = Config.Admin and Config.Admin.acePermission
    if type(permission) ~= 'string' or permission == '' then return false end
    return IsPlayerAceAllowed(source, permission)
end

local function rootOnly(source)
    if ScrapyardIsRootAdmin(source) then return true end
    print(('[qbx_scrapyardjob] denied root admin request from player %s'):format(tostring(source)))
    return false
end

local function adminSnapshot()
    return {
        isRootAdmin = true,
        businesses = MySQL.query.await([[SELECT id, location_id, owner_citizenid, ownership_type, status, purchase_price, rental_price, lease_expires_at, grace_expires_at
            FROM scrapyard_businesses ORDER BY location_id ASC LIMIT 200]]) or {},
        employees = MySQL.query.await([[SELECT e.business_id, e.citizenid, e.grade, e.hired_at, b.location_id, b.status AS business_status
            FROM scrapyard_employees e INNER JOIN scrapyard_businesses b ON b.id = e.business_id
            ORDER BY b.location_id ASC, e.hired_at ASC LIMIT 500]]) or {},
        auctions = MySQL.query.await([[SELECT id, model, vehicle_class, price, status, listed_at, expires_at
            FROM scrapyard_auctions ORDER BY id DESC LIMIT 100]]) or {},
    }
end

lib.callback.register('qbx_scrapyardjob:server:adminDashboard', function(source)
    if not rootOnly(source) then return { ok = false, error = 'Root administrator permission required.' } end
    return { ok = true, data = adminSnapshot() }
end)

lib.callback.register('qbx_scrapyardjob:server:adminAction', function(source, payload)
    if not rootOnly(source) then return { ok = false, error = 'Root administrator permission required.' } end
    if type(payload) ~= 'table' or type(payload.action) ~= 'string' then
        return { ok = false, error = 'Invalid administrator request.' }
    end

    local success, message = pcall(function()
        if payload.action == 'setBusinessStatus' then
            local businessId = payload.businessId
            local status = payload.status
            if type(businessId) ~= 'string' or #businessId < 1 or #businessId > 50 then error('Invalid business ID.') end
            if status ~= 'active' and status ~= 'suspended' and status ~= 'expired' then error('Invalid business status.') end
            local business = MySQL.single.await('SELECT id, location_id FROM scrapyard_businesses WHERE id = ?', { businessId })
            if not business then error('Business not found.') end
            if status == 'active' then
                local occupied = MySQL.single.await('SELECT id FROM scrapyard_businesses WHERE location_id = ? AND status IN (?, ?) AND id <> ? LIMIT 1', { business.location_id, 'active', 'suspended', businessId })
                if occupied then error('Another active or suspended business already owns this location.') end
            end
            local changed = MySQL.update.await('UPDATE scrapyard_businesses SET status = ? WHERE id = ?', { status, businessId })
            if not changed or changed < 1 then error('Business status was not changed.') end
            print(('[qbx_scrapyardjob] root admin %s set business %s status to %s'):format(source, businessId, status))
        elseif payload.action == 'setEmployee' then
            local businessId, citizenid = payload.businessId, payload.citizenid
            local grade = tonumber(payload.grade)
            if type(businessId) ~= 'string' or #businessId < 1 or #businessId > 50 then error('Invalid business ID.') end
            if type(citizenid) ~= 'string' or #citizenid < 1 or #citizenid > 50 then error('Invalid citizen ID.') end
            if not grade or grade % 1 ~= 0 or not Config.Employees.grades[grade] then error('Employee grade must be 0, 1, or 2.') end
            local business = MySQL.single.await('SELECT id, owner_citizenid, status FROM scrapyard_businesses WHERE id = ?', { businessId })
            if not business or (business.status ~= 'active' and business.status ~= 'suspended') then error('Business is unavailable for employee management.') end
            if citizenid == business.owner_citizenid then error('The business owner cannot be assigned as an employee.') end
            local employee = MySQL.single.await('SELECT id FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { businessId, citizenid })
            if employee then
                local changed = MySQL.update.await('UPDATE scrapyard_employees SET grade = ? WHERE business_id = ? AND citizenid = ?', { grade, businessId, citizenid })
                if changed == nil then error('Employee grade update failed.') end
            else
                local count = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM scrapyard_employees WHERE business_id = ?', { businessId }) or 0)
                if count >= Config.Employees.maxPerBusiness then error('Employee limit reached.') end
                local inserted = MySQL.insert.await('INSERT INTO scrapyard_employees (business_id, citizenid, grade, hired_at) VALUES (?, ?, ?, ?)', { businessId, citizenid, grade, os.time() })
                if not inserted then error('Employee could not be added.') end
            end
            print(('[qbx_scrapyardjob] root admin %s set employee %s grade %d for business %s'):format(source, citizenid, grade, businessId))
        elseif payload.action == 'removeEmployee' then
            local businessId, citizenid = payload.businessId, payload.citizenid
            if type(businessId) ~= 'string' or #businessId < 1 or #businessId > 50 then error('Invalid business ID.') end
            if type(citizenid) ~= 'string' or #citizenid < 1 or #citizenid > 50 then error('Invalid citizen ID.') end
            local business = MySQL.single.await('SELECT id, owner_citizenid FROM scrapyard_businesses WHERE id = ?', { businessId })
            if not business then error('Business not found.') end
            if citizenid == business.owner_citizenid then error('The business owner cannot be removed as an employee.') end
            local employee = MySQL.single.await('SELECT id FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { businessId, citizenid })
            if not employee then error('Employee not found.') end
            local changed = MySQL.update.await('DELETE FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { businessId, citizenid })
            if not changed or changed < 1 then error('Employee could not be removed.') end
            print(('[qbx_scrapyardjob] root admin %s removed employee %s from business %s'):format(source, citizenid, businessId))
        elseif payload.action == 'createAuction' then
            local model = payload.model
            local class = tonumber(payload.vehicleClass)
            local price = tonumber(payload.price)
            local days = tonumber(payload.days)
            if type(model) ~= 'string' or #model < 2 or #model > 80 or not model:match('^[%w_]+$') then error('Model must be 2-80 letters, numbers, or underscores.') end
            if not class or class % 1 ~= 0 or class < 0 or class > 21 then error('Vehicle class must be between 0 and 21.') end
            if not price or price % 1 ~= 0 or price < 1 or price > 2000000000 then error('Auction price is invalid.') end
            if not days or days % 1 ~= 0 or days < 1 or days > 30 then error('Auction duration must be 1-30 days.') end
            local stamp = os.time()
            local id = MySQL.insert.await('INSERT INTO scrapyard_auctions (model, vehicle_class, price, status, pickup_location, listed_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)', { model:lower(), class, price, 'available', nil, stamp, stamp + days * 86400 })
            if not id then error('Auction listing could not be created.') end
            print(('[qbx_scrapyardjob] root admin %s created auction listing %s'):format(source, id))
        elseif payload.action == 'disableAuction' then
            local auctionId = tonumber(payload.auctionId)
            if not auctionId or auctionId % 1 ~= 0 or auctionId < 1 then error('Invalid auction ID.') end
            local changed = MySQL.update.await('UPDATE scrapyard_auctions SET status = ? WHERE id = ? AND status = ?', { 'disabled', auctionId, 'available' })
            if not changed or changed < 1 then error('Available auction listing not found.') end
            print(('[qbx_scrapyardjob] root admin %s disabled auction %s'):format(source, auctionId))
        else
            error('Unknown administrator action.')
        end
    end)

    if not success then return { ok = false, error = tostring(message):gsub('^.-:%d+: ', '') } end
    return { ok = true, data = adminSnapshot() }
end)

RegisterCommand(Config.Admin.command or 'scrapyardadmin', function(source)
    if source == 0 then
        print('[qbx_scrapyardjob] This command must be used in-game.')
        return
    end
    if not rootOnly(source) then
        TriggerClientEvent('qbx_scrapyardjob:client:notify', source, 'Root administrator permission required.', 'error')
        return
    end
    TriggerClientEvent('qbx_scrapyardjob:client:openAdmin', source)
end, false)
