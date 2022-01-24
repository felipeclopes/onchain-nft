const { expect } = require("chai");
const { ethers } = require("hardhat");

// describe("CompanyProvider", function () {
// 	it("Should compile CompanyProvider", async function () {
// 		const CompanyProvider = await ethers.getContractFactory(
// 			"CompaniesProvider"
// 		);
// 		const provider = await CompanyProvider.deploy();
// 		await provider.deployed();
// 	});
// });

describe("CompanyDescriptor", function () {
	it("Should compile CompanyDescriptor", async function () {
		const CompanyDescriptor = await ethers.getContractFactory(
			"CompanyDescriptor"
		);
		const provider = await CompanyDescriptor.deploy([]);
		await provider.deployed();
	});
});

describe("Companies", function () {
	let descriptor;
	let singleCompanyList = [
		{
			name: "Mighty Health",
			tags: ["Wellness", "Fitness", "Aging"],
			batch: "S22",
		},
	];

	before(async () => {
		const CompanyDescriptor = await ethers.getContractFactory(
			"CompanyDescriptor"
		);
		descriptor = await CompanyDescriptor.deploy();
		await descriptor.deployed();
	});

	it("Should compile Companies", async function () {
		const Companies = await ethers.getContractFactory("Companies");
		const companies = await Companies.deploy(
			descriptor.address,
			[],
			"0x0000000000000000000000000000000000000000"
		);
		await companies.deployed();
	});

	it("Should be able to getCompanySupply", async function () {
		const Companies = await ethers.getContractFactory("Companies");
		const companies = await Companies.deploy(
			descriptor.address,
			singleCompanyList,
			"0x0000000000000000000000000000000000000000"
		);
		await companies.deployed();

		const supply = await companies.getCompanySupply();
		expect(supply).to.be.eq(1);
	});

	it("Should be able to mint", async function () {
		const Companies = await ethers.getContractFactory("Companies");
		const companies = await Companies.deploy(
			descriptor.address,
			singleCompanyList,
			"0x0000000000000000000000000000000000000000"
		);
		await companies.deployed();

		await companies.mint(1, { value: ethers.utils.parseEther("1") });
	});

	it("Should be able to mint multiple", async function () {
		const Companies = await ethers.getContractFactory("Companies");
		const companies = await Companies.deploy(
			descriptor.address,
			require("../data/complete.json"),
			"0x0000000000000000000000000000000000000000"
		);
		await companies.deployed();

		await companies.mint(5, { value: ethers.utils.parseEther("1") });

		expect(companies.tokenByIndex(4)).should.not.be.null;
		expect(companies.tokenByIndex(5)).should.be.null;
	});

	it("Shouldn't be able to mint more than supply", async function () {
		const Companies = await ethers.getContractFactory("Companies");
		const companies = await Companies.deploy(
			descriptor.address,
			singleCompanyList,
			"0x0000000000000000000000000000000000000000"
		);
		await companies.deployed();

		await companies.mint(1, { value: ethers.utils.parseEther("1") });

		await expect(
			companies.mint(1, { value: ethers.utils.parseEther("1") })
		).to.be.revertedWith("reverted with reason string 'No supply available'");
	});

	it("Should be able to withdrawl", async function () {
		const [owner, somebodyElse] = await hre.ethers.getSigners();

		const Companies = await ethers.getContractFactory("Companies");
		const companies = await Companies.deploy(
			descriptor.address,
			singleCompanyList,
			"0x0000000000000000000000000000000000000000"
		);
		await companies.deployed();

		const ownerBalance = await hre.ethers.provider.getBalance(owner.address);

		companies
			.connect(somebodyElse)
			.mint(1, { value: ethers.utils.parseEther("1.0") });

		const withdrawl = await companies.connect(owner).withdraw();
		const withdrawlReceipt = await withdrawl.wait();

		expect(await hre.ethers.provider.getBalance(owner.address)).to.be.eq(
			ownerBalance
				.add(ethers.utils.parseEther("1.0"))
				.sub(withdrawlReceipt.effectiveGasPrice.mul(withdrawlReceipt.gasUsed))
		);
	});
});
