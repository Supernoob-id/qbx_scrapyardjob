# qbx_scrapyardjob

FiveM Qbox scrapyard resource by **Supernoob Indonesia**. The first repository version includes the persistent business/auction foundation, role-checked server callbacks, rental processing, and a NUI shell. Location-specific interactions remain disabled until you configure genuine server coordinates.

## Dependencies
- qbx_core
- ox_lib
- ox_inventory
- ox_target
- oxmysql
- Renewed-Banking

Ensure dependencies start before this resource. No QB legacy resources are used.

## Installation
1. Copy `qbx_scrapyardjob/` into a FiveM resources folder.
2. Import `database.sql` into the same database used by oxmysql.
3. Set up Renewed-Banking job accounts only through the documented exports configured in `server/business.lua`; ensure the server resource is named exactly `Renewed-Banking`.
4. Configure `Config.Locations` with valid coordinates and enable only locations that exist in your world. Leave the table empty to keep location interactions disabled.
5. Confirm all configured item names exist in ox_inventory.
6. Add `ensure qbx_scrapyardjob` after dependencies in server.cfg.

## Configure before use
- `config.lua`: real business/pickup/dropoff locations, pricing, rental amounts, police integration, storage adapter, catalog and scrap item weights.
- `Config.Illegal` is disabled by default; mission coordinates, vehicle allowlist, payout, dispatch adapter, and server-side vehicle ownership/state verification must be configured before enabling.
- `Config.Storage` is disabled pending a server-specific storage adapter.
- Import the schema before starting the resource. The schema has no automatic seed locations or auction listings.
- Item weights here are safe defaults, not values retrieved from a server inventory configuration. Replace them with the project's intended weights.

## Scope and limitations
This is a repository implementation baseline, not a claim that every feature in the supplied specification has been runtime-tested. Deployment-sensitive vehicle spawning/ownership, government auction administration, full employee-management UI, storage integration, police dispatch, and transactional finance reconciliation require integration against the actual server resources and policies. Locations and illegal missions are disabled until configured. Do not enable unverified features on a live server.

## Checks
No FiveM runtime, Lua parser, MySQL server, or Renewed-Banking instance is available in this repository-writing environment. Perform a staging-server test before production.
