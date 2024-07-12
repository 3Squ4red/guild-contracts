// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {Guild} from "../src/Guild.sol";

contract DeployGuild is Script {
    address constant ORG_IMPL = 0x16193485Ae6EC95B7d7A394E218B5a2d496f3720;

    function run() external returns (address guild) {
        vm.startBroadcast();
        guild = address(new Guild(ORG_IMPL));
        vm.stopBroadcast();
    }
}
