// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseArmy.sol";
import "./RedProtein.sol";

/**
 * @title Red Army, which grows in bearish market
 * @notice ERC721 token cultivated by predicting market price (using Chainlink oracle)
 * @author Justa Liang
 */
contract RedArmy is BaseArmy {

    /**
     * @dev Set name, symbol, and addresses of interactive contracts
     * @param ensRegistryAddr Address of ENS Registry
    */
    constructor(address ensRegistryAddr) ERC721("Red Army", "rARMY") {
        serialNumber = 0;
        _initStrength = 1000;
        _ens = ENS(ensRegistryAddr);
        prtnAddress = address(new RedProtein(address(this)));
        _prtn = PRTN(prtnAddress);
        _prtn.produce(msg.sender, 7777777777);
    }

    /**
     * @notice Train a minion and update the environment factor
     * @param minionID ID of the minion
    */
    function train(uint minionID) external override checkCommander(minionID) {
        Minion storage target = _minions[minionID];
        require(
            target.armed,
            "ARMY: minion is already in training state");

        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(target.barrackAddr);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // update on-chain data
        target.envFactor = currPrice;
        target.armed = false;

        // emit minion state
        emit MinionState(minionID, target.barrackAddr, false, currPrice, target.strength);
    }

    /**
     * @notice Arm a minion and update its strength
     * @param minionID ID of the minion
    */
    function arm(uint minionID) external override checkCommander(minionID) {
        Minion storage target = _minions[minionID];
        require(
            !target.armed,
            "ARMY: minion is already armed");

        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(target.barrackAddr);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // update on-chain data
        target.strength = ((target.envFactor << 10)/currPrice*target.strength) >> 10;
        target.envFactor = currPrice;
        target.armed = true;

        // emit minion state
        emit MinionState(minionID, target.barrackAddr, true, currPrice, target.strength);
    }

    /**
     * @notice Use Protein to stimulate an armed minion to catch up training
     * @dev Commander cost Protein
     * @param minionID ID of the minion
    */
    function reinforce(uint minionID) external override checkCommander(minionID) {
        Minion storage target = _minions[minionID];
        require(
            target.armed,
            "ARMY: minion is already in training state");

        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(target.barrackAddr);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // change state
        if (currPrice < target.envFactor) {
             _prtn.consume(msg.sender, uint(((target.envFactor << 10)/currPrice*target.strength) >> 10));
        }
        target.armed = false;

        // emit minion state
        emit MinionState(minionID, target.barrackAddr, false, target.envFactor, target.strength);
    }

    /**
     * @notice Use Protein to recover a minion who suffer from negative training
     * @dev Commander cost Protein
     * @param minionID ID of the minion
    */
    function recover(uint minionID) external override checkCommander(minionID) {
        Minion storage target = _minions[minionID];
        require(
            !target.armed,
            "ARMY: minion is not in training state");

        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(target.barrackAddr);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // change state
        if (currPrice > target.envFactor) {
            _prtn.consume(msg.sender, uint(((target.envFactor << 10)/currPrice*target.strength) >> 10));
        }
        target.armed = true;

        // emit minion state
        emit MinionState(minionID, target.barrackAddr, true, target.envFactor, target.strength);
    }
}