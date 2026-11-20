# RoyalTrack — Clash Royale Companion (Android / Flutter)

A RoyaleAPI-inspired mobile companion focused on the major features: player lookup/profile, battle log, clan lookup/members, card catalog, local deck builder, favorites, and rankings.

## Data and API
- Uses the **official Clash Royale API** through a small Node.js backend proxy.
- The backend stores the Supercell API token in `.env`; the token is never embedded in the Flutter app.
- Proxy default is `https://proxy.royaleapi.dev` (official proxy instructions require an API key created at the Supercell Developer Portal and IP allowlisting `45.79.218.79`). You may alternatively set `CR_API_BASE=https://api.clashroyale.com`.
- Some RoyaleAPI analytics (global deck win/usage rates, historical datasets, matchup statistics) are not exposed by the official API and are intentionally not fabricated.

## Included features
- Home dashboard with shortcuts and saved favorites
- Player tag lookup; player stats, current deck cards, clan and recent battle log
- Clan tag lookup; clan info and member list
- Cards catalog from API, searchable and filterable by name/rarity
- Deck builder (8 cards), average elixir, local save/load, shareable text copied manually
- Local favorites for player/clan tags
- Rankings (best-effort endpoint; availability varies by API region/endpoint)
- Settings: backend URL, API connection status test, clear local saved decks/favorites
- Dark/light mode toggle
- Error/loading/empty states and API retry

## Setup (Windows / VS Code)
### 1) Backend
1. Install Node.js LTS.
2. `cd backend`
3. Copy `.env.example` to `.env` and fill `CR_API_TOKEN`.
4. Create a key at the official Clash Royale developer portal. Set the API key's allowed IP to `45.79.218.79` if using RoyaleAPI's official proxy.
5. Run `npm install` then `npm start`.
6. Backend default is `http://localhost:3000`. For Android emulator, Flutter uses `http://10.0.2.2:3000`. On a physical phone, use your PC's LAN IP address and ensure the firewall allows port 3000.

### 2) Flutter
The archive includes Flutter app source and configuration. It does not bundle generated Android Gradle/wrapper files, so generate the Android platform scaffolding once from this folder:
```powershell
flutter create --platforms=android --org com.royaltrack .
flutter pub get
flutter run
```
If Flutter asks to overwrite the existing source, do not overwrite `lib/` or `pubspec.yaml`; the source in this archive is the app code. In VS Code, open the `RoyalTrack` folder after platform generation.
For emulator, Settings > Backend URL defaults to `http://10.0.2.2:3000`.
For phone, change the URL to `http://YOUR_PC_LAN_IP:3000`.

## Important
- Do not commit `.env`; it is ignored.
- This is an independent fan app and is not affiliated with Supercell or RoyaleAPI.
- API availability/rate limits and data fields can change. API-backed views show errors instead of fabricated data.
