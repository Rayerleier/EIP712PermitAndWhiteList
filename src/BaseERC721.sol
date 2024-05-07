pragma solidity ^0.8.0;

import {console} from "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";

contract BaseERC721 is ERC721, Ownable, EIP712, Nonces {
    string private baseURI;
    uint256 private tokenId = 1;
    address private NFTMarketAddress;
    error onlyNFTMarket(address account);
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address _owner);
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            (
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            )
        );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) Ownable(msg.sender) EIP712(_name, "1") {
        baseURI = _uri;
    }

    modifier onlyMarket() {
        _checkMarket();
        _;
    }

    function setNFTMarket(address _nftMarketAddress) public {
        NFTMarketAddress = _nftMarketAddress;
    }

    function _checkMarket() internal view {
        if (NFTMarketAddress != msg.sender) {
            revert onlyNFTMarket(msg.sender);
        }
    }
    function mint(address _to) external {
        _mint(_to, tokenId++);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function permit(
        address _owner,
        address spender,
        uint256 value, // tokenId
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public  {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }
        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, _owner, spender, value, value, deadline)
        );
        bytes32 hash_ = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash_, v, r, s);
        if (signer != _owner) {
            revert ERC2612InvalidSigner(signer, _owner);
        }

        _approve(spender, value, _owner);
    }
}
