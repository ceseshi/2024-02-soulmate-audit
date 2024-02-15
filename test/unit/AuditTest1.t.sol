// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {Soulmate} from "../../src/Soulmate.sol";

contract AuditTest1 is BaseTest {

    function testClaimAfterGetDivorced() public {
        // Get a soulmate
        _mintOneTokenForBothSoulmates();

        // Wait 100 days
        uint256 _days = 100;
        vm.warp(block.timestamp + (_days * 1 days));

        // Get divorced
        vm.startPrank(soulmate1);
        soulmateContract.getDivorced();

        // Should not be able to claim
        airdropContract.claim();

        console2.log("balance", loveToken.balanceOf(soulmate1));
    }

    function testClaimAirdropWithoutSoulmate() public {
        // Jump to a current timestamp in mainnet
        uint256 timestamp = 1707775379;
        vm.warp(timestamp);

        // Get a new user
        address alice = makeAddr("alice");

        // Claim
        vm.prank(alice);
        airdropContract.claim();

        console2.log("balance", loveToken.balanceOf(alice));
    }

    function testClaimRewardsWithoutSoulmate() public {
        // Jump to a current timestamp in mainnet
        uint256 timestamp = 1707775379;
        vm.warp(timestamp);

        // Get a new user with tokens
        address alice = makeAddr("alice");
        uint256 initialBalance = 100 ether;
        deal(address(loveToken), alice, initialBalance);

        // Deposit and claim
        vm.startPrank(alice);
        loveToken.approve(address(stakingContract), initialBalance);
        stakingContract.deposit(initialBalance);
        stakingContract.claimRewards();

        // Compare balances
        console2.log("initialBalance", initialBalance);
        console2.log("balance", loveToken.balanceOf(alice));
    }

    function testClaimRewardsDivorced() public {

        vm.mockCallRevert(makeAddr("alices"), "", abi.encode("TRANSFER_FAILED"));
        makeAddr("alice").call{value:1}("");
        return;


        _mintOneTokenForBothSoulmates();

        // Deposit and claim
        vm.startPrank(soulmate1);
        vm.warp(block.timestamp + 10 days);
        airdropContract.claim();
        uint256 initialBalance = loveToken.balanceOf(soulmate1);
        loveToken.approve(address(stakingContract), initialBalance);
        stakingContract.deposit(loveToken.balanceOf(soulmate1));

        // Get divorced
        soulmateContract.getDivorced();

        vm.warp(block.timestamp + 10 days);
        initialBalance = loveToken.balanceOf(soulmate1);
        stakingContract.claimRewards();

        // Compare balances
        console2.log("initialBalance", initialBalance);
        console2.log("balance", loveToken.balanceOf(soulmate1));
    }

    /*function testClaimRewardsEveryDay() public {

        _mintOneTokenForBothSoulmates();
        vm.warp(block.timestamp + 1 days);

        vm.startPrank(soulmate1);
        airdropContract.claim();
        uint256 balance = loveToken.balanceOf(soulmate1);
        loveToken.approve(address(stakingContract), balance);
        stakingContract.deposit(balance);

        for(uint256 i = 0; i < 30; i++) {
            vm.warp(block.timestamp + 1 days);
            vm.expectRevert();
            stakingContract.claimRewards();
        }

        console2.log(loveToken.balanceOf(soulmate1));
    }*/

    function testGetDivorcedWithoutSoulmate() public {
        address alice = makeAddr("alice");

        vm.startPrank(alice);
        soulmateContract.getDivorced();
        bool isDivorced = soulmateContract.isDivorced(alice);
        assertTrue(isDivorced);
    }

    function testMintSoulmateTokenSameAddress() public {
        vm.startPrank(soulmate1);
        soulmateContract.mintSoulmateToken();
        soulmateContract.mintSoulmateToken();

        console2.log(soulmate1);
        console2.log(soulmateContract.soulmateOf(soulmate1));
    }

    function testAnyUserCanWriteMessage() public {
        string memory message = "Hello!";
        address alice = makeAddr("alice");

        vm.prank(alice);
        soulmateContract.writeMessageInSharedSpace(message);

        uint256 tokenId = 0;
        string memory sharedMessage = soulmateContract.sharedSpace(tokenId);
        assertTrue(keccak256(abi.encodePacked(sharedMessage)) == keccak256(abi.encodePacked(message)));
    }

    function testReadMessageWithNiceWords() public {
        string[4] memory niceWords = ["sweetheart", "darling", "my dear", "honey"];
        string memory message = "Hello!";
        address alice = makeAddr("alice");

        vm.startPrank(alice);
        soulmateContract.writeMessageInSharedSpace(message);

        uint256 niceWordsId = 0;
        vm.warp(4 + niceWordsId);

        require(block.timestamp % niceWords.length == niceWordsId, "invalid timestamp");
        string memory sharedMessage = soulmateContract.readMessageInSharedSpace();

        assertTrue(keccak256(abi.encodePacked(sharedMessage)) == keccak256(abi.encodePacked(string.concat(message, ", ", niceWords[niceWordsId]))));
    }

    function testStakingVault() public {
        // Give tokens to the user
        deal(address(loveToken), soulmate1, 1000);

        // Deposit to staking
        vm.startPrank(soulmate1);
        loveToken.approve(address(stakingContract), 1000);
        stakingContract.deposit(1000);

        // The tokens are deposited in the staking contract, not the vault
        assertEq(loveToken.balanceOf(address(stakingContract)), 1000);
    }
}