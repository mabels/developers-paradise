const path = require('path');
const semver = require('semver')
const Git = require("nodegit");


const REPOURL=process.argv.slice(2); // "https://go.googlesource.com/go";

function getTags(repoUrl, cbTags) {
  Git.Remote.createDetached(repoUrl).then(remote => {
    remote.connect(Git.Enums.DIRECTION.FETCH).then(number => {
      remote.referenceList().then(array => {  
	cbTags(array.map(i => i.name())
		    .filter(i => i.startsWith("refs/tags/"))
	            .map(i => path.basename(i)));
      });
    });
  })
}

process.argv.slice(2).forEach(repoUrl => getTags(repoUrl, (tags) => {
        const tag_prefix=path.basename(repoUrl);
	const maxver = tags
		.filter(i => i.startsWith(tag_prefix))
		.map(i => i.slice(tag_prefix.length))
		.map(i => {
			try {
				return new semver.SemVer(i);
			} catch (e) {
				return;
			}
		})
		.filter(i => i && i.prerelease.length === 0)
	        .reduce((r, i) => i.compare(r) > 0 ? i : r, new semver.SemVer("0.0.0"));
	console.log(`${tag_prefix.toUpperCase().replace(/[^A-Z0-9]/g, '_')}_VERSION=${maxver.raw}`);
}));

