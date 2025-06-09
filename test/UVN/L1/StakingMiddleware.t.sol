// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {L1TestHandler} from './L1TestHandler.sol';

import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

contract StakingMiddlewareTest is L1TestHandler {
    function setUp() public override {
        super.setUp();
    }

    function test_mint() public {
        stakeToken.mint(address(this), 1000);
        stakeToken.approve(address(stakingMiddleware), 1000);
        stakingMiddleware.stake(1000);
        vm.prank(operator);
        stakingMiddleware.mint();
        vm.prank(operator);
        stakingMiddleware.setDelegationStatus(true);
        stakingMiddleware.delegate(operator);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 1000);
        assertEq(stakingMiddleware.getVotes(operator), 1000);
    }

    function test_supportingInterfaces() public view {
        IERC165 erc165 = IERC165(address(stakingMiddleware));
        assertEq(erc165.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(erc165.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(erc165.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(erc165.supportsInterface(type(IAccessControl).interfaceId), true);
    }
}
