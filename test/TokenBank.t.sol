pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {BaseERC20} from "../src/BaseERC20.sol";
import {BaseERC721} from "../src/BaseERC721.sol";
import {SigUtils} from "./utils/sigUtils.sol";

contract TestTokenBank is Test {
    BaseERC20 erc20;
    TokenBank bank;
    SigUtils internal sigUtils;
    uint256 internal ownerPrivateKey;
    address internal owner_;
    uint256 internal totalSupply = 1e10 * 1e18;

    function setUp() public {
        ownerPrivateKey = 12345;
        owner_ = vm.addr(ownerPrivateKey);
        vm.startPrank(owner_);
        erc20 = new BaseERC20("rain", "rayer", totalSupply);
        bank = new TokenBank();
        sigUtils = new SigUtils(erc20.DOMAIN_SEPARATOR());
        vm.stopPrank();
    }

    function test_depositPermit() public {
        uint256 price = 1000;
        depositPermit(price);
    }

    function depositPermit(uint256 _value)internal {
        address owner = owner_;
        address spender = address(bank);
        uint256 value = _value;
        uint256 deadline = 1 days;
        uint256 nonce = erc20.nonces(owner);

        bytes32 digest = sigUtils.getTypedDataHash(
            owner,
            spender,
            value,
            nonce,
            deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        vm.startPrank(owner);
        bank.permitDeposit(
            address(erc20),
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
        assertEq(bank.balances(address(erc20), owner), value,"Desposit money exception");
        assertEq(erc20.balanceOf(owner), totalSupply-value, "Deposit money excecption.");
    }
}
