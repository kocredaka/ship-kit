// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Greeter} from "../src/Greeter.sol";

/// @notice Deploy the Greeter demo contract.
/// @dev Usage:
///      forge script script/DeployGreeter.s.sol --rpc-url $FUJI_RPC_URL --broadcast
///      Set GREETER_MESSAGE to override the default greeting.
///      The deployer key must be set via --private-key, --account, or the
///      PRIVATE_KEY env var (see .env.example). Never commit a real key.
contract DeployGreeter is Script {
    function run() external returns (Greeter greeter) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        string memory greeting = vm.envOr("GREETER_MESSAGE", string("hello, avalanche"));
        vm.startBroadcast(deployerKey);
        greeter = new Greeter(greeting);
        vm.stopBroadcast();
        console.log("Greeter deployed at:", address(greeter));
        console.log("Greeting:", greeter.message());
        console.log("Chain ID:", block.chainid);
    }
}
