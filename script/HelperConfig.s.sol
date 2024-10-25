

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import {Script, console2} from "forge-std/Script.sol";




contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        uint256 requiredBalance;
        address requiredToken;
        uint256 gracePeriod;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ARB_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;


    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        networkConfigs[ARB_SEPOLIA_CHAIN_ID] = getSepoliaArbConfig(); 
        
        // Note: We skip doing the local config
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view  returns (NetworkConfig memory) {
         if (networkConfigs[chainId].requiredToken != address(0)) {
            return networkConfigs[chainId];

        }
              revert HelperConfig__InvalidChainId();
        
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory ) {
        return NetworkConfig({
            requiredBalance: 100   * 1e6 , // 100 USDC with 6 decimals 
            requiredToken :0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, //  USDC on mainnet
            gracePeriod: 24 * 60 * 60 // 24 hours grace period expressed in seconds
            
        });
    }



    function getSepoliaArbConfig() public pure returns (NetworkConfig memory ) {
        return NetworkConfig ({
            requiredBalance: 100 * 1e6 , // 100 USDC with 6 decimals 
            requiredToken : 0xf3C3351D6Bd0098EEb33ca8f830FAf2a141Ea2E1, //  USDC on Sepolia Arbitrum 
            gracePeriod: 24 * 60 * 60 // 24 hours grace period expressed in seconds
        });
    }


        
        
        
}
        
