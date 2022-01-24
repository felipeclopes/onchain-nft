// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {Base64} from "./libraries/Base64.sol";

import {ICompany} from "./interfaces/ICompany.sol";
import {ICompanyDescriptor} from "./interfaces/ICompanyDescriptor.sol";

contract CompanyDescriptor is ICompanyDescriptor, Ownable {
    /**
     * @notice Create contract metadata for Opensea.
     */
    function constructContractURI()
        external
        pure
        override
        returns (string memory)
    {
        return "";
    }

    /**
     * @notice Create the ERC721 token URI for a token.
     */
    function constructTokenURI(ICompany.Company memory company)
        external
        pure
        override
        returns (string memory)
    {
        string
            memory baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: Avenir,Helvetica,Arial,sans-serif; font-size: 24px; } .small { font-size: 14px } .tags { font-size: 10px } .name { font-weight: bold }</style><rect width='100%' height='100%' fill='#df6d38' /><text x='50%' y='50%' class='base name' dominant-baseline='middle' text-anchor='middle'>";

        string memory tags = "<text class='base tags' x='10' y='340'>";
        for (uint16 i = 0; i < company.tags.length; i++) {
            tags = string(
                abi.encodePacked(tags, i != 0 ? ", " : "", company.tags[i])
            );
        }

        string memory finalSvg = string(
            abi.encodePacked(
                baseSvg,
                company.name,
                "</text><text x='50%' y='58%' class='base small' dominant-baseline='middle' text-anchor='middle'>",
                company.batch,
                "</text>",
                tags,
                "</text></svg>"
            )
        );

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        // We set the title of our NFT as the generated word.
                        company.name,
                        '", "description": "A YC company list and its metadata stored on chain.", "image": "data:image/svg+xml;base64,',
                        // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return finalTokenUri;
    }

    /**
     * @notice [MIT License] via Loot, inspired by OraclizeAPI's implementation - MIT license
     * @dev https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
