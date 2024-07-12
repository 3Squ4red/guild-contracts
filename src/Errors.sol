// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

error ZeroAddress();
// Guild
error InvalidOrg();
error EmptyOrgName();
error EmptyOrgIpfs();
error OrgAlreadyDeployedForAdmin(address admin, address org);
error NewAdminAlreadyInUse(address org);

// Organization
error OnlyAdmin();
error InvalidId();
error OnlyGuild();
error OnlyActiveTeam();
error DuplicateTeamId();
error InvalidTeamId();
error TeamAlreadyActive();
error Max5AtATime();
error DuplicateMember(address member);
error InvalidMember();

error DuplicateTaskId();
error EmptyTaskIpfs();
error InvalidAssignee();
error InvalidTaskId();
error TaskNotAssignedToATeam(address member);
error TaskAlreadyAccepted(address acceptor);
error CallerNotMemberOfTaskTeam(bytes32 teamId);
error CallerNeitherAcceptorNorAssigned();
error TaskAlreadyCompleted();
