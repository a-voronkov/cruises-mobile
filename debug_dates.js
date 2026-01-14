const https = require('https');

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
            resolve(JSON.parse(data));
        } catch (e) {
            console.error('Error parsing JSON from ' + url);
            resolve({});
        }
      });
      res.on('error', reject);
    });
  });
}

async function run() {
  try {
    // 1. Get Royal Caribbean ID
    const clData = await fetch('https://cruises.voronkov.club/api/cruises/reference/cruise-lines?search=Royal');
    const rci = clData.cruiseLines.find(c => c.name.includes('Royal Caribbean'));
    
    if (!rci) {
        console.log('RCI not found');
        return;
    }
    console.log(`Checking RCI (ID: ${rci.id})...`);

    // 2. Search without date filter
    const url = `https://cruises.voronkov.club/api/cruises/search?cruiseLineId=${rci.id}&limit=5`;
    console.log(`Fetching: ${url}`);
    const data = await fetch(url);
    const fs = require('fs');
    fs.writeFileSync('debug_error.log', JSON.stringify(data, null, 2));
    console.log('Written response to debug_error.log');
    
    if (data.message) console.error('Error in response');
    console.log(`Total cruises found: ${data.total}`);
    if (data.cruises && data.cruises.length > 0) {
        console.log('Sample dates:');
        data.cruises.forEach(c => console.log(`- ${c.startDate}`));
    }
      
  } catch (e) {
    console.error('Detailed Error:', e);
  }
}

run();
