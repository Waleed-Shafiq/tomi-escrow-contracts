// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ITomiDispute {
    function createTomiDispute(
        address disputedAddress, // the one with whom the dispute is
        string calldata disputedUri, // ipfs uri of disputed tomi (winners)
        address disputor, // the one who created the dispute
        string calldata disputeUri, // ipfs uri of dispute,
        uint256 dealSize, // deal reward
        uint256 loyaltyFee
    ) external returns (address);

    function submitProof(
        address disputor, // the address of disputor who already joined
        string memory proof // ipfs uri for 2nd proof
    ) external;

    function calculateWinnerReadOnly()
        external
        view
        returns (uint256, uint256, address);
}
