// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721Data is ERC721, AccessControl {
    bytes32 public constant DATA_MODERATOR_ROLE =
        keccak256("DATA_MODERATOR_ROLE");

    struct Data {
        string name;
        string description;
    }

    mapping(uint256 => Data) internal tokenData;

    mapping(uint256 => bool) internal locked;

    event SetData(
        address indexed from,
        uint256 indexed id,
        string name,
        string description
    );

    event DataLock(address indexed from, uint256 indexed id);

    event DataUnlock(address indexed from, uint256 indexed id);

    modifier tokenUnlocked(uint256 id) {
        
        require(!locked[id], "Token data locked");
        _;
    }

    constructor() {
        //初始化 用户角色
        _setupRole(DATA_MODERATOR_ROLE, msg.sender);
    }

    function dataOfToken(uint256 tokenId) public view returns (Data memory) {
        require(_exists(tokenId), "Query for nonexistent token");

        return tokenData[tokenId]; //按照 Id 查询 绑定数据
    }

    function tokenDataIsLocked(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Query for nonexistent token");

        return locked[tokenId]; //查询Token 锁定状态
    }

    function setData(uint256 tokenId, Data calldata data)
        public
        virtual
        tokenUnlocked(tokenId)
    {
        require(_exists(tokenId), "Nonexistent token");
        require(msg.sender == ownerOf(tokenId), "Not owner of token");

        _setData(tokenId, data);
    }

    function setData(uint256[] calldata tokenId, Data[] calldata data)
        public
        virtual
    { //批量设置
        require(tokenId.length == data.length, "Array length mismatch");

        for (uint256 i = 0; i < data.length; i++) {
            setData(tokenId[i], data[i]);
        }
    }

    function _setData(uint256 tokenId, Data memory data) internal {
        tokenData[tokenId] = data; // 添加Token 数据
        emit SetData(msg.sender, tokenId, data.name, data.description);
    }

    function forceUpdateAndLock(uint256 tokenId, Data calldata data)
        external
        virtual
        onlyRole(DATA_MODERATOR_ROLE)
    { // 管理员 修改 token 数据，并锁定禁止后续修改
        require(_exists(tokenId), "Nonexistent token");
        _setData(tokenId, data);
        _lock(tokenId);
    }

    function _lock(uint256 tokenId) internal virtual {
        locked[tokenId] = true; //加锁
        emit DataLock(msg.sender, tokenId);
    }

    function _unlock(uint256 tokenId) internal virtual {
        locked[tokenId] = false; //解锁
        emit DataUnlock(msg.sender, tokenId);
    }

    function unlockData(uint256 tokenId)
        external
        virtual
        onlyRole(DATA_MODERATOR_ROLE)
    {
        require(_exists(tokenId), "Nonexistent token");
        _unlock(tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    { //bytes4 interfaceId  MethodID  0x00000000
        //初始化 自定义接口
        return super.supportsInterface(interfaceId);
    }
}