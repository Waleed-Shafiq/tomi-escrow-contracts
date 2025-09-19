// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
// import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {IPermit2} from "./Interfaces/IPermit2.sol";
// import {IUniversalRouter} from "./Interfaces/IUniversalRouter.sol";
// import {Commands} from "./libraries/Commands.sol";
contract Escrow {

}
// contract EscrowPayment is Initializable, OwnableUpgradeable, UUPSUpgradeable {
//     using SafeERC20 for IERC20;
//     using Address for address payable;

//     /// @notice The Universal Router contract used for executing token transfers and swaps.
//     IUniversalRouter public universalRouter;
//     //address public universalRouter;

//     /// @notice Instance of the Permit2 interface for handling token approvals.
//     IPermit2 public permit2;
//     //address public permit2;

//     uint256 public escrowId;
//     uint256 public constant PPM = 1_000_000;
//     uint256 public constant escrowPlatformFee = 10_000; //1%
//     uint256 public constant regularDisputeDealSizeFee = 2_500; //1%
//     uint256 public constant miniDisputeDealSizeFee = 5_000; //1%
//     address public feeWallet;
//     address public oracle;
//     address public USDT;

//     struct Escrow {
//         string escrowDetialsURI;
//         address fromAddress;
//         address toAddress;
//         address tokenAddress;
//         uint256 tokenAmount;
//         uint256 feeinPPM;
//         uint256 submissionDeadline;
//         EscrowStatus status;
//         DisputeType disputeType;
//     }

//     struct EscrowDisputeInfo {
//         address disputeContract;
//         address winnerAddress;
//     }

//     enum DisputeType {
//         MiniDispute,
//         RegularDispute
//     }

//     enum EscrowStatus {
//         Created,
//         Paid,
//         Submitted,
//         Refunded,
//         InDispute
//     }

//     enum DisputeStatus {
//         InVoting,
//         Resolved,
//         Refunded
//     }

//     error YouAreNotAuthorized();
//     error AlreadyPaid();
//     error InDispute();
//     error InvalidDisputeType();
//     error InvalidFee();
//     error InvalidValue();
//     error InsufficientAllowance();
//     error ZeroAddress();
//     error ZeroAmount();
//     error NotInDispute();

//     mapping(uint256 taskId => Escrow escrow) public escrows;
//     mapping(uint256 escrowID => DisputeType disputeType)
//         public escrowToDisputeType;

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         _disableInitializers();
//     }

//     function initialize(address feeWalletAddress) external initializer {
//         if (feeWalletAddress == address(0)) {
//             revert ZeroAddress();
//         }
//         feeWallet = feeWalletAddress;
//     }

//     function createEscrow(
//         string memory detialsURI,
//         address toAddress,
//         address tokenAddress,
//         uint256 tokenAmount,
//         uint256 feeinPPM,
//         uint256 endTime,
//         DisputeType disputeType
//     ) external {
//         if (toAddress == address(0) && tokenAddress == address(0)) {
//             revert ZeroAddress();
//         }

//         if (tokenAmount == 0 && feeinPPM == 0) {
//             revert ZeroAmount();
//         }

//         escrowId++;

//         IERC20(tokenAddress).safeTransferFrom(
//             msg.sender,
//             address(this),
//             tokenAmount
//         );

//         escrows[escrowId] = Escrow({
//             escrowDetialsURI: detialsURI,
//             fromAddress: msg.sender,
//             toAddress: toAddress,
//             tokenAddress: tokenAddress,
//             tokenAmount: tokenAmount,
//             feeinPPM: feeinPPM + escrowPlatformFee,
//             submissionDeadline: endTime,
//             status: EscrowStatus.Created,
//             disputeType: disputeType
//         });

//         //escrow created event here
//     }

//     function approveEscrow(uint256 escrowID) external {
//         Escrow storage activeEscrow = escrows[escrowID];

//         if (activeEscrow.fromAddress != msg.sender) {
//             revert YouAreNotAuthorized();
//         }

//         if (activeEscrow.status == EscrowStatus.Paid) {
//             revert AlreadyPaid();
//         }

//         if (activeEscrow.status == EscrowStatus.InDispute) {
//             revert InDispute();
//         }

//         activeEscrow.status = EscrowStatus.Paid;
//         uint256 feeAmount = (activeEscrow.tokenAmount *
//             (activeEscrow.feeinPPM)) / PPM;

