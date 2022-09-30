// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract SCMoneyClub is ERC1155, ReentrancyGuard, Ownable { 
  uint256 public founderTokensId = 0;
  uint256 public seniorInvestorTokensId = 1;
  uint256 public investorTokensId = 2;
  uint256 public juniorInvestorTokensId = 3;

  uint256[] public individualMintSupplies = [5, 10, 25, 50];
  uint256[] public mintRates = [500000000000000000, 200000000000000000, 100000000000000000, 50000000000000000];

  constructor() ERC1155("https://api.scmoneyclub.com/wp-json/scmoneyclub/v1/proof-of-rank/{id}.json") { }

  function mint(uint256 id, uint256 amount) public virtual payable {
    uint256[] memory _individualMintSupplies = individualMintSupplies;
    require(id <= _individualMintSupplies.length, "Token doesn't exist");
    require(id <= 3, "Token doesn't exist");
    require(amount <= _individualMintSupplies[id], "Not enought supply left");
    require((balanceOf(msg.sender, id) + amount) <= _individualMintSupplies[id], "Not enought supply left");
    require(msg.value >= (amount * mintRates[id]), "Not enough ether sent");
    _mint(msg.sender, id, amount, "");
  }

  function updateRate(uint256 id, uint256 rate) public onlyOwner {
    require(id <= mintRates.length, "Token doesn't exist");
    mintRates[id] = rate;
  }

  function updateSupplies(uint256 id, uint256 supply) public onlyOwner {
    require(id <= individualMintSupplies.length, "Token doesn't exist");
    individualMintSupplies[id] = supply;
  }

  function mintMultiple(uint256[] memory ids, uint256[] memory amounts) payable public {
    require(ids.length == amounts.length, "Make sure Id's and Amount's matches");
    uint256[] memory _supplies = individualMintSupplies;
    uint256[] memory _mintRates = mintRates;
    require(ids.length <= _supplies.length, "Token doesn't exist");
    uint256 numberOfValids = 0;
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < 4; ++i) {
      for (uint256 j = 0; j < ids.length; ++j) {
        if (
          i == ids[j]
        ) {
            if (balanceOf(msg.sender, ids[j]) + amounts[j] <= _supplies[ids[j]]) {
              numberOfValids ++;
              totalAmount = totalAmount + (amounts[j] * _mintRates[ids[j]]);
            }
        }
      }
    }
    require(numberOfValids == ids.length, "Some or all token doesn't exist. Or you exceed your minting rate.");
    require(msg.value >= totalAmount, "Not enough ether sent");
    _mintBatch(msg.sender, ids, amounts, "0x0");
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function withdrawBalance() public onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(getBalance());
  }
}