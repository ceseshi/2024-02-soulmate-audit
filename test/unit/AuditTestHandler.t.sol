// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, Vm, console2} from "forge-std/Test.sol";

import {IVault} from "../../src/interface/IVault.sol";
import {ISoulmate} from "../../src/interface/ISoulmate.sol";
import {ILoveToken} from "../../src/interface/ILoveToken.sol";
import {IStaking} from "../../src/interface/IStaking.sol";

import {Vault} from "../../src/Vault.sol";
import {Soulmate} from "../../src/Soulmate.sol";
import {LoveToken} from "../../src/LoveToken.sol";
import {Airdrop} from "../../src/Airdrop.sol";
import {Staking} from "../../src/Staking.sol";

contract AuditTestHandler is Test {
    Soulmate public soulmateContract;
    LoveToken public loveToken;
    Staking public stakingContract;
    Airdrop public airdropContract;
    Vault public airdropVault;
    Vault public stakingVault;

    address deployer = makeAddr("deployer");
    address soulmate1 = makeAddr("soulmate1");
    address soulmate2 = makeAddr("soulmate2");
    address public lastUserMinting;

    uint256 public totalDivorces = 0;
    uint256 public calls = 0;

    uint256 public airdropVaultBalance = 0;
    uint256 public stakingVaultBalance = 0;
    uint256 public stakingContractBalance = 0;

    constructor() {
        vm.startPrank(deployer);
        airdropVault = new Vault();
        stakingVault = new Vault();
        soulmateContract = new Soulmate();
        loveToken = new LoveToken(
            ISoulmate(address(soulmateContract)),
            address(airdropVault),
            address(stakingVault)
        );
        stakingContract = new Staking(
            ILoveToken(address(loveToken)),
            ISoulmate(address(soulmateContract)),
            IVault(address(stakingVault))
        );

        airdropContract = new Airdrop(
            ILoveToken(address(loveToken)),
            ISoulmate(address(soulmateContract)),
            IVault(address(airdropVault))
        );
        airdropVault.initVault(
            ILoveToken(address(loveToken)),
            address(airdropContract)
        );
        stakingVault.initVault(
            ILoveToken(address(loveToken)),
            address(stakingContract)
        );

        vm.stopPrank();

        airdropVaultBalance = loveToken.balanceOf(address(airdropVault));
        stakingVaultBalance = loveToken.balanceOf(address(stakingVault));
        stakingContractBalance = loveToken.balanceOf(address(stakingContract));
    }

    function failed() public override returns(bool){
        warp();
        return false;
    }

    function warp() public {
        calls += 1;
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1*3600);
    }

    /* AIRDROP */
    function airdropClaim() public {
        warp();
        if (soulmateContract.soulmateOf(msg.sender) == address(0)) return;
        if (soulmateContract.isDivorced(msg.sender)) return;

        uint256 numberOfDaysInCouple = (block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(msg.sender))) / (24 * 3600);
        uint256 amountAlreadyClaimed = airdropContract._claimedBy(msg.sender);
        if (amountAlreadyClaimed >= numberOfDaysInCouple * 10 ** loveToken.decimals()) return;

        uint256 tokenAmountToDistribute = (numberOfDaysInCouple * 10 ** loveToken.decimals()) - amountAlreadyClaimed;

        if (tokenAmountToDistribute >= loveToken.balanceOf(address(airdropVault))) {
            tokenAmountToDistribute = loveToken.balanceOf(
                address(airdropVault)
            );
        }

        vm.prank(msg.sender);
        airdropContract.claim();

        airdropVaultBalance -= tokenAmountToDistribute;
    }

    /* LOVE TOKEN */
    function loveTokenTransfer(address to, uint256 amount) public {
        warp();
        uint256 balance = loveToken.balanceOf(msg.sender);
        amount = bound(amount, 0, balance);
        if (amount == 0) return;
        vm.prank(msg.sender);
        loveToken.transfer(to, amount);

    }

    function loveTokenTransferFrom(address from, address to, uint256 amount) public {
        warp();
        uint256 balance = loveToken.balanceOf(from);
        amount = bound(amount, 0, balance);
        if (amount == 0) return;
        vm.prank(from);
        loveToken.approve(msg.sender, amount);
        vm.prank(msg.sender);
        loveToken.transferFrom(from, to, amount);

    }

    /*function loveTokenApprove(address spender, uint256 amount) public {
        vm.prank(msg.sender);
        loveToken.approve(spender, amount);
    }*/

    /* SOULMATE */
    function soulmateMintSoulmateToken() public {
        warp();
        if (msg.sender == lastUserMinting) return;
        if (soulmateContract.soulmateOf(msg.sender) != address(0)) return;
        vm.prank(msg.sender);
        soulmateContract.mintSoulmateToken();
        lastUserMinting = msg.sender;

    }

    function soulmateWriteMessageInSharedSpace(string memory message) public {
        warp();
        if(soulmateContract.soulmateOf(msg.sender) == address(0)) return;
        vm.prank(msg.sender);
        soulmateContract.writeMessageInSharedSpace(message);

    }

    function soulmateGetDivorced(uint256 rnd) public {
        warp();
        if (bound(rnd, 0, 100) != 0) return;
        if(soulmateContract.soulmateOf(msg.sender) == address(0)) return;
        vm.prank(msg.sender);
        soulmateContract.getDivorced();
        totalDivorces += 1;

    }

    /*
    function soulmateApprove(address spender, uint256 id) public {
        warp();
        if (soulmateContract.totalSupply() <= id) return;
        if (soulmateContract.ownerOf(id) != msg.sender) return;
        vm.prank(msg.sender);
        soulmateContract.approve(spender, id);

    }

    function soulmateTransferFrom(address from, address to, uint256 amount) public {
        warp();
        vm.prank(msg.sender);
        soulmateContract.transferFrom(from, to, amount);

    }

    function soulmateSafeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) public {
        warp();
        vm.prank(msg.sender);
        soulmateContract.safeTransferFrom(from, to, amount);

    }

    function soulmateSafeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public {
        warp();
        vm.prank(msg.sender);
        soulmateContract.safeTransferFrom(from, to, amount, data);

    }

    function soulmateSetApprovalForAll(address operator, bool approved) public {
        warp();
        vm.prank(msg.sender);
        soulmateContract.setApprovalForAll(operator, approved);

    }
    */

    /* STAKING */
    function stakingDeposit(uint256 amount) public {
        warp();
        uint256 balance = loveToken.balanceOf(msg.sender);
        amount = bound(amount, 0, balance);
        if (amount == 0) return;
        vm.startPrank(msg.sender);
        loveToken.approve(address(stakingContract), amount);
        stakingContract.deposit(amount);
        vm.stopPrank();

        stakingVaultBalance += amount;
    }

    function stakingWithdraw(uint256 amount) public {
        warp();
        uint256 balance = stakingContract.userStakes(msg.sender);
        amount = bound(amount, 0, balance);
        if (amount == 0) return;
        vm.prank(msg.sender);
        stakingContract.withdraw(amount);

        stakingVaultBalance -= amount;
    }

    function stakingClaimRewards() public {
        warp();
        if (soulmateContract.soulmateOf(msg.sender) == address(0)) return;

        uint256 lastClaim = stakingContract.lastClaim(msg.sender);
        if (stakingContract.lastClaim(msg.sender) == 0) {
            uint256 soulmateId = soulmateContract.ownerToId(msg.sender);
            lastClaim = soulmateContract.idToCreationTimestamp(soulmateId);
        }
        uint256 timeInWeeksSinceLastClaim = ((block.timestamp - lastClaim) / 1 weeks);
        if (timeInWeeksSinceLastClaim < 1) return;

        uint256 amountToClaim = stakingContract.userStakes(msg.sender) * timeInWeeksSinceLastClaim;
        if (amountToClaim == 0) return;

        vm.prank(msg.sender);
        stakingContract.claimRewards();

        stakingVaultBalance -= amountToClaim;
    }
}