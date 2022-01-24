// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {ICompany} from "./interfaces/ICompany.sol";
import {ICompanyDescriptor} from "./interfaces/ICompanyDescriptor.sol";

import {IProxyRegistry} from "./libraries/IProxyRegistry.sol";

import "hardhat/console.sol";

contract Companies is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using Counters for Counters.Counter;

    event DescriptorUpdated(ICompanyDescriptor descriptor);
    event CompanyCreated(uint256 tokenId);
    event MintFeeUpdated(uint256 mintFee);
    event WhitelistEnabledUpdated(bool isEnabled);

    IProxyRegistry public immutable proxyRegistry;

    Counters.Counter private _tokenIdCounter;

    // ICompanyProvider private _companyProvider;
    ICompany.Company[] private _companies;
    ICompanyDescriptor private _companyDescriptor;

    uint256 public _maxTokenPerAddress = 10;
    struct Minter {
        address addr;
        uint256 hasMinted;
    }
    mapping(address => Minter) private _minters;

    uint256 private _mintFee = 0.05 ether;

    constructor(
        ICompanyDescriptor companyDescriptor,
        ICompany.Company[] memory companies,
        address _proxyAddress
    ) ERC721("YC Companies Club", "YCCC") {
        _companyDescriptor = companyDescriptor;

        for (uint256 i = 0; i < companies.length; i++) {
            _companies.push(companies[i]);
        }

        proxyRegistry = IProxyRegistry(_proxyAddress);
    }

    /**
     * @notice Set the descriptor.
     * @dev Only callable by the owner.
     */
    function setDescriptor(ICompanyDescriptor companyDescriptor)
        external
        onlyOwner
    {
        _companyDescriptor = companyDescriptor;
        emit DescriptorUpdated(companyDescriptor);
    }

    /**
     * @notice Pause minting.
     * @dev Only callable by the owner.
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Update the minting fee.
     * @dev Only callable by the owner.
     */
    function setMintFee(uint256 mintFee) external onlyOwner {
        _mintFee = mintFee;
        emit MintFeeUpdated(mintFee);
    }

    /**
     * @notice Withdrawl contract balance.
     * @dev Only callable by the owner.
     */
    function withdraw() public payable nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice Add more companies
     * @dev Only callable by the owner.
     */
    function addCompanies(ICompany.Company[] memory companies)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < companies.length; i++) {
            _companies.push(companies[i]);
        }
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Requests companies supply count (both minted & available on-chain).
     * @dev Subtract totalSupply() to determine available to be minted.
     */
    function getCompanySupply() public view returns (uint256 supplyCount) {
        // return _companyProvider.getCompanySupply();
        return _companies.length;
    }

    /**
     * @notice Mint a company.
     */
    function mint(uint256 amount) public payable whenNotPaused nonReentrant {
        require(amount > 0, "Need to mint at least one");
        require(
            msg.value >= SafeMath.mul(_mintFee, amount),
            "Minimum fee required"
        );
        require(!_exists(_tokenIdCounter.current()), "Token already exists");
        require(
            SafeMath.add(_tokenIdCounter.current(), amount) <=
                getCompanySupply(),
            "No supply available"
        );
        require(
            SafeMath.add(_minters[msg.sender].hasMinted, amount) <=
                _maxTokenPerAddress,
            "Above maxToken."
        );

        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _mint(msg.sender, newItemId);

            // console.log(tokenURI(newItemId));

            _setTokenURI(newItemId, tokenURI(newItemId));
            _tokenIdCounter.increment();

            _minters[msg.sender].hasMinted = SafeMath.add(
                _minters[msg.sender].hasMinted,
                1
            );

            emit CompanyCreated(_tokenIdCounter.current() - 1);
        }
    }

    /**
     * @notice Internal hook.
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Burn a company.
     * @dev Only callable by the owners.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyOwner
    {
        super._burn(tokenId);
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "Token must exist");

        return
            _companyDescriptor.constructTokenURI(
                // _companyProvider.getCompany(tokenId)
                _companies[tokenId]
            );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Construct an Opensea contract URI.
     */
    function contractURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token must exist");

        return _companyDescriptor.constructContractURI();
    }
}
