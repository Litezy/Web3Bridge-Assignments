// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/**
 * @title IUniswapV2Factory
 * @dev Uniswap V2 Factory Interface
 * 
 * GUIDE ON HOW AND WHERE TO USE:
 * ============================================
 * 
 * USE CASE: When you need to create new trading pairs (liquidity pools) or 
 * find existing pairs on Uniswap V2.
 * 
 * WHERE TO DEPLOY: This interface is used by:
 * - Router contracts (for creating pairs and managing liquidity)
 * - Front-end applications (to display pair information)
 * - Analytics tools (to track all pairs on the protocol)
 * 
 * COMMON SCENARIOS:
 * 1. Creating a new trading pair for two tokens
 * 2. Querying if a pair exists between two tokens
 * 3. Getting a list of all pairs in the protocol
 * 4. Managing protocol fees (feeTo address)
 * 
 * EXAMPLE USAGE IN SOLIDITY:
 * 
```
solidity
 * import "./IUniswapV2Factory.sol";
 * 
 * contract MyContract {
 *     IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);
 *     
 *     function createNewPair(address tokenA, address tokenB) public {
 *         address pair = factory.createPair(tokenA, tokenB);
 *     }
 *     
 *     function getExistingPair(address tokenA, address tokenB) public view {
 *         address pair = factory.getPair(tokenA, tokenB);
 *     }
 * }
 * 
```
 */

interface IUniswapV2Factory {
    // @notice Emitted when a new trading pair (liquidity pool) is created
    // @param token0 Address of the first token in the pair (sorted alphabetically)
    // @param token1 Address of the second token in the pair
    // @param pair Address of the newly created pair contract
    // param i Token pair index/number (deprecated in V3 but kept for compatibility)
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    /// @notice Get the address that collects protocol fees
    /// @return feeTo The address that receives swap fees (0 by default, can be set by feeToSetter)
    /// 
    /// HOW TO USE: Check if fees are enabled. If feeTo != address(0), 
    /// a 0.3% swap fee is collected (0.25% goes to liquidity providers, 0.05% to feeTo)
    function feeTo() external view returns (address);

    /// @notice Get the address that can set the feeTo address
    /// @return feeToSetter The address authorized to change feeTo
    /// 
    /// HOW TO USE: This is typically a governance multisig or DAO. 
    /// Only this address can enable/disable protocol fees.
    function feeToSetter() external view returns (address);

    /// @notice Get the pair address for two tokens
    /// @param tokenA Address of the first token
    /// @param tokenB Address of the second token
    /// @return pair The address of the pair contract, or address(0) if pair doesn't exist
    /// 
    /// HOW TO USE: Always check if returned address != address(0) before using the pair.
    /// Note: tokenA and tokenB can be passed in any order - the factory sorts them.
    /// 
    /// EXAMPLE:
    /// address pair = factory.getPair(tokenA, tokenB);
    /// require(pair != address(0), "Pair does not exist");
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    // @notice Get the pair address at a specific index
    // @param uint The index of the pair in the allPairs array (0-indexed)
    // @return pair The address of the pair at that index
    // 
    /// HOW TO USE: Use allPairsLength() to get total count, then iterate to get all pairs.
    /// Note: This returns address(0) for non-existent indices.
    function allPairs(uint) external view returns (address pair);

    /// @notice Get the total number of pairs created
    /// @return uint The total count of pairs in the factory
    /// 
    /// HOW TO USE: Use this to iterate through all pairs using allPairs(i) where i from 0 to allPairsLength()-1
    function allPairsLength() external view returns (uint);

    /// @notice Create a new trading pair (liquidity pool) for two tokens
    /// @param tokenA Address of the first token
    /// @param tokenB Address of the second token
    /// @return pair The address of the newly created pair contract
    /// 
    /// HOW TO USE: Call this to create a new AMM pool for token trading.
    /// This will initialize the pair with empty reserves and emit PairCreated event.
    /// 
    /// IMPORTANT NOTES:
    /// - Reverts if pair already exists (use getPair to check first)
    /// - tokenA and tokenB are sorted alphabetically to determine token0/token1
    /// - The creator (msg.sender) does NOT automatically receive liquidity tokens
    /// - Call addLiquidity on the router to add initial liquidity
    /// 
    /// EXAMPLE SCENARIO:
    /// You want to list a new token pair (e.g., DAI/USDC):
    /// 1. Check if pair exists: factory.getPair(DAI, USDC)
    /// 2. If not, create it: factory.createPair(DAI, USDC)
    /// 3. Then add liquidity via router: router.addLiquidity(DAI, USDC, amountA, amountB, ...)
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /// @notice Set the fee recipient address
    /// @param _feeTo The address that should receive protocol fees
    /// 
    /// HOW TO USE: Only callable by feeToSetter. When set, a small portion
    /// of each swap fee (0.05% of the 0.3% total) goes to feeTo instead of 
    /// being fully distributed to liquidity providers.
    /// 
    /// WARNING: Setting feeTo to a non-zero address enables protocol fees.
    /// This should typically be controlled by governance.
    function setFeeTo(address _feeTo) external;

    /// @notice Set the address authorized to change feeTo
    /// @param _feeToSetter The new feeToSetter address
    /// 
    /// HOW TO USE: Only callable by current feeToSetter. Used for:
    /// - Transferring governance authority
    /// - Updating the fee setter (e.g., to a multisig or DAO)
    function setFeeToSetter(address _feeToSetter) external;
}
