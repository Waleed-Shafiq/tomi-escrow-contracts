// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EscrowPayment} from "../src/EscrowPayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockUSDT} from "./mocks/MockUSDT.sol";
import {MockTomiDispute} from "./mocks/MockTomiDispute.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract EscrowPaymentTest is Test {
    EscrowPayment public escrow;
    MockUSDT public usdt;
    MockTomiDispute public tomiDispute;

    address internal alice; // fromAddress
    address internal bob; // toAddress
    address internal feeWallet;
    address internal disputeAIfeeWallet;
    address internal swapAndBurn;
    address internal resolverAI;
    address internal signer;
    address internal owner;
    uint256 internal signerPk;

    uint256 internal constant PPM = 1_000_000;
    uint256 internal constant PLATFORM_FEE_PPM = 10_000; // 1%
    uint256 internal constant DEFAULT_FEE_PPM = 50_000; // 5%
    uint256 internal constant RESOLVER_FEE = 1e6; // 1 USDT
    uint256 internal constant MINI_DISPUTE_FEE_PPM = 5_000; // 0.5%
    uint256 internal constant REGULAR_DISPUTE_FEE_PPM = 2_500; // 0.25%
    uint256 internal constant MIN_MINI_DISPUTE_AMOUNT = 15 * 1e6;
    uint256 internal constant MIN_REGULAR_DISPUTE_AMOUNT = 400 * 1e6;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        owner = makeAddr("owner");
        feeWallet = makeAddr("feeWallet");
        swapAndBurn = makeAddr("swapAndBurn");
        resolverAI = makeAddr("resolverAI");
        disputeAIfeeWallet = makeAddr("disputeAIfeeWallet");
        signerPk = 0xBEEF;
        signer = vm.addr(signerPk);

        usdt = new MockUSDT();
        tomiDispute = new MockTomiDispute();

        escrow = new EscrowPayment();
        bytes memory escrowParams = abi.encodeWithSelector(
            EscrowPayment.Initialize.selector,
            owner,
            feeWallet,
            address(tomiDispute),
            address(usdt),
            resolverAI,
            signer,
            RESOLVER_FEE
        );

        ERC1967Proxy escrowPayProxy = new ERC1967Proxy(
            address(escrow),
            escrowParams
        );
        escrow = EscrowPayment(address(escrowPayProxy));
    }

    function _signAIResolution(
        uint256 escrowID,
        address winner,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                escrowID,
                winner,
                resolverAI,
                deadline,
                address(escrow)
            )
        );
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, ethHash);
        return abi.encodePacked(r, s, v);
    }

    function _signOracleResolution(
        uint256 escrowID,
        address caller,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(escrowID, caller, deadline, address(escrow))
        );
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, ethHash);
        return abi.encodePacked(r, s, v);
    }

    function _createEscrowWithType(
        uint256 amount,
        uint256 deadline,
        EscrowPayment.DisputeType disputeType
    ) internal returns (uint256 id) {
        uint256 platformFee = (amount * PLATFORM_FEE_PPM) / PPM;
        usdt.mint(alice, amount + platformFee);
        vm.prank(alice);
        usdt.approve(address(escrow), amount + platformFee);
        vm.prank(alice);
        escrow.CreateEscrow(
            "ipfs://details",
            bob,
            address(usdt),
            amount,
            deadline,
            disputeType
        );
        id = escrow.escrowId();
    }

    function _createEscrow(
        uint256 amount,
        uint256 deadline
    ) internal returns (uint256 id) {
        id = _createEscrowWithType(
            amount,
            deadline,
            EscrowPayment.DisputeType.RegularDispute
        );
    }

    function _accept(uint256 id) internal {
        vm.prank(bob);
        escrow.AcceptEscrow(id);
    }

    function _submit(uint256 id, string memory uri) internal {
        vm.prank(bob);
        escrow.SubmitEscrow(id, uri);
    }

    function _prepareAIDispute(
        uint256 amount,
        string memory submissionUri
    ) internal returns (uint256 id) {
        id = _createEscrow(amount, block.timestamp + 5 days);
        _accept(id);
        _submit(id, submissionUri);

        usdt.mint(bob, RESOLVER_FEE);
        vm.prank(bob);
        usdt.approve(address(escrow), RESOLVER_FEE);
        vm.prank(bob);
        escrow.CreateAIDispute(id, RESOLVER_FEE);
    }

    function _getEscrowStatus(
        uint256 id
    ) internal view returns (EscrowPayment.EscrowStatus) {
        EscrowPayment.EscrowStatus status;
        EscrowPayment.DisputeType disputeType;
        (, , , , , , , , , status, disputeType) = escrow.escrows(id);
        disputeType;
        return status;
    }

    function _getAIInfo(
        uint256 id
    ) internal view returns (EscrowPayment.EscrowAIDisputeInfo memory) {
        (uint256 storedId, uint256 resolveTime, address winner) = escrow
            .escrowtoDisputeAI(id);
        return
            EscrowPayment.EscrowAIDisputeInfo({
                escrowID: storedId,
                resolveTime: resolveTime,
                winnerAddress: winner
            });
    }

    function _computeOracleFees(
        uint256 amount,
        uint256 amountInUSD,
        EscrowPayment.DisputeType disputeType
    ) internal pure returns (uint256 oracleFee, uint256 loyaltyFee) {
        uint256 feeRate = disputeType == EscrowPayment.DisputeType.MiniDispute
            ? MINI_DISPUTE_FEE_PPM
            : REGULAR_DISPUTE_FEE_PPM;
        loyaltyFee = (amount * feeRate) / PPM;
        oracleFee = amountInUSD + loyaltyFee;
    }

    function _openOracleDispute(
        EscrowPayment.DisputeType disputeType,
        address initiator,
        uint256 amount,
        uint256 amountInUSD,
        string memory submissionUri
    ) internal returns (uint256 id, uint256 oracleFee, uint256 loyaltyFee) {
        id = _createEscrowWithType(
            amount,
            block.timestamp + 5 days,
            disputeType
        );
        _accept(id);
        _submit(id, submissionUri);

        (oracleFee, loyaltyFee) = _computeOracleFees(
            amount,
            amountInUSD,
            disputeType
        );

        usdt.mint(initiator, oracleFee);
        vm.prank(initiator);
        usdt.approve(address(tomiDispute), oracleFee);

        vm.prank(initiator);
        escrow.CreateDispute(id, amountInUSD);
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
            deadline,
            EscrowPayment.DisputeType.MiniDispute
        );

        assertEq(usdt.balanceOf(address(escrow)), amount);
        assertEq(usdt.balanceOf(feeWallet), platformFee);
        assertEq(escrow.escrowId(), 1);
    }

    function test_AcceptEscrow_OnlyToAddressAndNotExpired() public {
        uint256 id = _createEscrow(1_000_000, block.timestamp + 1 days);

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
        uint256 id2 = _createEscrow(1_000_000, block.timestamp + 1 days);
        vm.warp(block.timestamp + 2 days);
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.EscrowExpired.selector);
        escrow.AcceptEscrow(id2);
    }

    function test_Submit_AllowsAcceptedAndSubmittedBlocksOthers() public {
        uint256 nowTs = block.timestamp;
        uint256 deadline = nowTs + 7 days;
        uint256 amount = 1_000_000; // 1 USDT (6 decimals)
        uint256 id1 = _createEscrow(amount, deadline); // 5%

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
        uint256 id = _createEscrow(2_000_000, deadline);
        _accept(id);

        vm.warp(deadline + 1);
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.EscrowExpired.selector);
        escrow.SubmitEscrow(id, "ipfs://late");
    }

    function test_Submit_OnlyToAddressCanSubmit() public {
        uint256 id = _createEscrow(2_000_000, block.timestamp + 5 days);
        _accept(id);

        address eve = makeAddr("eve");
        vm.prank(eve);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.SubmitEscrow(id, "ipfs://proof");
    }

    function test_Submit_AtDeadline_Allows() public {
        uint256 nowTs = block.timestamp;
        uint256 deadline = nowTs + 2 days;
        uint256 id = _createEscrow(2_000_000, deadline);
        _accept(id);

        // jump exactly to deadline
        vm.warp(deadline);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://on-deadline");
    }

    function test_Submit_RevertsAfterReleaseOrRefund() public {
        // Release path
        uint256 id1 = _createEscrow(1_000_000, block.timestamp + 3 days);
        _accept(id1);
        vm.prank(bob);
        escrow.SubmitEscrow(id1, "ipfs://work");
        vm.prank(alice);
        escrow.ReleaseEscrow(id1);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.OnlyAcceptedOneAreAllowed.selector);
        escrow.SubmitEscrow(id1, "ipfs://after-release");

        // Refund path
        uint256 id2 = _createEscrow(1_500_000, block.timestamp + 10 days);
        vm.prank(alice);
        escrow.RefundEscrow(id2);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.OnlyAcceptedOneAreAllowed.selector);
        escrow.SubmitEscrow(id2, "ipfs://after-refund");
    }

    function test_Submit_OnlyToAddressCanResubmitWhenSubmitted() public {
        uint256 id = _createEscrow(2_000_000, block.timestamp + 5 days);
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
        uint256 id = _createEscrow(amount, deadline);

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
        uint256 id = _createEscrow(3_000_000, block.timestamp + 4 days);
        _accept(id);

        vm.prank(alice);
        vm.expectRevert(EscrowPayment.EscrowNotExpiredYet.selector);
        escrow.RefundEscrow(id);
    }

    function test_Refund_Accepted_AfterDeadline_Allows() public {
        uint256 amount = 3_500_000;
        uint256 deadline = block.timestamp + 2 days;
        uint256 id = _createEscrow(amount, deadline);
        _accept(id);

        vm.warp(deadline + 1);
        vm.prank(alice);
        escrow.RefundEscrow(id);

        assertEq(usdt.balanceOf(alice), amount);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }

    function test_Refund_Submitted_Reverts() public {
        uint256 id = _createEscrow(2_500_000, block.timestamp + 5 days);
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://done");

        vm.prank(alice);
        vm.expectRevert(EscrowPayment.RefundNotAllowed.selector);
        escrow.RefundEscrow(id);
    }

    function test_Refund_OnlyFromAddressCanRefund() public {
        uint256 id = _createEscrow(2_000_000, block.timestamp + 5 days);
        // bob tries to refund
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.RefundEscrow(id);
    }

    function test_Refund_Accepted_AtDeadline_Allows() public {
        uint256 deadline = block.timestamp + 2 days;
        uint256 amount = 3_000_000;
        uint256 id = _createEscrow(amount, deadline);
        _accept(id);

        // at exact deadline it should allow refund
        vm.warp(deadline);
        vm.prank(alice);
        escrow.RefundEscrow(id);
        assertEq(usdt.balanceOf(alice), amount);
    }

    function test_Refund_AfterReleased_Reverts() public {
        uint256 id = _createEscrow(1_000_000, block.timestamp + 3 days);
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
        uint256 id = _createEscrow(amount, deadline);

        // accept and submit by bob
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://work");

        uint256 toBob = amount;

        // wrong caller cannot release
        vm.prank(bob);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.ReleaseEscrow(id);

        // release by alice
        vm.prank(alice);
        escrow.ReleaseEscrow(id);
        assertEq(usdt.balanceOf(bob), toBob);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }

    function test_Release_RevertsIfNotSubmitted() public {
        uint256 id = _createEscrow(1_000_000, block.timestamp + 5 days);
        // not submitted yet
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.OnlySubmittedOneAreAllowed.selector);
        escrow.ReleaseEscrow(id);
    }

    function test_Release_SplitsWhenNonZeroFee() public {
        uint256 amount = 4_200_000; // 4.2 USDT
        uint256 id = _createEscrow(amount, block.timestamp + 5 days);
        _accept(id);
        vm.prank(bob);
        escrow.SubmitEscrow(id, "ipfs://work");

        vm.prank(alice);
        escrow.ReleaseEscrow(id);

        uint256 toBob = amount;

        assertEq(usdt.balanceOf(bob), toBob);
        assertEq(usdt.balanceOf(address(escrow)), 0);
    }

    function test_Release_RevertsSecondTime() public {
        uint256 id = _createEscrow(1_000_000, block.timestamp + 5 days); // 10%
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
        uint256 id = _createEscrow(2_000_000, block.timestamp + 5 days);
        _accept(id);
        _submit(id, "ipfs://art");

        vm.prank(owner);
        escrow.UpdateDisputeAiFeeWallet(disputeAIfeeWallet);

        // fund and approve resolver fee for bob (responder)
        usdt.mint(bob, RESOLVER_FEE);
        vm.prank(bob);
        usdt.approve(address(escrow), RESOLVER_FEE);

        // creator cannot create AI dispute
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.YouAreNotAuthorized.selector);
        escrow.CreateAIDispute(id, RESOLVER_FEE);

        uint256 balanceBefore = usdt.balanceOf(resolverAI);

        // responder can create when Submitted
        vm.prank(bob);
        escrow.CreateAIDispute(id, RESOLVER_FEE);
        assertEq(usdt.balanceOf(disputeAIfeeWallet), RESOLVER_FEE - 5e5);
        assertEq(usdt.balanceOf(resolverAI), balanceBefore + 5e5);

        // set back to Submitted (simulate restart) and Deny then allow AI dispute
        // For a fresh escrow
        uint256 id2 = _createEscrow(2_500_000, block.timestamp + 6 days);
        _accept(id2);
        _submit(id2, "ipfs://b");
        vm.prank(alice);
        escrow.DenyEscrow(id2);
        usdt.mint(bob, RESOLVER_FEE);
        vm.prank(bob);
        usdt.approve(address(escrow), RESOLVER_FEE);
        vm.prank(bob);
        escrow.CreateAIDispute(id2, RESOLVER_FEE);
    }

    function test_AIDispute_ResolveViaAIRequiresValidSignature() public {
        vm.prank(owner);
        escrow.UpdateDisputeAiFeeWallet(disputeAIfeeWallet);
        uint256 id = _prepareAIDispute(4_000_000, "ipfs://submission");

        uint256 deadline = block.timestamp + 1 hours;

        bytes32 messageHash = keccak256(
            abi.encodePacked(id, bob, resolverAI, deadline, address(escrow))
        );
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, ethHash);
        bytes memory invalidSig = abi.encodePacked(r, s, v);

        vm.prank(resolverAI);
        vm.expectRevert(EscrowPayment.InvalidSignature.selector);
        escrow.ResolveViaAI(id, bob, deadline, invalidSig);

        bytes memory validSig = _signAIResolution(id, bob, deadline);

        vm.prank(resolverAI);
        escrow.ResolveViaAI(id, bob, deadline, validSig);

        EscrowPayment.EscrowStatus status = _getEscrowStatus(id);
        assertEq(
            uint256(status),
            uint256(EscrowPayment.EscrowStatus.ResolvedAI)
        );

        EscrowPayment.EscrowAIDisputeInfo memory info = _getAIInfo(id);
        assertEq(info.winnerAddress, bob);
        assertTrue(info.resolveTime != 0);
        assertFalse(escrow.escrowIDtoAIDispute(id));
    }

    function test_AIDispute_ClaimBeforeAppealWindowReverts() public {
        vm.prank(owner);
        escrow.UpdateDisputeAiFeeWallet(disputeAIfeeWallet);
        uint256 id = _prepareAIDispute(5_000_000, "ipfs://sub");

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signAIResolution(id, bob, deadline);

        vm.prank(resolverAI);
        escrow.ResolveViaAI(id, bob, deadline, sig);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.AppealTimeNotPassedYet.selector);
        escrow.ClaimAIDispute(id);
    }

    function test_AIDispute_ClaimAfterAppealWindowPaysResponder() public {
        vm.prank(owner);
        escrow.UpdateDisputeAiFeeWallet(disputeAIfeeWallet);
        uint256 amount = 9_000_000;
        uint256 id = _prepareAIDispute(amount, "ipfs://job");

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signAIResolution(id, bob, deadline);

        vm.prank(resolverAI);
        escrow.ResolveViaAI(id, bob, deadline, sig);

        EscrowPayment.EscrowAIDisputeInfo memory info = _getAIInfo(id);

        vm.warp(info.resolveTime + escrow.APPEAL_TIME_DISPUTE_AI() + 1);

        vm.prank(bob);
        escrow.ClaimAIDispute(id);

        assertEq(usdt.balanceOf(bob), amount);
        assertEq(usdt.balanceOf(address(escrow)), 0);

        EscrowPayment.EscrowStatus status = _getEscrowStatus(id);
        assertEq(uint256(status), uint256(EscrowPayment.EscrowStatus.Released));
    }

    function test_AIDispute_ClaimAfterAppealRefundsCreatorWhenAIWinner()
        public
    {
        vm.prank(owner);
        escrow.UpdateDisputeAiFeeWallet(disputeAIfeeWallet);

        uint256 amount = 7_500_000;
        uint256 id = _prepareAIDispute(amount, "ipfs://design");

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signAIResolution(id, alice, deadline);

        vm.prank(resolverAI);
        escrow.ResolveViaAI(id, alice, deadline, sig);

        EscrowPayment.EscrowAIDisputeInfo memory info = _getAIInfo(id);

        vm.warp(info.resolveTime + escrow.APPEAL_TIME_DISPUTE_AI() + 1);

        uint256 aliceBalanceBefore = usdt.balanceOf(alice);

        vm.prank(alice);
        escrow.ClaimAIDispute(id);

        assertEq(usdt.balanceOf(alice), aliceBalanceBefore + amount);
        assertEq(usdt.balanceOf(address(escrow)), 0);

        EscrowPayment.EscrowStatus status = _getEscrowStatus(id);
        assertEq(uint256(status), uint256(EscrowPayment.EscrowStatus.Refunded));
    }

    // ===== Oracle dispute tests =====
    function test_OracleDispute_CreateDisputeSetsStateAndLoyaltyFee() public {
        uint256 amount = 8_000_000;
        uint256 amountInUSD = MIN_MINI_DISPUTE_AMOUNT + 5 * 1e6;

        vm.prank(owner);
        escrow.UpdateOracleDisputeStatus(true);

        (
            uint256 id,
            uint256 oracleFee,
            uint256 loyaltyFee
        ) = _openOracleDispute(
                EscrowPayment.DisputeType.MiniDispute,
                bob,
                amount,
                amountInUSD,
                "ipfs://mini"
            );

        (
            address disputeAddress,
            address winner,
            EscrowPayment.DisputeStatus status
        ) = escrow.escrowtoDisputeOracle(id);

        assertEq(disputeAddress, address(tomiDispute));
        assertEq(winner, address(0));
        assertEq(
            uint256(status),
            uint256(EscrowPayment.DisputeStatus.InVoting)
        );

        assertEq(tomiDispute.lastDisputeCreator(), bob);
        assertEq(tomiDispute.lastDisputedAddress(), alice);
        assertEq(tomiDispute.lastLoyaltyFee(), loyaltyFee);
        uint256 expectedLoyalty = (amount * MINI_DISPUTE_FEE_PPM) / PPM;
        assertEq(loyaltyFee, expectedLoyalty);
        assertEq(oracleFee, amountInUSD + expectedLoyalty);
        assertEq(usdt.allowance(bob, address(tomiDispute)), oracleFee);

        EscrowPayment.EscrowStatus escrowStatus = _getEscrowStatus(id);
        assertEq(
            uint256(escrowStatus),
            uint256(EscrowPayment.EscrowStatus.InDisputeOracle)
        );
    }

    function test_OracleDispute_SubmitProofAgainRecordsProofAndBlocksAfterWinner()
        public
    {
        vm.prank(owner);
        escrow.UpdateOracleDisputeStatus(true);

        (uint256 id, , ) = _openOracleDispute(
            EscrowPayment.DisputeType.RegularDispute,
            bob,
            9_000_000,
            MIN_REGULAR_DISPUTE_AMOUNT,
            "ipfs://regular"
        );

        vm.prank(alice);
        escrow.SubmitProofAgain(id, "ipfs://proof1");
        assertEq(tomiDispute.lastProofSubmitter(), alice);
        assertEq(tomiDispute.lastProofURI(), "ipfs://proof1");

        vm.prank(bob);
        escrow.SubmitProofAgain(id, "ipfs://proof2");
        assertEq(tomiDispute.lastProofSubmitter(), bob);
        assertEq(tomiDispute.lastProofURI(), "ipfs://proof2");

        tomiDispute.setWinner(bob);

        vm.prank(alice);
        vm.expectRevert(EscrowPayment.WinnnerRevealed.selector);
        escrow.SubmitProofAgain(id, "ipfs://proof3");
    }

    function test_OracleDispute_ResolveViaOracleRequiresValidSignature()
        public
    {
        vm.prank(owner);
        escrow.UpdateOracleDisputeStatus(true);

        uint256 amount = 10_000_000;
        (uint256 id, , ) = _openOracleDispute(
            EscrowPayment.DisputeType.RegularDispute,
            bob,
            amount,
            MIN_REGULAR_DISPUTE_AMOUNT + 50 * 1e6,
            "ipfs://regular-resolve"
        );

        tomiDispute.setWinner(bob);

        uint256 deadline = block.timestamp + 2 hours;

        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(id, alice, deadline, address(escrow))
            );
            bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(
                messageHash
            );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, ethHash);
            bytes memory badSig = abi.encodePacked(r, s, v);

            vm.prank(alice);
            vm.expectRevert(EscrowPayment.InvalidSignature.selector);
            escrow.ResolveDisputeOracle(id, deadline, badSig);
        }

        bytes memory sig = _signOracleResolution(id, alice, deadline);

        uint256 bobBalanceBefore = usdt.balanceOf(bob);
        vm.prank(alice);
        escrow.ResolveDisputeOracle(id, deadline, sig);

        EscrowPayment.EscrowStatus status = _getEscrowStatus(id);
        assertEq(uint256(status), uint256(EscrowPayment.EscrowStatus.Released));

        address disputeAddress;
        address winner;
        EscrowPayment.DisputeStatus disputeStatus;
        (disputeAddress, winner, disputeStatus) = escrow.escrowtoDisputeOracle(
            id
        );
        assertEq(disputeAddress, address(tomiDispute));
        assertEq(winner, bob);
        assertEq(
            uint256(disputeStatus),
            uint256(EscrowPayment.DisputeStatus.Resolved)
        );
        assertEq(usdt.balanceOf(bob), bobBalanceBefore + amount);
        vm.prank(alice);
        vm.expectRevert(EscrowPayment.SignatureUsed.selector);
        escrow.ResolveDisputeOracle(id, deadline, sig);
    }

    function test_OracleDispute_ResolveViaOracleRefundsCreatorWhenWinner()
        public
    {
        vm.prank(owner);
        escrow.UpdateOracleDisputeStatus(true);

        uint256 amount = 6_000_000;
        (uint256 id, , ) = _openOracleDispute(
            EscrowPayment.DisputeType.RegularDispute,
            alice,
            amount,
            MIN_REGULAR_DISPUTE_AMOUNT + 10 * 1e6,
            "ipfs://creator"
        );

        tomiDispute.setWinner(alice);

        uint256 deadline = block.timestamp + 90 minutes;
        bytes memory sig = _signOracleResolution(id, alice, deadline);

        uint256 aliceBalanceBefore = usdt.balanceOf(alice);

        vm.prank(alice);
        escrow.ResolveDisputeOracle(id, deadline, sig);

        EscrowPayment.EscrowStatus status = _getEscrowStatus(id);
        assertEq(uint256(status), uint256(EscrowPayment.EscrowStatus.Refunded));

        assertEq(usdt.balanceOf(alice), aliceBalanceBefore + amount);
        assertEq(usdt.balanceOf(swapAndBurn), 0);

        address disputeAddress;
        address winner;
        EscrowPayment.DisputeStatus disputeStatus;
        (disputeAddress, winner, disputeStatus) = escrow.escrowtoDisputeOracle(
            id
        );
        assertEq(disputeAddress, address(tomiDispute));
        assertEq(winner, alice);
        assertEq(
            uint256(disputeStatus),
            uint256(EscrowPayment.DisputeStatus.Resolved)
        );
    }

    function test_OracleDispute_CreateDisputeRequiresAllowance() public {
        uint256 amount = 7_000_000;
        uint256 deadline = block.timestamp + 4 days;
        uint256 id = _createEscrowWithType(
            amount,
            deadline,
            EscrowPayment.DisputeType.RegularDispute
        );
        _accept(id);
        _submit(id, "ipfs://allowance");

        vm.prank(owner);
        escrow.UpdateOracleDisputeStatus(true);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.InsufficientAllowance.selector);
        escrow.CreateDispute(id, MIN_REGULAR_DISPUTE_AMOUNT);

        uint256 oracleFee = MIN_REGULAR_DISPUTE_AMOUNT +
            (amount * REGULAR_DISPUTE_FEE_PPM) /
            PPM;
        usdt.mint(bob, oracleFee);
        vm.prank(bob);
        usdt.approve(address(tomiDispute), oracleFee - 1);

        vm.prank(bob);
        vm.expectRevert(EscrowPayment.InsufficientAllowance.selector);
        escrow.CreateDispute(id, MIN_REGULAR_DISPUTE_AMOUNT);
    }
}
