// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITomiDispute} from "./Interfaces/ITomiDispute.sol";

contract EscrowPayment is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             State Varaibles                        ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    using SafeERC20 for IERC20;
    ITomiDispute public tomiDisputeAddress;
    uint256 public constant PPM = 1_000_000; //100 %
    uint256 public constant escrowPlatformFee = 10_000; //1%
    uint256 public constant regularDisputeDealSizeFee = 2_500; //0.25%
    uint256 public constant miniDisputeDealSizeFee = 5_000; //0.5%
    uint256 public escrowId;
    address public feeWallet;
    address public swapandBurnContract;
    address public usdtToken;

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
        EscrowStatus status;
        DisputeType disputeType;
    }

    struct EscrowDisputeInfo {
        address disputeContract;
        address winnerAddress;
        DisputeStatus status;
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
        Refunded,
        InDispute
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

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Events                                 ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    event EscrowCreated(Escrow escrowdetails, uint256 escrowFee);
    event EscrowAccepted(Escrow escrowdetails);
    event EscrowRefunded(Escrow escrowdetails);
    event EscrowSubmitted(Escrow escrowdetails);
    event EscrowReleased(
        Escrow escrowdetails,
        uint256 amountReleased,
        uint256 feeForSwapandBurn
    );

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Mappings                               ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    mapping(uint256 escrowID => Escrow escrow) public escrows;
    mapping(uint256 escrowID => EscrowDisputeInfo escrowDispute)
        public escrowtoDispute;

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
        address usdtAddress
    ) external initializer {
        if (feeWalletAddress == address(0)) {
            revert ZeroAddress();
        }
        swapandBurnContract = swapandBurnContractAddress;
        feeWallet = feeWalletAddress;
        tomiDisputeAddress = ITomiDispute(tomiDisputeaddress);
        usdtToken = usdtAddress;
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

        if (amountInUSDT == 0 && feeinPPM == 0) {
            revert ZeroAmount();
        }

        if (deadline > block.timestamp) {
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

        //transfer fee of the escrow + the amount in usdtToken to this address
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            (amountInUSDT + (amountInUSDT * escrowPlatformFee) / PPM)
        );

        //transfer fee to the escrow fee wallet
        IERC20(tokenAddress).safeTransferFrom(
            address(this),
            feeWallet,
            (amountInUSDT * escrowPlatformFee) / PPM
        );

        escrows[escrowId] = Escrow({
            escrowDetialsURI: detailsURI,
            submissionURI: "",
            fromAddress: msg.sender,
            toAddress: toAddress,
            tokenAddress: tokenAddress,
            tokenAmount: amountInUSDT,
            feeinPPM: feeinPPM,
            submissionDeadline: deadline,
            status: EscrowStatus.Created,
            disputeType: disputeType
        });

        Escrow memory activeEscrow = escrows[escrowId];
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
    function AcceptEscrow(uint256 escrowID) public {
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
        emit EscrowAccepted({escrowdetails: activeEscrow});
    }

    /**
     * @notice Refunds an escrow agreement with the given escrow ID.
     * @dev This function allows the creator of the escrow to refund the funds if the escrow has expired.
     *      Ensure that the caller is the creator of the escrow and the escrow is in the correct state.
     * @param escrowID The unique identifier of the escrow agreement to be refunded.
     */
    function RefundEscrow(uint256 escrowID) public {
        Escrow storage activeEscrow = escrows[escrowID];

        if (activeEscrow.fromAddress != msg.sender) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.Created) {
            revert OnlyCreatedOneAreAllowed();
        }

        if (activeEscrow.submissionDeadline > block.timestamp) {
            revert EscrowNotExpiredYet();
        }

        activeEscrow.status = EscrowStatus.Refunded;

        IERC20(usdtToken).safeTransferFrom(
            address(this),
            activeEscrow.fromAddress,
            activeEscrow.tokenAmount
        );
        emit EscrowRefunded({escrowdetails: activeEscrow});
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

        if (activeEscrow.status != EscrowStatus.Accepted) {
            revert OnlyAcceptedOneAreAllowed();
        }

        activeEscrow.submissionURI = submissionURI;
        activeEscrow.status = EscrowStatus.Submitted;

        emit EscrowSubmitted({escrowdetails: activeEscrow});
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

        if (activeEscrow.status == EscrowStatus.InDispute) {
            revert InDispute();
        }

        activeEscrow.status = EscrowStatus.Released;
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
            escrowdetails: activeEscrow,
            amountReleased: (activeEscrow.tokenAmount - feeAmount),
            feeForSwapandBurn: feeAmount
        });
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                        Dispute Functions                           ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    function CreateDispute(uint256 escrowID, uint256 amountinUSD) external {
        Escrow storage activeEscrow = escrows[escrowID];

        if (
            activeEscrow.fromAddress != msg.sender ||
            activeEscrow.toAddress != msg.sender
        ) {
            revert YouAreNotAuthorized();
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

        if (activeEscrow.disputeType == DisputeType.MiniDispute) {
            oracleFee =
                amountinUSD +
                (activeEscrow.tokenAmount * miniDisputeDealSizeFee) /
                PPM; //0.5%  of dealsize
        } else if (activeEscrow.disputeType == DisputeType.RegularDispute) {
            oracleFee =
                amountinUSD +
                (activeEscrow.tokenAmount * regularDisputeDealSizeFee) /
                PPM; // 0.25%  of the dealsize
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
                (activeEscrow.tokenAmount * regularDisputeDealSizeFee) / PPM //loyalty Fee
            );
        } else if (msg.sender == activeEscrow.fromAddress) {
            disputeAddress = tomiDisputeAddress.createTomiDispute(
                activeEscrow.toAddress, // the one with whom the dispute is
                activeEscrow.submissionURI,
                activeEscrow.fromAddress, // the one who is creator of dispute
                activeEscrow.escrowDetialsURI,
                activeEscrow.tokenAmount, // dealsize
                (activeEscrow.tokenAmount * regularDisputeDealSizeFee) / PPM //loyalty Fee
            );
        }

        escrowtoDispute[escrowID] = EscrowDisputeInfo({
            disputeContract: disputeAddress,
            winnerAddress: address(0),
            status: DisputeStatus.InVoting
        });

        activeEscrow.status = EscrowStatus.InDispute;

        //TODO :event will be added heree
    }

    // need to add the signature here
    function resolveDispute(uint256 escrowID) public {
        Escrow storage activeEscrow = escrows[escrowID];

        if (
            activeEscrow.fromAddress != msg.sender ||
            activeEscrow.toAddress != msg.sender
        ) {
            revert YouAreNotAuthorized();
        }

        if (activeEscrow.status != EscrowStatus.InDispute) {
            revert NotInDispute();
        }

        EscrowDisputeInfo storage activeDispute = escrowtoDispute[escrowID];

        (, , address winnerAddress) = ITomiDispute(
            activeDispute.disputeContract
        ).calculateWinnerReadOnly();

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

        //TODO :event will be added heree
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
