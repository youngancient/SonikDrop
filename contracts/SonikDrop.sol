// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./Utils.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// another possible feature is time-locking the airdrop
// i.e people can only claim within a certain time
// owners cannot withdraw tokens within that time

// how do I make money / Fee strategy

contract SonikDrop {
    // @dev state variables
    address public owner;
    address public tokenAddress;
    address public nftAddress;
    bool public isNftRequired;
    bool public isTimeLocked;

    uint256 public airdropEndTime;

    bytes32 merkleRoot;

    uint256 public totalAmountSpent;

    uint256 public totalNoOfClaimers;

    uint256 public totalNoOfClaimed;

    // @dev mapping to track users that have claimed
    mapping(address => bool) claimedAirdropMap;

    // @dev Factory would call the constructor to create a new instance of the contract
    constructor(
        address _tokenAddress,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        address _owner,
        uint256 _noOfClaimers
    ) {
        sanityCheck(msg.sender);
        sanityCheck(_owner);
        sanityCheck(_tokenAddress);
        sanityCheck(_nftAddress);
        zeroValueCheck(_noOfClaimers);

        tokenAddress = _tokenAddress;
        merkleRoot = _merkleRoot;
        owner = _owner;

        isNftRequired = _nftAddress != address(0);

        nftAddress = _nftAddress;

        isTimeLocked = _claimTime != 0;

        airdropEndTime = block.timestamp + _claimTime;

        totalNoOfClaimers = _noOfClaimers;
    }

    // @dev prevents zero address from interacting with the contract
    function sanityCheck(address _user) private pure {
        if (_user == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
    }

    function zeroValueCheck(uint256 _amount) private pure {
        if (_amount <= 0) {
            revert Errors.ZeroValueDetected();
        }
    }

    // @dev prevents users from accessing onlyOwner privileges
    function onlyOwner() private view {
        sanityCheck(msg.sender);
        if (msg.sender != owner) {
            revert Errors.UnAuthorizedFunctionCall();
        }
    }

    // @dev returns if a user has claimed or not
    function _hasClaimedAirdrop(address _user) private view returns (bool) {
        sanityCheck(_user);
        return claimedAirdropMap[_user];
    }

    // @dev returns if airdropTime has ended or not
    function hasAidropTimeEnded() public view returns (bool) {
        return block.timestamp > airdropEndTime;
    }

    // @dev checks contract token balance
    function getContractBalance() public view returns (uint256) {
        // onlyOwner();
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // @user check for eligibility
    function checkEligibility(
        address _user,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        sanityCheck(_user);
        if (_hasClaimedAirdrop(msg.sender)) {
            return false;
        }

        // @dev we hash the encoded byte form of the user address and amount to create a leaf
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        // @dev check if the merkleProof provided is valid or belongs to the merkleRoot
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // @user for claiming airdrop
    function claimAirdrop(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        sanityCheck(msg.sender);

        // check if NFT is required
        if (isNftRequired) {
            claimAirdrop(_amount, _merkleProof, 0);
            return;
        }

        // check if User has claimed before
        if (_hasClaimedAirdrop(msg.sender)) {
            revert Errors.HasClaimedRewardsAlready();
        }

        //    checks if User is eligible
        if (!checkEligibility(msg.sender, _amount, _merkleProof)) {
            revert Errors.InvalidClaim();
        }

        if (isTimeLocked && hasAidropTimeEnded()) {
            revert Errors.AirdropClaimEnded();
        }

        claimedAirdropMap[msg.sender] = true;
        totalAmountSpent += _amount;

        if (!IERC20(tokenAddress).transfer(msg.sender, _amount)) {
            revert Errors.TransferFailed();
        }

        emit Events.AirdropClaimed(msg.sender, _amount);
    }

    // @user for claiming airdrop with compulsory NFT ownership
    function claimAirdrop(
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint256 _tokenId
    ) public {
        sanityCheck(msg.sender);
        if (_hasClaimedAirdrop(msg.sender)) {
            revert Errors.HasClaimedRewardsAlready();
        }

        //    checks if User is eligible
        if (!checkEligibility(msg.sender, _amount, _merkleProof)) {
            revert Errors.InvalidClaim();
        }

        if (isTimeLocked && hasAidropTimeEnded()) {
            revert Errors.AirdropClaimEnded();
        }

        // @dev checks if user has the required NFT
        if (IERC721(nftAddress).ownerOf(_tokenId) != msg.sender) {
            revert Errors.NFTNotFound();
        }

        uint256 _currentNoOfClaims = totalNoOfClaimed;

        if (_currentNoOfClaims + 1 > totalNoOfClaimers) {
            revert Errors.TotalClaimersExceeded();
        }

        if (getContractBalance() < _amount) {
            revert Errors.InsufficientContractBalance();
        }

        totalNoOfClaimed += 1;
        claimedAirdropMap[msg.sender] = true;
        totalAmountSpent += _amount;

        if (!IERC20(tokenAddress).transfer(msg.sender, _amount)) {
            revert Errors.TransferFailed();
        }

        emit Events.AirdropClaimed(msg.sender, _amount);
    }

    // @user for the contract owner to update the Merkle root
    // @dev updates the merkle state
    function updateMerkleRoot(bytes32 _newMerkleRoot) external {
        onlyOwner();
        bytes32 _oldMerkleRoot = merkleRoot;

        merkleRoot = _newMerkleRoot;

        emit Events.MerkleRootUpdated(_oldMerkleRoot, _newMerkleRoot);
    }

    // @user get current merkle proof
    function getMerkleRoot() external view returns (bytes32) {
        onlyOwner();
        return merkleRoot;
    }

    // @user For owner to withdraw left over tokens

    /* @dev the withdrawal is only possible if the amount of tokens left in the contract
        is less than the total amount of tokens claimed by the users
    */
    function withdrawLeftOverToken() external {
        onlyOwner();
        uint256 contractBalance = getContractBalance();
        zeroValueCheck(contractBalance);

        // if (totalAmountSpent <= contractBalance) {
        //     // does this make any sense?
        //     revert Errors.UnclaimedTokensStillMuch();
        // }

        if (isTimeLocked) {
            if (!hasAidropTimeEnded()) {
                revert Errors.AirdropClaimTimeNotEnded();
            }
        }
        /* if the totalAmountSpent is greater than the contract balance
        it is safe to withdraw because at least 51% of the token would have been circulated
        */
        if (!IERC20(tokenAddress).transfer(owner, contractBalance)) {
            revert Errors.WithdrawalFailed();
        }

        emit Events.WithdrawalSuccessful(msg.sender, contractBalance);
    }

    // // @user for owner to transfer ownership
    // function transferOwnership(address _newOwner) external {
    //     sanityCheck(_newOwner);
    //     onlyOwner();

    //     if (owner == _newOwner) {
    //         revert Errors.CannotSetOwnerTwice();
    //     }

    //     owner = _newOwner;

    //     emit Events.OwnershipTransferred(msg.sender, _newOwner);
    // }

    // @user for owner to fund the airdrop
    function fundAirdrop(uint256 _amount) external {
        onlyOwner();
        zeroValueCheck(_amount);
        if (
            !IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        ) {
            revert Errors.TransferFailed();
        }
        emit Events.AirdropTokenDeposited(msg.sender, _amount);
    }

    function updateNftRequirement(address _newNft) external {
        sanityCheck(_newNft);
        onlyOwner();
        if (_newNft == nftAddress) {
            revert Errors.CannotSetAddressTwice();
        }
        isNftRequired = true;

        emit Events.NftRequirementUpdated(msg.sender, block.timestamp, _newNft);
    }

    function turnOffNftRequirement() external {
        onlyOwner();
        isNftRequired = false;
        nftAddress = address(0);

        emit Events.NftRequirementOff(msg.sender, block.timestamp);
    }

    function updateClaimTime(uint256 _claimTime) external {
        onlyOwner();
        isTimeLocked = _claimTime != 0;
        airdropEndTime = block.timestamp + _claimTime;

        emit Events.ClaimTimeUpdated(msg.sender, airdropEndTime, _claimTime);
    }

    function updateClaimersNumber(uint256 _noOfClaimers) external {
        onlyOwner();
        zeroValueCheck(_noOfClaimers);

        totalNoOfClaimers = _noOfClaimers;
        
        emit Events.ClaimersNumberUpdated(
            msg.sender,
            block.timestamp,
            _noOfClaimers
        );
    }
}
