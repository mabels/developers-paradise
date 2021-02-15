const https = require('https');
const semver = require('semver')

const APIUSER = process.env.APIUSER && process.env.APIUSER.length ? process.env.APIUSER : undefined;

async function completeList(repo, page, list, cb) {
  const url = `/repos/${repo}/tags?per_page=100&page=${page}`;
  // console.log('url:', url);
  https.get({
  hostname: `api.github.com`,
  port: 443,
  headers: {
	  ...(
	    typeof(APIUSER) === "string" ? {
	    	"authorization": `Basic ${Buffer.from(APIUSER).toString('base64')}`,
	    } : {}
	  ),
	  "user-agent": 'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_2_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36',
	  "accept": "application/vnd.github.v3+json"
  },
  path: url,
  method: 'GET'
}, (res) => {
	if (!(200 <= ~~res.statusCode && ~~res.statusCode < 300)) {
        	console.error('statusCode:', url, res.statusCode);
		process.exit(1);
	}
	let out = "";
  	res.on('data', (d) => {
		out += d;
	});
	res.on('end', function (chunk) {
	    const json = JSON.parse(out);
	    // console.log('res=', json.length, list.map(i => i.tag_name));
	    if (json.length) {
		    list.push(...json);
		    completeList(repo, page+1, list, cb)
	    } else {
		    cb(list);
  	            // console.log(list.map(i => i.name));
	    }
        });
  }).on('error', (e) => {
 	 console.error(e);
  });
}

process.argv.slice(2).forEach(repo => {
	completeList(repo, 0, [], versions => {
		const maxver = versions.map(i => {
			try {
				return new semver.SemVer(i.name);
			} catch (e) {
				return;
			}
		}).filter(i => i && i.prerelease.length === 0)
	          .reduce((r, i) => i.compare(r) > 0 ? i : r, new semver.SemVer("0.0.0"));
		console.log(`${repo.toUpperCase().replace(/[^A-Z0-9]/g, '_')}_VERSION=${maxver.raw}`);
	});
})
