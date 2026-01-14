// Native fetch in Node 18+

// Base URL
const BASE_URL = 'https://cruises.voronkov.club/api';

const fs = require('fs');

async function main() {
    const scrapers = ['cruisemapper', 'cruisetimetables', 'netcruise', 'cruisedomain', 'cruclub'];
    const results = {};

    try {
        // 1. Queue Stats
        console.log('Fetching queue stats...');
        const queueRes = await fetch(`${BASE_URL}/admin/unified-data/queue/stats`);
        if (queueRes.ok) results.queue = await queueRes.json();

        // 2. Scraper Mapping Stats
        results.scrapers = {};
        for (const scraper of scrapers) {
            console.log(`Fetching stats for ${scraper}...`);
            const res = await fetch(`${BASE_URL}/scrapers/${scraper}/mapping-stats`);
            if (res.ok) {
                results.scrapers[scraper] = await res.json();
                
                // If ships unmapped > 0, fetch sample
                if (results.scrapers[scraper].stats?.ships?.unmapped > 0) {
                     const unmappedRes = await fetch(`${BASE_URL}/scrapers/${scraper}/unmapped/ship?limit=5`);
                     if (unmappedRes.ok) {
                         results.scrapers[scraper].unmappedShipsSample = await unmappedRes.json();
                     }
                }
            } else {
                results.scrapers[scraper] = { error: res.statusText };
            }
        }

        // 3. Itinerary Stats
        console.log('Fetching itinerary stats...');
        const itinStatsRes = await fetch(`${BASE_URL}/admin/unified-data/ship-itineraries/stats`);
        if (itinStatsRes.ok) results.itineraries = await itinStatsRes.json();

        // 4. Conflicts
        console.log('Fetching conflicts...');
        const conflictsRes = await fetch(`${BASE_URL}/admin/unified-data/ship-itineraries/conflicts?limit=20&status=pending`);
        if (conflictsRes.ok) results.conflicts = await conflictsRes.json();

        // 5. Verification: Broad Sampling of Deployed Fix
        console.log('--- Verifying Fix on Multiple Cruises ---');
        // Fetch 5 random-ish cruises (using offset)
        const offset = Math.floor(Math.random() * 50);
        const searchRes = await fetch(`${BASE_URL}/cruises/search?limit=5&offset=${offset}`);
        
        if (searchRes.ok) {
            const searchData = await searchRes.json();
            const cruises = searchData.cruises || [];
            console.log(`Checking ${cruises.length} cruises for itinerary integrity...`);

            results.verificationSamples = [];

            for (const c of cruises) {
                console.log(`Checking Cruise ${c.id} (${c.ship?.name})...`);
                const detailsRes = await fetch(`${BASE_URL}/cruises/${c.id}`);
                if (detailsRes.ok) {
                    const details = await detailsRes.json();
                    const itineraries = details.itineraries || [];
                    
                    // Check for duplicates (same date, different port)
                    const dateMap = new Map();
                    let duplicatesFound = false;
                    for (const it of itineraries) {
                        const dateKey = it.date.split('T')[0]; // Simple date part
                        if (dateMap.has(dateKey)) {
                            duplicatesFound = true;
                            break;
                        }
                        dateMap.set(dateKey, it.portId);
                    }

                    const sampleResult = {
                        cruiseId: c.id,
                        shipName: c.ship?.name,
                        itineraryCount: itineraries.length,
                        hasItineraries: itineraries.length > 0,
                        hasDuplicates: duplicatesFound
                    };
                    results.verificationSamples.push(sampleResult);
                    console.log(`  -> Itineraries: ${itineraries.length}, Duplicates: ${duplicatesFound ? 'YES' : 'No'}`);
                } else {
                    console.error(`  -> Failed to fetch details: ${detailsRes.statusText}`);
                }
            }
        } else {
            console.error('Failed to search cruises:', searchRes.statusText);
        }

        // Write to file
        fs.writeFileSync('admin_stats.json', JSON.stringify(results, null, 2));
        console.log('Stats saved to admin_stats.json');

    } catch (error) {
        console.error('Fatal error:', error);
    }
}

main();
