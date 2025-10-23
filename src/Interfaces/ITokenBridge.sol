// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ITokenBridge {
    function bridgeTokens(
        address recipient,
        uint256 amount,
        uint16 targetChainID,
        uint256 slippageInPPM
    ) external payable;

    function estimateFee(
        uint16 dstChainId,
        address recipient
    ) external view returns (uint256);
}
