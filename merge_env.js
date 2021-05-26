const fs = require('fs').promises;


const reLine = /^\s*(\S+)\s*=\s*(.*)\s*$/;
async function parseFile(fname) {
	const content =	await fs.readFile(fname)
	return content.toString().split(/[\r\n]+/).map(i => {
		const kv = i.match(reLine);
		if (kv) {
			return {
				key: kv[1],
				val: kv[2]
			};
		}
		return {};
	}).filter(i => i.key)
}

Promise.all(process.argv.slice(2).map(parseFile)).then(toMerge => {
	console.log(Object.entries(toMerge.reduce((r, va) => {
		return va.reduce((r, v) => {
			r[v.key] = v.val;
			return r;
		}, r);
	}, {})).map(i => `${i[0]}=${i[1]}`).join("\n"));
}).catch(console.error);
