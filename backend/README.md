## RoyalTrack API proxy
Keeps the Supercell token server-side. Configure `.env`, then `npm install` and `npm start`.

Supercell Developer Portal API key: create a Clash Royale key and set the allowed IP address to `45.79.218.79` if you are using `https://proxy.royaleapi.dev`. Official RoyaleAPI proxy docs describe this method. Do not put API tokens in Flutter code or commit `.env`.

Endpoints proxied (allow-listed): player, player battlelog, clan, clan members, cards, locations, and player/clan rankings.
