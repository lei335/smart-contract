// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library ParsePubKey {
    /**
     * @dev Parse address from compressed pubkey. Execution cost: 40734 gas
     * @param _methodType pubkey's calculate method
     * @param pubKeyData compressed pubkey
     */
    function parsePubKey(string calldata _methodType, bytes calldata pubKeyData) external pure returns (address) {
        address addr;
        bytes32 methodType = keccak256(abi.encodePacked("EcdsaSecp256k1VerificationKey2019"));
        if(keccak256(abi.encodePacked(_methodType))==methodType){
            addr = getAddrFromCompressedPubKey(pubKeyData);
        }
        return addr;
    }

    function getAddrFromCompressedPubKey(bytes calldata compressedPubKey) internal pure returns (address) {
        require(compressedPubKey.length == 33, "invalid compressed pubkey");

        uint8 prefix = uint8(compressedPubKey[0]);
        require(prefix == 0x02 || prefix == 0x03, "invalid compressed pubkey prefix");

        uint256 x = uint256(bytes32(compressedPubKey[1:33]));
        uint256 y = calculateY(x, prefix);

        bytes32 hash = keccak256(abi.encodePacked(bytes32(x), bytes32(y)));

        return address(uint160(uint256(hash)));
    }

    function calculateY(uint256 x, uint8 prefix) internal pure returns (uint256) {
        uint256 p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
        // addmod(mulmod(x, mulmod(x, x, p), p), 7, p)
        uint256 y2 = addmod(mulmod(x, mulmod(x,x,p),p), 7,p);
        y2 = expmod(y2, (p+1)/4,p);
        uint256 y = (y2+prefix)%2==0?y2:p-y2;
        return y;
    }

    // 使用内联汇编直接计算，会消耗大量gas
    function expmod(uint256 base, uint256 exponent, uint256 modulus) internal pure returns (uint256) {
        uint256 r=1;
        uint256 bit = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        assembly {
            for {} gt(bit,0) {}{
                r := mulmod(mulmod(r,r,modulus), exp(base,iszero(iszero(and(exponent,bit)))), modulus)
                r := mulmod(mulmod(r,r,modulus), exp(base, iszero(iszero(and(exponent,div(bit,2))))),modulus)
                r := mulmod(mulmod(r,r,modulus), exp(base, iszero(iszero(and(exponent, div(bit, 4))))), modulus)
                r := mulmod(mulmod(r,r,modulus), exp(base, iszero(iszero(and(exponent, div(bit, 8))))), modulus)
                bit := div(bit,16)
            }
        }
        return r;
    }
}