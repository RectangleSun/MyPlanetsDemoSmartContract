// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract Delegation is ERC721 {
    mapping(address => mapping(address => bool)) private delegationApproval;

    event DelegationApproval(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function isDelegateApproved(address owner, address operator)
        public
        view
        returns (bool)
    {
        return delegationApproval[owner][operator];
    }

    function setDelegationApproval(address operator, bool approved) external {
        require(operator != msg.sender, "Approval to caller");
        delegationApproval[msg.sender][operator] = approved;
        emit DelegationApproval(msg.sender, operator, approved);
    }

    function isOwnerOrDelegate(uint256 tokenId, address ownerOrd)
        public
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);

        if (owner != ownerOrd) {
            return isDelegateApproved(owner, ownerOrd);
        } else {
            return true;
        }
    }
}