// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EscrowPayment} from "../src/EscrowPayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CounterScript is Script {
    EscrowPayment public escrowPayment;
    address feeWalletAddress = 0xF35Ad8EeD264E7B7d5d21CF8452E8caB944678d6;
    address swapandBurnContractAddress = 0xF35Ad8EeD264E7B7d5d21CF8452E8caB944678d6;
    address tomiDisputeaddress = 0xF35Ad8EeD264E7B7d5d21CF8452E8caB944678d6;
    address usdtAddress = 0x6fEA2f1b82aFC40030520a6C49B0d3b652A65915;
    address resolverAIAddress = 0xF35Ad8EeD264E7B7d5d21CF8452E8caB944678d6;
    address signerAddress = 0x28E44c38683f3Dc5f76C0E7a3318c542406C7C34;
    uint256 resolverFeeAmount = 1e6;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        EscrowPayment implementation = new EscrowPayment();
        bytes memory escrowPaymentParams = abi.encodeCall(
            EscrowPayment.Initialize,
            (
                feeWalletAddress,
                swapandBurnContractAddress,
                tomiDisputeaddress,
                usdtAddress,
                resolverAIAddress,
                signerAddress,
                resolverFeeAmount
            )
        );

        ERC1967Proxy escrowPaymentProxy = new ERC1967Proxy(
            address(implementation),
            escrowPaymentParams
        );

        escrowPayment = EscrowPayment(address(escrowPaymentProxy));
        console.log("escrowPayment implementation deployed at:", address(implementation));
        console.log("escrowPayment proxy deployed at:", address(escrowPayment));
        vm.stopBroadcast();
    }
}
