// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/Guild.sol";
import "../src/interfaces/IOrganization.sol";
import "../src/Organization.sol";

contract GuildTest is Test {
    Guild guild;
    Organization Original_org;
    address[] public organizations;
    address[] public Admins;

    address alice = makeAddr("alice");
    address bob = makeAddr("Bob");
    address kumar = makeAddr("kumar");

    //EVENTS
    event AdminAdded(address indexed admin);
    event OrgDeployed(IOrganization indexed org, address indexed _admin);
    event OrgDeleted(IOrganization indexed org);
    event OrgNameUpdated(
        address indexed org,
        string indexed oldName,
        string indexed newName
    );
    event OrgIpfsUpdated(
        address indexed org,
        string indexed oldIpfs,
        string indexed newIpfs
    );
    event OrgAdminUpdated(
        IOrganization indexed org,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    //Test Functions
    function setUp() external {
        Original_org = new Organization();
        guild = new Guild(address(Original_org));
    }

    function DeployOrganization() public returns (address) {
        guild.deployOrg("Organization1", "IPFS1", alice);
        organizations = guild.getOrgs();
        address organization = organizations[0];
        return organization;
    }

    /**
    @dev --> This function deploys the Organization contract and check it was deployed or not.
    Case1 --> Deploy Organization and Test the address
    */
    function testDeployOrg1() external {
        assertEq(organizations.length, 0);
        address org = DeployOrganization();
        assertEq(org, guild.getOrgOf(alice));
        assertTrue(org != address(0));
        assertTrue(organizations.length == 1);

        //Check the names and IpFs of the deployed Organization.
        IOrganization organization = IOrganization(org);
        assertEq(organization.name(), "Organization1");
        console.log(
            "The Name of the Deployed Organization is ",
            organization.name()
        );
        assertEq(organization.ipfs(), "IPFS1");
        console.log(
            "IPFS of the Deployed Organization is ",
            organization.ipfs()
        );
        Admins = guild.getAdmins();
        assertEq(Admins[0], alice);
    }

    //Case2 --> What if the Admin try to deploy multiple organizations (Must Revert)
    function testDeployOrg2() external {
        address org = DeployOrganization();
        vm.expectRevert(
            abi.encodeWithSelector(
                OrgAlreadyDeployedForAdmin.selector,
                alice,
                org
            )
        );
        DeployOrganization();
    }

    //Case2 --> Can the Two Organizations have the same name
    //Todo --> Better if the names also check to be unique
    function testDeployOrg3() external {
        DeployOrganization();
        guild.deployOrg("Organization1", "IPFS1", bob);
    }

    //Case3 --> check if Non - owner can deploy Organizations
    function testDeployOrg4() external {
        vm.startPrank(alice);
        vm.expectRevert();
        guild.deployOrg("Organization1", "IPFS", alice);
        vm.stopPrank();
    }
    //Case4 --> check if the "name" "IPFS" "admin" can be empty
    function testDeployOrgEmptyName() external {
        vm.expectRevert(EmptyOrgName.selector);
        guild.deployOrg("", "IPFS1", alice);
        vm.expectRevert(EmptyOrgIpfs.selector);
        guild.deployOrg("Org1", "", bob);
    }

    /**
    @dev --> This functions tests the 'updateName' function in the Guild contract
    case1 --> Normal Working Test
    */
    function testupdateName1() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.expectEmit(true, true, true, false);
        emit OrgNameUpdated(org, "Organization1", "New Organization");
        guild.updateName(organization, "New Organization");
        assertEq(organization.name(), "New Organization");
    }

    //Case2 --> check the access control for 'UpdateName' function.
    function testupdateName2() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.startPrank(alice);
        vm.expectRevert();
        guild.updateName(organization, "New Organization");
    }

    //Case2 --> Check if the new name can be Empty(Must Revert if new name is empty)
    function testupdateName3() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.expectRevert(EmptyOrgName.selector);
        guild.updateName(organization, "");
    }

    //Case3 --> check if the owner tries to change the invalid organization name
    function testupdateName4() external {
        DeployOrganization();
        address fakeAddr = makeAddr("fakeaddress");
        IOrganization organization = IOrganization(fakeAddr);
        vm.expectRevert(InvalidOrg.selector);
        guild.updateName(organization, "FakeOrganization");
    }

    /** 
    @dev --> This function tests the updateIPFS function in the guild conctract
    case1 --> Normal Working Test 
    */
    function testupdateIPFS1() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.expectEmit(true, true, true, false);
        emit OrgIpfsUpdated(org, "IPFS1", "IPFS2");
        guild.updateIpfs(organization, "IPFS2");
        assertEq(organization.ipfs(), "IPFS2");
    }

    //case2 --> check if the new IPfs can be empty (Must not be empty)
    function testupdateIPFS2() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.expectRevert(EmptyOrgIpfs.selector);
        guild.updateIpfs(organization, "");
    }

    //case3 --> check access control of the 'updateIPFS' function
    function testupdateIPFS3() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.startPrank(alice);
        vm.expectRevert();
        guild.updateIpfs(organization, "New IPFS");
    }

    //Case4  --> check if the IPFS can be updated to invalid organization
    function testupdateAdminIPFS4() external {
        DeployOrganization();
        address fakeOrg = makeAddr("fakeOrg");
        IOrganization organization = IOrganization(fakeOrg);
        vm.expectRevert(InvalidOrg.selector);
        guild.updateIpfs(organization, "newIPFS");
    }

    /**
    @dev --> This function tests the 'UpdateAdmin' function in the Guild contract
    case1 --> Normal Working Test
    */
    function testupdateAdmin1() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        assertEq(organization.admin(), alice);
        vm.expectEmit(true, true, true, false);
        emit OrgAdminUpdated(organization, alice, bob);
        guild.updateAdmin(organization, bob);
        assertEq(organization.admin(), bob);
    }

    //Case2 --> Check who can access the Admin (Only Owner)
    function testupdateAdmin2() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.startPrank(alice);
        vm.expectRevert();
        guild.updateAdmin(organization, bob);
    }

    //case3  --> Check Valid organization or not
    function testupdateAdmin3() external {
        DeployOrganization();
        address fakeaddr = makeAddr("fakeAddress");
        IOrganization organization = IOrganization(fakeaddr);
        vm.expectRevert(InvalidOrg.selector);
        guild.updateAdmin(organization, bob);
    }

    //Case4 --> check If the Owner can add the admin
    //Who is already an admin of another organization
    function testupdateAdmin4() external {
        address org = DeployOrganization();
        //IOrganization organization = IOrganization(org);
        vm.expectRevert(
            abi.encodeWithSelector(
                OrgAlreadyDeployedForAdmin.selector,
                alice,
                org
            )
        );
        guild.deployOrg("Organization2", "IPFS2", alice);
    }

    //Case5  --> check if the Admin can add again to another organization
    function testupdateAdmin5() external {
        guild.deployOrg("Organization1", "IPFS1", alice);
        organizations = guild.getOrgs();
        address alice_org = organizations[0];
        IOrganization alice_organization = IOrganization(alice_org);
        guild.deployOrg("Organization2", "IPFS2", bob);
        organizations = guild.getOrgs();
        address bob_org = organizations[1];
        //IOrganization bob_organization = IOrganization(bob_org);
        console.log("alice organization is ", alice_org);
        console.log("Bob Organization is ", bob_org);
        //Tries to give the alice org to bob
        vm.expectRevert(
            abi.encodeWithSelector(NewAdminAlreadyInUse.selector, bob_org)
        );
        guild.updateAdmin(alice_organization, bob);
    }

    //Case6 --> check wheather the old Admin is removed or not
    function testupdateAdmin6() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        guild.updateAdmin(organization, kumar);
        Admins = guild.getAdmins();
        assertEq(Admins.length, 1);
        assertEq(Admins[0], kumar);
    }
    /**
    @dev --> This function tests the 'deleteOrg' in the Guiild contract
    case1 --> Normal Workig Test
    */
    function testdeleteOrg1() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.expectEmit(true, false, false, false);
        emit OrgDeleted(organization);
        guild.deleteOrg(organization);
        address _org = guild.getOrgOf(alice);
        assertEq(_org, address(0));
    }

    //Case2 --> check the Access control of the 'deleteOrg' function
    function testdeleteOrg2() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.startPrank(bob);
        vm.expectRevert();
        guild.deleteOrg(organization);
    }
    //Case3  --> check if we can delete the invalid Organization
    function testdeleteOrg3() external {
        DeployOrganization();
        //IOrganization organization = IOrganization(org);
        address fakeAddr = makeAddr("fakeAddress");
        IOrganization fakeOrganization = IOrganization(fakeAddr);
        vm.expectRevert(InvalidOrg.selector);
        guild.deleteOrg(fakeOrganization);
    }

    //@audit --> ZERO Address check is missing
    function testDeployOrgEmptyAdmin() external {
        vm.expectRevert();
        guild.deployOrg("Org1", "IPFS1", address(0));
    }

    function testOnlyOwnerCanUpdateName() external {
        address org = DeployOrganization();
        IOrganization organization = IOrganization(org);
        vm.startPrank(bob);
        vm.expectRevert();
        guild.updateName(organization, "NewName");
    }
}
