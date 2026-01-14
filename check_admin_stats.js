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

        // 5. Check Cruise Details (Verification of Fix)
        console.log('Checking Cruise Details for ID 17 (known conflict ship)...');
        // Need to find a cruise ID for ship 17 first
        const verificationSearch = await fetch(`${BASE_URL}/cruises/search?shipId=17&limit=1`);
        if (verificationSearch.ok) {
            const searchData = await verificationSearch.json();
            if (searchData.cruises && searchData.cruises.length > 0) {
                const testCruiseId = searchData.cruises[0].id;
                console.log(`Fetching details for Cruise ID: ${testCruiseId}...`);
                
                const detailsRes = await fetch(`${BASE_URL}/cruises/${testCruiseId}`);
                if (detailsRes.ok) {
                    const cruiseDetails = await detailsRes.json();
                    results.verificationDetails = {
                        cruiseId: cruiseDetails.id,
                        shipName: cruiseDetails.ship?.name,
                        itineraryCount: cruiseDetails.itineraries?.length || 0,
                        itinerariesSample: cruiseDetails.itineraries?.slice(0, 5)
                    };
                    console.log(`Cruise ${testCruiseId} Itineraries: ${results.verificationDetails.itineraryCount}`);
                } else {
                    results.verificationDetails = { error: detailsRes.statusText };
                }
            } else {
                console.log('No cruises found for Ship 17 to verify.');
            }
        }
        
        // Write to file
        fs.writeFileSync('admin_stats.json', JSON.stringify(results, null, 2));
        console.log('Stats saved to admin_stats.json');

    } catch (error) {
        console.error('Fatal error:', error);
    }
}

main();
