// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EscrowPayment} from "../src/EscrowPayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockUSDT} from "./mocks/MockUSDT.sol";
import {MockTomiDispute} from "./mocks/MockTomiDispute.sol";

contract EscrowPaymentTest is Test {
    EscrowPayment public escrow;
    MockUSDT public usdt;
    MockTomiDispute public tomiDispute;

    address internal alice; // fromAddress
    address internal bob; // toAddress
    address internal feeWallet;
    address internal swapAndBurn;
    address internal resolverAI;

    uint256 internal constant PPM = 1_000_000;
    uint256 internal constant PLATFORM_FEE_PPM = 10_000; // 1%
    uint256 internal constant DEFAULT_FEE_PPM = 50_000; // 5%
    uint256 internal constant RESOLVER_FEE = 1e6; // 1 USDT

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        feeWallet = makeAddr("feeWallet");
        swapAndBurn = makeAddr("swapAndBurn");
        resolverAI = makeAddr("resolverAI");

        usdt = new MockUSDT();
        tomiDispute = new MockTomiDispute();

        escrow = new EscrowPayment();
        bytes memory escrowParams = abi.encodeWithSelector(
            EscrowPayment.Initialize.selector,
            feeWallet,
            swapAndBurn,
            address(tomiDispute),
            address(usdt),
            resolverAI,
            RESOLVER_FEE
        );

        ERC1967Proxy escrowPayProxy = new ERC1967Proxy(
            address(escrow),
            escrowParams
        );
        escrow = EscrowPayment(address(escrowPayProxy));
    }

    function _createEscrow(
        uint256 amount,
        uint256 feePpm,
        uint256 deadline
    ) internal returns (uint256 id) {
        // fund alice
        uint256 platformFee = (amount * PLATFORM_FEE_PPM) / PPM;
        usdt.mint(alice, amount + platformFee);
        // approvals
        vm.prank(alice);
        usdt.approve(address(escrow), amount + platformFee);
        // create
        vm.prank(alice);
        escrow.CreateEscrow(
            "ipfs://details",
            bob,
            address(usdt),
            amount,
            feePpm,
            deadline,
            EscrowPayment.DisputeType.RegularDispute
        );
        id = escrow.escrowId();
    }

    function _accept(uint256 id) internal {
        vm.prank(bob);
        escrow.AcceptEscrow(id);
    }

    function _submit(uint256 id, string memory uri) internal {
        vm.prank(bob);
        escrow.SubmitEscrow(id, uri);
    }

    function test_CreateEscrow_RevertsOnPastOrNowDeadline() public {
        uint256 nowTs = block.timestamp;
        // deadline equal to now -> invalid
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.InvalidTime.selector);
        escrow.CreateEscrow(
            "ipfs://d",
            bob,
            address(usdt),
            1_000_000,
            DEFAULT_FEE_PPM,
            nowTs,
            EscrowPayment.DisputeType.RegularDispute
        );

        // deadline in the past -> invalid
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.InvalidTime.selector);
        escrow.CreateEscrow(
            "ipfs://d",
            bob,
            address(usdt),
            1_000_000,
            DEFAULT_FEE_PPM,
            nowTs - 1,
            EscrowPayment.DisputeType.RegularDispute
        );
    }

    function test_CreateEscrow_RevertsOnNonUsdtToken() public {
        uint256 deadline = block.timestamp + 1 days;
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.OnlyUsdtAllowed.selector);
        escrow.CreateEscrow(
            "ipfs://d",
            bob,
            address(0xBEEF),
            1_000_000,
            DEFAULT_FEE_PPM,
            deadline,
            EscrowPayment.DisputeType.RegularDispute
        );
    }

    function test_CreateEscrow_RevertsWhenAmountAndFeeZero() public {
        uint256 deadline = block.timestamp + 1 days;
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.ZeroAmount.selector);
        escrow.CreateEscrow(
            "ipfs://d",
            bob,
            address(usdt),
            0,
            0,
            deadline,
            EscrowPayment.DisputeType.RegularDispute
        );
    }

    function test_CreateEscrow_TransfersPlatformFeeAndLocksFunds() public {
        uint256 amount = 10_000_000; // 10 USDT
        uint256 deadline = block.timestamp + 2 days;
        uint256 platformFee = (amount * PLATFORM_FEE_PPM) / PPM;

        usdt.mint(alice, amount + platformFee);
        vm.prank(alice);
        usdt.approve(address(escrow), amount + platformFee);

        vm.prank(alice);
        escrow.CreateEscrow(
            "ipfs://d",
            bob,
            address(usdt),
            amount,
            DEFAULT_FEE_PPM,
            deadline,
            EscrowPayment.DisputeType.MiniDispute
        );

        assertEq(usdt.balanceOf(address(escrow)), amount);
        assertEq(usdt.balanceOf(feeWallet), platformFee);
        assertEq(escrow.escrowId(), 1);
    }

    function test_AcceptEscrow_OnlyToAddressAndNotExpired() public {
        uint256 id = _createEscrow(1_000_000, 10_000, block.timestamp + 1 days);

        // wrong caller
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.AcceptEscrow(id);

        // ok caller
        _accept(id);

        // cannot accept twice
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.OnlyCreatedOneAreAllowed.selector);
        escrow.AcceptEscrow(id);

        // new escrow expired cannot accept
        uint256 id2 = _createEscrow(
            1_000_000,
            10_000,
            block.timestamp + 1 days
        );
        vm.warp(block.timestamp + 2 days);
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.EscrowExpired.selector);
        escrow.AcceptEscrow(id2);
    }

    function test_Submit_AllowsAcceptedAndSubmittedBlocksOthers() public {
        uint256 nowTs = block.timestamp;
        uint256 deadline = nowTs + 7 days;
        uint256 amount = 1_000_000; // 1 USDT (6 decimals)
        uint256 id1 = _createEscrow(amount, 50_000, deadline); // 5%

        // Created -> submit should revert
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.OnlyAcceptedOneAreAllowed.selector);
        escrow.SubmitEscrow(id1, "ipfs://sub1");

        // Accept and submit -> allowed
        _accept(id1);
        vm.prank(bob);
        escrow.SubmitEscrow(id1, "ipfs://sub2");

        // Re-submit while already Submitted -> allowed (before deadline)
        vm.prank(bob);
        escrow.SubmitEscrow(id1, "ipfs://sub3");
    }

    function test_Submit_BlocksPastDeadline() public {
        uint256 nowTs = block.timestamp;
        uint256 deadline = nowTs + 3 days;
        uint256 id = _createEscrow(2_000_000, DEFAULT_FEE_PPM, deadline);
        _accept(id);

        vm.warp(deadline + 1);
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.EscrowExpired.selector);
        escrow.SubmitEscrow(id, "ipfs://late");
    }

    function test_Submit_OnlyToAddressCanSubmit() public {
        uint256 id = _createEscrow(
            2_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 5 days
        );
        _accept(id);

        address eve = makeAddr("eve");
        vm.prank(eve);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.SubmitEscrow(id, "ipfs://proof");
    }

    function test_Submit_AtDeadline_Allows() public {
        uint256 nowTs = block.timestamp;
        uint256 deadline = nowTs + 2 days;
        uint256 id = _createEscrow(2_000_000, DEFAULT_FEE_PPM, deadline);
        _accept(id);

        // jump exactly to deadline
        vm.warp(deadline);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://on-deadline");
    }

    function test_Submit_RevertsAfterReleaseOrRefund() public {
        // Release path
        uint256 id1 = _createEscrow(
            1_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 3 days
        );
        _accept(id1);
        vm.prank(bob);
        escrow.SubmitEscrow(id1, "ipfs://work");
        vm.prank(alice);
        escrow.ReleaseEscrow(id1);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.OnlyAcceptedOneAreAllowed.selector);
        escrow.SubmitEscrow(id1, "ipfs://after-release");

        // Refund path
        uint256 id2 = _createEscrow(
            1_500_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 10 days
        );
        vm.prank(alice);
        escrow.RefundEscrow(id2);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.OnlyAcceptedOneAreAllowed.selector);
        escrow.SubmitEscrow(id2, "ipfs://after-refund");
    }

    function test_Submit_OnlyToAddressCanResubmitWhenSubmitted() public {
        uint256 id = _createEscrow(
            2_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 5 days
        );
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://first");

        address eve = makeAddr("eve");
        vm.prank(eve);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.SubmitEscrow(id, "ipfs://second");
    }

    function test_Refund_Created_Instant() public {
        uint256 amount = 5_000_000; // 5 USDT
        uint256 deadline = block.timestamp + 10 days;
        uint256 id = _createEscrow(amount, DEFAULT_FEE_PPM, deadline);

        uint256 platformFee = (amount * PLATFORM_FEE_PPM) / PPM;
        // balances after creation
        assertEq(usdt.balanceOf(address(escrow)), amount);
        assertEq(usdt.balanceOf(feeWallet), platformFee);

        // refund by alice
        vm.prank(alice);
        escrow.RefundEscrow(id);

        assertEq(usdt.balanceOf(address(escrow)), 0);
        assertEq(usdt.balanceOf(alice), amount); // got principal back
    }

    function test_Refund_Accepted_BeforeDeadline_Reverts() public {
        uint256 id = _createEscrow(
            3_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 4 days
        );
        _accept(id);

        vm.prank(alice);
        vm.expectRevert(EscrowPayment.EscrowNotExpiredYet.selector);
        escrow.RefundEscrow(id);
    }

    function test_Refund_Accepted_AfterDeadline_Allows() public {
        uint256 amount = 3_500_000;
        uint256 deadline = block.timestamp + 2 days;
        uint256 id = _createEscrow(amount, DEFAULT_FEE_PPM, deadline);
        _accept(id);

        vm.warp(deadline + 1);
        vm.prank(alice);
        escrow.RefundEscrow(id);

        assertEq(usdt.balanceOf(alice), amount);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }

    function test_Refund_Submitted_Reverts() public {
        uint256 id = _createEscrow(
            2_500_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 5 days
        );
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://done");

        vm.prank(alice);
        vm.expectRevert(EscrowPayment.RefundNotAllowed.selector);
        escrow.RefundEscrow(id);
    }

    function test_Refund_OnlyFromAddressCanRefund() public {
        uint256 id = _createEscrow(
            2_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 5 days
        );
        // bob tries to refund
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.RefundEscrow(id);
    }

    function test_Refund_Accepted_AtDeadline_Allows() public {
        uint256 deadline = block.timestamp + 2 days;
        uint256 amount = 3_000_000;
        uint256 id = _createEscrow(amount, DEFAULT_FEE_PPM, deadline);
        _accept(id);

        // at exact deadline it should allow refund
        vm.warp(deadline);
        vm.prank(alice);
        escrow.RefundEscrow(id);
        assertEq(usdt.balanceOf(alice), amount);
    }

    function test_Refund_AfterReleased_Reverts() public {
        uint256 id = _createEscrow(
            1_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 3 days
        );
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://work");
        vm.prank(alice);
        escrow.ReleaseEscrow(id);

        vm.prank(alice);
        vm.expectRevert(EscrowPayment.RefundNotAllowed.selector);
        escrow.RefundEscrow(id);
    }

    function test_Release_OnlyFromAddressAndSubmittedAndPayouts() public {
        uint256 amount = 20_000_000; // 20 USDT
        uint256 deadline = block.timestamp + 3 days;
        uint256 feePpm = 50_000; // 5%
        uint256 id = _createEscrow(amount, feePpm, deadline);

        // accept and submit by bob
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://work");

        uint256 burnFee = (amount * feePpm) / PPM; // 5%
        uint256 toBob = amount - burnFee;

        // wrong caller cannot release
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.ReleaseEscrow(id);

        // release by alice
        vm.prank(alice);
        escrow.ReleaseEscrow(id);

        assertEq(usdt.balanceOf(swapAndBurn), burnFee);
        assertEq(usdt.balanceOf(bob), toBob);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }

    function test_Release_RevertsIfNotSubmitted() public {
        uint256 id = _createEscrow(1_000_000, 10_000, block.timestamp + 5 days);
        // not submitted yet
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.OnlySubmittedOneAreAllowed.selector);
        escrow.ReleaseEscrow(id);
    }

    function test_Release_SplitsWhenNonZeroFee() public {
        uint256 amount = 4_200_000; // 4.2 USDT
        uint256 feePpm = 12_345; // 1.2345%
        uint256 id = _createEscrow(amount, feePpm, block.timestamp + 5 days);
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://work");

        vm.prank(alice);
        escrow.ReleaseEscrow(id);

        uint256 burnFee = (amount * feePpm) / PPM;
        uint256 toBob = amount - burnFee;
        assertEq(usdt.balanceOf(swapAndBurn), burnFee);
        assertEq(usdt.balanceOf(bob), toBob);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }

    function test_Release_RevertsSecondTime() public {
        uint256 id = _createEscrow(
            1_000_000,
            100_000,
            block.timestamp + 5 days
        ); // 10%
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://work");
        vm.prank(alice);
        escrow.ReleaseEscrow(id);

        // second release should revert due to status not Submitted
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.OnlySubmittedOneAreAllowed.selector);
        escrow.ReleaseEscrow(id);
    }

    // ===== AI Dispute tests =====
    function test_AIDispute_CreateOnlyResponderAndAllowedWhenSubmittedOrDenied()
        public
    {
        uint256 id = _createEscrow(
            2_000_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 5 days
        );
        _accept(id);
        _submit(id, "ipfs://art");

        // fund and approve resolver fee for bob (responder)
        usdt.mint(bob, RESOLVER_FEE);
        vm.prank(bob);
        usdt.approve(address(escrow), RESOLVER_FEE);

        // creator cannot create AI dispute
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.createAIDispute(id, RESOLVER_FEE);

        // responder can create when Submitted
        vm.prank(bob);
        escrow.createAIDispute(id, RESOLVER_FEE);

        // set back to Submitted (simulate restart) and Deny then allow AI dispute
        // For a fresh escrow
        uint256 id2 = _createEscrow(
            2_500_000,
            DEFAULT_FEE_PPM,
            block.timestamp + 6 days
        );
        _accept(id2);
        _submit(id2, "ipfs://b");
        vm.prank(alice);
        escrow.DenyEscrow(id2);
        usdt.mint(bob, RESOLVER_FEE);
        vm.prank(bob);
        usdt.approve(address(escrow), RESOLVER_FEE);
        vm.prank(bob);
        escrow.createAIDispute(id2, RESOLVER_FEE);
    }

    function test_AIDispute_ClaimAfterAppealWindowPaysWinner() public {
        uint256 amount = 9_000_000;
        uint256 feePpm = 40_000; // 4%
        uint256 id = _createEscrow(amount, feePpm, block.timestamp + 4 days);
        _accept(id);
        _submit(id, "ipfs://job");

        // responder opens AI dispute
        usdt.mint(bob, RESOLVER_FEE);
        vm.prank(bob);
        usdt.approve(address(escrow), RESOLVER_FEE);
        vm.prank(bob);
        escrow.createAIDispute(id, RESOLVER_FEE);

        // resolver sets winner as responder
        vm.prank(resolverAI);
        escrow.resolveViaAI(id, bob);

        // cannot claim before appeal time
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.AppealTimeNotPassedYet.selector);
        escrow.claimAIDispute(id);

        // pass appeal window, then claim; fee split applied
        vm.warp(block.timestamp + 1 hours);
        vm.prank(bob);
        escrow.claimAIDispute(id);

        uint256 fee = (amount * feePpm) / PPM;
        assertEq(usdt.balanceOf(swapAndBurn), fee);
        assertEq(usdt.balanceOf(bob), amount - fee);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }
}
