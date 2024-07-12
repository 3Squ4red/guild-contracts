// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

struct Team {
    bytes32 teamId; // this field is here only to help figure out if a teamId is already in use or not
    address[] members;
    bool active;
}

struct Task {
    address assignedMember; // would be zero address if the task is assigned to a team
    bytes32 assignedTeam; // would be bytes32(0) if the task is assigned to a member
    address acceptor; // address of the member of the team with the above teamId who accepted the task. should be zero if `assignedTeam` is zero OR if the `assignedMember` is non-zero
    string infoIpfs; // would be set while task creation
    string completionIpfs; // would be set while task completion. the task would be considered closed if this is not empty
}

interface IOrganization {
    ///Events

    /**
    * This event is emitted when the token is Created
    * This event is emitted by the 'createTeam' function
    * 'teamId' is the id of the Team which will be created
    * 'members' are the Team members which are going to be the part of the Team
    */
    event TeamCreated(bytes32 indexed teamId, address[] indexed members);

    /**
    * This event is emitted when the Team is Activated
    * This event is emitted by the 'activateTeam' function 
    * 'teamId' is the id of the Activated team
    */
    event TeamActivated(bytes32 indexed teamId);

    /**
    * This event is emitted when activated team is deactivated
    * This event is emitted by the function 'deactivateTeam' function
    * 'teamId' is the Id of the Deactivated team
    */
    event TeamDeactivated(bytes32 indexed teamId);

    /**
    * This event is emitted  when the new member is added to the Existed Team
    * This event is emitted by the 'addMember' function
    * 'teamId' is the Id of the Team in which the player is going to be added.
    * 'Member' is the address of the member
    */
    event MemberAdded(bytes32 indexed teamId, address indexed member);

    /**
    * This event is emitted when the existed member is removed from the Team
    * This event is emitted by the 'removeMember' function
    * 'teamId' is the Id of the Team
    * 'member' is the address of the member whose going to be removed from the team
    */
    event MemberRemoved(bytes32 indexed teamId, address indexed member);

    /**
    * This event is emitted when the new Task is Created
    * This event is emitted by the 'createTask' function
    * 'taskId' is the Id of the newly created Task
    * 'assignedMember' is the address of the member is the Task is assigned to a specific member(Can be address(0) if it was assigned to a Team)
    * 'assignedTeam' is the id of the Team (It can be empty if the Task is assigned to specific member)
    * 'infoIpfs' is the IPFS of the Task
    */
    event TaskCreated(
        bytes32 indexed taskId,
        address indexed assignedMember,
        bytes32 indexed assignedTeam,
        string infoIpfs
    );

    /**
    * This event is emitted when the Task is Accepted by the Team
    * This event is emitted by the 'acceptTask' function
    * 'taskId' is the Id of the Task
    * 'acceptor' is the address of the acceptor who accepted the task
    */
    event TaskAccepted(bytes32 indexed taskId, address indexed acceptor);

    /**
    * This event is emitted when the Task is completed
    * This event is emitted by the 'completeTask' function
    * 'taskId' is the Id of the Task
    * 'completionIpfs' is IPFS of the completion Task
    */
    event TaskCompleted(bytes32 indexed taskId, string indexed completionIpfs);

    /**
    * @dev Initialize the contract
    * @param name_ is the name of the Organization
    * @param ipfs_ is the IPFS of the Organization
    * @param admin_ is the admin of the organization
    */
    function initialize(string calldata name_, string calldata ipfs_, address admin_) external;

    /**
    * @dev Creates the new Team in the Organization
    * @param _teamId is the Id of the Team which is created
    * @param _members is the address of the members which are part of the Team
    * Only the Admin of the Organization can call this function
    * emits a `TeamCreated` event
    */
    function createTeam(bytes32 _teamId, address[] calldata _members) external;

    function activateTeam(bytes32 _teamId) external;


    function deactivateTeam(bytes32 _teamId) external;

    function addMemberToTeam(bytes32 _teamId, address _member) external;
    function removeMember(bytes32 _teamId, address _member) external;

    function createTask(
        bytes32 _taskId,
        address _assignedMember,
        bytes32 _assignedTeam,
        string calldata _infoIpfs
    ) external;
    function acceptTask(bytes32 _taskId) external;
    function completeTask(
        bytes32 _taskId,
        string calldata _completionIpfs
    ) external;

    function changeName(string calldata _newName) external;
    function changeIpfs(string calldata _newIpfs) external;
    function changeAdmin(address _newAdmin) external;
    function boom() external;

    function name() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function admin() external view returns (address);
    function guild() external view returns (address);

    function getTeam(bytes32 _teamId) external view returns (Team memory team);
    function getTeamIds() external view returns (bytes32[] memory teamIds);
    function getTask(bytes32 _taskId) external view returns (Task memory task);
    function getTaskIds() external view returns (bytes32[] memory taskIds);
    function getCurrentTaskOf(
        address _member
    ) external view returns (bytes32 taskId);

    function isMember(
        bytes32 _teamId,
        address _member
    ) external view returns (bool);
}
