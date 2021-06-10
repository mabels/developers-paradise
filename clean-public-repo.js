const ecrpub = require("@aws-sdk/client-ecr-public");


async function allImages(client, allList, nextToken) {
	const command = new ecrpub.DescribeImagesCommand({ repositoryName: 'developers-paradise', nextToken });
	const response = await client.send(command);
	allList = allList || [];
	allList.push(...response.imageDetails);
	if (response.nextToken) {
		return await allImages(client, allList, response.nextToken);
	}
	return allList	
}

async function deleteImages(client, older) {
	if (!older.length) {
		return;
	}
	const chunk = older.splice(0, 80);
	console.log(`deleteImages: ${chunk.length} from ${older.length}`, chunk.map(i => i.imageDigest));
	const command = new ecrpub.BatchDeleteImageCommand({
		repositoryName: 'developers-paradise', 
		imageIds: chunk.map(i => ({imageDigest: i.imageDigest}))  
	});
        const response = await client.send(command);
	console.log(JSON.stringify(response, null, 2));
	await deleteImages(client, older);
}

const CLEAN_OLDER_DAYS = 14;
//const AT_LEAST_VERSION = 40; 
(async function() {
	const client = new ecrpub.ECRPUBLICClient({ region: "us-east-1" });

	const all = await allImages(client)

	// console.log(all.length);
	const start = (new Date()).getTime() - (CLEAN_OLDER_DAYS * 24 * 60 * 60 * 1000);
	const older = all.filter(i => {
		return (new Date(i.imagePushedAt)).getTime() < start;
	});
	// console.log(older.length, older.map(i => i.imageDigest));
	await deleteImages(client, older);
})();

