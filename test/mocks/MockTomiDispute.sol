// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ITomiDispute} from "../../src/Interfaces/ITomiDispute.sol";

contract MockTomiDispute is ITomiDispute {
    address public lastDisputeCreator;
    address public lastDisputedAddress;

    error EvmError();

    function createTomiDispute(
        address disputedAddress,
        string calldata,
        address disputor,
        string calldata,
        uint256,
        uint256
    ) external override returns (address) {
        lastDisputeCreator = disputor;
        lastDisputedAddress = disputedAddress;
        return address(this);
    }

    function submitProof(address, string memory) external override {}

    function calculateWinnerReadOnly()
        external
        pure
        override
        returns (uint256, uint256, address)
    {
        return (0, 0, address(0));
    }
}
