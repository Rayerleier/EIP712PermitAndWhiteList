pragma solidity ^0.8.0;

interface TokenReceiver {
    function tokensReceived(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) external returns (bool);
}
