// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title Search
/// @notice This library provides functions to search for a target value in an array sorted in ascending order.
library Search {
    /// @dev Performs exponential descending search to narrow down the range for finding a target value in a array sorted in ascending order with a bias towards higher values
    /// @return left the lower index of the range when target is rounded up to the index (array[left - 1] < target <= array[left])
    /// @return right The right index of the range, returns type(uint256).max if the target is greater than all values in the array
    function exponentialSearchDesc(uint256[] storage array, uint256 target)
        internal
        view
        returns (uint256 left, uint256 right)
    {
        uint256 len = array.length;
        if (len == 0) return (0, type(uint256).max);

        uint256 highIndex = len - 1;
        uint256 item = array[highIndex];
        if (target > item) return (highIndex, type(uint256).max);
        // only one item in the array and target is less than the item
        if (highIndex == 0) return (0, 0);

        uint256 bound = 1;
        uint256 index = highIndex;
        while (target <= item) {
            // exact match found, return early
            if (target == item) return (index, index);
            bound *= 2;
            // we've reached the end of the array, return the lower bound
            if (bound >= len) return (0, highIndex - bound / 2 + 1);
            index = highIndex - bound + 1;
            item = array[index];
        }

        left = highIndex - min(bound, len - 1) + 2;
        right = highIndex - bound / 2 + 1;

        left = max(0, left);
        return (left, right);
    }

    function binarySearchRoundingUp(uint256[] storage array, uint256 target, uint256 left, uint256 right)
        internal
        view
        returns (uint256 index)
    {
        while (left < right) {
            uint256 mid = left + (right - left) / 2;

            if (array[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        if (left < array.length && array[left] >= target) {
            return left;
        }
        return type(uint256).max;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}
