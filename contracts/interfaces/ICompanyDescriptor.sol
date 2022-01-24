// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {ICompany} from "./ICompany.sol";

interface ICompanyDescriptor {
    function constructContractURI() external pure returns (string memory);

    function constructTokenURI(ICompany.Company memory place)
        external
        pure
        returns (string memory);
}
