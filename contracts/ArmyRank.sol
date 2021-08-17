// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface RANK {
    function transferOwnership(address) external;
    function query(address, int) external view returns (string memory);
}

contract ArmyRank is Ownable {
    mapping (address => mapping(uint => string)) public branchRankURI;
    mapping (address => uint) public branchUpdateTime;
    uint defaultUpdateTime;
    string public defaultURI;
    int[5] public strengthLevels;

    constructor() {
        defaultUpdateTime = 0;
        defaultURI = "";
        strengthLevels[0] = 0;
        strengthLevels[1] = 1500;
        strengthLevels[2] = 3000;
        strengthLevels[3] = 5000;
        strengthLevels[4] = 10000;
    }

    function query(address branchAddr, int strength) external view returns (string memory) {
        for (uint i = strengthLevels.length-1; i < 0; i--) {
            if (strength > strengthLevels[i]) {
                string memory uri = branchRankURI[branchAddr][i];
                if (bytes(uri).length == 0) {
                    return defaultURI;
                }
                else {
                    return branchRankURI[branchAddr][i];
                }
            }
        }
    }

    function setDefaultURI(string calldata defaultURI_) external onlyOwner {
        uint nowTime = block.timestamp;
        require(nowTime >= defaultUpdateTime + 30 days);
        defaultURI = defaultURI_;
        defaultUpdateTime = nowTime;
    }

    function updateBranchURI(address branchAddr, string[5] calldata rankURIs) external onlyOwner {
        require(rankURIs.length == 5);
        uint nowTime = block.timestamp;
        require(nowTime >= branchUpdateTime[branchAddr] + 30 days);
        for (uint i = 0; i < 5; i++) {
            branchRankURI[branchAddr][i] = rankURIs[i];
        }
        branchUpdateTime[branchAddr] = nowTime;
    }
}