// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ITokenBridge} from "./Interfaces/ITokenBridge.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title FeeManager
/// @notice Manages the fee for bridging tokens to another chain.
contract FeeManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @dev Uses the SafeERC20 library for safe operations with IERC20 tokens.
    using SafeERC20 for IERC20;

    address public iTokenBridgeAddress;
    address public burnerOnETH;
    uint256 public slippageInPPM;
    uint256 public thresholdtoBridge;

    uint16 public ethChainID;

    IERC20 public usd;

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                            Errors                                  ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @notice Revert when provided input is invalid (e.g., zero address or amount).
    error InvalidInputs();

    /// @notice Revert when sent native fee is insufficient to cover LayerZero costs.
    error InsufficientFee();

    /// @notice Revert when the token balance is below the threshold to bridge.
    error ThresholdNotReached();

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                            Events                                  ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @notice Emitted when tokens are bridged to another chain.
    event TokensBridged(
        address indexed recipient,
        uint256 amount,
        uint16 targetChainID,
        uint256 slippageInPPM
    );

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Constructor                            ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @dev Disables initializers to prevent misuse of implementation contract.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Main Functions                         ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    function Initialize(
        address owner,
        address bridgeAddress,
        address usdtAddress,
        address burnerOnETHAddress,
        uint256 _thresholdtoBridge
    ) external initializer {
        if (
            owner == address(0) ||
            bridgeAddress == address(0) ||
            usdtAddress == address(0) ||
            burnerOnETHAddress == address(0) ||
            _thresholdtoBridge == 0
        ) {
            revert InvalidInputs();
        }

        __Ownable_init(owner);
        __UUPSUpgradeable_init();

        iTokenBridgeAddress = bridgeAddress;
        usd = IERC20(usdtAddress);
        burnerOnETH = burnerOnETHAddress;
        thresholdtoBridge = _thresholdtoBridge;
        slippageInPPM = 990000; // 1% default
        ethChainID = 101;
    }

    function bridgeToETH() external payable {
        uint256 amount = usd.balanceOf(address(this));

        if (amount < thresholdtoBridge) {
            revert ThresholdNotReached();
        }

        if (msg.value < this.estimateFeeToETH()) {
            revert InsufficientFee();
        }

        usd.approve(iTokenBridgeAddress, amount);
        ITokenBridge(iTokenBridgeAddress).bridgeTokens{value: msg.value}(
            burnerOnETH,
            amount,
            ethChainID,
            slippageInPPM
        );

        emit TokensBridged(burnerOnETH, amount, ethChainID, slippageInPPM);
    }

    function estimateFeeToETH() external view returns (uint256) {
        return
            ITokenBridge(iTokenBridgeAddress).estimateFee(
                ethChainID,
                burnerOnETH
            );
    }

    function updateBurnerOnETH(address _burnerOnETH) external onlyOwner {
        if (_burnerOnETH == address(0)) {
            revert InvalidInputs();
        }
        burnerOnETH = _burnerOnETH;
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                         Internal Functions                         ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @notice Internal function to authorize upgrade.
    /// @param newImplementation Address of new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