//         IERC20(activeEscrow.tokenAddress).safeTransfer(
//             activeEscrow.toAddress,
//             (activeEscrow.tokenAmount - feeAmount)
//         );

//         //Will have to add the tokenlist check here
//         IERC20(activeEscrow.tokenAddress).safeTransfer(feeWallet, feeAmount);
//         //Amount Paid to the  swap and burn contract, FeeWallet  is swapandBurnContract
//     }

//     function createDispute(
//         uint256 escrowID,
//         uint256 amountinUSD, //send to oracle
//         bytes memory command,
//         bytes[] memory input
//     ) external {
//         Escrow storage activeEscrow = escrows[escrowID];

//         if (
//             activeEscrow.fromAddress != msg.sender ||
//             activeEscrow.toAddress != msg.sender
//         ) {
//             revert YouAreNotAuthorized();
//         }

//         if (
//             activeEscrow.disputeType == DisputeType.RegularDispute &&
//             amountinUSD < 400 * 1e6
//         ) {
//             revert InvalidFee();
//         } else if (
//             activeEscrow.disputeType == DisputeType.MiniDispute &&
//             amountinUSD < 15 * 1e6
//         ) {
//             revert InvalidFee();
//         }

//         if (IERC20(USDT).allowance(msg.sender, oracle) < amountinUSD) {
//             revert InsufficientAllowance();
//         }

//         uint256 amountToSwap;
//         if (activeEscrow.disputeType == DisputeType.RegularDispute) {
//             amountToSwap =
//                 (activeEscrow.tokenAmount * regularDisputeDealSizeFee) /
//                 PPM;
//         } else if (activeEscrow.disputeType == DisputeType.MiniDispute) {
//             amountToSwap =
//                 (activeEscrow.tokenAmount * miniDisputeDealSizeFee) /
//                 PPM;
//         }

//         IERC20(activeEscrow.tokenAddress).forceApprove(
//             address(permit2),
//             amountToSwap
//         );

//         permit2.approve(
//             address(activeEscrow.tokenAddress),
//             address(universalRouter),
//             type(uint160).max,
//             type(uint48).max
//         );

//         if (command == Commands.V3_SWAP_EXACT_IN) {
//             (address recipient, uint256 amountIn, , bytes memory path, ) = abi
//                 .decode(input, (address, uint256, uint256, bytes, bool));

//             if (recipient != address(this)) {
//                 revert InvalidValue();
//             }
//         } else if (
//             keccak256(command) ==
//             keccak256(abi.encodePacked(Commands.V2_SWAP_EXACT_IN))
//         ) {
//             (address recipient, uint256 amountIn, address[] memory path, ) = abi
//                 .decode(input, (address, uint256, uint256, address[], bool));

//             if (recipient != address(this)) {
//                 revert InvalidValue();
//             }
//         }

//         universalRouter.execute(command, input, block.timestamp);

//         //fee handles here
//         //deal size + 0.25% fee?
//         //Create Dispute Here.
//         //How much will be the end time for the dispute.

//         activeEscrow.status = EscrowStatus.InDispute;
//     }

//     // need  to add the signature here
//     function resolveDispute(uint256 escrowID) public {
//         Escrow storage activeEscrow = escrows[escrowID];

//         if (
//             activeEscrow.fromAddress != msg.sender ||
//             activeEscrow.toAddress != msg.sender
//         ) {
//             revert YouAreNotAuthorized();
//         }

//         if (activeEscrow.status != EscrowStatus.InDispute) {
//             revert NotInDispute();
//         }

//         //resolve dispute here

//         address winnerAddress; //result from the dispute

//         if (winnerAddress == activeEscrow.fromAddress) {
//             activeEscrow.status = EscrowStatus.Refunded;
//         } else if (winnerAddress == activeEscrow.toAddress) {
//             activeEscrow.status = EscrowStatus.Paid;
//         }

//         uint256 feeAmount = (activeEscrow.tokenAmount * activeEscrow.feeinPPM) /
//             PPM;

//         IERC20(activeEscrow.tokenAddress).safeTransfer(
//             winnerAddress,
//             (activeEscrow.tokenAmount - feeAmount)
//         );

//         //Will add the tokenlist check here
//         IERC20(activeEscrow.tokenAddress).safeTransfer(feeWallet, feeAmount);
//     }

//     function _authorizeUpgrade(
//         address newImplementation
//     ) internal override onlyOwner {}
// }
