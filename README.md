## EscrowPayment Contract Flows

### Participants

- **Creator (`fromAddress`)**: Funds the escrow and decides whether the work is accepted, denied, or refunded.
- **Provider (`toAddress`)**: Accepts the job, submits deliverables, and can dispute a denial or claim payment.
- **Resolver AI (`resolverAI`)**: Handles automated dispute resolution once funded with the resolver fee.
- **Oracle Network (`ITomiDispute`)**: Provides community arbitration when an appeal or manual dispute is opened.
- **Fee Wallet & Swap/Burn Contract**: Receive platform and performance fees deducted during release.

### Status Reference

`Created → Accepted → Submitted → (Released | Denied | Refunded) → Dispute States`

Escrows can move into `InDisputeAI`, `ResolvedAI`, or `InDisputeOracle` when disputes are opened. Refund/Release outcomes repeat depending on the dispute winner.

### Timing Reference

- `submissionDeadline` (set at creation) defines when the provider must submit work; any submission or acceptance action after this timestamp reverts.
- `resultTime` is recorded on release or denial and anchors downstream timers.
- `DENIED_REFUND_TIME` = 72 hours. After a denial, creator-triggered refunds stay locked until this window elapses without a dispute.
- `APPEAL_TIME_DISPUTE_AI` = 30 minutes. After AI resolution, the loser must appeal to the oracle before this timer expires.
- When an escrow is accepted but not submitted, refunds only unlock once `block.timestamp` surpasses `submissionDeadline`.

### USDT Amount Reference

- Token amounts use 6 decimals (`1 USDT = 1e6`).
- Platform fee `escrowPlatformFee` = 10,000 ppm (1%). Collected up-front and forwarded to `feeWallet`.
- Dynamic performance fee `feeinPPM` is set per escrow and charged on release or dispute win.
- Resolver AI fee (`resolverFeeAI`) is set during initialization and must be prep-paid in USDT before an AI dispute starts.
- Oracle loyalty fees: 5,000 ppm (0.5%) for Mini disputes, 2,500 ppm (0.25%) for Regular disputes.
- Minimum disputed amount: Mini ≥ 15 USDT, Regular ≥ 400 USDT (checked against USDT's 6 decimals).

### Create & Fund Flow

1. Creator calls `CreateEscrow` with job metadata, token amount, deadline, fee PPM, and dispute type.
2. Contract validates the deadline, token (USDT only), and fee range, then increments `escrowId`.
3. Creator transfers the deal size plus a 1% platform fee (amount × 10,000 ppm); that USDT fee is forwarded immediately to `feeWallet`.
4. Escrow record is stored with status `Created` and `EscrowCreated` is emitted.

### Acceptance Flow

1. Provider reviews the deal off-chain and calls `AcceptEscrow` before `submissionDeadline`.
2. Caller must match `toAddress` and status must be `Created`.
3. Status transitions to `Accepted` and `EscrowAccepted` is emitted.

### Submission Flow

1. Provider delivers work via `SubmitEscrow`, attaching a `submissionURI` (hosted proof of work).
2. Status must be `Accepted` (or already `Submitted`) and `block.timestamp` must be before `submissionDeadline`.
3. Status becomes `Submitted` and `EscrowSubmitted` records the action.

### Release Flow (Happy Path)

1. Creator reviews the submission and calls `ReleaseEscrow`.
2. Only the creator can release, and status must be `Submitted`.
3. Contract timestamps `resultTime`, routes the performance fee (`tokenAmount × feeinPPM ÷ 1e6`) to `swapandBurnContract`, and sends the remainder to the provider. This `resultTime` starts the 72-hour denial refund clock if a later dispute flows back to denial.
4. Status moves to `Released` with `EscrowReleased` signaling the transfer details.

### Denial Flow

1. If work is unsatisfactory, the creator calls `DenyEscrow` while status is `Submitted`.
2. Result time is captured and status becomes `Denied`, starting the 72-hour refund lock (`DENIED_REFUND_TIME`).
3. Provider may refund (after 72h elapses with no dispute), open an AI dispute immediately, or escalate to the oracle.

### Refund Flow

- **Before Acceptance**: Creator can call `RefundEscrow` immediately while status is `Created`.
- **After Acceptance**: Creator can refund only after `submissionDeadline` passes with no submission (time drift is checked on-chain).
- **After Denial**: Refund is allowed once `resultTime + 72h` is reached and no dispute has been opened.
- **Blocked Cases**: Refunds revert if status is `Submitted`, `Released`, already `Refunded`, in AI/Oracle dispute, or within appeal windows.

### AI Dispute Flow

1. Provider funds the resolver fee in USDT and calls `createAIDispute` when status is `Submitted` or `Denied`.
2. The escrow status becomes `InDisputeAI`, resolver fee (≥ `resolverFeeAI` USDT) is transferred to `resolverAI`, and `DipsuteAICreated` is emitted.
3. `resolveAIDispute` (callable by `resolverAI`) records the winner, moves funds accordingly, and sets status to `ResolvedAI`, capturing `resolveTime` for appeal tracking.
4. Loser has 30 minutes (`APPEAL_TIME_DISPUTE_AI`) from `resolveTime` to escalate to the oracle via `CreateDispute`.
5. After the appeal window, winner (or creator if provider won) claims funds through `claimAIDispute` which releases or refunds and emits `AI_DisputeClaimed`.

### Oracle Dispute Flow

1. Either party calls `CreateDispute` while status is `Submitted`, `Denied`, or (if they lost AI) within the appeal window of `ResolvedAI`.
2. Caller supplies dispute amount (Mini ≥ 15 USDT, Regular ≥ 400 USDT) and ensures USDT allowance to `ITomiDispute`; oracle fee and loyalty fee are calculated from dispute type.
3. Underlying dispute contract (from `tomiDisputeAddress`) is instantiated via `createTomiDispute`, and escrow status becomes `InDisputeOracle` with `DisputeOracleCreated`.
4. Parties can add more evidence using `submitProofAgain` until the oracle network reveals a winner.
5. Once `ITomiDispute.calculateWinnerReadOnly` returns a winner, either party finalizes via `resolveDisputeOracle` using a signer-approved signature.
6. Funds are distributed: creator receives full refund if they win; provider receives amount minus fee sent to `swapandBurnContract` if they win. Emits `DisputeResolvedByOracle`.

### Administrative Updates

Owner-only setters (`updateFeeWallet`, `updateSwapAndBurnContract`, `updateTomiDisputeAddress`, `updateResolverAddress`, `updateResolverFee`) keep dependencies current. Each rejects zero addresses, unchanged values, or zero fees.

### Deployment Command : 
forge script script/FeeManager.s.sol \
  --rpc-url "$RPC_URL_ARB" \
  --private-key "$PRIVATE_KEY" \
  --broadcast --verify

Deployment Chain : Arbitrum 
Deployment Address For FeeManager : 
  feeManger implementation deployed at: 0x96f02Da4042F2234e2E887c90d6E17F504AB13B4
  feeManger proxy deployed at: 0x960623419543C60dFC316F1D15194E69Fbe4C364

forge script script/EscrowPayment.s.sol \
  --rpc-url "$RPC_URL_ARB" \
  --private-key "$PRIVATE_KEY" \
  --broadcast --verify

  escrowPayment implementation deployed at: 0xd378F9Ac772F1F608154861a39A3a8E28280d38f
  escrowPayment proxy deployed at: 0x9A5bf30a7681D4abb654f77e26Ab66d2fDF4A1CE

