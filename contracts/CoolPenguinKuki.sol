// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}


pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CoolPenguinKuki is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ContextMixin
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    string private _baseTokenURI = "";

    uint256 public _mintingFee = 25000000000000000000;
    uint256 public constant MAX_SUPPLY = 10000;

    address payable walletAddress;

    bool public saleIsActive = true;

    event KukiMinted(uint256 tokenId, address owner);

    constructor(string memory _tokenURI, address payable _walletAddress)
        ERC721("CoolPenguinKuki", "KUKI")
    {
        _baseTokenURI = _tokenURI;
        walletAddress = _walletAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function mint() public payable {
        require(saleIsActive, "Sale must be active to mint Penguin");
        require(
            _tokenIdCounter.current() < MAX_SUPPLY + 1,
            "MAX_SUPPLY reached. Cannot mint new NFT."
        );
        require(
            _mintingFee <= msg.value,
            "Token Supply is not enough for minting."
        );
        (bool sent, ) = walletAddress.call{value: msg.value}("");
        require(sent, "Failed to send Matic");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _baseTokenURI);
        emit KukiMinted(tokenId, msg.sender);
    }

    function reservePenguins(uint256 nftCount) public onlyOwner {
        uint256 i;
        uint256 _remaningCount = totalRemainingSupply();
        require(
            nftCount < _remaningCount,
            "MAX_SUPPLY reached. Cannot mint new NFT."
        );
        for (i = 0; i < nftCount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, _baseTokenURI);
        }
    }

    function giftPenguins(address to) public onlyOwner {
        require(
            _tokenIdCounter.current() < MAX_SUPPLY + 1,
            "MAX_SUPPLY reached. Cannot mint new NFT."
        );
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _baseTokenURI);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalRemainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function setMintingFee(uint256 newMintingFee) public onlyOwner {
        _mintingFee = newMintingFee;
    }

    function withdrawBalance(address payable _to) public payable onlyOwner {
        (bool sent, ) = _to.call{value:  address(this).balance}("");
        require(sent, "Failed to send Matic");
    }

    function setWalletAddress(address payable _newWalletAddress) external onlyOwner {
        walletAddress = _newWalletAddress;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}
