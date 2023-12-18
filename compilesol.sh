#! /bin/bash

# solc version 0.8.16+commit.07a7930e.Linux.g++
# abigen version 1.10.4-stable

solc contracts/library/Recover.sol --bin --abi -o ~/Documents/ContractABI/ --overwrite

abigen --sol ./contracts/library/Recover.sol --out ./go-contracts/recover/recover.go --pkg recover --type recover --bin ~/Documents/ContractABI/Recover.bin