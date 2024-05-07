pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {NFTmarket} from "../src/NFTmarket.sol";
import {BaseERC721} from "../src/BaseERC721.sol";
import {BaseERC20} from "../src/BaseERC20.sol";
import {SigUtils} from "./utils/sigUtils.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";

contract NFTmarketTest is Test, Nonces {
    BaseERC20 erc20;
    BaseERC721 erc721;
    NFTmarket nftmarket;
    SigUtils internal sigutils;
    struct SignModal {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    uint256 ownerPrivateKey = 12345;
    address owner_ = vm.addr(ownerPrivateKey);
    uint256 buyerPrivateKey = 76553241;
    address buyer_ = vm.addr(buyerPrivateKey);

    function setUp() public {
        vm.startPrank(owner_);
        nftmarket = new NFTmarket();
        erc721 = new BaseERC721("rain", "rayer", "arandomURI");
        erc721.setNFTMarket(address(nftmarket));
        erc20 = new BaseERC20("RAIN", "RAYER", 1e18);
        erc20.transfer(buyer_, 1e18);

        erc721.mint(owner_);
    }

    function test_permitList() public {
        uint256 tokenId = 1;
        uint256 price = 1000;
        permitList(address(erc721), tokenId, price);
        assertEq(
            nftmarket.sellerOfListings(address(erc721), tokenId),
            owner_,
            "nft owner exception"
        );
        assertEq(erc721.ownerOf(tokenId), address(nftmarket));
    }

    function permitList(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) internal {
        sigutils = new SigUtils(erc721.DOMAIN_SEPARATOR());
        vm.startPrank(owner_);
        address spender = address(nftmarket);
        uint256 value = tokenId;
        uint256 nonce = nonces(owner_);
        uint256 deadline = 1 days;
        bytes32 digest = sigutils.getTypedDataHash(
            owner_,
            spender,
            value,
            tokenId,
            deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        nftmarket.permitList(nftAddress, tokenId, deadline, price, v, r, s);
    }

    function test_buyPermit() public {
        address nftAddress = address(erc721);
        uint256 tokenId = 1;
        uint256 price = 1000;
        permitList(nftAddress, tokenId, price);
        buyPermit(tokenId, price);
    }

    function buyPermit(uint256 tokenId, uint256 price) internal {
        // verify the white list
        buySign(tokenId, price);
    }

    function whiteListSign(
        uint256 tokenId
    ) internal returns (uint8 v1, bytes32 r1, bytes32 s1) {
        sigutils = new SigUtils(erc721.DOMAIN_SEPARATOR());
        vm.startPrank(buyer_);
        address owner = erc721.owner();
        address spender = address(buyer_);
        uint256 value = tokenId;
        uint256 nonce = tokenId;
        uint256 deadline = 1 days;

        bytes32 digest = sigutils.getTypedDataHash(
            owner,
            spender,
            value,
            nonce,
            deadline
        );
        return vm.sign(ownerPrivateKey, digest);
    }

    function buySign(uint256 tokenId, uint256 price) internal {
        (uint8 v1, bytes32 r1, bytes32 s1) = whiteListSign(tokenId);
        NFTmarket.SignModal memory sign1 = NFTmarket.SignModal(v1, r1, s1);

        sigutils = new SigUtils(erc20.DOMAIN_SEPARATOR());
        address owner = buyer_;
        address spender = address(nftmarket);
        uint256 value = price;
        uint256 nonce = erc20.nonces(buyer_);
        uint256 deadline = 1 days;

        bytes32 digest2 = sigutils.getTypedDataHash(
            owner,
            spender,
            value,
            nonce,
            deadline
        );
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(buyerPrivateKey, digest2);
        NFTmarket.SignModal memory sign2 = NFTmarket.SignModal(v2, r2, s2);

        uint256 buyerBalance = erc20.balanceOf(buyer_);
        uint256 ownerBalance = erc20.balanceOf(owner_);

        vm.startPrank(buyer_);
        nftmarket.permitBuy(
            address(erc721),
            tokenId,
            address(erc20),
            buyer_,
            address(nftmarket),
            price,
            deadline,
            sign1,
            sign2
        );
        assertEq(erc721.ownerOf(tokenId), address(buyer_), "buy failed");
        assertEq(erc20.balanceOf(buyer_), buyerBalance - price);
        assertEq(erc20.balanceOf(owner_), ownerBalance + price);
    }
}
