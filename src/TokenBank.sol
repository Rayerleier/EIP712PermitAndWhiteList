// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Write a TokenBank contract that can deposit your own Token into TokenBank and withdraw from TokenBank.

// TokenBank has two methods:

// deposit(): needs to record the deposit amount for each address;
// withdraw(): users can withdraw their previously deposited tokens.
// Enter your code or github link in the answer box.

import {TokenReceiver} from "./interface/TokenReceive.sol";
import "./library/Address.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./BaseERC20.sol";

contract TokenBank is TokenReceiver, Ownable {
    mapping(address => mapping(address => uint256)) public balances;

    using Address for address;
    constructor() Ownable(msg.sender) {}

    modifier OnlyContract(address account) {
        require(account.isContract(), "Only Contract");
        _;
    }

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    

    function permitDeposit(
        address contractAdress,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        BaseERC20(contractAdress).permit(
            msg.sender,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
        deposit(contractAdress, value);
    }

    // Extend TokenBank to implement deposits using the transfer callback from the previous question.
    function tokensReceived(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) external OnlyContract(msg.sender) returns (bool) {
        balances[msg.sender][to] += amount;
        emit Deposited(to, amount);
        return true;
    }

    function deposit(
        address _constractAdress,
        uint256 _amount
    ) public returns (bool) {
        // 确认ERC20中存在balance
        (bool success, bytes memory data) = _constractAdress.call(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );
        uint256 result = abi.decode(data, (uint256));
        require(result >= _amount, "Not enough balance in ERC20.");
        require(success, "Request failed.");

        // 确认ERC20中存在allowance
        (bool allowanceSuccess, bytes memory allowanceData) = _constractAdress
            .call(
                abi.encodeWithSignature(
                    "allowance(address,address)",
                    msg.sender,
                    this
                )
            );
        uint256 allowanceResult = abi.decode(allowanceData, (uint256));
        require(allowanceResult >= _amount, "Not enough allowance in ERC20.");
        require(allowanceSuccess, "Allowance Request failed.");

        // 从ERC20中转账
        (bool transferSuccess, ) = _constractAdress.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                this,
                _amount
            )
        );
        require(transferSuccess, "Transfer Failed.");
        balances[_constractAdress][msg.sender] += _amount;
        emit Deposited(msg.sender, _amount);
        return transferSuccess;
    }

    function withdraw(
        address _constractAdress,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        require(
            balances[_constractAdress][msg.sender] >= _amount,
            "Not enough balances in TokenBank"
        );
        (bool withdrawSuccess, ) = _constractAdress.call(
            abi.encodeWithSignature(
                "transfer(address _to, uint256 _value)",
                _constractAdress,
                _amount
            )
        );
        require(withdrawSuccess, "Withdraw Failed.");
        balances[_constractAdress][msg.sender] -= _amount;
        emit Withdrawn(msg.sender, _amount);
        return withdrawSuccess;
    }
}
