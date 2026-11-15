// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ShipKitRegistry} from "../src/ShipKitRegistry.sol";

/// @notice Deploy ShipKitRegistry to the chain selected by --rpc-url.
/// @dev Usage:
///      Fuji:   forge script script/DeployRegistry.s.sol --rpc-url $FUJI_RPC_URL --broadcast
///      C-Chain: forge script script/DeployRegistry.s.sol --rpc-url $CCHAIN_RPC_URL --broadcast
///      The deployer key must be set via --private-key, --account, or the
///      PRIVATE_KEY env var (see .env.example). Never commit a real key.
contract DeployRegistry is Script {
    function run() external returns (ShipKitRegistry registry) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        registry = new ShipKitRegistry();
        vm.stopBroadcast();
        console.log("ShipKitRegistry deployed at:", address(registry));
        console.log("Chain ID:", block.chainid);
    }
}
