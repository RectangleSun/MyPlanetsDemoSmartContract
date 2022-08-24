pragma solidity ^0.8.0;

// SPDX-License-Identifier: SimPL-2.0

import "./ContractOwner.sol"; // done

// 全局导入拥有权限
contract Manager is ContractOwner {

    // 映射members(成员)
    mapping(string => address) public members;

    // 映射userPermits(用户许可)  地址 => string => bool
    mapping(address => mapping(string => bool)) public userPermits;
    
    // 修改|添加|删除 member(成员)
    function setMember(string memory name, address member)
        external ContractOwnerOnly {
        
        members[name] = member;
    }
    
    // 修改|添加|删除 userPermit(用户许可) 
    function setUserPermit(address user, string memory permit,
        bool enable) external ContractOwnerOnly {
        
        userPermits[user][permit] = enable;
    }
    
    // 获得当前时间戳
    function getTimestamp() external view returns(uint256) {
        return block.timestamp;
    }
}
