// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IOrganization.sol";
import "./Errors.sol";

contract Organization is IOrganization, Initializable {
    string private _name;
    string private _ipfs;
    address private _admin;
    address private _guild;

    bytes32[] private _teamIds;
    mapping(bytes32 => Team) private _teams;

    bytes32[] private _taskIds;
    mapping(bytes32 => Task) private _tasks;

    mapping(address => bytes32) private _currentTask;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata ipfs_,
        address admin_
    ) external initializer {
        _name = name_;
        _ipfs = ipfs_;
        _admin = admin_;
        _guild = msg.sender;
    }

    modifier validId(bytes32 id) {
        if (id == "") revert InvalidId();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert OnlyAdmin();
        _;
    }

    modifier onlyGuild() {
        if (msg.sender != _guild) revert OnlyGuild();
        _;
    }

    modifier onlyValidTeamId(bytes32 teamId) {
        if (_teams[teamId].teamId == bytes32(0)) revert InvalidTeamId();
        _;
    }

    modifier onlyActiveTeam(bytes32 teamId) {
        if (!_teams[teamId].active) revert OnlyActiveTeam();
        _;
    }

    modifier onlyValidTaskId(bytes32 taskId) {
        if (bytes(_tasks[taskId].infoIpfs).length == 0) revert InvalidTaskId();
        _;
    }

    modifier validAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    //@TODO: add the restriction to prevent a member from being a part of two teams at the same time
    function createTeam(
        bytes32 _teamId,
        address[] calldata _members
    ) external onlyAdmin validId(_teamId) {
        require(_teams[_teamId].teamId == bytes32(0), DuplicateTeamId());
        require(_members.length < 6, Max5AtATime());

        if (_members.length > 0) {
            for (uint i = 0; i < _members.length; i++) {
                address member = _members[i];
                require(_members[i] != address(0), ZeroAddress());

                for (uint j = 0; j < _members.length; j++) {
                    if ((j != i) && (member == _members[j])) {
                        revert DuplicateMember(member);
                    }
                }
            }
        }

        Team memory newTeam = Team({
            teamId: _teamId,
            members: _members,
            active: true
        });
        _teams[_teamId] = newTeam;
        _teamIds.push(_teamId);

        emit TeamCreated(_teamId, _members);
    }

    function activateTeam(
        bytes32 _teamId
    ) external onlyAdmin onlyValidTeamId(_teamId) {
        require(!_teams[_teamId].active, TeamAlreadyActive());

        _teams[_teamId].active = true;

        emit TeamActivated(_teamId);
    }

    function deactivateTeam(
        bytes32 _teamId
    ) external onlyAdmin onlyValidTeamId(_teamId) onlyActiveTeam(_teamId) {
        _teams[_teamId].active = false;

        emit TeamDeactivated(_teamId);
    }

    //@TODO: add the restriction to prevent a member from being a part of two teams at the same time
    function addMemberToTeam(
        bytes32 _teamId,
        address _member
    )
        external
        onlyAdmin
        onlyValidTeamId(_teamId)
        onlyActiveTeam(_teamId)
        validAddress(_member)
    {
        require(!isMember(_teamId, _member), DuplicateMember(_member));

        _teams[_teamId].members.push(_member);

        emit MemberAdded(_teamId, _member);
    }

    function removeMember(
        bytes32 _teamId,
        address _member
    ) external onlyAdmin onlyValidTeamId(_teamId) validAddress(_member) {
        require(isMember(_teamId, _member), InvalidMember());

        uint256 length = _teams[_teamId].members.length;
        for (uint i = 0; i < length; i++) {
            if (_teams[_teamId].members[i] == _member) {
                _teams[_teamId].members[i] = _teams[_teamId].members[
                    length - 1
                ];
                _teams[_teamId].members.pop();

                // update the task this member was doing
                bytes32 currentTask = _currentTask[_member];
                if (currentTask != bytes32(0)) {
                    if (_tasks[currentTask].assignedMember == _member)
                        _tasks[currentTask].assignedMember = address(0);
                    else _tasks[currentTask].acceptor = address(0);
                }
                _currentTask[_member] = bytes32(0);

                emit MemberRemoved(_teamId, _member);
                return;
            }
        }
    }

    //@TODO: add the restriction to prevent a task from being assigned to a member who's not a part of any team
    function createTask(
        bytes32 _taskId,
        address _assignedMember,
        bytes32 _assignedTeam,
        string calldata _infoIpfs
    ) external onlyAdmin validId(_taskId) {
        require(bytes(_tasks[_taskId].infoIpfs).length == 0, DuplicateTaskId());
        require(bytes(_infoIpfs).length > 0, EmptyTaskIpfs());
        // revert if both _assignedMember and _assignedTeam are empty
        if (_assignedMember == address(0) && _assignedTeam == bytes32(0))
            revert InvalidAssignee();
        // revert if both _assignedMember and _assignedTeam are non-empty
        if (_assignedMember != address(0) && _assignedTeam != bytes32(0))
            revert InvalidAssignee();

        if (_assignedMember != address(0)) {
            // the task is assigned to an individual
            _currentTask[_assignedMember] = _taskId;
        } else {
            // the task is assigned to a team
            assert(_assignedTeam != bytes32(0));
            require(
                _teams[_assignedTeam].teamId != bytes32(0),
                InvalidTeamId()
            );
            require(_teams[_assignedTeam].active, OnlyActiveTeam());
        }

        Task memory newTask = Task({
            assignedMember: _assignedMember,
            assignedTeam: _assignedTeam,
            acceptor: address(0),
            infoIpfs: _infoIpfs,
            completionIpfs: ""
        });
        _tasks[_taskId] = newTask;
        _taskIds.push(_taskId);

        emit TaskCreated(_taskId, _assignedMember, _assignedTeam, _infoIpfs);
    }

    function acceptTask(bytes32 _taskId) external onlyValidTaskId(_taskId) {
        address assignedMember = _tasks[_taskId].assignedMember;
        address acceptor = _tasks[_taskId].acceptor;
        bytes32 assignedTeam = _tasks[_taskId].assignedTeam;
        require(
            assignedMember == address(0),
            TaskNotAssignedToATeam(assignedMember)
        );
        // following should hold
        assert(_tasks[_taskId].assignedTeam != bytes32(0));
        require(acceptor == address(0), TaskAlreadyAccepted(acceptor));
        require(
            isMember(assignedTeam, msg.sender),
            CallerNotMemberOfTaskTeam(assignedTeam)
        );

        _tasks[_taskId].acceptor = msg.sender;
        _currentTask[msg.sender] = _taskId;

        emit TaskAccepted(_taskId, msg.sender);
    }

    function completeTask(
        bytes32 _taskId,
        string calldata _completionIpfs
    ) external onlyValidTaskId(_taskId) {
        require(bytes(_completionIpfs).length > 0, EmptyTaskIpfs());
        require(
            _tasks[_taskId].assignedMember == msg.sender ||
                _tasks[_taskId].acceptor == msg.sender,
            CallerNeitherAcceptorNorAssigned()
        );
        // following should hold
        assert(_currentTask[msg.sender] == _taskId);
        require(
            bytes(_tasks[_taskId].completionIpfs).length == 0,
            TaskAlreadyCompleted()
        );

        _tasks[_taskId].completionIpfs = _completionIpfs;
        _currentTask[msg.sender] = bytes32(0);

        emit TaskCompleted(_taskId, _completionIpfs);
    }

    function changeName(string calldata _newName) external onlyGuild {
        _name = _newName;
    }

    function changeIpfs(string calldata _newIpfs) external onlyGuild {
        _ipfs = _newIpfs;
    }

    function changeAdmin(address _newAdmin) external onlyGuild {
        _admin = _newAdmin;
    }

    //@TODO: use a bool flag to mark the Org as deleted instead of using selfdestruct
    function boom() external onlyGuild {
        selfdestruct(payable(_guild));
    }

    // view functions

    function name() external view returns (string memory) {
        return _name;
    }
    function ipfs() external view returns (string memory) {
        return _ipfs;
    }
    function admin() external view returns (address) {
        return _admin;
    }
    function guild() external view returns (address) {
        return _guild;
    }

    function getTeam(bytes32 _teamId) external view returns (Team memory team) {
        team = _teams[_teamId];
    }

    function getTeamIds() external view returns (bytes32[] memory teamIds) {
        teamIds = _teamIds;
    }

    function getTask(bytes32 _taskId) external view returns (Task memory task) {
        task = _tasks[_taskId];
    }

    function getTaskIds() external view returns (bytes32[] memory taskIds) {
        taskIds = _taskIds;
    }

    function getCurrentTaskOf(
        address _member
    ) external view returns (bytes32 taskId) {
        taskId = _currentTask[_member];
    }

    function isMember(
        bytes32 _teamId,
        address _member
    ) public view returns (bool) {
        uint256 length = _teams[_teamId].members.length;
        for (uint i = 0; i < length; i++) {
            if (_teams[_teamId].members[i] == _member) {
                return true;
            }
        }
        return false;
    }
}
