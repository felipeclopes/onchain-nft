const main = async () => {
	const CompanyDescriptor = await ethers.getContractFactory(
		"CompanyDescriptor"
	);
	const descriptor = await CompanyDescriptor.deploy();
	const result = await descriptor.deployed();

	const Companies = await ethers.getContractFactory("Companies");
	const companies = await Companies.deploy(descriptor.address, [], null);
	await companies.deployed();
};

const runMain = async () => {
	try {
		await main();
		process.exit(0);
	} catch (error) {
		console.log(error);
		process.exit(1);
	}
};

runMain();
