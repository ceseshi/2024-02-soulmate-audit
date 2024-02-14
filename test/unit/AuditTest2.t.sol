// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {BaseTest, Vm, console2} from "./BaseTest.t.sol";
import {AuditTestHandler} from "./AuditTestHandler.t.sol";
import {Soulmate} from "../../src/Soulmate.sol";

contract AuditTest2 is BaseTest {

    //uint256 airdropVaultBalance = 0;
    //uint256 stakingVaultBalance = 0;

    AuditTestHandler handler;

    function setUp() public override {
        //super.setUp();
        handler = new AuditTestHandler();
        soulmateContract = handler.soulmateContract();
        loveToken = handler.loveToken();
        stakingContract = handler.stakingContract();
        airdropContract = handler.airdropContract();
        airdropVault = handler.airdropVault();
        stakingVault = handler.stakingVault();

        vm.recordLogs();

        //airdropVaultBalance = loveToken.balanceOf(address(airdropVault));
        //stakingVaultBalance = loveToken.balanceOf(address(stakingVault));

        targetContract(address(handler));
        for (uint256 i = 0; i < 200; i++) {
            targetSender(makeAddr(string(abi.encodePacked(i))));
        }
        /*
        targetSender(soulmate1);
        targetSender(soulmate2);
        targetSender(makeAddr("alice"));
        targetSender(makeAddr("bob"));
        */
    }

    /// forge-config: default.invariant.runs = 10
    /// forge-config: default.invariant.depth = 5000
    /// forge-config: default.invariant.fail-on-revert = false
    function invariantTest() public {
        if (handler.calls() >= 5000) {
            //console2.log(handler.calls(), soulmateContract.totalSupply(), handler.totalDivorces());
            //console2.log("totalDivorces", handler.totalDivorced());
        }

        assertTrue(soulmateContract.totalSouls() == soulmateContract.totalSupply() * 2);

        //Invariant: Sum(balanceOf[address]) + balanceOf[VaultContract] + balanceOf[StakingContract] == totalSupply

        /*
        Vm.Log[] memory logs = vm.getRecordedLogs();

        //console2.log("logs.length", logs.length);

        for(uint256 i = 0; i < logs.length; i++) {
            //console2.log("Log", logs[i].emitter);
            //console2.logBytes32(logs[i].topics[0]);

            if(logs[i].emitter == address(loveToken) && logs[i].topics[0] == keccak256("Transfer(address,address,uint256)")) {
                address from = address(uint160(uint256(logs[i].topics[1])));
                address to = address(uint160(uint256(logs[i].topics[2])));
                uint256 value = abi.decode(logs[i].data, (uint256));

                if(from == address(airdropVault)) {
                    airdropVaultBalance -= value;
                    //console2.log("airdropVault ->", from, to, value);
                }
                else if(to == address(airdropVault)) {
                    airdropVaultBalance += value;
                    //console2.log("airdropVault <-", from, to, value);
                }

                if(from == address(stakingVault)) {
                    stakingVaultBalance -= value;
                    //console2.log("stakingVault ->", from, to, value);
                }
                else if(to == address(stakingVault)) {
                    stakingVaultBalance += value;
                    //console2.log("stakingVault <-", from, to, value);
                }

                /*
                console2.log(from, to, value);
                console2.logBytes(abi.encode(logs[i]));
                console2.log("data", string(logs[i].data));
                console2.log("airdropVaultBalance", airdropVaultBalance);
                console2.log("stakingVaultBalance", stakingVaultBalance);
                * /
            }
        }*/
        uint256 airdropVaultBalance = handler.airdropVaultBalance();
        uint256 stakingVaultBalance = handler.stakingVaultBalance();
        uint256 stakingContractBalance = handler.stakingContractBalance();

        if (handler.calls() >= 1900) {
            //console2.log(airdropVaultBalance, stakingVaultBalance);
        }

        assertEq(loveToken.balanceOf(address(airdropVault)), airdropVaultBalance, "airdropVaultBalance");
        assertEq(loveToken.balanceOf(address(stakingVault)), stakingVaultBalance, "stakingVaultBalance");
        assertEq(loveToken.balanceOf(address(stakingContract)), stakingContractBalance, "stakingContractBalance");
        //assertEq(soulmateContract.totalSouls(), 0);
    }
}