// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

contract FacetA{
    struct FacetData{
        bytes32 data;
    }

    function facetData() internal pure returns (FacetData storage facet) {
        bytes32 storagePosition = keccak256("Diamond:Storage:FacetA");
        assembly {
            facet.slot := storagePosition
        }
    }

    function setDataA(bytes32 _data) external {
        FacetData storage facet = facetData();
        facet.data = _data;
    }

    function getDataA() external view returns (bytes32) {
        FacetData storage facet = facetData();
        return facet.data;
    }
}