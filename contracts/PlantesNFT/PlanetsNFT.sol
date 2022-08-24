// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721Data.sol";
import "./Stardust.sol";
import "./PlanetPassItems.sol";


contract PlanetsNFT is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    ERC721Data,
    Pausable
{
    using Strings for uint256;

    struct Override {
        uint256 state;
        bool enabled;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant STATE_UPDATER_ROLE =
        keccak256("STATE_UPDATER_ROLE");

    string private baseURI; // URL 前缀

    bytes32 public immutable root;

    bool public claimEnabled; //申明

    mapping(uint256 => bool) public claimed;

    uint256 public defaultState;

    mapping(uint256 => Override) private overrideState;

    PlanetPassItems public planetPassItemsContract;

    uint256 public customizationItemId; // 0 自定义ID


    event OverrideStateUpdate(
        uint256 indexed tokenId,
        uint256 indexed state,
        bool enabled
    );

    event DefaultStateUpdate(uint256 indexed state);

    constructor(
        string memory baseURI_,
        bytes32 _root,
        PlanetPassItems _planetPassItemsContract,
        uint256 _customizationItemId
    ) ERC721("Planet Demo", "PLANETDEMO") {
        baseURI = baseURI_;
        root = _root;
        planetPassItemsContract = _planetPassItemsContract;
        customizationItemId = _customizationItemId;
        claimEnabled = false;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(STATE_UPDATER_ROLE, msg.sender);

        _pause();  //开启合约
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();//开启合约
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();//暂停
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string calldata newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = newBaseURI;
    }


    function setCustomizationItemId(uint256 _customizationItemId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        customizationItemId = _customizationItemId;
    }


    function enableClaim() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimEnabled = true;
    }

    function disableClaim() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimEnabled = false;
    }


    struct ClaimData {
        uint256 tokenId;
        bytes32[] proof;
        Data data;
    }


//whenNotPaused  检查合约状态
    function claim(address to, ClaimData[] calldata claimData)
        external
        whenNotPaused 
    {
        require(claimEnabled, "Claim disabled");

        for (uint256 i = 0; i < claimData.length; i++) {
            _claim(to, claimData[i]);
        }
    }

    function _claim(address to, ClaimData calldata claimData) internal {
        require(!claimed[claimData.tokenId], "Already claimed");

        require(
            _verify(_leaf(claimData.tokenId, msg.sender), claimData.proof),
            "Bad merkle proof"
        );

        claimed[claimData.tokenId] = true;

        _safeMint(to, claimData.tokenId);
        _setData(claimData.tokenId, claimData.data);
    }


    function _leaf(uint256 tokenId, address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }


    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }


    function safeMint(
        address to,
        uint256 tokenId,
        Data calldata data
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setData(tokenId, data);
    }


    function safeMint(
        address to,
        uint256[] calldata tokenId,
        Data[] calldata data
    ) external onlyRole(MINTER_ROLE) {
        require(tokenId.length == data.length, "Array length mismatch");

        for (uint256 i = 0; i < tokenId.length; i++) {
            _safeMint(to, tokenId[i]);
            _setData(tokenId[i], data[i]);
        }
    }

    function setDefaultState(uint256 _defaultState)
        external
        onlyRole(STATE_UPDATER_ROLE)
    {
        defaultState = _defaultState;
        emit DefaultStateUpdate(_defaultState);
    }


    function setOverrideState(
        uint256[] calldata tokenId,
        Override calldata _overrideState
    ) external onlyRole(STATE_UPDATER_ROLE) {
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(_exists(tokenId[i]), "Nonexistent token");

            overrideState[tokenId[i]] = _overrideState;
            emit OverrideStateUpdate(
                tokenId[i],
                _overrideState.state,
                _overrideState.enabled
            );
        }
    }


    function getPlanetState(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Query for nonexistent token");

        if (overrideState[tokenId].enabled) {
            return overrideState[tokenId].state;
        } else {
            return defaultState;
        }
    }


    function setData(uint256 tokenId, Data calldata data)
        public
        virtual
        override
        whenNotPaused
    {
        planetPassItemsContract.burn(msg.sender, customizationItemId, 1);
        super.setData(tokenId, data);
    }


    function setData(uint256[] calldata tokenId, Data[] calldata data)
        public
        virtual
        override
        whenNotPaused
    {
        planetPassItemsContract.burn(
            msg.sender,
            customizationItemId,
            tokenId.length
        );
        super.setData(tokenId, data);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return tokenURIWithState(tokenId, getPlanetState(tokenId));
    }

    function tokenURIWithState(uint256 tokenId, uint256 state)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURI(),
                        state.toString(),
                        "/",
                        tokenId.toString()
                    )
                )
                : "";
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Data, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
