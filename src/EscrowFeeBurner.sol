// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPermit2} from "./Interfaces/IPermit2.sol";
import {IUniversalRouter} from "./Interfaces/IUniversalRouter.sol";
import {ITomi} from "./Interfaces/ITomi.sol";

contract EscrowFeeBurner is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice The Universal Router contract used for executing token transfers and swaps.
    IUniversalRouter public universalRouter;

    /// @notice Instance of the Permit2 interface for handling token approvals.
    IPermit2 public permit2;

    /// @notice Instance of the USDT token interface.
    IERC20 public USDT;

    /// @notice Instance of the TOMI token interface.
    IERC20 public TOMI;

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                            Errors                                  ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //
    error ZeroAddress();
    error TomiNotSwapped();

    event TomiBurned(uint256 amount);

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Constructor                            ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ╔════════════════════════════════════════════════════════════════════╗ //
    // ║                             Main Functions                         ║ //
    // ╚════════════════════════════════════════════════════════════════════╝ //

    /// @notice Initializes the EscrowFeeBurner contract with necessary parameters.
    /// @param owner The initial owner of the contract.
    /// @param universalRouterAddress The address of the Universal Router contract.
    /// @param permit2Address The address of the Permit2 contract.
    /// @param usdtAddress The address of the USDT token contract.
    function Initialize(
        address owner,
        address universalRouterAddress,
        address permit2Address,
        address usdtAddress,
        address tomiAddress
    ) external initializer {
        if (
            universalRouterAddress == address(0) ||
            permit2Address == address(0) ||
            usdtAddress == address(0) ||
            tomiAddress == address(0)
        ) {
            revert ZeroAddress();
        }

        __Ownable_init(owner);
        __UUPSUpgradeable_init();

        permit2 = IPermit2(permit2Address);
        universalRouter = IUniversalRouter(universalRouterAddress);
        USDT = IERC20(usdtAddress);
        TOMI = IERC20(tomiAddress);
    }

    function burnTomi(
        bytes calldata commands,
        bytes[] calldata inputs
    ) external {
        uint256 balanceUSDT = IERC20(USDT).balanceOf(address(this));
        uint256 tomiBeforeBalance = TOMI.balanceOf(address(this));

        // Approve Permit2 to spend USDT
        USDT.forceApprove(address(permit2), balanceUSDT);
        // Create a permit for Permit2 to spend USDT
        permit2.approve(
            address(USDT),
            address(universalRouter),
            uint160(balanceUSDT),
            uint48(block.timestamp + 10 minutes)
        );

        // Execute the swap from USDT to TOMI
        universalRouter.execute(commands, inputs, block.timestamp);

        // verify that TOMI tokens were received
        if (tomiBeforeBalance >= TOMI.balanceOf(address(this))) {
            revert TomiNotSwapped();
        }

        emit TomiBurned(TOMI.balanceOf(address(this)));
        // Burn the received TOMI tokens
        ITomi(address(TOMI)).burn(TOMI.balanceOf(address(this)));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
