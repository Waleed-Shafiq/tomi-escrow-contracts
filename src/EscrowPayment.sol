// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITomiDispute} from "./Interfaces/ITomiDispute.sol";

contract EscrowPayment is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             State Varaibles                        ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    using SafeERC20 for IERC20;
    ITomiDispute public tomiDisputeAddress;

    address public feeWallet;
    address public swapandBurnContract;
    address public usdtToken;
    address public resolverAI;
    address public signer;

    uint256 public escrowId;
    uint256 public resolverFeeAI;
    uint256 public totalEscrowFeeCollected;

    uint256 public constant PPM = 1_000_000; //100 %
    uint256 public constant escrowPlatformFee = 10_000; //1%
    uint256 public constant regularDisputeDealSizeFee = 2_500; //0.25%
    uint256 public constant miniDisputeDealSizeFee = 5_000; //0.5%
    uint256 public constant DENIED_REFUND_TIME = 72 hours; // 72 Hours
    uint256 public constant APPEAL_TIME_DISPUTE_AI = 30 minutes; // 30 Mints

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Structs                                ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    struct Escrow {
        string escrowDetialsURI;
        string submissionURI;
        address fromAddress;
        address toAddress;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 feeinPPM;
        uint256 submissionDeadline;
        uint256 resultTime; // the timestamp of response of the creator
        EscrowStatus status;
        DisputeType disputeType;
    }

    struct EscrowDisputeInfo {
        address disputeContract;
        address winnerAddress;
        DisputeStatus status;
    }

    struct EscrowAIDisputeInfo {
        uint256 escrowID;
        uint256 resolveTime;
        address winnerAddress;
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Enums                                  ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    enum DisputeType {
        MiniDispute,
        RegularDispute
    }

    enum EscrowStatus {
        Created,
        Accepted,
        Submitted,
        Released,
        Denied,
        Refunded,
        InDisputeAI,
        ResolvedAI,
        InDisputeOracle
    }

    enum DisputeStatus {
        InVoting,
        Resolved,
        Refunded
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Errors                                 ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    error YouAreNotAuthorized();
    error InDispute();
    error InvalidDisputeType();
    error InvalidFee();
    error InsufficientAllowance();
    error ZeroAddress();
    error ZeroAmount();
    error NotInDispute();
    error InvalidTime();
    error OnlyCreatedOneAreAllowed();
    error OnlySubmittedOneAreAllowed();
    error OnlyAcceptedOneAreAllowed();
    error EscrowExpired();
    error EscrowNotExpiredYet();
    error OnlyUsdtAllowed();
    error WinnnerNotRevealedYet();
    error WinnnerRevealed();
    error SameAsLastOne();
    error RefundNotAllowed();
    error AppealTimeNotPassedYet();
    error InvalidResponse();
    error AppealWindowOver();
    error SignExpired();
    error InvalidSignature();
    error SignatureUsed();

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Events                                 ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    event EscrowCreated(Escrow escrowdetails, uint256 escrowFee);
    event EscrowAccepted(uint256 escrowId, EscrowStatus escrowIdStatus);
    event EscrowRefunded(uint256 escrowId, EscrowStatus escrowIdStatus);
    event EscrowSubmitted(uint256 escrowId, EscrowStatus escrowIdStatus);
    event EscrowDenied(uint256 escrowId, EscrowStatus escrowIdStatus);
    event EscrowReleased(
        uint256 escrowId,
        EscrowStatus escrowIdStatus,
        uint256 amountReleased,
        uint256 feeForSwapandBurn
    );
    event DipsuteAICreated(uint256 escrowID, address disputerAddress);
    event DisputeOracleCreated(uint256 escrowID, address disputerAddress);
    event DisputeResolvedByAI(
        uint256 escrowID,
        address winnerAddress,
        uint256 timeStamp
    );
    event DisputeResolvedByOracle(
        uint256 escrowID,
        address disputeContract,
        address winnerAddress,
        uint256 timeStamp
    );

    event AI_DisputeClaimed(uint256 escrowId, EscrowStatus escrowIdStatus);
    event ProofSubmitted(
        uint256 escrowId,
        address disputeContract,
        address submittedBy,
        string proofURI
    );

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Mappings                               ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    mapping(bytes => bool) public signatureUsed;
    mapping(uint256 escrowID => Escrow escrow) public escrows;
    mapping(uint256 escrowID => bool created) public escrowIDtoAIDispute;
    mapping(uint256 escrowID => EscrowAIDisputeInfo escrowDisputAI)
        public escrowtoDisputeAI;

    mapping(uint256 escrowID => EscrowDisputeInfo escrowDispute)
        public escrowtoDisputeOracle;

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Constructor                            ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Initializer                            ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    function Initialize(
        address feeWalletAddress,
        address swapandBurnContractAddress,
        address tomiDisputeaddress,
        address usdtAddress,
        address resolverAIAddress,
        address signerAddress,
        uint256 resolverFeeAmount
    ) external initializer {
        if (
            feeWalletAddress == address(0) ||
            swapandBurnContractAddress == address(0) ||
            tomiDisputeaddress == address(0) ||
            usdtAddress == address(0) ||
            resolverAIAddress == address(0) || 
            signerAddress == address(0)
        ) {
            revert ZeroAddress();
        }

        if (resolverFeeAmount == 0) {
            revert ZeroAmount();
        }

        __Ownable_init(msg.sender); //will update this to owner param
        __UUPSUpgradeable_init();

        swapandBurnContract = swapandBurnContractAddress;
        feeWallet = feeWalletAddress;
        tomiDisputeAddress = ITomiDispute(tomiDisputeaddress);
        usdtToken = usdtAddress;
        resolverAI = resolverAIAddress;
        resolverFeeAI = resolverFeeAmount;
        signer = signerAddress;
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                            Escrow Functions                        ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /**
     * @notice Creates a new escrow agreement with the specified parameters.
     * @dev This function allows a user to create an escrow contract with a recipient, token, and other details.
     *      The token is currently limited to USDT only.
     * @param detailsURI A URI pointing to the details of the escrow agreement.
     * @param toAddress The address of the recipient who will receive the funds upon successful completion.
     * @param tokenAddress The address of the token contract (currently limited to USDT).
     * @param amountInUSDT The amount of USDT tokens to be held in escrow.
     * @param feeinPPM The fee for the escrow service, specified in parts per million (PPM).
     * @param deadline The timestamp (in seconds) by which the escrow must be completed.
     * @param disputeType The type of dispute resolution mechanism to be used for this escrow.
     */
    function CreateEscrow(
        string memory detailsURI,
        address toAddress,
        address tokenAddress, // generic but limited to usdtToken only for now
        uint256 amountInUSDT,
        uint256 feeinPPM,
        uint256 deadline,
        DisputeType disputeType
    ) external {
        if (toAddress == address(0)) {
            revert ZeroAddress();
        }

        if (amountInUSDT == 0 || feeinPPM == 0 || feeinPPM > PPM) {
            revert ZeroAmount();
        }

        // Require a future deadline
        if (deadline <= block.timestamp) {
            revert InvalidTime();
        }

        if (
            disputeType != DisputeType.MiniDispute &&
            disputeType != DisputeType.RegularDispute
        ) {
            revert InvalidDisputeType();
        }

        if (tokenAddress != usdtToken) {
            revert OnlyUsdtAllowed();
        }

        escrowId++;

        escrows[escrowId] = Escrow({
            escrowDetialsURI: detailsURI,
            submissionURI: "",
            fromAddress: msg.sender,
            toAddress: toAddress,
            tokenAddress: tokenAddress,
            tokenAmount: amountInUSDT,
            feeinPPM: feeinPPM,
            submissionDeadline: deadline,
            resultTime: 0,
            status: EscrowStatus.Created,
            disputeType: disputeType
        });

        Escrow memory activeEscrow = escrows[escrowId];

        totalEscrowFeeCollected =
            totalEscrowFeeCollected +
            (amountInUSDT * escrowPlatformFee) /
            PPM;

        //transfer fee of the escrow + the amount in usdtToken to this address
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            (amountInUSDT + (amountInUSDT * escrowPlatformFee) / PPM)
        );

        //transfer fee to the escrow fee wallet
        IERC20(tokenAddress).safeTransfer(
            feeWallet,
            (amountInUSDT * escrowPlatformFee) / PPM
        );

        emit EscrowCreated({
            escrowdetails: activeEscrow,
            escrowFee: (amountInUSDT * escrowPlatformFee) / PPM
        });
    }

    /**
     * @notice Accepts an escrow agreement with the given escrow ID.
     * @dev This function allows a user to accept an existing escrow agreement.
     *      Ensure that the caller has the necessary permissions to accept the escrow.
     * @param escrowID The unique identifier of the escrow agreement to be accepted.
     */
    function AcceptEscrow(uint256 escrowID) external {
        Escrow storage activeEscrow = escrows[escrowID];

        if (activeEscrow.toAddress != msg.sender) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.Created) {
            revert OnlyCreatedOneAreAllowed();
        }

        if (activeEscrow.submissionDeadline < block.timestamp) {
            revert EscrowExpired();
        }

        activeEscrow.status = EscrowStatus.Accepted;
        emit EscrowAccepted({
            escrowId: escrowID,
            escrowIdStatus: activeEscrow.status
        });
    }

    /**
     * @notice Refunds an escrow agreement with the given escrow ID.
     * @dev This function allows the creator of the escrow to refund the funds if the escrow has expired.
     *      Ensure that the caller is the creator of the escrow and the escrow is in the correct state.
     * @param escrowID The unique identifier of the escrow agreement to be refunded.
     */
    function RefundEscrow(uint256 escrowID) external {
        Escrow storage activeEscrow = escrows[escrowID];

        if (activeEscrow.fromAddress != msg.sender) {
            revert YouAreNotAuthorized();
        }

        // If not accepted yet, allow instant refund
        if (activeEscrow.status == EscrowStatus.Created) {
            //proceed
        } else if (activeEscrow.status == EscrowStatus.Accepted) {
            // If accepted, only allow refund after deadline, and only if no submission was made
            if (block.timestamp < activeEscrow.submissionDeadline) {
                revert EscrowNotExpiredYet();
            }
        } else if (activeEscrow.status == EscrowStatus.InDisputeOracle) {
            revert InDispute();
        } else if (activeEscrow.status == EscrowStatus.Denied) {
            if (
                activeEscrow.resultTime + DENIED_REFUND_TIME > block.timestamp
            ) {
                revert AppealTimeNotPassedYet();
            }
        } else {
            // Submitted/Released/Refunded or any other state is not refundable
            revert RefundNotAllowed();
        }

        activeEscrow.status = EscrowStatus.Refunded;

        IERC20(activeEscrow.tokenAddress).safeTransfer(
            activeEscrow.fromAddress,
            activeEscrow.tokenAmount
        );

        emit EscrowRefunded({
            escrowId: escrowID,
            escrowIdStatus: activeEscrow.status
        });
    }

    /**
     * @notice Submits the details of an escrow identified by its ID.
     * @dev This function allows a user to submit a URI containing details
     *      or metadata related to the escrow.
     * @param escrowID The unique identifier of the escrow.
     * @param submissionURI The URI containing the submission details for the escrow.
     */
    function SubmitEscrow(
        uint256 escrowID,
        string memory submissionURI
    ) external {
        Escrow storage activeEscrow = escrows[escrowID];
        if (activeEscrow.toAddress != msg.sender) {
            revert YouAreNotAuthorized();
        }

        if (
            activeEscrow.status != EscrowStatus.Accepted &&
            activeEscrow.status != EscrowStatus.Submitted
        ) {
            revert OnlyAcceptedOneAreAllowed();
        }

        if (block.timestamp > activeEscrow.submissionDeadline) {
            revert EscrowExpired();
        }

        activeEscrow.submissionURI = submissionURI;
        activeEscrow.status = EscrowStatus.Submitted;

        emit EscrowSubmitted({
            escrowId: escrowID,
            escrowIdStatus: activeEscrow.status
        });
    }

    /**
     * @notice Release an escrow agreement with the given escrow ID.
     * @dev This function allows the creator of the escrow to Released the funds if the escrow has successful submission.
     *      Ensure that the caller is the creator of the escrow and the escrow is in the correct state.
     * @param escrowID The unique identifier of the escrow agreement to be refunded.
     */
    function ReleaseEscrow(uint256 escrowID) external {
        Escrow storage activeEscrow = escrows[escrowID];

        if (activeEscrow.fromAddress != msg.sender) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.Submitted) {
            revert OnlySubmittedOneAreAllowed();
        }

        activeEscrow.status = EscrowStatus.Released;
        activeEscrow.resultTime = block.timestamp;
        uint256 feeAmount = (activeEscrow.tokenAmount *
            (activeEscrow.feeinPPM)) / PPM;

        //Amount Paid to the  swap and burn contract,
        IERC20(activeEscrow.tokenAddress).safeTransfer(
            swapandBurnContract,
            feeAmount
        );

        IERC20(activeEscrow.tokenAddress).safeTransfer(
            activeEscrow.toAddress,
            (activeEscrow.tokenAmount - feeAmount)
        );

        emit EscrowReleased({
            escrowId: escrowID,
            escrowIdStatus: activeEscrow.status,
            amountReleased: (activeEscrow.tokenAmount - feeAmount),
            feeForSwapandBurn: feeAmount
        });
    }

    /**
     * @notice Denies an escrow transaction with the given escrow ID.
     * @dev This function allows the caller to deny an existing escrow transaction.
     *      Ensure that the caller has the appropriate permissions to deny the escrow.
     * @param escrowID The unique identifier of the escrow transaction to be denied.
     */
    function DenyEscrow(uint256 escrowID) external {
        Escrow storage activeEscrow = escrows[escrowID];

        if (activeEscrow.fromAddress != msg.sender) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.Submitted) {
            revert OnlySubmittedOneAreAllowed();
        }

        activeEscrow.status = EscrowStatus.Denied;
        activeEscrow.resultTime = block.timestamp;

        emit EscrowDenied({
            escrowId: escrowID,
            escrowIdStatus: activeEscrow.status
        });
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                         AI Dispute Functions                       ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /**
     * @notice Creates an AI dispute for the specified escrow transaction.
     * @dev This function allows the caller to initiate a dispute for an escrow identified by `escrowID`.
     *      The dispute will be handled by an AI-based resolution mechanism.
     * @param escrowID The unique identifier of the escrow transaction for which the dispute is being created.
     */
    function createAIDispute(uint256 escrowID, uint256 resolverFee) external {
        Escrow storage activeEscrow = escrows[escrowID];

        // Only responder (toAddress) can create the AI dispute
        if (msg.sender != activeEscrow.toAddress) {
            revert YouAreNotAuthorized();
        }

        // Allow AI dispute when Submitted or Denied
        if (
            activeEscrow.status != EscrowStatus.Submitted &&
            activeEscrow.status != EscrowStatus.Denied
        ) {
            revert OnlySubmittedOneAreAllowed();
        }

        if (
            IERC20(usdtToken).allowance(msg.sender, address(this)) < resolverFee
        ) {
            revert InsufficientAllowance();
        }

        if (resolverFee < resolverFeeAI) {
            revert InvalidFee();
        }

        // transfer the resolver fee to the AI resolver as 1 USDT
        IERC20(usdtToken).safeTransferFrom(msg.sender, resolverAI, resolverFee);

        escrowIDtoAIDispute[escrowID] = true;
        activeEscrow.status = EscrowStatus.InDisputeAI;
        escrowtoDisputeAI[escrowID] = EscrowAIDisputeInfo({
            escrowID: escrowID,
            resolveTime: 0,
            winnerAddress: address(0)
        });

        emit DipsuteAICreated(escrowID, msg.sender);
    }

    /**
     * @notice Resolves an escrow dispute via AI for the specified escrow ID.
     * @dev This function is called by the AI resolver to determine the winner of the dispute.
     *      It verifies the signature, ensures the caller is the authorized AI resolver, and checks the escrow's dispute status.
     *      The winner is determined based on the provided address, and the escrow status is updated accordingly.
     * @param escrowID The unique identifier of the escrow transaction being resolved.
     * @param winnerAddress The address of the party determined to be the winner of the dispute.
     * @param deadline The timestamp by which the signature must be valid.
     * @param signature The cryptographic signature verifying the authenticity of the resolution.
     */
    function resolveViaAI(
        uint256 escrowID,
        address winnerAddress,
        uint256 deadline,
        bytes calldata signature
    ) external {
        if (block.timestamp > deadline) {
            revert SignExpired();
        }

        if (msg.sender != resolverAI) {
            revert YouAreNotAuthorized();
        }

        if (signatureUsed[signature]) {
            revert SignatureUsed();
        }

        signatureUsed[signature] = true;

        if (
            !_isValidSignature(
                signer,
                keccak256(
                    abi.encodePacked(
                        escrowID,
                        winnerAddress,
                        msg.sender,
                        deadline,
                        address(this)
                    )
                ),
                signature
            )
        ) {
            revert InvalidSignature();
        }

        Escrow storage activeEscrow = escrows[escrowID];

        if (
            escrowIDtoAIDispute[escrowID] != true &&
            activeEscrow.status != EscrowStatus.InDisputeAI
        ) {
            revert NotInDispute();
        }

        if (
            winnerAddress != activeEscrow.fromAddress &&
            winnerAddress != activeEscrow.toAddress
        ) {
            revert InvalidResponse();
        }

        EscrowAIDisputeInfo storage activeDispute = escrowtoDisputeAI[escrowID];

        activeDispute.winnerAddress = winnerAddress;
        activeDispute.resolveTime = block.timestamp;
        activeEscrow.status = EscrowStatus.ResolvedAI;
        escrowIDtoAIDispute[escrowID] = false;

        emit DisputeResolvedByAI({
            escrowID: escrowID,
            winnerAddress: winnerAddress,
            timeStamp: block.timestamp
        });
    }

    /**
     * @notice Claims the resolution of an AI dispute for the specified escrow ID.
     * @dev This function allows the winner of an AI-resolved dispute to claim their funds.
     *      The function ensures that the dispute has been resolved and the appeal time has passed.
     * @param escrowID The unique identifier of the escrow transaction being claimed.
     */
    function claimAIDispute(uint256 escrowID) external {
        Escrow storage activeEscrow = escrows[escrowID];

        // Allow either party to trigger the payout to the AI winner
        if (
            msg.sender != activeEscrow.fromAddress &&
            msg.sender != activeEscrow.toAddress
        ) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.ResolvedAI) {
            revert NotInDispute();
        }

        EscrowAIDisputeInfo memory activeDisputeAI = escrowtoDisputeAI[
            escrowID
        ];

        // Enforce appeal window: must be AFTER resolveTime + APPEAL_TIME
        if (
            block.timestamp <
            activeDisputeAI.resolveTime + APPEAL_TIME_DISPUTE_AI
        ) {
            revert AppealTimeNotPassedYet();
        }

        if (activeDisputeAI.winnerAddress == address(0)) {
            revert WinnnerNotRevealedYet();
        }

        if (activeDisputeAI.winnerAddress == activeEscrow.fromAddress) {
            activeEscrow.status = EscrowStatus.Refunded;
            IERC20(activeEscrow.tokenAddress).safeTransfer(
                activeDisputeAI.winnerAddress,
                (activeEscrow.tokenAmount)
            );
        } else if (activeDisputeAI.winnerAddress == activeEscrow.toAddress) {
            activeEscrow.status = EscrowStatus.Released;
            uint256 feeAmount = (activeEscrow.tokenAmount *
                activeEscrow.feeinPPM) / PPM;

            IERC20(activeEscrow.tokenAddress).safeTransfer(
                swapandBurnContract,
                feeAmount
            );

            IERC20(activeEscrow.tokenAddress).safeTransfer(
                activeDisputeAI.winnerAddress,
                (activeEscrow.tokenAmount - feeAmount)
            );
        }

        emit AI_DisputeClaimed({
            escrowId: escrowID,
            escrowIdStatus: activeEscrow.status
        });
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                        Dispute Functions                           ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /**
     * @notice Creates a dispute for a specific escrow transaction.
     * @dev This function allows a user to initiate a dispute for an escrow transaction
     *      by providing the escrow ID and the disputed amount in USD.
     * @param escrowID The unique identifier of the escrow transaction to dispute.
     * @param amountinUSD The amount in USD that is being disputed.
     */
    function CreateDispute(uint256 escrowID, uint256 amountinUSD) external {
        Escrow storage activeEscrow = escrows[escrowID];

        if (
            activeEscrow.fromAddress != msg.sender &&
            activeEscrow.toAddress != msg.sender
        ) {
            revert YouAreNotAuthorized();
        }

        // Allow Submitted/Denied directly, or ResolvedAI within appeal window by AI loser
        if (
            activeEscrow.status == EscrowStatus.Submitted ||
            activeEscrow.status == EscrowStatus.Denied
        ) {
            // ok
        } else if (activeEscrow.status == EscrowStatus.ResolvedAI) {
            EscrowAIDisputeInfo memory ai = escrowtoDisputeAI[escrowID];
            if (block.timestamp > ai.resolveTime + APPEAL_TIME_DISPUTE_AI) {
                revert AppealWindowOver();
            }
            address loser = ai.winnerAddress == activeEscrow.fromAddress
                ? activeEscrow.toAddress
                : activeEscrow.fromAddress;
            if (msg.sender != loser) {
                revert YouAreNotAuthorized();
            }
        } else {
            revert OnlySubmittedOneAreAllowed();
        }

        if (
            activeEscrow.disputeType == DisputeType.RegularDispute &&
            amountinUSD < 400 * 1e6
        ) {
            revert InvalidFee();
        } else if (
            activeEscrow.disputeType == DisputeType.MiniDispute &&
            amountinUSD < 15 * 1e6
        ) {
            revert InvalidFee();
        }

        uint256 oracleFee;
        uint256 loyaltyFee;

        if (activeEscrow.disputeType == DisputeType.MiniDispute) {
            oracleFee =
                amountinUSD +
                (activeEscrow.tokenAmount * miniDisputeDealSizeFee) /
                PPM; //0.5%  of dealsize
            loyaltyFee =
                (activeEscrow.tokenAmount * miniDisputeDealSizeFee) /
                PPM;
        } else if (activeEscrow.disputeType == DisputeType.RegularDispute) {
            oracleFee =
                amountinUSD +
                (activeEscrow.tokenAmount * regularDisputeDealSizeFee) /
                PPM; // 0.25%  of the dealsize
            loyaltyFee =
                (activeEscrow.tokenAmount * regularDisputeDealSizeFee) /
                PPM;
        }

        if (
            IERC20(usdtToken).allowance(
                msg.sender,
                address(tomiDisputeAddress)
            ) < oracleFee
        ) {
            revert InsufficientAllowance();
        }

        address disputeAddress;

        if (msg.sender == activeEscrow.toAddress) {
            disputeAddress = tomiDisputeAddress.createTomiDispute(
                activeEscrow.fromAddress, // the one with whom the dispute is
                activeEscrow.escrowDetialsURI,
                activeEscrow.toAddress, // the one who is creator of dispute
                activeEscrow.submissionURI,
                activeEscrow.tokenAmount, // dealsize
                loyaltyFee
            );
        } else if (msg.sender == activeEscrow.fromAddress) {
            disputeAddress = tomiDisputeAddress.createTomiDispute(
                activeEscrow.toAddress, // the one with whom the dispute is
                activeEscrow.submissionURI,
                activeEscrow.fromAddress, // the one who is creator of dispute
                activeEscrow.escrowDetialsURI,
                activeEscrow.tokenAmount, // dealsize
                loyaltyFee
            );
        }

        escrowtoDisputeOracle[escrowID] = EscrowDisputeInfo({
            disputeContract: disputeAddress,
            winnerAddress: address(0),
            status: DisputeStatus.InVoting
        });

        activeEscrow.status = EscrowStatus.InDisputeOracle;

        emit DisputeOracleCreated(escrowID, msg.sender);
    }

    /**
     * @notice Allows a user to submit proof again for a specific escrow in dispute.
     * @dev This function enables the submission of additional proof for an escrow
     *      that is currently in dispute via the oracle mechanism.
     *      The caller must be either the creator or the recipient of the escrow.
     * @param escrowID The unique identifier of the escrow for which proof is being submitted.
     * @param proofURI The URI containing the proof details to be submitted.
     */
    function submitProofAgain(
        uint256 escrowID,
        string calldata proofURI
    ) external {
        Escrow memory activeEscrow = escrows[escrowID];

        if (
            activeEscrow.fromAddress != msg.sender &&
            activeEscrow.toAddress != msg.sender
        ) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.InDisputeOracle) {
            revert NotInDispute();
        }

        EscrowDisputeInfo memory activeDispute = escrowtoDisputeOracle[
            escrowID
        ];

        (, , address winnerAddress) = ITomiDispute(
            activeDispute.disputeContract
        ).calculateWinnerReadOnly();

        if (winnerAddress != address(0)) {
            revert WinnnerRevealed();
        }

        ITomiDispute(activeDispute.disputeContract).submitProof(
            msg.sender,
            proofURI
        );

        emit ProofSubmitted(
            escrowID,
            activeDispute.disputeContract,
            msg.sender,
            proofURI
        );
    }

    /**
     * @notice Resolves a dispute for a specific escrow identified by `escrowID` using an oracle's decision.
     * @dev This function requires a valid signature from the oracle to verify the resolution.
     * @param escrowID The unique identifier of the escrow for which the dispute is being resolved.
     * @param deadline The timestamp until which the provided signature is valid.
     * @param signature The cryptographic signature provided by the oracle to authorize the dispute resolution.
     */
    function resolveDisputeOracle(
        uint256 escrowID,
        uint256 deadline,
        bytes calldata signature
    ) external {
        if (block.timestamp > deadline) {
            revert SignExpired();
        }

        if (signatureUsed[signature]) {
            revert SignatureUsed();
        }

        signatureUsed[signature] = true;

        if (
            !_isValidSignature(
                signer,
                keccak256(
                    abi.encodePacked(
                        escrowID,
                        msg.sender,
                        deadline,
                        address(this)
                    )
                ),
                signature
            )
        ) {
            revert InvalidSignature();
        }

        Escrow storage activeEscrow = escrows[escrowID];

        if (
            activeEscrow.fromAddress != msg.sender &&
            activeEscrow.toAddress != msg.sender
        ) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.InDisputeOracle) {
            revert NotInDispute();
        }

        EscrowDisputeInfo storage activeDispute = escrowtoDisputeOracle[
            escrowID
        ];

        address winnerAddress;

        try
            ITomiDispute(activeDispute.disputeContract)
                .calculateWinnerReadOnly()
        returns (uint256, uint256, address _winnerAddress) {
            winnerAddress = _winnerAddress;
        } catch {
            revert WinnnerNotRevealedYet();
        }

        if (winnerAddress == address(0)) {
            revert WinnnerNotRevealedYet();
        }

        activeDispute.winnerAddress = winnerAddress;
        activeDispute.status = DisputeStatus.Resolved;

        //still have to handle the refund case from dispute

        if (winnerAddress == activeEscrow.fromAddress) {
            activeEscrow.status = EscrowStatus.Refunded;
            IERC20(activeEscrow.tokenAddress).safeTransfer(
                winnerAddress,
                (activeEscrow.tokenAmount)
            );
        } else if (winnerAddress == activeEscrow.toAddress) {
            activeEscrow.status = EscrowStatus.Released;
            uint256 feeAmount = (activeEscrow.tokenAmount *
                activeEscrow.feeinPPM) / PPM;

            IERC20(activeEscrow.tokenAddress).safeTransfer(
                swapandBurnContract,
                feeAmount
            );

            IERC20(activeEscrow.tokenAddress).safeTransfer(
                winnerAddress,
                (activeEscrow.tokenAmount - feeAmount)
            );
        }

        emit DisputeResolvedByOracle({
            escrowID: escrowID,
            disputeContract: activeDispute.disputeContract,
            winnerAddress: winnerAddress,
            timeStamp: block.timestamp
        });
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                     Admin Only Functions                           ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    function updateFeeWallet(address _feeWalletAddress) external onlyOwner {
        if (_feeWalletAddress == address(0)) {
            revert ZeroAddress();
        }

        if (_feeWalletAddress == feeWallet) {
            revert SameAsLastOne();
        }

        feeWallet = _feeWalletAddress;

        //TODO:  add  event  here
    }

    function updateSwapAndBurnContract(
        address _swapAndBurnAddress
    ) external onlyOwner {
        if (_swapAndBurnAddress == address(0)) {
            revert ZeroAddress();
        }

        if (swapandBurnContract == _swapAndBurnAddress) {
            revert SameAsLastOne();
        }

        swapandBurnContract = _swapAndBurnAddress;

        //TODO:  add  event  here
    }

    function updateTomiDisputeAddress(
        address _updatedTomiDisputeAddress
    ) external onlyOwner {
        if (_updatedTomiDisputeAddress == address(0)) {
            revert ZeroAddress();
        }

        if (_updatedTomiDisputeAddress == address(tomiDisputeAddress)) {
            revert SameAsLastOne();
        }

        tomiDisputeAddress = ITomiDispute(_updatedTomiDisputeAddress);

        //TODO:  add  event  here
    }

    function updateResolverAddress(
        address _updatedResolverAddress
    ) external onlyOwner {
        if (_updatedResolverAddress == address(0)) {
            revert ZeroAddress();
        }

        if (_updatedResolverAddress == address(resolverAI)) {
            revert SameAsLastOne();
        }

        resolverAI = _updatedResolverAddress;

        //TODO:  add  event  here
    }

    function updateResolverFee(uint256 _updatedResolverFee) external onlyOwner {
        if (_updatedResolverFee == 0) {
            revert ZeroAmount();
        }

        if (_updatedResolverFee == resolverFeeAI) {
            revert SameAsLastOne();
        }

        resolverFeeAI = _updatedResolverFee;

        //TODO:  add  event  here
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                     Internal Functions                             ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function _isValidSignature(
        address authority,
        bytes32 generatedHash,
        bytes calldata signature
    ) private pure returns (bool) {
        bytes32 signedHash = MessageHashUtils.toEthSignedMessageHash(
            generatedHash
        );
        return ECDSA.recover(signedHash, signature) == authority;
    }
}
