pragma solidity ^0.8.0;

// SPDX-License-Identifier: SimPL-2.0

abstract contract ContractOwner {
    //　合约拥有者
    address public contractOwner = msg.sender; 
    
    modifier ContractOwnerOnly {
        // 只有合约拥有者可以调用
        require(msg.sender == contractOwner, "contract owner only");
        _;
    }
}
