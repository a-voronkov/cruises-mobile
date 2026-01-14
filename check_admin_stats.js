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

        // 5. Verification: Trigger Consolidation and Check Details
        console.log('Fetching a known merged cruise from log...');
        const logRes = await fetch(`${BASE_URL}/admin/unified-data/merge-log?entityType=cruise&limit=1`);
        if (logRes.ok) {
            const logData = await logRes.json();
            if (logData.logs && logData.logs.length > 0) {
                const log = logData.logs[0];
                const { masterId, sourceName, sourceEntityId } = log;
                console.log(`Found merged cruise: MasterID=${masterId}, Source=${sourceName}, SourceID=${sourceEntityId}`);

                // Trigger consolidation
                console.log('Triggering manual consolidation...');
                const processRes = await fetch(`${BASE_URL}/admin/unified-data/cruises/process`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ scraper: sourceName, cruiseId: sourceEntityId })
                });

                if (processRes.ok) {
                    const processResult = await processRes.json();
                    console.log('Consolidation result:', JSON.stringify(processResult));

                    // Check details
                    console.log(`Fetching details for Cruise ID: ${masterId}...`);
                    const detailsRes = await fetch(`${BASE_URL}/cruises/${masterId}`);
                    if (detailsRes.ok) {
                        const cruiseDetails = await detailsRes.json();
                        results.verificationDetails = {
                            cruiseId: cruiseDetails.id,
                            shipName: cruiseDetails.ship?.name,
                            itineraryCount: cruiseDetails.itineraries?.length || 0,
                            itinerariesSample: cruiseDetails.itineraries?.slice(0, 5)
                        };
                        console.log(`Cruise ${masterId} Itineraries: ${results.verificationDetails.itineraryCount}`);
                    } else {
                         console.error('Failed to fetch cruise details:', detailsRes.statusText);
                    }
                } else {
                    console.error('Failed to trigger consolidation:', processRes.statusText);
                }
            } else {
                console.log('No merge logs found.');
            }
        } else {
            console.error('Failed to fetch merge log:', logRes.statusText);
        }
        
        // Write to file
        fs.writeFileSync('admin_stats.json', JSON.stringify(results, null, 2));
        console.log('Stats saved to admin_stats.json');

    } catch (error) {
        console.error('Fatal error:', error);
    }
}

main();
