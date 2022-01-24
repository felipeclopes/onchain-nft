// SPDX-License-Identifier: MIT

/// @title Interface for Companies
/// @author YCCC

pragma solidity ^0.8.6;

interface ICompany {
    /**
     * @notice Place – Represents place information for a geographic location.
     *
     * See IPlaceDrop.sol, IPlaceDrop.Place
     *
     * name – string representing the place name
     * streetAddress – string indicating a precise address
     * sublocality – string representing the subdivision and first-order civil
     * entity below locality (neighborhood or common name)
     * locality – string representing the incorporated city or town political
     */
    struct Company {
        string name;
        string[] tags;
        string batch;
    }
}
