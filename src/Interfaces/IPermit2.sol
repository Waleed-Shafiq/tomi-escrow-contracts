// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPermit2 {
    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration
    );

    /// @notice Gives allowance for the token to the spender of amount
    /// @param token The token address to approve to spender
    /// @param spender The address of the spender
    /// @param amount The amount to approve
    /// @param expiration The expiration time
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;
}
