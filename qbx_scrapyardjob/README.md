# qbx_scrapyardjob

FiveM Qbox scrapyard resource by **Supernoob Indonesia**. The resource includes an ACE-protected root administration panel for business status, employee, and auction listing management, alongside the initial business/auction foundation.

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
2. Import `database.sql` into the database used by oxmysql.
3. In `server.cfg`, grant root permission only to trusted staff, for example:
   ```cfg
   add_ace group.admin scrapyard.root allow
   add_principal identifier.license:YOUR_LICENSE_HERE group.admin
   ```
   Replace the identifier with the trusted administrator's actual license. Do not grant the ACE to broad public groups.
4. Configure `Config.Admin.acePermission` and `Config.Admin.command` if desired. Root admins can use `/scrapyardadmin`.
5. Configure real coordinates in `Config.Locations`; no location is active by default.
6. Confirm configured item names exist in ox_inventory and configure server-specific integrations.
7. Add `ensure qbx_scrapyardjob` after dependencies in server.cfg.

## Root administrator
Root access is checked on the server for the command and every admin callback using `IsPlayerAceAllowed`. The NUI is only presentation and does not grant authorization. Root admins can review businesses, change business status, manage employee grades/membership, create auction listings, and disable available listings. These operations are logged to the server console. Activating a business can fail if its location is occupied. Removing an employee does not alter the business owner.

## Configure before use
- `config.lua`: actual business/pickup/dropoff locations, pricing, rental amounts, police integration, storage adapter, catalog, and scrap item weights.
- `Config.Illegal` is disabled by default; mission coordinates, vehicle allowlist, dispatch adapter, and server-side vehicle validation must be implemented/configured before enabling.
- `Config.Storage` is disabled pending a server-specific adapter.
- The database schema has no automatic seed locations or auction listings.
- Auction creation currently stores no pickup coordinate. Physical pickup, delivery, and salvage are not implemented in this version. Do not sell auction vehicles until that vehicle workflow is completed.
- Replace example item weights with the values intended for your inventory.

## Scope and limitations
This is not a claim that the resource has been runtime-tested. Vehicle spawning/ownership, government auction pickup and delivery, full salvage processing, storage integration, police dispatch, and transaction reconciliation require integration with the actual server resources and policies. Locations and illegal missions remain disabled until configured. Do not enable unverified features on a live server.

## Checks
No FiveM runtime, Lua parser, MySQL server, or Renewed-Banking instance is available in this repository-writing environment. Run syntax checks and test on a staging server before production.
