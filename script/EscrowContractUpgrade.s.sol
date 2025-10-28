// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EscrowPayment} from "../src/EscrowPayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EscrowPaymentScript is Script {
    EscrowPayment public escrowPayment;
    //address feeWalletAddress = 0xF35Ad8EeD264E7B7d5d21CF8452E8caB944678d6;
    address feeWalletAddress = vm.envAddress("FEE_MANAGER");
    address tomiDisputeaddress = vm.envAddress("TOMI_DISPUTE");
    address usdtAddress = vm.envAddress("USDT_ADDRESS");

    //address tomiDisputeaddress = 0xF35Ad8EeD264E7B7d5d21CF8452E8caB944678d6;
    //address usdtAddress = 0x96264a7bC5e3C744fa97e32E552C72FE821E6560;
    address resolverAIAddress = vm.envAddress("RESOLVER_AI");
    //address resolverAIAddress = 0x400ab8Fe9Ee2F81b96338D24C7595cdf628Fa52F;
    address signerAddress = vm.envAddress("SIGNER_ADDRESS");
    //address signerAddress = 0x28E44c38683f3Dc5f76C0E7a3318c542406C7C34;
    uint256 resolverFeeAmount = 10e6; // fee updated to 10 USD

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        EscrowPayment implementation = new EscrowPayment();
        address proxyAddress = 0x4a9E98843F7AA1A321b118c2178CE179A380F8B8;
        EscrowPayment(payable(proxyAddress)).upgradeToAndCall{ value: 0 ether }(address(implementation), bytes(""));
        console.log("EscrowPayment Updated to:", address(implementation));
        vm.stopBroadcast();
    }
}
