// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {IGuild} from "./interfaces/IGuild.sol";
import "./Organization.sol";
import "./Errors.sol";

contract Guild is IGuild, Ownable2Step {
    using EnumerableSet for EnumerableSet.AddressSet;

    address private immutable ORG_IMPL;

    EnumerableSet.AddressSet private _admins;
    EnumerableSet.AddressSet private _orgs;

    mapping(address => address) private _adminToOrg;

    constructor(address _orgImpl) Ownable(msg.sender) {
        ORG_IMPL = _orgImpl;
    }

    modifier validOrg(IOrganization _org) {
        if (!_orgs.contains(address(_org))) revert InvalidOrg();
        _;
    }

    modifier validateOrgDeployment(
        string memory _name,
        string memory _ipfs,
        address _admin
    ) {
        if (bytes(_name).length == 0) revert EmptyOrgName();
        if (bytes(_ipfs).length == 0) revert EmptyOrgIpfs();
        if (_admin == address(0)) revert ZeroAddress();
        if (_admins.contains(_admin))
            revert OrgAlreadyDeployedForAdmin(_admin, getOrgOf(_admin));
        assert(_adminToOrg[_admin] == address(0));
        _;
    }

    function deployOrg(
        string calldata _name,
        string calldata _ipfs,
        address _admin
    ) external onlyOwner validateOrgDeployment(_name, _ipfs, _admin) {
        IOrganization org = IOrganization(Clones.clone(ORG_IMPL));
        org.initialize(_name, _ipfs, _admin);

        _orgs.add(address(org));
        _admins.add(_admin);
        _adminToOrg[_admin] = address(org);

        emit OrgDeployed(org, _admin);
    }

    function updateName(
        IOrganization _org,
        string calldata _newName
    ) external onlyOwner validOrg(_org) {
        if (bytes(_newName).length == 0) revert EmptyOrgName();

        string memory oldName = _org.name();
        _org.changeName(_newName);

        emit OrgNameUpdated(address(_org), oldName, _newName);
    }

    function updateIpfs(
        IOrganization _org,
        string calldata _newIpfs
    ) external onlyOwner validOrg(_org) {
        if (bytes(_newIpfs).length == 0) revert EmptyOrgIpfs();

        string memory oldIpfs = _org.ipfs();
        _org.changeIpfs(_newIpfs);

        emit OrgIpfsUpdated(address(_org), oldIpfs, _newIpfs);
    }

    function updateAdmin(
        IOrganization _org,
        address _newAdmin
    ) external onlyOwner validOrg(_org) {
        require(
            !_admins.contains(_newAdmin),
            NewAdminAlreadyInUse(getOrgOf(_newAdmin))
        );
        address oldAdmin = _org.admin();

        bool isRemoved = _admins.remove(oldAdmin);
        assert(isRemoved); // old admin should be in _admins
        _admins.add(_newAdmin);
        _adminToOrg[oldAdmin] = address(0);
        _adminToOrg[_newAdmin] = address(_org);

        _org.changeAdmin(_newAdmin);

        emit OrgAdminUpdated(_org, oldAdmin, _newAdmin);
    }

    function deleteOrg(IOrganization _org) external onlyOwner validOrg(_org) {
        address admin = _org.admin();

        _orgs.remove(address(_org));
        _admins.remove(admin);
        _adminToOrg[admin] = address(0);

        _org.boom();

        emit OrgDeleted(_org);
    }

    function getAdmins() external view returns (address[] memory admins) {
        admins = _admins.values();
    }

    function getOrgs() external view returns (address[] memory orgs) {
        orgs = _orgs.values();
    }

    function getOrgOf(address _admin) public view returns (address org) {
        org = _adminToOrg[_admin];
    }
}
