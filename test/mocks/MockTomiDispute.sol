// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ITomiDispute} from "../../src/Interfaces/ITomiDispute.sol";

contract MockTomiDispute is ITomiDispute {
    address public lastDisputeCreator;
    address public lastDisputedAddress;
    uint256 public lastLoyaltyFee;
    address public storedWinner;
    bool public revertOnWinner;
    address public lastProofSubmitter;
    string public lastProofURI;

    error EvmError();

    function createTomiDispute(
        address disputedAddress,
        string calldata,
        address disputor,
        string calldata,
        uint256,
        uint256 loyaltyFee
    ) external override returns (address) {
        lastDisputeCreator = disputor;
        lastDisputedAddress = disputedAddress;
        lastLoyaltyFee = loyaltyFee;
        return address(this);
    }

    function submitProof(address disputor, string memory proof) external override {
        lastProofSubmitter = disputor;
        lastProofURI = proof;
    }

    function calculateWinnerReadOnly()
        external
        view
        override
        returns (uint256, uint256, address)
    {
        if (revertOnWinner) {
            revert EvmError();
        }
        return (0, 0, storedWinner);
    }

    function setWinner(address winner) external {
        storedWinner = winner;
    }

    function setRevertOnWinner(bool shouldRevert) external {
        revertOnWinner = shouldRevert;
    }
}
