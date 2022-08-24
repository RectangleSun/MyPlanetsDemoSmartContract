// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PlanetPassItems is ERC1155, ERC1155Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => bytes32) internal itemType;

    event SetItemType(uint256 indexed tokenId, bytes32 itemType);

    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // DEFAULT_ADMIN_ROLE 默认的管理员标识
        _setupRole(MINTER_ROLE, msg.sender); // Mint 管理员
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function tokenIsType(uint256 id, bytes32 _type) public view returns (bool) {
        return itemType[id] == _type; //查看类型
    }

    function tokenType(uint256 id) public view returns (bytes32) {
        return itemType[id];
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function setItemType(uint256 item, string memory newType)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bytes32 hashedType = keccak256(abi.encodePacked(newType));
        itemType[item] = hashedType;
        emit SetItemType(item, hashedType);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}