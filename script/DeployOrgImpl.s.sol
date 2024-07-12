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

