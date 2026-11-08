local function unixNow() return os.time() end
local function locationConfig(id)
    for _, loc in ipairs(Config.Locations) do if loc.id == id and loc.enabled and loc.coords then return loc end end
end

local function createBankAccount(account, label)
    local ok, response = pcall(function()
        return exports['Renewed-Banking']:CreateJobAccount({ name = account, label = label }, 0)
    end)
    return ok and response ~= false
end

lib.callback.register('qbx_scrapyardjob:server:acquireBusiness', function(src, data)
    if type(data) ~= 'table' or type(data.location) ~= 'string' then return { ok = false, error = 'Invalid location.' } end
    local loc = locationConfig(data.location)
    if not loc then return { ok = false, error = Locales.en.unavailable } end
    local player = exports.qbx_core:GetPlayer(src)
    local cid = player and player.PlayerData and player.PlayerData.citizenid
    if not cid then return { ok = false, error = 'Player unavailable.' } end
    local kind = data.ownershipType == 'rental' and 'rental' or data.ownershipType == 'purchase' and 'purchase' or nil
    if not kind then return { ok = false, error = 'Invalid ownership type.' } end
    local id = ('yard_%s_%s'):format(data.location, cid):sub(1, 50)
    local account = (Config.Business.accountPrefix .. data.location):sub(1, 100)
    local stamp = unixNow()
    local leaseEnd = kind == 'rental' and stamp + Config.Business.defaultRentalDays * 86400 or 0
    local graceEnd = kind == 'rental' and leaseEnd + Config.Business.graceDays * 86400 or 0
    local price = kind == 'rental' and Config.Business.rentalPrice or Config.Business.purchasePrice

    local lockName = 'location:' .. data.location
    if GlobalState[lockName] then return { ok = false, error = 'Location is being processed.' } end
    GlobalState[lockName] = true
    local ok, err = pcall(function()
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM scrapyard_businesses WHERE owner_citizenid = ? AND status IN (?, ?)', { cid, 'active', 'suspended' }) or 0
        if tonumber(count) >= Config.Business.maxPerPlayer then error('Business limit reached.') end
        local active = MySQL.single.await('SELECT id FROM scrapyard_businesses WHERE location_id = ? AND status IN (?, ?) LIMIT 1', { data.location, 'active', 'suspended' })
        if active then error('Location is already owned.') end
        local accountOk = createBankAccount(account, loc.label)
        if not accountOk then error('Bank account creation failed.') end
        local inserted = MySQL.insert.await('INSERT INTO scrapyard_businesses (id, location_id, owner_citizenid, ownership_type, status, bank_account_id, purchase_price, rental_price, lease_started_at, lease_expires_at, grace_expires_at, last_rent_payment_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', { id, data.location, cid, kind, 'active', account, kind == 'purchase' and price or 0, kind == 'rental' and price or 0, stamp, leaseEnd, graceEnd, stamp })
        if not inserted then error('Business database insert failed.') end
    end)
    GlobalState[lockName] = nil
    if not ok then return { ok = false, error = tostring(err) } end
    return { ok = true, data = { location = data.location, owned = true, business = { id = id, status = 'active', ownership_type = kind } } }
end)

lib.callback.register('qbx_scrapyardjob:server:employees', function(src, payload)
    if type(payload) ~= 'table' or type(payload.location) ~= 'string' then return { ok = false, error = 'Invalid request.' } end
    local business = MySQL.single.await('SELECT * FROM scrapyard_businesses WHERE location_id = ? AND status = ?', { payload.location, 'active' })
    local player = exports.qbx_core:GetPlayer(src)
    local cid = player and player.PlayerData and player.PlayerData.citizenid
    if not business or not cid then return { ok = false, error = 'Business or player unavailable.' } end
    local rootAdmin = ScrapyardIsRootAdmin(src)
    local role = rootAdmin and { owner = true, rootAdmin = true } or (business.owner_citizenid == cid and { owner = true } or nil)
    if not role then
        local emp = MySQL.single.await('SELECT grade FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { business.id, cid })
        if emp and tonumber(emp.grade) == 2 then role = { owner = false } end
    end
    if not role then return { ok = false, error = Locales.en.not_authorized } end
    if payload.action == 'hire' then
        local target = type(payload.citizenid) == 'string' and payload.citizenid or nil
        local grade = tonumber(payload.grade)
        if not target or #target > 50 or not grade or grade < 0 or grade > 2 then return { ok = false, error = 'Invalid employee details.' } end
        if not role.owner and grade >= 2 then return { ok = false, error = 'Managers cannot appoint another manager.' } end
        local count = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM scrapyard_employees WHERE business_id = ?', { business.id }) or 0)
        if count >= Config.Employees.maxPerBusiness then return { ok = false, error = 'Employee limit reached.' } end
        MySQL.insert.await('INSERT INTO scrapyard_employees (business_id, citizenid, grade, hired_at) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE grade = VALUES(grade)', { business.id, target, grade, os.time() })
        return { ok = true }
    elseif payload.action == 'fire' then
        if type(payload.citizenid) ~= 'string' or payload.citizenid == business.owner_citizenid then return { ok = false, error = 'Invalid employee.' } end
        local employee = MySQL.single.await('SELECT grade FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { business.id, payload.citizenid })
        if not employee then return { ok = false, error = 'Employee not found.' } end
        if not role.owner and tonumber(employee.grade) >= 2 then return { ok = false, error = 'Managers cannot remove another manager.' } end
        MySQL.query.await('DELETE FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { business.id, payload.citizenid })
        return { ok = true }
    end
    return { ok = false, error = 'Unknown employee action.' }
end)
