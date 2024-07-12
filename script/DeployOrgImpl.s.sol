// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {Organization} from "../src/Organization.sol";

contract DeployOrgImpl is Script {
    function run() external returns (address ORG_IMPL) {
        vm.startBroadcast();
        ORG_IMPL = address(new Organization());
        vm.stopBroadcast();
    }
}

// 0x16193485Ae6EC95B7d7A394E218B5a2d496f3720
// forge script script/DeployOrgImpl.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key <private-key> --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
