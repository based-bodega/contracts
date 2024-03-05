// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakingContract is ERC721Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public projectToken;

    struct StakingInfo {
        uint256 startTime;
        uint256 nftId;
        uint256 tokensEarned;
        uint256 collectionId; // Unique identifier for NFT collection (e.g., 1 for NFT A, 2 for NFT B)
    }

    mapping(address => StakingInfo) public stakingInfo;
    mapping(address => EnumerableSet.UintSet) private stakedNFTs;

    uint256 public constant DURATION = 1 days;

    event Staked(address indexed user, uint256 nftId, uint256 collectionId);
    event Unstaked(address indexed user, uint256 nftId, uint256 tokensEarned);

    constructor(address _projectToken) {
        projectToken = IERC20(_projectToken);
    }

    modifier onlyStaker() {
        require(stakedNFTs.contains(uint256(msg.sender)), "Not a staker");
        _;
    }

    function stake(uint256 _nftId, uint256 _collectionId) external {
        require(!stakedNFTs.contains(_nftId), "NFT already staked");

        // Transfer NFT to this contract
        IERC721(msg.sender).safeTransferFrom(msg.sender, address(this), _nftId);

        stakedNFTs.add(_nftId);

        stakingInfo[msg.sender] = StakingInfo(block.timestamp, _nftId, 0, _collectionId);

        emit Staked(msg.sender, _nftId, _collectionId);
    }
        
    function unstake() external onlyStaker {
        StakingInfo storage info = stakingInfo[msg.sender];
        require(info.startTime.add(DURATION) <= block.timestamp, "Cannot unstake yet");

        // Calculate tokens earned based on the daily yield
        uint256 tokensEarned = (block.timestamp.sub(info.startTime).div(DURATION)).mul(getRewardForCollection(info.collectionId));

        // Transfer earned tokens to the user
        projectToken.transfer(msg.sender, tokensEarned);

        // Remove NFT from staked list
        stakedNFTs.remove(info.nftId);

        // Reset staking information
        delete stakingInfo[msg.sender];

        emit Unstaked(msg.sender, info.nftId, tokensEarned);
    }

    function getBalance(address _user) external view returns (uint256) {
        return projectToken.balanceOf(_user);
    }

    function getStakedNFTs(address _user) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](1);
        result[0] = stakingInfo[_user].nftId;
        return result;
    }

    function getTokensOutstanding(address _user) external view returns (uint256) {
        StakingInfo storage info = stakingInfo[_user];
        if (info.startTime.add(DURATION) <= block.timestamp) {
            return (block.timestamp.sub(info.startTime).div(DURATION)).mul(getRewardForCollection(info.collectionId)).sub(info.tokensEarned);
        }
        return 0;
    }

    function getTokensEarnedTotal(address _user) external view returns (uint256) {
        return stakingInfo[_user].tokensEarned;
    }

    function getRewardForCollection(uint256 _collectionId) internal view returns (uint256) {
        // Define your logic for determining the daily reward based on the collection
        // For example, return 10 tokens for Collection 1 (NFT A) and 1 token for Collection 2 (NFT B)
        if (_collectionId == 1) {
            return 10;
        } else if (_collectionId == 2) {
            return 1;
        } else {
            // Default case, return 0 if collection is not recognized
            return 0;
        }
    }
}
