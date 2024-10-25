// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {TwoCandidateVoting} from "../src/TwoCandidateVoting.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployTwoCandidateVoting is Script {
    function run() external returns (TwoCandidateVoting, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();         
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        address requiredToken = config.requiredToken;
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);      
        

        // Deploy the Upgradeable contract 
        TwoCandidateVoting twoCandidateVoting = new TwoCandidateVoting();
        
        /// @dev Prepare iitialization data
        bytes memory initData = abi.encodeCall(
            TwoCandidateVoting.initialize,
            ( 
                requiredToken,
                config.requiredBalance,
                config.gracePeriod
            
                
             
        )
            
        );

        console2.log("UUPS upgradeable TwoCandidateVoting contract deployed at address: ", address(twoCandidateVoting));

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(twoCandidateVoting),
            initData
            );

        console2.log("Logic contract deployed at address: ", address(twoCandidateVoting));
        console2.log("Proxy contract deployed at address: ", address(proxy));

        vm.stopBroadcast();

        
                
        return (TwoCandidateVoting(payable(proxy)), helperConfig); 
    }
}
