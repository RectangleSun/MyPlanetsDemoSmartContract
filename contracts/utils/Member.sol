pragma solidity ^0.8.0;

// SPDX-License-Identifier: SimPL-2.0

import "./Manager.sol"; // done

// 抽象生成合约
abstract contract Member {
    // 修饰 检查当前用户string行为的许可
    modifier CheckPermit(string memory permit) {
        require(manager.userPermits(msg.sender, permit),
            "no permit");
        _;
    }

     modifier ContractOwnerOnly {
        // 只有合约拥有者可以调用
        require(msg.sender == admin, "contract owner only");
        _;
    }

    // 生成manager(经理)
    Manager public manager;

    address public  admin;

    address public newAdmin;

    constructor(){
      admin = msg.sender;
    }

    
    // 迁移
    function setManager(address addr) external ContractOwnerOnly {
        manager = Manager(addr);
    }

     function setNewAdmin (address _newAdmin) external ContractOwnerOnly {
        require(admin == msg.sender,"you are not admin");
        newAdmin = _newAdmin;
    }
    
    function getNewAdmin () public {
        require(newAdmin == msg.sender,"you are not newAdmin");
        admin = msg.sender;
    }
}
