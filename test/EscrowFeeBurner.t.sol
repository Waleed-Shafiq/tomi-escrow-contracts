// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EscrowFeeBurner} from "../src/EscrowFeeBurner.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Commands} from "../src/libraries/Commands.sol";

contract EscrowFeeBurnerTest is Test {
    address owner;
    address universalRouter;
    address permit2;
    address swaprouterv2;

    EscrowFeeBurner escrowFeeBurnerContract;

    IERC20 usdt;
    IERC20 tomi;

    ERC1967Proxy proxy;

    function setUp() public {
        owner = makeAddr("owner");
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        universalRouter = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;
        permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        tomi = IERC20(0x4385328cc4D643Ca98DfEA734360C0F596C83449);
        swaprouterv2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        escrowFeeBurnerContract = new EscrowFeeBurner();
        bytes memory escrowFeeBurnerParams = abi.encodeWithSelector(
            EscrowFeeBurner.Initialize.selector,
            owner,
            universalRouter,
            permit2,
            address(usdt),
            address(tomi),
            swaprouterv2
        );

        ERC1967Proxy EscrowFeeBurnerProxy = new ERC1967Proxy(
            address(escrowFeeBurnerContract),
            escrowFeeBurnerParams
        );
        escrowFeeBurnerContract = EscrowFeeBurner(
            address(EscrowFeeBurnerProxy)
        );
    }

    function testBurnTomi() public {
        uint256 burnAmount = 20000 * 1e6; // 20 USDT
        bytes memory commands = abi.encodePacked(
            bytes1(uint8(Commands.V2_SWAP_EXACT_IN))
        );
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(tomi);
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(
            address(escrowFeeBurnerContract),
            burnAmount,
            0,
            path,
            true
        );
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        deal(address(usdt), address(escrowFeeBurnerContract), burnAmount);
        escrowFeeBurnerContract.burnTomi(commands, inputs);
        vm.stopPrank();
    }
}
