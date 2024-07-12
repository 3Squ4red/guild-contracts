// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import "./IOrganization.sol";

interface IGuild {
    ///events

    /*
     * ths event is emitted when the new admin is added.
     * `admin` is the address of the admin.
     */
    event AdminAdded(address indexed admin);

    /*
     * This event is emitted when the new organization is deployed.
     * `org` is the address of the deployed organization.
     */
    event OrgDeployed(IOrganization indexed org, address indexed _admin);

    /*
    This event is emitted when the Organization is deleted.
    * `org` is the address of the organization of the contract which was deleted.
    */
    event OrgDeleted(IOrganization indexed org);

    event OrgNameUpdated(address indexed org, string indexed oldName, string indexed newName);
    event OrgIpfsUpdated(address indexed org, string indexed oldIpfs, string indexed newIpfs);

    /*
     * This event is emitted when the admin of the organization contract is updated.
     * `org` is the organization contract .
     * `oldAdmin` is the address of the previous admin of the Organization.
     * `newAdmin` is the address of the new admin of the Oraganization contract.
     */
    event OrgAdminUpdated(
        IOrganization indexed org,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    ///Functions

    function updateName(IOrganization _org, string calldata _newName) external;
    function updateIpfs(IOrganization _org, string calldata _newIpfs) external;

    /*
     * @dev Replaces the existing admin of an organization with a new one.
     * @param _org is the address of the Organization of which the admin will update
     * @param _newAdmin is the address of the new Admin for Organization contract.
     * only the Owner of the Guild can update the Admin.
     * emits a `AdminUpdated` event
     */
    function updateAdmin(IOrganization _org, address _newAdmin) external;

    /*
     * @dev Returns a list of the addresses of all the admins stored via the `addAdmin` or `updateAdmin` functions.
     * It can be accessed by anyone
     */
    function getAdmins() external view returns (address[] memory _admins);

    /*
     * @dev Deploys a new instance of the `Organization` contract. It reverts when an admin calls it more than once.
     * @param `_name` and `_ipfs` are the parameters for the Organization contract deployment
     * Only Admins added through `addAdmin` or `updateAdmin` can call this
     * emits a `OrgDeployed` event
     */
    function deployOrg(string calldata _name, string calldata _ipfs, address _admin) external;

    /*
     * @dev Destroys an `Organization` contract.
     * @param `_org` The address of the Organizaztion which will be deleted.
     * Only the Owner of the Guild can delete organizations
     * emits a `OrgDeleted` event
     */
    function deleteOrg(IOrganization _org) external;

    /*
    @dev Returns a list of addresses of all the `Organization` contracts deployed through the `deployOrg` function.
    */
    function getOrgs() external view returns (address[] memory _orgs);

    function getOrgOf(address _admin) external view returns (address org);
}
