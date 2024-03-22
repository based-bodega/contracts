// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is ERC721Holder, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public projectToken;

    struct StakingInfo {
        uint256 startTime;
        uint256 tokensEarned;
    }

    mapping(address => mapping(address => StakingInfo)) public stakingInfo;
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private stakedNFTs;
    mapping(address => uint256) public rewardRate;

    uint256 public constant DURATION = 1 days;

    event Staked(address indexed user, uint256[] nftIds, address nftAddress);
    event Unstaked(
        address indexed user,
        address nftAddress,
        uint256[] nftIds,
        uint256 tokensEarned
    );

    constructor(address _projectToken, address _initialOwner) Ownable(_initialOwner) {
        projectToken = IERC20(_projectToken);
    }

    function stake(uint256 _nftId, address _nftAddress) private {
        require(
            !stakedNFTs[msg.sender][_nftAddress].contains(_nftId),
            "NFT already staked"
        );

        // Transfer NFT to this contract
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _nftId
        );

        stakedNFTs[msg.sender][_nftAddress].add(_nftId);
    }

    function stakeAll(
        uint256[] calldata _nftIds,
        address _nftAddress
    ) external {
        require(_nftIds.length > 0, "Incorrect nft ids");
        StakingInfo storage info = stakingInfo[msg.sender][_nftAddress];

        if (
            stakedNFTs[msg.sender][_nftAddress].length() > 0 &&
            info.startTime.add(DURATION) <= block.timestamp
        ) {
            uint256 tokensEarned = (block.timestamp.sub(info.startTime))
                .div(DURATION)
                .mul(getRewardRate(_nftAddress))
                .mul(stakedNFTs[msg.sender][_nftAddress].length());

            // Transfer earned tokens to the user
            projectToken.transfer(msg.sender, tokensEarned);
            info.startTime = block.timestamp;
            info.tokensEarned += tokensEarned;
        } else {
            info.startTime = block.timestamp;
            info.tokensEarned = 0;
        }

        for (uint256 i = 0; i < _nftIds.length; i++) {
            stake(_nftIds[i], _nftAddress);
        }
        emit Staked(msg.sender, _nftIds, _nftAddress);
    }

    function unstake(uint256 _nftId, address _nftAddress) private {
        // Transfer NFT to user
        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _nftId
        );

        // Remove NFT from staked list
        stakedNFTs[msg.sender][_nftAddress].remove(_nftId);
    }

    function unstakeAll(address _nftAddress) external {
        require(
            stakedNFTs[msg.sender][_nftAddress].length() > 0,
            "Not a staker"
        );
        StakingInfo storage info = stakingInfo[msg.sender][_nftAddress];
        require(
            info.startTime.add(DURATION) <= block.timestamp,
            "Cannot unstake yet"
        );

        uint256[] memory nftIds = stakedNFTs[msg.sender][_nftAddress].values();

        // Calculate tokens earned based on the daily yield
        uint256 tokensEarned = (block.timestamp.sub(info.startTime))
            .div(DURATION)
            .mul(getRewardRate(_nftAddress))
            .mul(stakedNFTs[msg.sender][_nftAddress].length());

        for (uint256 i = 0; i < nftIds.length; i++) {
            unstake(nftIds[i], _nftAddress);
        }

        // Transfer earned tokens to the user
        projectToken.transfer(msg.sender, tokensEarned);

        info.startTime = block.timestamp;
        info.tokensEarned += tokensEarned;

        emit Unstaked(msg.sender, _nftAddress, nftIds, tokensEarned);
    }

    function getBalance(address _user) external view returns (uint256) {
        return projectToken.balanceOf(_user);
    }

    function getStakedNFTs(
        address _user,
        address _nftAddress
    ) external view returns (uint256[] memory) {
        uint256[] memory nftIds = stakedNFTs[_user][_nftAddress].values();
        return nftIds;
    }

    function getClaimableReward(
        address _user,
        address _nftAddress
    ) external view returns (uint256) {
        StakingInfo storage info = stakingInfo[_user][_nftAddress];
        if (info.startTime.add(DURATION) <= block.timestamp) {
            return (
                (block.timestamp.sub(info.startTime))
                    .div(DURATION)
                    .mul(getRewardRate(_nftAddress))
                    .mul(stakedNFTs[msg.sender][_nftAddress].length())
            );
        }
        return 0;
    }

    function getTokensEarnedTotal(
        address _user,
        address _nftAddress
    ) external view returns (uint256) {
        return stakingInfo[_user][_nftAddress].tokensEarned;
    }

    function getRewardRate(
        address _nftAddress
    ) internal view returns (uint256) {
        return rewardRate[_nftAddress];
    }

    // Define your logic for determining the daily reward based on the collection
    // For example, return 10 tokens for Collection 1 (NFT A) and 1 token for Collection 2 (NFT B)
    function setRewardRate(
        address _nftAddress,
        uint256 _rewardRate
    ) external onlyOwner {
        rewardRate[_nftAddress] = _rewardRate;
    }
}
