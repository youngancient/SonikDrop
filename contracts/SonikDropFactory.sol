// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./SonikDrop.sol";
import "./Utils.sol";

contract SonikDropFactory {
    //  when a person interacts with the factory, he would options like
    // 1. Adding an NFT requirement
    // 2. Adding a time lock
    address collector;

    uint256 public counter;
    mapping(uint => SonikDrop) idTosonikDropClones;
    SonikDrop[] allSonikClones;

    uint256 baseFee = 0.0002 ether;

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
        if (msg.sender == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
        if (_noOfClaimers == 0) {
            revert Errors.ZeroValueDetected();
        }

        _chargeFee(_noOfClaimers);

        uint256 _id = counter + 1;
        newSonik_ = new SonikDrop(
            _tokenAddress,
            _merkleRoot,
            _nftAddress,
            _claimTime,
            msg.sender,
            _noOfClaimers
        );
        idTosonikDropClones[_id] = newSonik_;
        allSonikClones.push(newSonik_);
        counter++;

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

    function getSonikDrop(uint256 _id) external view returns (SonikDrop) {
        return idTosonikDropClones[_id];
    }

    function getAllSonikDrops() external view returns (SonikDrop[] memory) {
        return allSonikClones;
    }

    function withdrawFees() external payable {
        _onlyCollector();
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
}
