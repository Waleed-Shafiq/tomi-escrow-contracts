// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EscrowFeeBurner} from "../src/EscrowFeeBurner.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EscrowFeeBurnerScript is Script {
    EscrowFeeBurner public escrowFeeBurner;
    address universalRouterAddress = vm.envAddress("UNIVERSAL_ROUTER");
    address permit2Address = vm.envAddress("PERMIT2_ADDRESS");
    address tomiAddress = vm.envAddress("TOMI_ADDRESS");
    address usdtAddress = vm.envAddress("USDT_ADDRESS_ETH");

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        EscrowFeeBurner implementation = new EscrowFeeBurner();
        bytes memory escrowFeeBurnerParams = abi.encodeCall(
            EscrowFeeBurner.Initialize,
            (
                owner,
                universalRouterAddress,
                permit2Address,
                usdtAddress,
                tomiAddress
            )
        );

        ERC1967Proxy escrowFeeBurnerProxy = new ERC1967Proxy(
            address(implementation),
            escrowFeeBurnerParams
        );

        escrowFeeBurner = EscrowFeeBurner(address(escrowFeeBurnerProxy));
        console.log(
            "escrowFeeBurner implementation deployed at:",
            address(implementation)
        );
        console.log(
            "escrowFeeBurner proxy deployed at:",
            address(escrowFeeBurnerProxy)
        );
        vm.stopBroadcast();
    }
}
