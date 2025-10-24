// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FeeManagerScript is Script {
    FeeManager public feeManger;
    address bridgeAddress = vm.envAddress("BRIDGE_ADDRESS");
    address usdtAddress = vm.envAddress("USDT_ADDRESS");
    address burnerOnETHAddress = vm.envAddress("ETH_BURNER");
    uint256 _thresholdtoBridge = 10e6; // fee updated to 10 USD

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        FeeManager implementation = new FeeManager();
        bytes memory feeManagerParams = abi.encodeCall(
            FeeManager.Initialize,
            (
                owner,
                bridgeAddress,
                usdtAddress,
                burnerOnETHAddress,
                _thresholdtoBridge
            )
        );

        ERC1967Proxy feeMangerProxy = new ERC1967Proxy(
            address(implementation),
            feeManagerParams
        );

        feeManger = FeeManager(address(feeMangerProxy));
        console.log(
            "feeManger implementation deployed at:",
            address(implementation)
        );
        console.log("feeManger proxy deployed at:", address(feeMangerProxy));
        vm.stopBroadcast();
    }
}
