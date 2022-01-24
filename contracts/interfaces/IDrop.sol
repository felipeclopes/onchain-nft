// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {ICompany} from "./ICompany.sol";

interface IDrop {
    function getTreasury() external view returns (address payable);

    function getCompanyCount() external view returns (uint256);

    function getEndingIndex() external view returns (uint256);

    function getCompany(uint256 tokenId)
        external
        view
        returns (ICompany.Company memory);
}
