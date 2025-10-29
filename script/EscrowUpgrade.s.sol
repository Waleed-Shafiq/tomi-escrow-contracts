// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EscrowPayment} from "../src/EscrowPayment.sol";

contract EscrowUpgradeScript is Script {
    // keccak256("eip1967.proxy.implementation") - 1
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = 0x9A5bf30a7681D4abb654f77e26Ab66d2fDF4A1CE;

        require(proxyAddress != address(0), "proxy address not set");
        require(
            proxyAddress.code.length != 0,
            "proxy address has no code deployed"
        );

        EscrowPayment proxy = EscrowPayment(payable(proxyAddress));

        address implementationBefore = _readImplementation(proxyAddress);
        bool oracleStatusBefore = proxy.isOracleDisputeAllowed();
        
        vm.startBroadcast(deployerPrivateKey);

        EscrowPayment implementation = new EscrowPayment();
        proxy.upgradeToAndCall{value: 0}(address(implementation), bytes(""));

        vm.stopBroadcast();

        address implementationAfter = _readImplementation(proxyAddress);
        bool oracleStatusAfter = proxy.isOracleDisputeAllowed();
        address disputeWalletAfter = proxy.disputeAiFeeWallet();

        require(
            implementationAfter == address(implementation),
            "implementation slot mismatch"
        );
        require(
            oracleStatusBefore == oracleStatusAfter,
            "oracle dispute status changed"
        );

        console.log("EscrowPayment upgrade successful");
        console.log("Proxy address:", proxyAddress);
        console.log("Previous implementation:", implementationBefore);
        console.log("New implementation:", implementationAfter);
        
    }

    function _readImplementation(
        address proxy
    ) internal view returns (address) {
        bytes32 data = vm.load(proxy, IMPLEMENTATION_SLOT);
        return address(uint160(uint256(data)));
    }
}
