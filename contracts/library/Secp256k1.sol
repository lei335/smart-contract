// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Secp256k1
 * @author zl
 * @notice get address from compressed pubKey(33Byte, using secp256k1 curve)
 */
library Secp256k1 {
    /**
     * @dev Parse address from compressed pubkey. Execution cost: 9326 gas
     * @param _methodType pubkey's calculate method
     * @param pubKeyData compressed pubkey
     */
    // for example:
    // compressedPubKey hex: 0x0236a1316b6bad1abbca48f1264befb4024e26b5ace328af549400665155fde90a
	// compressedPubKey = []byte{2, 54, 161, 49, 107, 107, 173, 26, 187, 202, 72, 241, 38, 75, 239, 180, 2, 78, 38, 181, 172, 227, 40, 175, 84, 148, 0, 102, 81, 85, 253, 233, 10}
	// address          = "0xCEFD365B4D9333145394bbCf3492CD6816A4e885"
    function parsePubKey(string calldata _methodType, bytes calldata pubKeyData) external view returns (address) {
        address addr;
        bytes32 methodType = keccak256(abi.encodePacked("EcdsaSecp256k1VerificationKey2019"));
        if(keccak256(abi.encodePacked(_methodType))==methodType){
            addr = Secp256k1.getAddrFromCompressedPubKey(pubKeyData);
        }
        return addr;
    }

    function getAddrFromCompressedPubKey(bytes calldata compressedPubKey) internal view returns (address) {
        require(compressedPubKey.length == 33, "invalid compressed pubkey");

        uint8 prefix = uint8(compressedPubKey[0]);
        require(prefix == 0x02 || prefix == 0x03, "invalid compressed pubkey prefix");

        uint256 x = uint256(bytes32(compressedPubKey[1:33]));
        uint256 y = calculateY(x, prefix);

        bytes32 hash = keccak256(abi.encodePacked(bytes32(x), bytes32(y)));

        return address(uint160(uint256(hash)));
    }

    function calculateY(uint256 x, uint8 prefix) internal view returns (uint256) {
        uint256 p;
        // secp256k1曲线方程：y^2 = (x^3 + 7) % p;
        //uint256 ySquared = (x**3 + 7) % p; // 会溢出报错
        uint256 ySquared;
        assembly {
            // p = 2**256 - 2**32 -977
            p := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
            // Calculate y^2 = x^3 + 7 (mod p)
            ySquared := addmod(mulmod(x, mulmod(x, x, p), p), 7, p)
        }

        uint256 y = expmod(ySquared, (p+1)/4, p); // 二次剩余求平方根

        if(y%2 != prefix%2){
            y = p - y;
        }
        return y;
    }

    // 直接调用evm上预编译合约，这部分计算不会消耗gas
    function expmod(uint256 base, uint256 exponent, uint256 modulus) internal view returns (uint256) {
        uint256 res;
        assembly {
            let p := mload(0x40) // define pointer of free memory
            mstore(p, 0x20) // length of base, 32Byte
            mstore(add(p, 0x20), 0x20) // length of exponent
            mstore(add(p, 0x40), 0x20) // length of modulus
            mstore(add(p, 0x60), base) // base
            mstore(add(p,0x80), exponent) // exponent
            mstore(add(p, 0xa0), modulus) // modulus
            // 调用evm上预编译合约expmod(gasLimit, contractAddress, input, inputLength, output, outputLength)
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                revert(0,0)
            }
            res := mload(p)
        }
        return res;
    }
}