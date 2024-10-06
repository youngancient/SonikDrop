// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./SonikDrop.sol";
import "./Utils.sol";

contract SonikDropFactory {
    //  when a person interacts with the factory, he would options like
    // 1. Adding an NFT requirement
    // 2. Adding a time lock
    address collector;

    uint256 public cloneCount;

    mapping(address => SonikDrop[]) ownerToSonikDropClones;

    SonikDrop[] allSonikDropClones;

    uint256 baseFee;

    constructor() {
        collector = msg.sender;
    }

    function _onlyCollector() private view {
        if (msg.sender != collector) {
            revert Errors.UnAuthorizedFunctionCall();
        }
    }

    function _chargeFee(uint256 _noOfClaimers) private {
        uint256 fee = baseFee * _noOfClaimers;
        if (msg.value < fee) {
            revert Errors.FeeIsRequired();
        }
    }

    function _createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers
    ) private returns (SonikDrop newSonik_) {

        if(baseFee == 0) {
            revert Errors.FeeNotSet();
        }
        
        if (msg.sender == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
        if (_noOfClaimers == 0) {
            revert Errors.ZeroValueDetected();
        }

        _chargeFee(_noOfClaimers);

        newSonik_ = new SonikDrop(
            _tokenAddress,
            _merkleRoot,
            _nftAddress,
            _claimTime,
            msg.sender,
            _noOfClaimers
        );
        ownerToSonikDropClones[msg.sender].push(newSonik_);
        allSonikDropClones.push(newSonik_);
        cloneCount++;

        emit Events.SonikCloneCreated(
            msg.sender,
            block.timestamp,
            address(newSonik_)
        );
    }

    function createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _noOfClaimers
    ) external payable returns (SonikDrop newSonik_) {
        return
            _createSonikDrop(
                _tokenAddress,
                _merkleRoot,
                _nftAddress,
                0,
                _noOfClaimers
            );
    }

    function createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        uint256 _noOfClaimers
    ) external payable returns (SonikDrop newSonik_) {
        return
            _createSonikDrop(
                _tokenAddress,
                _merkleRoot,
                address(0),
                0,
                _noOfClaimers
            );
    }

    function getOwnerSonikDropClones(address _owner ) external view returns (SonikDrop[] memory) {
        return ownerToSonikDropClones[_owner];
    }

    function getAllSonikDropClones() external view returns (SonikDrop[] memory) {
        return allSonikDropClones;
    }

    function withdrawFees() external payable {
        _onlyCollector();
        uint256 _contractBalance = address(this).balance;

        if(_contractBalance == 0){
            revert Errors.ZeroValueDetected();
        }

        (bool success, ) = collector.call{value: address(this).balance}("");
        
        if (!success) {
            revert Errors.WithdrawalFailed();
        }
        emit Events.WithdrawalSuccessful(collector, address(this).balance);
    }

    function updateCollector(address _newCollector) external {
        _onlyCollector();
        address _oldCollector = collector;
        if (_newCollector == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
        collector = _newCollector;

        emit Events.CollectorUpdated(
            _oldCollector,
            block.timestamp,
            _newCollector
        );
    }

    function updateFee(uint256 _newFee) external{
        _onlyCollector();
        if(_newFee == 0) {
            revert Errors.ZeroValueDetected();
        }
        uint256 _prevFee = baseFee;
        baseFee = _newFee;

        emit Events.FeeUpdated(_prevFee, _newFee, block.timestamp);
    }
}
