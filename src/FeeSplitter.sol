// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';
import {SafeCall} from '@eth-optimism-bedrock/src/libraries/SafeCall.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {IFeeVault} from './interfaces/optimism/IFeeVault.sol';
import {IL2StandardBridge} from './interfaces/optimism/IL2StandardBridge.sol';

/**
 * @title FeeSplitter
 * @dev Withdraws funds from system FeeVault contracts, shares revenue with Optimism, Uniswap Labs, and the Attestation Rewards distributor
 * @dev Inspired by the Base FeeDisburser contract
 */
contract FeeSplitter is Ownable {
    /**
     * @dev Struct holding configurable revenue shares of fees held in this contract
     */
    struct FeeSplitBasisPoints {
        uint256 optimismNet;
        uint256 optimismGross;
        uint256 rewardsDistributorNet;
        uint256 rewardsDistributorGross;
    }
    /*//////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The basis point scale which revenue share splits are denominated in.
     */

    uint32 public constant BASIS_POINT_SCALE = 10_000;
    /**
     * @dev The minimum gas limit for the FeeSplitter withdrawal transaction to L1.
     */
    uint32 public constant WITHDRAWAL_MIN_GAS = 35_000;

    /*//////////////////////////////////////////////////////////////
                            Immutables
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The address of the Optimism wallet that will receive Optimism's revenue share.
     */
    address payable public immutable OPTIMISM_WALLET;
    /**
     * @dev The address of the Rewards Distributor that will receive a share of fees;
     */
    address payable public immutable REWARDS_DISTRIBUTOR;
    /**
     * @dev The address of the L1 wallet that will receive the OP chain runner's share of fees.
     */
    address public immutable L1_WALLET;
    /**
     * @dev The minimum amount of time in seconds that must pass between fee disbursals.
     */
    uint256 public immutable FEE_DISBURSEMENT_INTERVAL;

    /*//////////////////////////////////////////////////////////////
                            Variables
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The timestamp of the last disbursal.
     */
    uint256 public lastDisbursementTime;
    /**
     * @dev Tracks aggregate net fee revenue which is the sum of sequencer and base fees.
     * @dev Explicity tracking Net Revenue is required to seperate L1FeeVault initiated
     *      withdrawals from Net Revenue calculations.
     */
    uint256 public netFeeRevenue;

    // TODO: if we don't support withdrawing to L1 wallet we don't need to track netFeeRevenue (i.e. we send fees to labs on L2)

    /**
     * @dev The net and gross revenue percentages denominated in basis points that is used in
     *      revenue share calculation.
     */
    FeeSplitBasisPoints feeSplit;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when the fee split is updated.
     * @param _oldFeeSplitHash The hash of the old configuration
     * @param _newFeeSplitHash The hash of the new configuration
     */
    event FeeSplitUpdated(address indexed _sender, bytes32 indexed _oldFeeSplitHash, bytes32 indexed _newFeeSplitHash);
    /**
     * @dev Emitted when fees are disbursed.
     * @param _disbursementTime The time of the disbursement.
     * @param _paidToOptimism The amount of fees disbursed to Optimism.
     * @param _totalFeesDisbursed The total amount of fees disbursed.
     */
    event FeesDisbursed(uint256 _disbursementTime, uint256 _paidToOptimism, uint256 _totalFeesDisbursed);
    /**
     * @dev Emitted when fees are received from FeeVaults.
     * @param _sender The FeeVault that sent the fees.
     * @param _amount The amount of fees received.
     */
    event FeesReceived(address indexed _sender, uint256 _amount);
    /**
     * @dev Emitted when no fees are collected from FeeVaults at time of disbursement.
     */
    event NoFeesCollected();

    modifier validateFeeSplit(FeeSplitBasisPoints memory _feeSplit) {
        require(_feeSplit.optimismNet != 0, 'FeeSplitter: Invalid optimism net revenue share');
        require(_feeSplit.optimismGross != 0, 'FeeSplitter: Invalid optimism gross revenue share');
        require(_feeSplit.rewardsDistributorNet != 0, 'FeeSplitter: Invalid rewards distributor net revenue share');
        require(_feeSplit.rewardsDistributorGross != 0, 'FeeSplitter: Invalid rewards distributor gross revenue share');

        require(
            _feeSplit.optimismNet + _feeSplit.rewardsDistributorNet < BASIS_POINT_SCALE,
            'FeeSplitter: Invalid net revenue share parameters'
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Constructor for the FeeSplitter contract which validates and sets immutable variables.
     * @param _owner The owner of the contract.
     * @param _optimismWallet The address which receives Optimism's revenue share.
     * @param _l1Wallet The L1 address which receives the remainder of the revenue.
     * @param _feeDisbursementInterval The minimum amount of time in seconds that must pass between fee disbursals.
     */
    constructor(
        address _owner,
        address payable _optimismWallet,
        address payable _rewardsDistributor,
        address _l1Wallet,
        // Rewards shares
        FeeSplitBasisPoints memory _feeSplit,
        uint256 _feeDisbursementInterval
    ) Ownable(_owner) validateFeeSplit(_feeSplit) {
        require(_optimismWallet != address(0), 'FeeSplitter: OptimismWallet cannot be address(0)');
        require(_rewardsDistributor != address(0), 'FeeSplitter: RewardsDistributor cannot be address(0)');
        require(_l1Wallet != address(0), 'FeeSplitter: L1Wallet cannot be address(0)');
        require(
            _feeDisbursementInterval >= 24 hours, 'FeeSplitter: FeeDisbursementInterval cannot be less than 24 hours'
        );

        feeSplit = _feeSplit;

        OPTIMISM_WALLET = _optimismWallet;
        REWARDS_DISTRIBUTOR = _rewardsDistributor;
        L1_WALLET = _l1Wallet;
        FEE_DISBURSEMENT_INTERVAL = _feeDisbursementInterval;
    }

    /*//////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Withdraws funds from FeeVaults, sends Optimism their revenue share, and withdraws remaining funds to L1.
     * @dev Implements revenue share business logic as follows:
     *          Net Revenue             = sequencer FeeVault fee revenue + base FeeVault fee revenue
     *          Gross Revenue           = Net Revenue + l1 FeeVault fee revenue
     *          Optimism Revenue Share  = Maximum of 15% of Net Revenue and 2.5% of Gross Revenue
     *          L1 Wallet Revenue Share = Gross Revenue - Optimism Revenue Share
     */
    function disburseFees() external virtual {
        require(
            block.timestamp >= lastDisbursementTime + FEE_DISBURSEMENT_INTERVAL,
            'FeeSplitter: Disbursement interval not reached'
        );

        // Sequencer and base FeeVaults will withdraw fees to the FeeSplitter contract mutating netFeeRevenue
        feeVaultWithdrawal(payable(Predeploys.SEQUENCER_FEE_WALLET));
        feeVaultWithdrawal(payable(Predeploys.BASE_FEE_VAULT));

        feeVaultWithdrawal(payable(Predeploys.L1_FEE_VAULT));

        // Gross revenue is the sum of all fees
        uint256 feeBalance = address(this).balance;

        // Stop execution if no fees were collected
        if (feeBalance == 0) {
            emit NoFeesCollected();
            return;
        }

        lastDisbursementTime = block.timestamp;

        // Net revenue is the sum of sequencer fees and base fees
        uint256 optimismNetRevenueShare = netFeeRevenue * feeSplit.optimismNet / BASIS_POINT_SCALE;
        uint256 rewardsDistributorNetRevenueShare = netFeeRevenue * feeSplit.rewardsDistributorNet / BASIS_POINT_SCALE;
        netFeeRevenue = 0;

        uint256 optimismGrossRevenueShare = feeBalance * feeSplit.optimismGross / BASIS_POINT_SCALE;
        uint256 rewardsDistributorGrossRevenueShare = feeBalance * feeSplit.rewardsDistributorGross / BASIS_POINT_SCALE;

        // Revenue shares are the maximum of net and gross revenue
        uint256 optimismRevenueShare = Math.max(optimismNetRevenueShare, optimismGrossRevenueShare);
        uint256 rewardsDistributorRevenueShare =
            Math.max(rewardsDistributorNetRevenueShare, rewardsDistributorGrossRevenueShare);

        // Send Optimism their revenue share on L2
        require(
            SafeCall.send(OPTIMISM_WALLET, gasleft(), optimismRevenueShare),
            'FeeSplitter: Failed to send funds to Optimism'
        );

        // Send Attestation Rewards distributor their revenue share on L2
        require(
            SafeCall.send(REWARDS_DISTRIBUTOR, gasleft(), rewardsDistributorRevenueShare),
            'FeeSplitter: Failed to send funds to Rewards Distributor'
        );

        // Send remaining funds to L1 wallet on L1
        IL2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE)).bridgeETHTo{value: address(this).balance}(
            L1_WALLET, WITHDRAWAL_MIN_GAS, bytes('')
        );
        emit FeesDisbursed(lastDisbursementTime, optimismRevenueShare, feeBalance);
    }

    /**
     * @dev Receives ETH fees withdrawn from L2 FeeVaults.
     * @dev Will revert if ETH is not sent from L2 FeeVaults.
     */
    receive() external payable virtual {
        if (msg.sender == Predeploys.SEQUENCER_FEE_WALLET || msg.sender == Predeploys.BASE_FEE_VAULT) {
            // Adds value received to net fee revenue if the sender is the sequencer or base FeeVault
            netFeeRevenue += msg.value;
        } else if (msg.sender != Predeploys.L1_FEE_VAULT) {
            revert('FeeSplitter: Only FeeVaults can send ETH to FeeSplitter');
        }
        emit FeesReceived(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Withdraws fees from a FeeVault.
     * @param _feeVault The address of the FeeVault to withdraw from.
     * @dev Withdrawal will only occur if the given FeeVault's balance is greater than or equal to
     *        the minimum withdrawal amount.
     */
    function feeVaultWithdrawal(address payable _feeVault) internal {
        require(
            IFeeVault(_feeVault).WITHDRAWAL_NETWORK() == IFeeVault.WithdrawalNetwork.L2,
            'FeeSplitter: FeeVault must withdraw to L2'
        );
        require(
            IFeeVault(_feeVault).RECIPIENT() == address(this),
            'FeeSplitter: FeeVault must withdraw to FeeSplitter contract'
        );
        if (_feeVault.balance >= IFeeVault(_feeVault).MIN_WITHDRAWAL_AMOUNT()) {
            IFeeVault(_feeVault).withdraw();
        }
    }

    // TODO: maybe add timelock delay
    function updateFeeSplit(FeeSplitBasisPoints memory _feeSplit) external onlyOwner() validateFeeSplit(_feeSplit) {
        emit FeeSplitUpdated(msg.sender, hash(feeSplit), hash(_feeSplit));
        feeSplit = _feeSplit;
    }

    /**
     * @dev Helper function to get the hash of a specific feeSplit configuration
     */
    function hash(FeeSplitBasisPoints memory _feeSplit) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_feeSplit.optimismNet, _feeSplit.optimismGross, _feeSplit.rewardsDistributorNet, _feeSplit.rewardsDistributorGross));
    }
}
