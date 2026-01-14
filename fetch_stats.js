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
            resolve({}); // graceful failure
        }
      });
      res.on('error', reject);
    });
  });
}

function getTodayString() {
    const d = new Date();
    return d.toISOString().split('T')[0];
}

async function run() {
  try {
    const today = getTodayString();
    console.log(`Fetching cruise lines...`);
    const clData = await fetch('https://cruises.voronkov.club/api/cruises/reference/cruise-lines');
    
    const cruiseLines = clData.cruiseLines || []; 
    console.log(`Found ${cruiseLines.length} cruise lines. Fetching future cruise counts from ${today}...`);

    const results = [];

    // Process in chunks to avoid overwhelming the server (though 50 is likely fine)
    // Sequential for simplicity
    for (const cl of cruiseLines) {
        process.stdout.write(`Checking ${cl.name}... `);
        const url = `https://cruises.voronkov.club/api/cruises/search?startDate=${today}&cruiseLineId=${cl.id}&limit=1`;
        const data = await fetch(url);
        const count = data.total || 0;
        console.log(count);
        results.push({ name: cl.name, count });
    }

    console.log('\n--- Future Cruises per Company ---');
    results.sort((a, b) => b.count - a.count);
    results.forEach(r => {
        if (r.count > 0) {
            console.log(`${r.name}: ${r.count}`);
        }
    });
      
  } catch (e) {
    console.error('Detailed Error:', e);
  }
}

run();
