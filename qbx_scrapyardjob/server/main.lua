local function now() return os.time() end
local function notify(src, message, kind) TriggerClientEvent('qbx_scrapyardjob:client:notify', src, message, kind or 'error') end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function citizenId(src)
    local player = getPlayer(src)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

local function getBusinessForLocation(locationId)
    return MySQL.single.await('SELECT * FROM scrapyard_businesses WHERE location_id = ? AND status IN (?, ?) LIMIT 1', { locationId, 'active', 'suspended' })
end

local function roleFor(business, cid, source)
    if source and ScrapyardIsRootAdmin(source) then return { grade = 3, owner = true, rootAdmin = true } end
    if not business or not cid then return nil end
    if business.owner_citizenid == cid then return { grade = 3, owner = true } end
    local row = MySQL.single.await('SELECT grade FROM scrapyard_employees WHERE business_id = ? AND citizenid = ?', { business.id, cid })
    if row then return { grade = tonumber(row.grade), owner = false } end
end

local function allowed(role, permission)
    if not role then return false end
    if role.owner or role.rootAdmin then return true end
    local grade = Config.Employees.grades[role.grade]
    return grade and grade.permissions[permission] == true or false
end

local function getAccountMoney(account)
    local ok, amount = pcall(function() return exports['Renewed-Banking']:getAccountMoney(account) end)
    if not ok then return nil end
    return tonumber(amount)
end

local function dashboard(src, locationId)
    if type(locationId) ~= 'string' or #locationId > 50 then return nil end
    local business = getBusinessForLocation(locationId)
    local cid = citizenId(src)
    local role = roleFor(business, cid, src)
    if not business or not role then return { location = locationId, owned = false, role = nil, auctions = {} } end
    local auctions = MySQL.query.await('SELECT id, model, vehicle_class, price, expires_at FROM scrapyard_auctions WHERE status = ? AND expires_at > ? ORDER BY listed_at DESC LIMIT 50', { 'available', now() }) or {}
    local vehicles = MySQL.query.await('SELECT id, model, vehicle_class, plate, status, purchase_price FROM scrapyard_vehicles WHERE business_id = ? ORDER BY id DESC LIMIT 50', { business.id }) or {}
    local transactions = MySQL.query.await('SELECT title, amount, transaction_type, issuer, created_at FROM scrapyard_transactions WHERE business_id = ? ORDER BY created_at DESC LIMIT 30', { business.id }) or {}
    local employees = MySQL.query.await('SELECT citizenid, grade, hired_at FROM scrapyard_employees WHERE business_id = ? ORDER BY hired_at ASC', { business.id }) or {}
    return { location = locationId, owned = true, business = { id = business.id, status = business.status, ownership_type = business.ownership_type, account_balance = getAccountMoney(business.bank_account_id) }, role = role, auctions = auctions, vehicles = vehicles, transactions = transactions, employees = employees }
end

lib.callback.register('qbx_scrapyardjob:server:dashboard', function(src, locationId)
    local result = dashboard(src, locationId)
    if not result then return nil end
    return result
end)

lib.callback.register('qbx_scrapyardjob:server:buyAuction', function(src, payload)
    if type(payload) ~= 'table' then return { ok = false, error = 'Invalid request.' } end
    local auctionId = tonumber(payload.auctionId)
    local locationId = payload.location
    if not auctionId or auctionId < 1 or type(locationId) ~= 'string' then return { ok = false, error = 'Invalid auction selection.' } end
    local business = getBusinessForLocation(locationId)
    local cid = citizenId(src)
    local role = roleFor(business, cid, src)
    if not business or business.status ~= 'active' or not allowed(role, 'purchaseVehicle') then return { ok = false, error = Locales.en.not_authorized } end
    local key = 'auction:' .. tostring(auctionId)
    if GlobalState[key] then return { ok = false, error = 'Auction purchase is processing.' } end
    GlobalState[key] = true
    local result = { ok = false, error = 'Purchase failed.' }
    local success, err = pcall(function()
        local auction = MySQL.single.await('SELECT * FROM scrapyard_auctions WHERE id = ? AND status = ? AND expires_at > ? FOR UPDATE', { auctionId, 'available', now() })
        if not auction then error('Auction is no longer available.') end
        local amount = tonumber(auction.price)
        local balance = getAccountMoney(business.bank_account_id)
        if not balance or balance < amount then error('Insufficient business funds.') end
        local removeOk, removed = pcall(function() return exports['Renewed-Banking']:removeAccountMoney(business.bank_account_id, amount) end)
        if not removeOk or removed == false then error('Business account debit failed.') end
        local plate = ('SY%06d'):format(math.random(0, 999999))
        local transactionId = ('scrap-auction-%d-%d'):format(auctionId, now())
        local inserted = MySQL.transaction.await({
            { query = 'UPDATE scrapyard_auctions SET status = ? WHERE id = ? AND status = ?', values = { 'sold', auctionId, 'available' } },
            { query = 'INSERT INTO scrapyard_vehicles (business_id, auction_id, purchased_by, model, vehicle_class, plate, purchase_price, status, pickup_location) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', values = { business.id, auctionId, cid, auction.model, auction.vehicle_class, plate, amount, 'awaiting_pickup', auction.pickup_location } },
            { query = 'INSERT INTO scrapyard_transactions (business_id, transaction_id, title, amount, transaction_type, issuer, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', values = { business.id, transactionId, 'Government auction vehicle', amount, 'withdraw', cid or 'root-admin', now() } },
        })
        if not inserted then
            pcall(function() exports['Renewed-Banking']:addAccountMoney(business.bank_account_id, amount) end)
            error('Database update failed; refund was requested.')
        end
        result = { ok = true, data = dashboard(src, locationId) }
    end)
    GlobalState[key] = nil
    if not success then result = { ok = false, error = tostring(err):gsub('^.-:%d+: ', '') } end
    return result
end)

exports('GetBusinessForCitizen', function(cid)
    return MySQL.query.await('SELECT * FROM scrapyard_businesses WHERE owner_citizenid = ? AND status IN (?, ?)', { cid, 'active', 'suspended' })
end)
