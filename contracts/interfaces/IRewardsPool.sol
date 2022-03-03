// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../external/compound/ICompLike.sol";
import "../interfaces/IPass.sol";

interface IRewardsPool {
  /// @dev Event emitted when controlled token is added
  event ControlledTokenAdded(IPass indexed token);

  event AwardCaptured(uint256 amount);

  /// @dev Event emitted when assets are deposited
  event Deposited(
    address indexed operator,
    address indexed to,
    IPass indexed token,
    uint256 amount
  );

  /// @dev Event emitted when interest is awarded to a winner
  event Awarded(address indexed winner, IPass indexed token, uint256 amount);

  /// @dev Event emitted when external ERC20s are awarded to a winner
  event AwardedExternalERC20(address indexed winner, address indexed token, uint256 amount);

  /// @dev Event emitted when external ERC20s are transferred out
  event TransferredExternalERC20(address indexed to, address indexed token, uint256 amount);

  /// @dev Event emitted when external ERC721s are awarded to a winner
  event AwardedExternalERC721(address indexed winner, address indexed token, uint256[] tokenIds);

  /// @dev Event emitted when assets are withdrawn
  event Withdrawal(
    address indexed operator,
    address indexed from,
    IPass indexed token,
    uint256 amount,
    uint256 redeemed
  );

  /// @dev Event emitted when the Balance Cap is set
  event BalanceCapSet(uint256 balanceCap);

  /// @dev Event emitted when the Liquidity Cap is set
  event LiquidityCapSet(uint256 liquidityCap);

  /// @dev Event emitted when the Rewards Strategy is set
  event PrizeStrategySet(address indexed prizeStrategy);

  /// @dev Event emitted when the Ticket is set
  event TicketSet(IPass indexed ticket);

  /// @dev Emitted when there was an error thrown awarding an External ERC721
  event ErrorAwardingExternalERC721(bytes error);

  /// @notice Deposit assets into the Rewards Pool in exchange for tokens
  /// @param to The address receiving the newly minted tokens
  /// @param amount The amount of assets to deposit
  function depositTo(address to, uint256 amount) external;

  /// @notice Deposit assets into the Rewards Pool in exchange for tokens,
  /// then sets the delegate on behalf of the caller.
  /// @param to The address receiving the newly minted tokens
  /// @param amount The amount of assets to deposit
  /// @param delegate The address to delegate to for the caller
  function depositToAndDelegate(address to, uint256 amount, address delegate) external;

  /// @notice Withdraw assets from the Rewards Pool instantly.  A fairness fee may be charged for an early exit.
  /// @param from The address to redeem tokens from.
  /// @param amount The amount of tokens to redeem for assets.
  /// @return The actual amount withdrawn
  function withdrawFrom(address from, uint256 amount) external returns (uint256);

  /// @notice Called by the rewards strategy to award prizes.
  /// @dev The amount awarded must be less than the awardBalance()
  /// @param to The address of the winner that receives the award
  /// @param amount The amount of assets to be awarded
  function award(address to, uint256 amount) external;

  /// @notice Returns the balance that is available to award.
  /// @dev captureAwardBalance() should be called first
  /// @return The total amount of assets to be awarded for the current rewards
  function awardBalance() external view returns (uint256);

  /// @notice Captures any available interest as award balance.
  /// @dev This function also captures the reserve fees.
  /// @return The total amount of assets to be awarded for the current rewards
  function captureAwardBalance() external returns (uint256);

  /// @dev Checks with the Rewards Pool if a specific token type may be awarded as an external rewards
  /// @param externalToken The address of the token to check
  /// @return True if the token may be awarded, false otherwise
  function canAwardExternal(address externalToken) external view returns (bool);

  // @dev Returns the total underlying balance of all assets. This includes both principal and interest.
  /// @return The underlying balance of assets
  function balance() external returns (uint256);

  /**
   * @notice Read internal Ticket accounted balance.
     * @return uint256 accountBalance
     */
  function getAccountedBalance() external view returns (uint256);

  /**
   * @notice Read internal balanceCap variable
     */
  function getBalanceCap() external view returns (uint256);

  /**
   * @notice Read internal liquidityCap variable
     */
  function getLiquidityCap() external view returns (uint256);

  /**
   * @notice Read ticket variable
     */
  function getTicket() external view returns (IPass);

  /**
   * @notice Read token variable
     */
  function getToken() external view returns (address);

  /**
   * @notice Read prizeStrategy variable
     */
  function getPrizeStrategy() external view returns (address);

  /// @dev Checks if a specific token is controlled by the Rewards Pool
  /// @param controlledToken The address of the token to check
  /// @return True if the token is a controlled token, false otherwise
  function isControlled(IPass controlledToken) external view returns (bool);

  /// @notice Called by the Rewards-Strategy to transfer out external ERC20 tokens
  /// @dev Used to transfer out tokens held by the Rewards Pool.  Could be liquidated, or anything.
  /// @param to The address of the winner that receives the award
  /// @param externalToken The address of the external asset token being awarded
  /// @param amount The amount of external assets to be awarded
  function transferExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  ) external;

  /// @notice Called by the Rewards-Strategy to award external ERC20 prizes
  /// @dev Used to award any arbitrary tokens held by the Rewards Pool
  /// @param to The address of the winner that receives the award
  /// @param amount The amount of external assets to be awarded
  /// @param externalToken The address of the external asset token being awarded
  function awardExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  ) external;

  /// @notice Called by the rewards strategy to award external ERC721 prizes
  /// @dev Used to award any arbitrary NFTs held by the Rewards Pool
  /// @param to The address of the winner that receives the award
  /// @param externalToken The address of the external NFT token being awarded
  /// @param tokenIds An array of NFT Token IDs to be transferred
  function awardExternalERC721(
    address to,
    address externalToken,
    uint256[] calldata tokenIds
  ) external;

  /// @notice Allows the owner to set a balance cap per `token` for the pool.
  /// @dev If a user wins, his balance can go over the cap. He will be able to withdraw the excess but not deposit.
  /// @dev Needs to be called after deploying a rewards pool to be able to deposit into it.
  /// @param balanceCap New balance cap.
  /// @return True if new balance cap has been successfully set.
  function setBalanceCap(uint256 balanceCap) external returns (bool);

  /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
  /// @param liquidityCap The new liquidity cap for the rewards pool
  function setLiquidityCap(uint256 liquidityCap) external;

  /// @notice Sets the rewards strategy of the rewards pool.  Only callable by the owner.
  /// @param _prizeStrategy The new rewards strategy.
  function setPrizeStrategy(address _prizeStrategy) external;

  /// @notice Set rewards pool ticket.
  /// @param ticket Address of the ticket to set.
  /// @return True if ticket has been successfully set.
  function setTicket(IPass ticket) external returns (bool);

  /// @notice Delegate the votes for a Compound COMP-like token held by the rewards pool
  /// @param compLike The COMP-like token held by the rewards pool that should be delegated
  /// @param to The address to delegate to
  function compLikeDelegate(ICompLike compLike, address to) external;
}
