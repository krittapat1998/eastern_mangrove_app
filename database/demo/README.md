# Local demo environment (fictional data)

Everything here is for **local development / App Store screenshots only**. All names,
phone numbers and e-mails are made up (`example.com`).

```bash
# 1) create the demo DB once (copy of your local DB, then emptied by the seed)
psql -h localhost -U <db user> -d postgres -c "CREATE DATABASE eastern_mangrove_demo TEMPLATE eastern_mangrove_communities"

# 2) seed it (from api-server/)  – refuses to run unless DB_HOST=localhost and DB_NAME contains "demo"
cd api-server
NODE_PATH="$PWD/node_modules" DB_NAME=eastern_mangrove_demo node ../database/demo/seed_demo.js

# 3) run the API against it
DB_NAME=eastern_mangrove_demo PORT=3002 node server.js

# 4) API smoke / CRUD test (re-seed afterwards: it approves/rejects the 2 pending communities)
node ../database/demo/api_smoke_test.js

# 5) run the iOS app on the simulator against it
#    (the app reads --dart-define=API_BASE_URL, default = production)
../docs/imageApp/tools/run_sim_local.sh
```

Demo logins: see the constants at the top of `seed_demo.js` (`demo_admin`, `demo_community`).

Store screenshots: `python3 docs/imageApp/tools/make_store_screenshots.py`
(raw simulator shots in `docs/imageApp/raw_ios_6_9/` -> `docs/imageApp/ios_6_9_new/`).

Notes
- DB stores areas in hectares; the app shows/asks for ไร่ (1 ha = 6.25 ไร่) and converts in `ApiClient` (`AreaUnit`).
- DB years are Gregorian; the app shows/asks for พ.ศ. (`lib/utils/thai_date.dart`).
