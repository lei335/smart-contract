// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Bls12381 {

    /**
     * @dev Calculate -p
     * Execution cost: 5152 gas
     * @param p The p is a G1 point (x, y) in Affine form; x and y are base field element(Fp, 48bytes), each of 
     * them is encoded as 64bytes by BigEndian encoding, and top 16bytes are always 0. 
     * The first two bytes32 represent the X coordinate and the last two bytes32 represent the Y coordinate.
     */
    function g1Neg(bytes32[4] memory p) public pure returns (bytes32[4] memory) {
        uint128 a = uint128(bytes16(p[3] << 128));
        uint128 b = uint128(bytes16(p[3]));
        uint128 c = uint128(bytes16(p[2] << 128));
        // bytes16[3] memory q = [bytes16(0x1eabfffeb153ffffb9feffffffffaaab), 0x64774b84f38512bf6730d2a0f6b0f624, 0x1a0111ea397fe69a4b1ba7b6434bacd7];

        // negate p, new Y: q - p2.Y, X no change
        assembly ("memory-safe") {
            // bls12-381 prime number q, field modulus,
            // q = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            let q1 := 40769914829639538012874174947278170795 // 0x1eabfffeb153ffffb9feffffffffaaab
            let q2 := 133542214618860690590306275168919549476 // 0x64774b84f38512bf6730d2a0f6b0f624
            let q3 := 34565483545414906068789196026815425751 // 0x1a0111ea397fe69a4b1ba7b6434bacd7

            let borrow := 0
            // q1 - a
            switch lt(q1, a)
            case 1 {
                borrow := 1
                // q1 borrow one bit forward
                // a := sub(0x011eabfffeb153ffffb9feffffffffaaab, a)
                a := sub(add(shl(128, 1), q1), a)
            }
            default {
                a := sub(q1, a)
            }

            // q2 - b - borrow
            q2 := sub(q2, borrow)
            switch lt(q2, b)
            case 1 {
                borrow := 1
                b := sub(add(shl(128, 1), q2), b)
            }
            default {
                borrow := 0
                b := sub(q2, b)
            }

            // q3 - c - borrow,  q3 must greater than c
            q3 := sub(q3, borrow)
            switch lt(q3, c)
            case 1 {
                revert(0,0)
            }
            default {
                c := sub(q3, c)
            }
        }
        p[2] = bytes32(bytes.concat(bytes16(0), bytes16(c)));
        p[3] = bytes32(bytes.concat(bytes16(b), bytes16(a)));
        return p;
    }

    /**
     * @dev Calculate p1+p2
     * @param p1 The p1 is a G1 point (x, y) in Affine form; x and y are base field element(Fp, 48bytes), each of 
     * them is encoded as 64bytes by BigEndian encoding, and top 16bytes are always 0. 
     * The first two bytes32 represent the X coordinate and the last two bytes32 represent the Y coordinate.
     * @param p2 Same to p1.
     */
    function g1Add(bytes32[4] memory p1, bytes32[4] memory p2) public view returns (bytes32[4] memory) {
        // g1Add(p1, p2)
        bytes32[8] memory input;
        input[0] = p1[0];
        input[1] = p1[1];
        input[2] = p1[2];
        input[3] = p1[3];
        input[4] = p2[0];
        input[5] = p2[1];
        input[6] = p2[2];
        input[7] = p2[3];
        assembly ("memory-safe") {
            // use preCompiled contract
            if iszero(staticcall(600, 0x0a, input, 256, p1, 128)) {
                let pt := mload(0x40)
                returndatacopy(pt, 0, returndatasize())
                revert(pt, returndatasize())
            }
        }
        return p1;
    }

    /**
     * @dev Calculate p1-p2
     * @param p1 The p1 is a G1 point (x, y) in Affine form; x and y are base field element(Fp, 48bytes), each of 
     * them is encoded as 64bytes by BigEndian encoding, and top 16bytes are always 0. 
     * The first two bytes32 represent the X coordinate and the last two bytes32 represent the Y coordinate.
     * @param p2 Same to p1.
     */
    function g1Sub(bytes32[4] memory p1, bytes32[4] memory p2) public view returns (bytes32[4] memory) {
        // negate p2
        p2 = g1Neg(p2);
        // g1Add(p1, p2)
        return g1Add(p1, p2);
    }

    /**
     * @dev Calculate p*scalar
     * @param p The p is a G1 point (x, y) in Affine form; x and y are base field element(Fp, 48bytes), each of 
     * them is encoded as 64bytes by BigEndian encoding, and top 16bytes are always 0. 
     * The first two bytes32 represent the X coordinate and the last two bytes32 represent the Y coordinate.
     * @param scalar The 32-byte scalar.
     */
    function g1Mul(bytes32[4] memory p, bytes32 scalar) public view returns (bytes32[4] memory) {
        bytes32[5] memory input;
        input[0] = p[0];
        input[1] = p[1];
        input[2] = p[2];
        input[3] = p[3];
        input[4] = scalar;

        assembly ("memory-safe") {
            // use preCompiled contract
            if iszero(staticcall(12000, 0x0b, input, 160, p, 128)) {
                let pt := mload(0x40)
                returndatacopy(pt, 0, returndatasize())
                revert(pt, returndatasize())
            }
        }
        return p;
    }

    /**
     * @dev Calculate -p
     * @param p The p is a G2 point (x,y) in Affine form; x and y are degree two finite field extension of Fp 
     * element(Fp2, 96bytes, 48bytes+48bytes), each of them is encoded as 128bytes(64bytes+64bytes) by BigEndian encoding,
     * and top 16bytes of every 64bytes are always 0.
     * The first four bytes32 represent the X coordinate and the last four bytes32 represent the Y coordinate.
     */
    function g2Neg(bytes32[8] memory p) public pure returns (bytes32[8] memory) {
        bytes32[4] memory a = [bytes32(p[2]),p[3],p[4],p[5]];
        a = g1Neg(a);
        p[4] = a[2];
        p[5] = a[3];
        a = [bytes32(p[4]), p[5], p[6], p[7]];
        a = g1Neg(a);
        p[6] = a[2];
        p[7] = a[3];
        return p;
    }

    /**
     * @dev Calculate p1+p2
     * @param p1 The p1 is a G2 point (x,y) in Affine form; x and y are degree two finite field extension of Fp 
     * element(Fp2, 96bytes, 48bytes+48bytes), each of them is encoded as 128bytes(64bytes+64bytes) by BigEndian encoding,
     * and top 16bytes of every 64bytes are always 0.
     * The first four bytes32 represent the X coordinate and the last four bytes32 represent the Y coordinate.
     * @param p2 Same to p1.
     */
    function g2Add(bytes32[8] memory p1, bytes32[8] memory p2) public view returns (bytes32[8] memory) {
        // g2Add(p1, p2)
        bytes32[16] memory input;
        for(uint8 i = 0; i<8; i++){
            input[i] = p1[i];
        }
        for(uint8 i=0; i<8;i++){
            input[8+i] = p2[i];
        }
        assembly ("memory-safe") {
            // use preCompiled contract
            if iszero(staticcall(4500, 0x0d, input, 512, p1, 256)) {
                let pt := mload(0x40)
                returndatacopy(pt, 0, returndatasize())
                revert(pt, returndatasize())
            }
        }
        return p1;
    }

    /**
     * @dev Calculate p1-p2
     * @param p1 The p1 is a G2 point (x,y) in Affine form; x and y are degree two finite field extension of Fp 
     * element(Fp2, 96bytes, 48bytes+48bytes), each of them is encoded as 128bytes(64bytes+64bytes) by BigEndian encoding,
     * and top 16bytes of every 64bytes are always 0.
     * The first four bytes32 represent the X coordinate and the last four bytes32 represent the Y coordinate.
     * @param p2 Same to p1.
     */
    function g2Sub(bytes32[8] memory p1, bytes32[8] memory p2) public view returns (bytes32[8] memory) {
        // negate p2
        p2 = g2Neg(p2);
        // g2Add(p1, p2)
        return g2Add(p1, p2);
    }

    /**
     * @dev Calculate p*scalar
     * @param p The p is a G2 point (x,y) in Affine form; x and y are degree two finite field extension of Fp 
     * element(Fp2, 96bytes, 48bytes+48bytes), each of them is encoded as 128bytes(64bytes+64bytes) by BigEndian encoding,
     * and top 16bytes of every 64bytes are always 0.
     * The first four bytes32 represent the X coordinate and the last four bytes32 represent the Y coordinate.
     * @param scalar The 32-byte scalar.
     */
    function g2Mul(bytes32[8] memory p, bytes32 scalar) public view returns (bytes32[8] memory) {
        bytes32[9] memory input;
        for(uint8 i=0; i<8; i++) {
            input[i] = p[i];
        }
        input[8] = scalar;

        assembly ("memory-safe") {
            // use preCompiled contract
            if iszero(staticcall(55000, 0x0e, input, 288, p, 256)) {
                let pt := mload(0x40)
                returndatacopy(pt, 0, returndatasize())
                revert(pt, returndatasize())
            }
        }
        return p;
    } 

    /**
     * @dev Calculate e(p1, p2).e(p3, p4) ==? 1
     * @param p1 The p1 is a G1 point (x, y) in Affine form; x and y are base field element(Fp, 48bytes), each of 
     * them is encoded as 64bytes by BigEndian encoding, and top 16bytes are always 0. 
     * The first two bytes32 represent the X coordinate and the last two bytes32 represent the Y coordinate.
     * @param p2 The p2 is a G2 point (x,y) in Affine form; x and y are degree two finite field extension of Fp 
     * element(Fp2, 96bytes, 48bytes+48bytes), each of them is encoded as 128bytes(64bytes+64bytes) by BigEndian encoding,
     * and top 16bytes of every 64bytes are always 0.
     * The first four bytes32 represent the X coordinate and the last four bytes32 represent the Y coordinate.
     * @param p3 Same to p1.
     * @param p4 Same to p2.
     */
    function pairing(bytes32[4] memory p1, bytes32[8] memory p2, bytes32[4] memory p3, bytes32[8] memory p4) public view returns (bytes32) {
        bytes32[24] memory input;
        for(uint8 i = 0; i<4; i++) {
            input[i] = p1[i];
        }
        for(uint8 i=0; i<8; i++) {
            input[i+4] = p2[i];
        }
        for(uint8 i=0;i<4;i++) {
            input[i+12] = p3[i];
        }
        for(uint8 i=0; i<8; i++) {
            input[i+16] = p4[i];
        }

        // This is wrong:
        // 【
        // 因为'bytes32 res'是value type，而array是reference type。正确写法应该是：
        // bytes memory res = new bytes(32);
        // if iszero(staticcall(161000, 0x10, input, 768, add(res, 32), 32))
        // return bytes32(res);
        // add(res, 32)是因为在memory中mem[res...res+32]存放的是res的位置，而接下来的slot即mem[res+32...res+64]存放的才是res真正的值
        // 】
        // bytes32 res;  
        // assembly ("memory-safe") {
        //     if iszero(staticcall(161000, 0x10, input, 768, res, 32)) {
        //         let pt := mload(0x40)
        //         returndatacopy(pt, 0, returndatasize())
        //         revert(pt, returndatasize())
        //     }
        // }
        // return res;

        // This is ok:
        assembly ("memory-safe") {
            // use preCompiled contract
            if iszero(staticcall(161000, 0x10, input, 768, p1, 32)) {
                let pt := mload(0x40)
                returndatacopy(pt, 0, returndatasize())
                revert(pt, returndatasize())
            }
        }
        return p1[0];
    }
}
