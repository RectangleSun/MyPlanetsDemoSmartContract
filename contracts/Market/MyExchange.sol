// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyExchange is ERC721Holder {
    using SafeMath for uint256;
    struct OrderMsg {
        bool isFinish;
        uint256[] cardid; //卡片id
        uint256[] price; //单价
        uint256 createTime; //创建时间
        uint256 sellCont; //已售出
        address maker; //制定者
        address payToken; //支付币
        address nftAddress; //NFT地址
        address[] buyAddress;
        bytes32 orderid;
    }

    event CreateOrders(
        address indexed maker,
        bytes32 indexed orderid,
        address payToken,
        address nftAddress,
        uint256[] tokenIds,
        uint256[] price
    );
    // event TradeOrders{
    //     address indexed maker,
    // };

    OrderMsg[] nowOrder; // 所有创建的订单
    mapping(address => OrderMsg[]) myCreateOrder; //我的创建单
    mapping(address => OrderMsg[]) myTradeOrder; //我的成交单
    mapping(address => bool) isSellNft; // 是否支持交易

    function createOrder(OrderMsg memory createOrders) external {
        uint256 length = createOrders.cardid.length;

        require(
            isSellNft[createOrders.nftAddress],
            " This NFT contract does not support transactions "
        );
        require(length != 0, "Card id is empty");
        require(
            createOrders.nftAddress != address(0) &&
                createOrders.payToken != address(0),
            "NFT or PayToken is error"
        );
        bytes32 orderid = keccak256(
            abi.encode(msg.sender, block.number, createOrders.nftAddress)
        );
        for (uint256 i = 0; i != length; i++) {
            IERC721(createOrders.nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                createOrders.cardid[i],
                "createOrder"
            );
        }
        createOrders.orderid = orderid;
        emit CreateOrders(
            createOrders.maker,
            createOrders.orderid,
            createOrders.payToken,
            createOrders.nftAddress,
            createOrders.cardid,
            createOrders.price
        );

        nowOrder.push(createOrders);
        myCreateOrder[msg.sender].push(createOrders);
    }

    function tradeOrder(bytes32 orderid, uint256 cont) external {
        uint256 index = _checkOrder(orderid, cont);
        uint256 indexMy = _checkMyCreateOrder(orderid);
        require(index != 0, "order does not exist");
        require(indexMy != 0,"");
        OrderMsg storage _order = nowOrder[index - 1];

        uint256[] memory tradeTokenIds = new uint256[](cont);
        uint256[] memory tradePrice = new uint256[](cont);
        bytes32 tradeId = keccak256(
            abi.encode(msg.sender, block.number, orderid)
        );

        for (uint256 i = _order.sellCont; i != _order.cardid.length; i++) {
            IERC20(_order.payToken).transferFrom(
                msg.sender,
                _order.maker,
                _order.price[i]
            );
            IERC721(_order.nftAddress).transferFrom(
                address(this),
                msg.sender,
                _order.cardid[i]
            );
            tradeTokenIds[i] = _order.cardid[i];
            tradePrice[i] = _order.price[i];
            
        }
        myTradeOrder[msg.sender].push(
            OrderMsg(
                false,
                tradeTokenIds,
                tradePrice,
                block.timestamp,
                tradeTokenIds.length,
                _order.maker,
                _order.payToken,
                _order.nftAddress,
                _order.buyAddress,
                tradeId
            )
        );

        _order.sellCont = _order.sellCont.add(cont);
        _order.buyAddress.push(msg.sender);
        nowOrder[indexMy - 1].buyAddress.push(msg.sender);
        nowOrder[indexMy - 1].sellCont = _order.sellCont;
        if (_order.sellCont == _order.cardid.length) {
            _order.isFinish = true;
            nowOrder[indexMy - 1].isFinish = true;
        }
    }


    function cancelOrder(bytes32 orderid)external {
        uint256 index = _checkOrder(orderid, 0);
        require(index != 0, "order does not exist");
        OrderMsg memory _order = nowOrder[index - 1];
        require(_order.maker == msg.sender, "invalid card");

        for (uint256 i = _order.sellCont; i < _order.cardid.length; i++) {
            IERC721(_order.nftAddress).transferFrom(
                address(this),
                msg.sender,
                _order.cardid[i]
            );
        }
    }

    function _checkMyCreateOrder(bytes32 orderid)
        private
        view
        returns (uint256 index)
    {
        index = 0;
        uint256 length = myCreateOrder[msg.sender].length;
        for (uint256 i = 0; i != length; i++) {
            if (orderid == myCreateOrder[msg.sender][i].orderid) {
                index = i + 1;
                break;
            }
        }
    }

    function _checkOrder(bytes32 orderid, uint256 cont)
        private
        view
        returns (uint256 orderIndex)
    {
        orderIndex = 0;
        for (uint256 i = 0; i != nowOrder.length; i++) {
            if (orderid == nowOrder[i].orderid) {
                if (
                    (nowOrder[i].sellCont.add(cont) <=
                        nowOrder[i].cardid.length) && !nowOrder[i].isFinish
                ) {
                    orderIndex = i + 1;
                    break;
                }
            }
        }
    }
}
