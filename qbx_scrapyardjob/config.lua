Config = {}
Config.Locale = 'en'
Config.Debug = false
Config.Notify = { position = 'top-right', duration = 5000 }

Config.Security = {
    maxDistance = 8.0,
    requestCooldownMs = 1200,
    maxRewardItems = 8,
    maxAmountPerReward = 10,
}

Config.Business = {
    maxPerPlayer = 4,
    defaultRentalDays = 7,
    graceDays = 7,
    rentalPrice = 25000,
    purchasePrice = 500000,
    accountPrefix = 'scrapyard_',
    defaultEmployees = 8,
    requireConfiguredLocation = true,
}

Config.Catalog = {
    -- Define model, class and pricing here. Auction rows are added by server operators.
    classes = { 'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports', 'Super', 'Motorcycles', 'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats', 'Helicopters', 'Planes', 'Service', 'Emergency', 'Military', 'Commercial', 'Trains' },
}
Config.Employees = {
    maxPerBusiness = 8,
    grades = {
        [0] = { name = 'Worker', permissions = { pickupVehicle = true, scrapVehicle = true } },
        [1] = { name = 'Supervisor', permissions = { pickupVehicle = true, scrapVehicle = true, sellParts = true, purchaseVehicle = true, manageFinances = true } },
        [2] = { name = 'Manager', permissions = { pickupVehicle = true, scrapVehicle = true, sellParts = true, purchaseVehicle = true, manageFinances = true, manageEmployees = true } },
    },
}
Config.Auction = { enabled = true, listingDays = 3, pickupBlip = true }
Config.Rewards = {
    classes = {
        [0]={parts=35,materials=90},[1]={parts=40,materials=90},[2]={parts=55,materials=95},[3]={parts=45,materials=90},[4]={parts=60,materials=85},[5]={parts=65,materials=85},[6]={parts=70,materials=80},[7]={parts=80,materials=75},[8]={parts=30,materials=70},[9]={parts=65,materials=90},[10]={parts=75,materials=100},[11]={parts=60,materials=90},[12]={parts=50,materials=95},[13]={parts=5,materials=15},[14]={parts=65,materials=85},[15]={parts=85,materials=70},[16]={parts=90,materials=75},[17]={parts=55,materials=90},[18]={parts=75,materials=85},[19]={parts=95,materials=100},[20]={parts=80,materials=100},[21]={parts=95,materials=100},
    },
    materials = { 'metalscrap','plastic','copper','iron','aluminum','steel','glass','ducttape','rubber','electric_scrap' },
    parts = { 'engine1','transmission1','brakes1','suspension1','headlights','hood','roof','turbo','spoiler','bumper','skirts','exhaust','seat','rims','tires','sparkplugs','carbattery','axleparts','sparetire','noscan' },
    -- Replace weights with the weights from your inventory/items configuration.
    weights = { materials = { metalscrap=20,plastic=14,copper=8,iron=12,aluminum=10,steel=8,glass=10,ducttape=4,rubber=10,electric_scrap=4 }, parts = { engine1=2,transmission1=2,brakes1=8,suspension1=8,headlights=8,hood=5,roof=3,turbo=1,spoiler=3,bumper=6,skirts=4,exhaust=5,seat=8,rims=8,tires=8,sparkplugs=8,carbattery=4,axleparts=5,sparetire=5,noscan=1 } },
    materialMin = 1, materialMax = 4, partMin = 1, partMax = 2,
}
Config.Cooldowns = { playerSeconds = 1800, vehicleSeconds = 86400 }
Config.Police = { enabled = false, minimumOnDuty = 0, dispatchEvent = nil, riskPercent = 25 }
Config.Storage = { enabled = false, adapter = nil }
Config.Shop = { enabled = false, priceMultiplier = 1.0 }
Config.Locations = {
    -- No active locations until server-specific coordinates and pickup/dropoff points are configured.
    -- Example: { id='davis', label='Davis Scrapyard', coords=vec3(...), pickup=vec3(...), dropoff=vec3(...), enabled=true }
}

Config.Illegal = { enabled = false, missionStart = nil, delivery = nil, vehicleModels = {}, payout = 0 }
