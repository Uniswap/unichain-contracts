// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {INetFeeSplitter, NetFeeSplitter} from '../../src/FeeSplitter/NetFeeSplitter.sol';

contract NetFeeSplitterTest is Test {
    function test_RevertIf_DifferentArrayLengths() public {
        address[] memory recipients = new address[](0);
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        vm.expectRevert(INetFeeSplitter.InvalidRecipients.selector);
        new NetFeeSplitter(recipients, recipientData);
    }

    function test_RevertIf_DuplicateRecipients() public {
        address[] memory recipients = new address[](2);
        recipients[0] = makeAddr('recipient');
        recipients[1] = makeAddr('recipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](2);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 100});
        recipientData[1] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 100});
        vm.expectRevert(INetFeeSplitter.DuplicateRecipient.selector);
        new NetFeeSplitter(recipients, recipientData);
    }

    function test_RevertIf_SetterZero() public {
        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr('recipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: address(0), allocation: 100});
        vm.expectRevert(INetFeeSplitter.SetterZero.selector);
        new NetFeeSplitter(recipients, recipientData);
    }

    function test_RevertIf_RecipientZero() public {
        address[] memory recipients = new address[](1);
        recipients[0] = address(0);
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 100});
        vm.expectRevert(INetFeeSplitter.RecipientZero.selector);
        new NetFeeSplitter(recipients, recipientData);
    }

    function test_RevertIf_AllocationZero() public {
        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr('recipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 0});
        vm.expectRevert(INetFeeSplitter.AllocationZero.selector);
        new NetFeeSplitter(recipients, recipientData);
    }

    function test_RevertIf_InvalidTotalAllocation(uint256 allocation) public {
        vm.assume(allocation != 10_000 && allocation != 0);
        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr('recipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: allocation});
        vm.expectRevert(INetFeeSplitter.InvalidTotalAllocation.selector);
        new NetFeeSplitter(recipients, recipientData);
    }

    function test_RevertIf_TransferRecipientZero() public {
        address[] memory recipients = new address[](1);
        address recipient_ = makeAddr('recipient');
        recipients[0] = recipient_;
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.prank(makeAddr('setter'));
        vm.expectRevert(INetFeeSplitter.RecipientZero.selector);
        splitter.transferAllocationAndSetSetter(recipient_, address(0), address(1), 1);
    }

    function test_RevertIf_NewSetterZero() public {
        address[] memory recipients = new address[](1);
        address recipient_ = makeAddr('recipient');
        recipients[0] = recipient_;
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.prank(makeAddr('setter'));
        vm.expectRevert(INetFeeSplitter.SetterZero.selector);
        splitter.transferAllocationAndSetSetter(recipient_, address(0), address(0), 1);
    }

    function test_RevertIf_AllocationZeroOnTransfer() public {
        address[] memory recipients = new address[](2);
        recipients[0] = makeAddr('recipient');
        recipients[1] = makeAddr('newRecipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](2);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 5000});
        recipientData[1] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 5000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.expectRevert(INetFeeSplitter.AllocationZero.selector);
        vm.prank(makeAddr('setter'));
        splitter.transferAllocation(makeAddr('recipient'), makeAddr('newRecipient'), 0);
    }

    function test_RevertIf_AllocationTransferWithSetterSetterAlreadySet() public {
        address[] memory recipients = new address[](2);
        recipients[0] = makeAddr('recipient');
        recipients[1] = makeAddr('newRecipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](2);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 5000});
        recipientData[1] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 5000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.prank(makeAddr('setter'));
        vm.expectRevert(INetFeeSplitter.SetterAlreadySet.selector);
        splitter.transferAllocationAndSetSetter(
            makeAddr('recipient'), makeAddr('newRecipient'), makeAddr('newSetter'), 1
        );
    }

    function test_RevertIf_TransferInitiatorNotSetter(address initiator) public {
        vm.assume(initiator != makeAddr('setter'));
        address[] memory recipients = new address[](2);
        recipients[0] = makeAddr('recipient');
        recipients[1] = makeAddr('newRecipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](2);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 5000});
        recipientData[1] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 5000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.expectRevert(INetFeeSplitter.Unauthorized.selector);
        vm.prank(initiator);
        splitter.transferAllocation(makeAddr('recipient'), makeAddr('newRecipient'), 1);
    }

    function test_RevertIf_SetterOfRecipientIsZero() public {
        address[] memory recipients = new address[](1);
        address recipient_ = makeAddr('recipient');
        recipients[0] = recipient_;
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        address newRecipient = makeAddr('newRecipient');
        vm.expectRevert(INetFeeSplitter.SetterZero.selector);
        splitter.transferAllocation(recipient_, newRecipient, 1);
    }

    function test_ShouldTransferAllocation() public {
        address setter_ = makeAddr('setter');
        address recipient_ = makeAddr('recipient');
        address[] memory recipients = new address[](1);
        recipients[0] = recipient_;
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: setter_, allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);
        address newRecipient = makeAddr('newRecipient');
        address newSetter = makeAddr('newSetter');
        assertEq(splitter.setterOf(newRecipient), address(0));
        assertEq(splitter.balanceOf(newRecipient), 0);
        assertEq(splitter.earnedFees(recipient_), 1 ether);
        assertEq(splitter.earnedFees(newRecipient), 0);
        vm.expectEmit(true, true, true, true);
        emit INetFeeSplitter.AllocationTransferred(setter_, recipient_, newRecipient, 1);
        vm.prank(setter_);
        splitter.transferAllocationAndSetSetter(recipient_, newRecipient, newSetter, 1);
        assertEq(splitter.setterOf(newRecipient), newSetter, 'should set new setter as the setter of the new recipient');
        assertEq(splitter.balanceOf(recipient_), 9999, 'should transfer the allocation to the new recipient');
        assertEq(splitter.balanceOf(newRecipient), 1, 'should receive the allocation');
        (success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);
        assertEq(
            splitter.earnedFees(recipient_),
            1 ether + 1 ether * 9999 / 10_000,
            'recipient should keep previous fees in addition to new fees'
        );
        assertEq(splitter.earnedFees(newRecipient), 1 ether / 10_000, 'new recipient should receive fees');
    }

    function test_RevertIf_TransferSetterNotSetter(address initiator) public {
        vm.assume(initiator != makeAddr('setter'));
        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr('recipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.expectRevert(INetFeeSplitter.Unauthorized.selector);
        vm.prank(initiator);
        splitter.transferSetter(makeAddr('recipient'), makeAddr('newSetter'));
    }

    function test_ShouldTransferSetter() public {
        address setter_ = makeAddr('setter');
        address recipient_ = makeAddr('recipient');
        address newSetter_ = makeAddr('newSetter');
        address[] memory recipients = new address[](1);
        recipients[0] = recipient_;
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: setter_, allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        vm.expectEmit(true, true, true, true);
        emit INetFeeSplitter.SetterTransferred(recipient_, setter_, newSetter_);
        vm.prank(setter_);
        splitter.transferSetter(recipient_, newSetter_);
        assertEq(splitter.setterOf(recipient_), newSetter_);
    }

    function test_ShouldDistributeAndWithdrawFeesCorrectly(
        INetFeeSplitter.Recipient[] memory recipientData_,
        uint256[] memory fees
    ) public {
        vm.assume(recipientData_.length > 0);
        vm.assume(fees.length > 0);
        uint256 recipientDataLen = recipientData_.length > 50 ? 50 : recipientData_.length;
        uint256 feesLen = fees.length > 50 ? 50 : fees.length;
        // calculate total fees and bound the individual fees
        uint256 totalFees;
        for (uint256 i = 0; i < feesLen; i++) {
            fees[i] = bound(fees[i], 0.001 ether, 1000 ether);
            totalFees += fees[i];
        }
        // set up recipients and recipient data, bound the allocation
        address[] memory recipients = new address[](recipientDataLen);
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](recipientDataLen);
        uint256 totalAllocation;
        for (uint256 i = 0; i < recipientDataLen; i++) {
            recipientData[i] = recipientData_[i];
            recipientData[i].setter = setter(i);
            recipients[i] = recipient(i);
            recipientData[i].allocation = bound(recipientData[i].allocation, 1 ether, 100 ether);
            totalAllocation += recipientData[i].allocation;
        }
        // normalize the balances so the sum is 10_000
        uint256 combinedAllocation = 0;
        for (uint256 i = 0; i < recipientDataLen; i++) {
            recipientData[i].allocation = recipientData[i].allocation * 10_000 / totalAllocation;
            combinedAllocation += recipientData[i].allocation;
        }
        // adjust for rounding errors
        if (combinedAllocation < 10_000) {
            recipientData[recipientData.length - 1].allocation += 10_000 - combinedAllocation;
        }

        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);

        // distribute the fees
        for (uint256 i = 0; i < feesLen; i++) {
            (bool success,) = address(splitter).call{value: fees[i]}('');
            assertTrue(success);
        }

        // check that the fees are distributed correctly
        for (uint256 i = 0; i < recipientDataLen; i++) {
            uint256 expectedFees = totalFees * recipientData[i].allocation / 10_000;
            assertEq(splitter.earnedFees(recipients[i]), expectedFees);
            vm.prank(recipients[i]);
            splitter.withdrawFees(recipientData[i].setter);
            assertEq(splitter.earnedFees(recipients[i]), 0);
            assertEq(recipientData[i].setter.balance, expectedFees);
        }
    }

    function setter(uint256 i) internal returns (address) {
        return makeAddr(string(abi.encodePacked('setter', i)));
    }

    function recipient(uint256 i) internal returns (address) {
        return makeAddr(string(abi.encodePacked('recipient', i)));
    }
}
