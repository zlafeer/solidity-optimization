// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Gas Optimization Example with Array Summation
/// @author Zach Lafeer
/// @notice Provides five functions for computing the sum of an array
/// @dev Functions are ordered from least to most optimized
contract SumArray {

    // Dynamic array of uint256 items
    uint[] private storageArray;
    
    /// @notice Constructs dynamic array of unsigned integers
    /// @dev All integers are in range [0,10) to reduce risk of sum overflow with large n.
    /// @param n length of array
    constructor(uint n) {
        for (uint i = 0; i < n; i++) {
            storageArray.push(i%10);
        }
    }

    /// @notice Naive Implementation
    /// @return Sum of array
    function sumA() public view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < storageArray.length; i++) {
            sum += storageArray[i];
        }
        return sum;
    }

    /// @notice Memory Caching Implementation
    /// @dev Copies array from storage to memory before iteration.
    ///      This operation is better optimized by the Solidity compiler.
    /// @return Sum of array
    function sumB() public view returns (uint) {
        // Declares memory variable with a copy of the storage array.
        uint[] memory memoryArray = storageArray;
        uint sum = 0;
        for (uint i = 0; i < memoryArray.length; i++) {
            sum += memoryArray[i];
        }
        return sum;
    }

    /// @notice Unchecked Arithmetic Implementation
    /// @dev Adds unchecked arithmetic to bypass overflow checks on the iteration counter i.  
    /// @return Sum of array
    function sumC() public view returns (uint) {
        uint[] memory memoryArray = storageArray;
        uint sum = 0;
        uint i = 0;
        while (i < memoryArray.length) {
            sum += memoryArray[i];
            // Arithmetic in this block is not checked for under/overflow.
            // i is guaranteed to not overflow 256 bits since n was checked at construction.
            unchecked {
                i++;
            }
        }
        return sum;
    }

    /// @notice Inline Assembly Implementation
    /// @dev Adds inline assembly to bypass array bounds checks during iteration.
    /// @return Sum of array
    function sumD() public view returns (uint) {
        uint[] memory memoryArray = storageArray;
        uint sum = 0;
        uint i = 0;
        while (i < memoryArray.length) {
            assembly {
                // memoryArray points to 32 (0x20) bytes containing the array length.
                // The first item is located at memoryArray + 0x20.
                // Every item is 32 (0x20) bytes wide.
                // Item i is stored at memoryArray + 0x20 + (i * 0x20).
                sum := add(sum, mload(add(add(memoryArray, 0x20), mul(i, 0x20))))
                // Increments i
                i := add(i, 0x01)
            }
        }
        return sum;
    }

    /// @notice Full Assembly Implementation
    /// @dev The function is rewritten entirely within an assembly block for even less gas usage.
    ///      Due to the use of assembly, copying the array to memory is now extraneous and consumes
    ///      more gas than reading only once from storage.
    /// @return Sum of array
    function sumE() public view returns (uint) {
        assembly {
            // storageArray.slot returns the storage slot of the array.
            // Items of a dynamic array are stored sequentially starting at the hash of the array slot.
            // keccak256(a, b) returns the b byte hash of a.
            // pointer is the storage slot of the first item in the array
            let pointer := keccak256(storageArray.slot, 0x20)
            // The length of a dynamic array is stored at the storage slot.
            let length := sload(storageArray.slot)
            // Instantiates a variable of default type: u256.
            let sum := 0
            // For loop syntax where lt(i, length) returns true iff i < length
            for { let i := 0 } lt(i, length) { i := add(i, 0x01) } {
                // The storage slot for item i is pointer + i.
                // sload(q) returns the value at storage slot q.
                sum := add(sum, sload(add(pointer, i)))
            }
            // Store sum from stack to memory scratch space at address 0x00.
            mstore(0x00, sum)
            // Return 32 (0x20) bytes from memory address 0x00.
            return(0x00, 0x20)
        }
    }
}
