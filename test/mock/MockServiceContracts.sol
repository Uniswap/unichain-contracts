// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IService} from '../../src/interfaces/UVN/L1/IService.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {ERC165, IERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract MockServiceContract is IService, ERC165 {
    IERC721 public token;

    constructor(IERC721 token_) {
        token = token_;
    }

    function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
        external
    {}

    function reportOperatorSlash(address operator, uint256 remainingPercentage) external {}

    function onWithdrawal(address operator) external {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IService).interfaceId || super.supportsInterface(interfaceId);
    }

    function transfer(address to, uint256 tokenId) external {
        token.safeTransferFrom(address(this), to, tokenId);
    }
}

contract RevertingServiceContract is IService, ERC165 {
    function reportOperatorStake(address, uint256, address, uint256) external pure virtual {
        revert();
    }

    function reportOperatorSlash(address, uint256) external pure {
        revert();
    }

    function onWithdrawal(address) external pure {
        revert();
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure virtual returns (bytes4) {
        revert();
    }

    function supportsInterface(bytes4) public pure virtual override(ERC165, IERC165) returns (bool) {
        revert();
    }
}

contract MaliciousServiceContract is RevertingServiceContract {
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4) public pure override returns (bool) {
        return true;
    }
}

contract InfiniteLoopServiceContract is MaliciousServiceContract {
    function reportOperatorStake(address, uint256, address, uint256) external pure override {
        while (true) {}
    }
}

contract RevertDataBombServiceContract is MaliciousServiceContract {
    function reportOperatorStake(address, uint256, address, uint256) external pure override {
        assembly {
            revert(0, 10000)
        }
    }
}

contract NonServiceERC165Contract is IERC165 {
    function supportsInterface(bytes4) public pure override(IERC165) returns (bool) {
        return false;
    }
}

contract EmptyContract {}
