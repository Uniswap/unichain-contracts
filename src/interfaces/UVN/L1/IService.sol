// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseService} from '../../UVN/interfaces/IBaseService.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/// @title IService
/// @notice This interface is used by contracts that operators deposit their ERC-721 tokens into to operate for. It must implement the following interfaces in order to be notified of changes to operator's and delegator's stake successfully.
interface IService is IBaseService, IERC165, IERC721Receiver {}
