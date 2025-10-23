// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeManagerTest is Test {
    address burnerOnETHAddress;
    address owner;
    address bridgeAddress = 0x5E8f246D15F1bAe9749926403628491592656265;
    uint256 _thresholdtoBridge = 10 * 1e6; // 10 USDT

    FeeManager feeManagerContract;

    IERC20 usdt;
    ERC1967Proxy proxy;

    function setUp() public {
        owner = makeAddr("owner");
        burnerOnETHAddress = makeAddr("burnerOnETHAddress");
        usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

        feeManagerContract = new FeeManager();
        bytes memory feeManageParams = abi.encodeWithSelector(
            FeeManager.Initialize.selector,
            owner,
            bridgeAddress,
            address(usdt),
            address(burnerOnETHAddress),
            _thresholdtoBridge
        );

        ERC1967Proxy FeeManagerProxy = new ERC1967Proxy(
            address(feeManagerContract),
            feeManageParams
        );
        feeManagerContract = FeeManager(address(FeeManagerProxy));
    }

    function testBridgeToETH() public {
        uint256 bridgeAmount = 20 * 1e6; // 20 USDT
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        deal(address(usdt), address(feeManagerContract), bridgeAmount);
        uint256 amount = feeManagerContract.estimateFeeToETH();
        feeManagerContract.bridgeToETH{value: amount}();
        vm.stopPrank();
    }
}
