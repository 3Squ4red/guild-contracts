// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/Guild.sol";
import "../src/interfaces/IOrganization.sol";
import "../src/Organization.sol";

contract OrganizationTest is Test {
    Guild guild;
    IOrganization Original_org;
    address[] public organizations;
    address[] public Admins;

    //Addresses
    address Player1 = makeAddr("Player1");
    address Player2 = makeAddr("Player2");
    address Player3 = makeAddr("Player3");
    address Player4 = makeAddr("Player4");
    address Player5 = makeAddr("Player5");
    address Player6 = makeAddr("player6");

    address alice = makeAddr("Alice");
    address bob = makeAddr("bob");

    //EVENTS
    event TeamCreated(bytes32 indexed teamId, address[] indexed members);
    event TeamActivated(bytes32 indexed teamId);
    event TeamDeactivated(bytes32 indexed teamId);
    event MemberAdded(bytes32 indexed teamId, address indexed member);
    event MemberRemoved(bytes32 indexed teamId, address indexed member);
    event TaskCreated(
        bytes32 indexed taskId,
        address indexed assignedMember,
        bytes32 indexed assignedTeam,
        string infoIpfs
    );
    event TaskAccepted(bytes32 indexed taskId, address indexed acceptor);
    event TaskCompleted(bytes32 indexed taskId, string indexed completionIpfs);

    function setUp() external {
        Original_org = new Organization();
        guild = new Guild(address(Original_org));
    }

    function DeployOrganization() public returns (IOrganization) {
        guild.deployOrg("Organization1", "IPFS1", alice);
        organizations = guild.getOrgs();
        address organization = organizations[0];
        IOrganization org = IOrganization(organization);
        return org;
    }
    function createTeam() public returns (IOrganization) {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](5);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;
        players[4] = Player5;
        org.createTeam("Team1", players);
        vm.stopPrank();
        return org;
    }

    /**
    @dev --> This functions tests the 'createTeam' function in the Organization contract
    case1 --> Normal Working Test
    */

    function testCreateTeam1() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](5);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;
        players[4] = Player5;

        vm.expectEmit(true, true, false, false);
        emit TeamCreated("Team1", players);
        org.createTeam("Team1", players);

        vm.stopPrank();
    }

    //Case2  --> Check if the Non Admin can crate the Team
    function testcreateTeam2() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(bob);
        address[] memory players = new address[](5);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;
        players[4] = Player5;
        vm.expectRevert(OnlyAdmin.selector);
        org.createTeam("Team1", players);
        vm.stopPrank();
    }

    //Case3 --> Check If the TeamId can be invalid
    function testcreateTeam3() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](5);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;
        players[4] = Player5;
        vm.expectRevert(InvalidId.selector);
        org.createTeam("", players);
        vm.stopPrank();
    }

    //Case4 --> check If the TeamId is already existed Id
    function testcreateTeam4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        address player7 = makeAddr("Player7");
        address[] memory _players = new address[](2);
        _players[0] = Player6;
        _players[1] = player7;
        vm.expectRevert(DuplicateTeamId.selector);
        org.createTeam("Team1", _players);
        vm.stopPrank();
    }

    //Case5 --> check if the members lenght can be more than 5
    function testcreateTeam5() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](6);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;
        players[4] = Player5;
        players[5] = Player6;
        vm.expectRevert(Max5AtATime.selector);
        org.createTeam("Team1", players);
        vm.stopPrank();
    }

    //Case6 --> Check If there is any Duplicate address in the given members
    function testcreateTeam6() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](5);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player1;
        players[3] = Player4;
        players[4] = Player1;
        vm.expectRevert(
            abi.encodeWithSelector(DuplicateMember.selector, Player1)
        );
        org.createTeam("Team1", players);
    }

    //Case7 --> Check If the address can be Zero address in the the team creation
    function testcreateTeam7() external {
        IOrganization org = DeployOrganization();
        address[] memory players = new address[](5);
        vm.startPrank(alice);
        players[0] = Player1;
        players[1] = address(0);
        players[2] = Player2;
        players[3] = Player3;
        players[4] = Player4;
        vm.expectRevert(ZeroAddress.selector);
        org.createTeam("Team1", players);
    }

    //Check8  --> Check If the Teams can be empty
    //Todo --> The members can't be empty has to check
    function testcreate8() external {
        IOrganization org = DeployOrganization();
        address[] memory players = new address[](0);
        vm.startPrank(alice);
        //vm.expectEmit(true,true,false,false);
        org.createTeam("Team1", players);
    }

    /**
    @dev --> The function tests the 'ActivateTeam' function in the Organization contract
    //Case1 --> Normal working Test 
    */
    function testActivateTeam1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.deactivateTeam("Team1");
        vm.expectEmit(true, false, false, false);
        emit TeamActivated("Team1");
        org.activateTeam("Team1");
    }

    //Case2 --> Check The Access control
    function testActivateTeam2() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.deactivateTeam("Team1");
        vm.startPrank(bob);
        vm.expectRevert(OnlyAdmin.selector);
        org.activateTeam("Team1");
    }
    //Case3 --> check if we activate the invalid Team Id
    function testActivateTeam3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.deactivateTeam("Team1");
        vm.expectRevert(InvalidTeamId.selector);
        org.activateTeam("InvalidTeamId");
        vm.stopPrank();
    }

    //Case4  --> check If we activate the test which is already active
    function testActivateTeam4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(TeamAlreadyActive.selector);
        org.activateTeam("Team1");
        vm.stopPrank();
    }

    //Check5 --> check the Teams struct
    function testActivateTeam5() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        Team memory team = org.getTeam("Team1");
        assertEq(team.active, true);
        assertEq(team.teamId, "Team1");
        assertEq(team.members[0], Player1);
        assertEq(team.members[4], Player5);
    }

    /**
    @dev --> Function to test  'deactivateTeam' in the Organization contract
    Case1 --> Normal functionality check
    */
    function testdeactivateTeam1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectEmit(true, false, false, false);
        emit TeamDeactivated("Team1");
        org.deactivateTeam("Team1");
    }

    //Case2  --> Check the Access control of the 'deactivateTeam' function
    function testdeactivateTeam2() external {
        IOrganization org = createTeam();
        vm.startPrank(bob);
        vm.expectRevert(OnlyAdmin.selector);
        org.deactivateTeam("Team1");
    }

    //Case3  --> check If the Admin can chnage the Invalid TeamId
    function testdeactivateTeam3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidTeamId.selector);
        org.deactivateTeam("Team2");
    }

    //Case4  --> check The Team struct
    function testdeactivateTeam4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.deactivateTeam("Team1");
        Team memory team = org.getTeam("Team1");
        assertEq(team.active, false);
    }

    /**
    @dev --> Function to test the 'addMemberToTeam' Function in the Organization contract
    Case1 --> Normal working Test
    */
    function testaddMemberToTeam1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectEmit(true, true, false, false);
        emit MemberAdded("Team1", Player6);
        org.addMemberToTeam("Team1", Player6);
    }

    //Case2 --> Check the access control of the 'addMemberToTeam' function
    function testaddMemberToTeam2() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](4);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;

        org.createTeam("Team1", players);
        vm.startPrank(bob);
        vm.expectRevert(OnlyAdmin.selector);
        org.addMemberToTeam("Team1", Player5);
    }

    //Case3 --> check If we can add members of the Team to make the Team Size more than 5.
    function testAddMemberToTeam3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.addMemberToTeam("Team1", Player6);
        Team memory team = org.getTeam("Team1");
        assertEq(team.members.length, 6);
    }

    //Case4 --> check If we Pass the Invalid TeamId
    function testaddMemberToTeam4() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](4);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;

        org.createTeam("Team1", players);
        vm.expectRevert(InvalidTeamId.selector);
        org.addMemberToTeam("Team2", Player5);
    }

    //Case5 --> Check If we can add member to the inActive Team
    function testaddMemberToTeam5() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](4);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;

        org.createTeam("Team1", players);
        org.deactivateTeam("Team1");
        vm.expectRevert(OnlyActiveTeam.selector);
        org.addMemberToTeam("Team1", Player5);
    }

    //Case6 --> Check If we can add the Invalid address to the Team
    function testAddMemberToTeam6() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](4);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;

        org.createTeam("Team1", players);
        vm.expectRevert(ZeroAddress.selector);
        org.addMemberToTeam("Team1", address(0));
    }

    //Case7 --Check If Admin can add the DuplicateAddresses
    function testAddMemberToTeam7() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](4);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;

        org.createTeam("Team1", players);
        vm.expectRevert(
            abi.encodeWithSelector(DuplicateMember.selector, Player4)
        );
        org.addMemberToTeam("Team1", Player4);
    }

    //Check If the Team struct is updated Properly
    function testAddMemberToTeam8() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](4);
        players[0] = Player1;
        players[1] = Player2;
        players[2] = Player3;
        players[3] = Player4;

        org.createTeam("Team1", players);
        org.addMemberToTeam("Team1", Player5);
        Team memory team = org.getTeam("Team1");
        assertEq(team.members[4], Player5);
    }

    /**
    @dev --> This function is to test the 'removeMember' function in the Organization contract
    //Check1 --> Normal Working Test
    */

    function testremoveMember1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.removeMember("Team1", Player1);
        Team memory team = org.getTeam("Team1");
        assertTrue(team.members[0] != Player1);
        assertEq(team.members.length, 4);
    }

    //Case2 --> Check the Access control of the 'removeMember' function
    function testremoveMember2() external {
        IOrganization org = createTeam();
        vm.startPrank(bob);
        vm.expectRevert(OnlyAdmin.selector);
        org.removeMember("Team1", Player1);
    }

    //Case3 --> check the TeamId If its valid or Invalid
    function testremoveMember3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidTeamId.selector);
        org.removeMember("FakeTeamId", Player1);
    }

    //Case4 --> Check If the Member tries to remove is not already a member
    function testremoveMember4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidMember.selector);
        org.removeMember("Team1", Player6);
    }

    //Case5 --> check the '_member' input parameter if it can be address(0)
    function testremoveMember5() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(ZeroAddress.selector);
        org.removeMember("Team1", address(0));
    }
    //Case6  --> check If the  Task is updating after removing the member
    //Removing the individual if he has task assigned.
    function testremovemember6() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", Player2, "", "InfoIpfs");
        vm.expectEmit(true, true, false, false);
        emit MemberRemoved("Team1", Player1);
        org.removeMember("Team1", Player1);
    }

    //Case7 --> Remove the member of the Team who has accepted the Task and another individual accepts the Task of the Removed individual
    //@audit -- More than one Individual has the same Task assigned due to not updating the currentTask
    function testRemoveMember7() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "Sample");
        vm.startPrank(Player1);
        org.acceptTask("Task1");
        bytes32 taskid = org.getCurrentTaskOf(Player1);
        assertEq(taskid, "Task1");

        vm.startPrank(alice);
        org.removeMember("Team1", Player1);

        vm.startPrank(Player2);
        org.acceptTask("Task1");
        bytes32 task = org.getCurrentTaskOf(Player2);
        bytes32 task1 = org.getCurrentTaskOf(Player1);
        assertEq(task1, "");
        assertEq(task, "Task1");
    }

    //Case8 --> Check if the Individual of the Team has assigned a task after that the individual has been removed and after that the task was accepted by another Team member
    // After that the admin adds the member again who was removed and check if he has the sam task assigned and submit the Task.
    //@audit
    function testRemoveMember8() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "SampleIpfs");
        vm.startPrank(Player1);
        org.acceptTask("Task1");
        vm.stopPrank();
        vm.startPrank(alice);
        org.removeMember("Team1", Player1);
        vm.startPrank(Player2);
        org.acceptTask("Task1");
        vm.stopPrank();
        vm.startPrank(alice);
        org.addMemberToTeam("Team1", Player1);
        vm.stopPrank();
        //bytes32 Player1Task = org.getCurrentTaskOf(Player1);
        bytes32 Player2Task = org.getCurrentTaskOf(Player2);
        //assertEq(Player1Task,"Task1");
        assertEq(Player2Task, "Task1");
    }

    /**
    @dev --> This function test the 'createTask()' function in the Organization contract
    Case1  --> Normal working Test
    */
    function testCreateTask1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit TaskCreated("Task1", Player1, "", "InfoIpfs");
        org.createTask("Task1", Player1, "", "InfoIpfs");
    }

    //Case2 --> Test the Access control of the 'CreateTask' function
    function testCreateTask2() external {
        IOrganization org = createTeam();
        vm.startPrank(bob);
        vm.expectRevert(OnlyAdmin.selector);
        org.createTask("Task1", Player1, "", "InfoIpfs");
    }
    //Case3 --> Test If the 'TaskId' can be empty
    function testCreateTask3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidId.selector);
        org.createTask("", Player1, "", "IPFS");
    }
    //Case4 --> check If its working as expect for the Team
    function testCreateTask4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit TaskCreated("Task1", address(0), "Team1", "ExampleIPFS");
        org.createTask("Task1", address(0), "Team1", "ExampleIPFS");
    }

    //Case5 --> check if the If we can give the duplicate TaskId
    function testCreateTask5() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "ExampleIPFS");
        vm.expectRevert(DuplicateTaskId.selector);
        org.createTask("Task1", Player1, "", "IPFSREV");
    }

    //Case6  --> check If we can give the empty IPfs
    function testCreateTask6() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(EmptyTaskIpfs.selector);
        org.createTask("Task1", address(0), "Team1", "");
    }

    //Case7  --> Check If we can Give the both 'Team' and 'Member' as empty
    function testCreateTask7() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidAssignee.selector);
        org.createTask("Task1", address(0), "", "ExpIPFs");
    }

    //Case8 --> check If we can give the both 'Team' and 'Member' as non empty
    function testCreateTask8() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidAssignee.selector);
        org.createTask("Task1", Player1, "Team1", "ExpIPFs");
    }

    //Case9 --> check If the Task Assigned To member correctly
    function testcreateTask9() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", Player1, "", "ExpIPFs");
        bytes32 tasks = org.getCurrentTaskOf(Player1);
        assertEq(tasks, "Task1");
    }

    //Case10  --> check If we createTask to the InactiveTeam
    function testcreateTask10() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.deactivateTeam("Team1");
        vm.expectRevert(OnlyActiveTeam.selector);
        org.createTask("Task1", address(0), "Team1", "ExampleIPFs");
    }

    //Case11 --> Check if we assign the Task to the Invalid team(Team Which is not created)
    function testCreateTask11() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        vm.expectRevert(InvalidTeamId.selector);
        org.createTask("Task1", address(0), "Team2", "ExampleIpfs");
    }

    //Case12 --> check the Task struct IF it was assigned Correctly or not
    function testcreateTask12() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "sampleIPFS");
        Task memory task = org.getTask("Task1");
        assertEq(task.assignedMember, address(0));
        assertEq(task.assignedTeam, "Team1");
        assertEq(task.acceptor, address(0));
        assertEq(task.completionIpfs, "");
        org.createTask("Task2", Player1, "", "SampleIPFS");
        Task memory task1 = org.getTask("Task2");
        assertEq(task1.assignedMember, Player1);
        assertEq(task1.assignedTeam, "");
        assertEq(task1.acceptor, address(0));
        assertEq(task1.infoIpfs, "SampleIPFS");
    }

    /**
    @dev --> function to check the 'acceptTask' function in the organizatioin contract
    //Check1 --> Normal Working Test
    */
    function testAcceptTask1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "sampleIPFS");
        //Task memory task = org.getTask("Task1");
        vm.stopPrank();
        vm.startPrank(Player1);
        vm.expectEmit(true, true, false, false);
        emit TaskAccepted("Task1", Player1);
        org.acceptTask("Task1");
        vm.stopPrank();
    }
    //Check if the AcceptTask Function is working properly if the  individual access the function
    function testAcceptTest2() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", Player1, "", "Sample");
        vm.stopPrank();

        vm.startPrank(Player1);
        vm.expectRevert(
            abi.encodeWithSelector(TaskNotAssignedToATeam.selector, Player1)
        );
        org.acceptTask("Task1");
    }

    //Check3 --> Check If we can accept the already accepted Task
    function testAcceptTask3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "Sample");
        vm.stopPrank();
        vm.startPrank(Player1);
        org.acceptTask("Task1");
        vm.expectRevert(
            abi.encodeWithSelector(TaskAlreadyAccepted.selector, Player1)
        );
        org.acceptTask("Task1");
    }

    //Check4  --> Check if the Non Team member tries to accept the task
    function testAcceptTask4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "Sample");
        vm.stopPrank();
        vm.startPrank(Player6);
        vm.expectRevert(
            abi.encodeWithSelector(
                CallerNotMemberOfTaskTeam.selector,
                bytes32("Team1")
            )
        );
        org.acceptTask("Task1");
    }

    /**
    @dev --> This functions test the 'completeTask' function in the organization contract
    Case1 --> Normal working test
    */
    function testCompleteTask1() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "Sample");
        vm.stopPrank();
        vm.startPrank(Player1);
        org.acceptTask("Task1");
        vm.expectEmit(true, true, false, false);
        emit TaskCompleted("Task1", "completionIPFs");
        org.completeTask("Task1", "completionIPFs");
    }

    //Case2  --> Try testing with Invalid TaskId
    function testCompleteTask2() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "Sample");
        vm.stopPrank();
        vm.startPrank(Player1);
        org.acceptTask("Task1");
        vm.expectRevert(InvalidTaskId.selector);
        org.completeTask("Task2", "completionIPFS");
    }

    //Case3 --> check the competion IPFS can be empty
    function testCompeleteTask3() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", address(0), "Team1", "Sample");
        vm.stopPrank();
        vm.startPrank(Player1);
        org.acceptTask("Task1");
        vm.expectRevert(EmptyTaskIpfs.selector);
        org.completeTask("Task1", "");
    }

    //Check4  --> Check if the unAuthorised address tries to complete the task
    function testCompleteTask4() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", Player6, "", "Sample");
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(CallerNeitherAcceptorNorAssigned.selector);
        org.completeTask("Task1", "completionIPFS");
        vm.stopPrank();

        vm.startPrank(alice);
        org.createTask("Task2", address(0), "Team1", "Sample");
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(CallerNeitherAcceptorNorAssigned.selector);
        org.completeTask("Task1", "CompletionIPFs");
        vm.stopPrank();
    }

    //Case5  --> checking 'CompleteTask' function with the single Member
    function testCompleteTask5() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", Player1, "", "Sample");
        vm.stopPrank();
        vm.startPrank(Player1);
        org.completeTask("Task1", "CompletionIPfs");
    }

    //Case6 --> complete the Task if the Task is Already comleted
    function testCompleteTask6() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        org.createTask("Task1", Player1, "", "Sample");
        vm.stopPrank();
        vm.startPrank(Player1);
        org.completeTask("Task1", "CompletionIPFS");
        vm.stopPrank();
        vm.startPrank(Player1);
        vm.expectRevert(); //Assertion Failed and the code will Panic
        org.completeTask("Task1", "CompetionIpfs");
    }

    /**
    @dev Check the 'ChangeName' function 
    */
    function testChangeName() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(address(guild));
        org.changeName("New Oraganization");
        string memory newname = org.name();
        assertEq(newname, "New Oraganization");
    }

    /**
    @dev --> Check for changeIpfs() function 
    
    */
    function testChangeIPfs() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(address(guild));
        org.changeIpfs("New IPFS");
        string memory newIpfs = org.ipfs();
        assertEq(newIpfs, "New IPFS");
    }

    /**
    @dev --> check the changeAdmin() function
    */
    function testChageAdmin() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(address(guild));
        org.changeAdmin(bob);
        address newAdmin = org.admin();
        assertEq(newAdmin, bob);
    }

    /**
    @dev Test the boom() function
    */
    function testBoom() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(address(guild));

        // Call the boom function
        org.boom();
    }

    /**
    Check --> check the 'isMember' function 
    */
    function testisMember() external {
        IOrganization org = createTeam();
        vm.startPrank(alice);
        bool success = org.isMember("Team1", Player1);
        assertEq(true, success);
        bool success1 = org.isMember("Team1", bob);
        assertEq(false, success1);
    }

    //Assumptions

    //Can the Remove Member will work fine If there is only one member in the Team.
    function testremoveMember() external {
        IOrganization org = DeployOrganization();
        vm.startPrank(alice);
        address[] memory players = new address[](1);
        players[0] = Player1;
        org.createTeam("Team1", players);
        org.removeMember("Team1", Player1);
        Team memory team = org.getTeam("Team1");
        assertEq(team.members.length, 0);
        //bool success = org.isMember("Team1",Player1);
        //assertEq(success,false);
        bool success = org.isMember("Team1", address(0));
        assertEq(success, false);
        vm.stopPrank();
    }
}
