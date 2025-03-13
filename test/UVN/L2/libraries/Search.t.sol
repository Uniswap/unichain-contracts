// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from 'forge-std/Test.sol';

import {Search} from '../../../../src/UVN/L2/libraries/Search.sol';

contract SearchTest is Test {
    uint256[] array;

    function setUpArray(uint256 itemLength, uint256 startValue, uint256 stepSize) internal {
        itemLength = bound(itemLength, 1, 100);
        startValue = bound(startValue, 0, 100);
        stepSize = bound(stepSize, 1, 10);

        for (uint256 i = 0; i < itemLength; i++) {
            array.push(startValue + i * stepSize);
        }
    }

    function testFuzz_exponentialSearchDesc(uint256 itemLength, uint256 startValue, uint256 stepSize) public {
        setUpArray(itemLength, startValue, stepSize);

        uint256 len = array.length;
        // loop through all possible targets even the ones that are not in the array also including 0 and values greater than the last item in the array
        for (uint256 target = 0; target <= array[len - 1] + 1; target++) {
            (uint256 left, uint256 right) = Search.exponentialSearchDesc(array, target);
            if (target > array[len - 1]) {
                assertEq(left, len - 1);
                assertEq(right, type(uint256).max);
                continue;
            }
            assertEq(target <= array[right], true, 'Target should always be equal or less than the right bound');
            assertEq(
                target >= (left > 0 ? array[left - 1] : 0),
                true,
                'Target should always be equal or greater than the left bound'
            );
            if (left == right && left != 0) {
                assertEq(
                    array[left] == target || array[left] == array[len - 1],
                    true,
                    'If left and right are the same the target should be found at the index or it is the last item in the array'
                );
            }
        }
    }

    function testFuzz_binarySearchRoundingUpValueBelowMin(uint256 itemLength, uint256 startValue, uint256 stepSize)
        public
    {
        setUpArray(itemLength, startValue, stepSize);
        uint256 minValue = array[0];
        if (minValue > 0) {
            uint256 belowMin = minValue - 1;
            uint256 index = Search.binarySearchRoundingUp(array, belowMin, 0, array.length - 1);
            assertEq(index, 0, 'Value below minimum should return first index');
        }
    }

    function testFuzz_binarySearchRoundingUpValueAboveMax(uint256 itemLength, uint256 startValue, uint256 stepSize)
        public
    {
        setUpArray(itemLength, startValue, stepSize);

        uint256 len = array.length;
        uint256 maxValue = array[len - 1];

        uint256 aboveMax = maxValue + 1;
        uint256 index = Search.binarySearchRoundingUp(array, aboveMax, 0, len - 1);
        assertEq(index, type(uint256).max, 'Value above maximum should return max uint256');
    }

    function testFuzz_binarySearchRoundingUpValueBetween(uint256 itemLength, uint256 startValue, uint256 stepSize)
        public
    {
        setUpArray(itemLength, startValue, stepSize);

        uint256 len = array.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 exactTarget = array[i];
            uint256 index = Search.binarySearchRoundingUp(array, exactTarget, 0, len - 1);
            assertEq(index, i, 'Exact match should return correct index');

            // Test value between current and next element if not the last element and step size is greater than 1
            if (i < len - 1 && array[i + 1] > array[i] + 1) {
                uint256 betweenTarget = array[i] + 1;
                index = Search.binarySearchRoundingUp(array, betweenTarget, 0, len - 1);
                assertEq(index, i + 1, 'Between value should round up to next index');
            }
        }
    }

    function testFuzz_binarySearchRoundingUpRandomSubranges(uint256 itemLength, uint256 startValue, uint256 stepSize)
        public
    {
        setUpArray(itemLength, startValue, stepSize);

        uint256 len = array.length;
        for (uint256 i = 0; i < 10; i++) {
            if (len <= 2) break;

            uint256 leftBound = bound(uint256(keccak256(abi.encode(i, 'left'))), 0, len - 2);
            uint256 rightBound = bound(uint256(keccak256(abi.encode(i, 'right'))), leftBound + 1, len - 1);

            uint256 targetIndex = bound(uint256(keccak256(abi.encode(i, 'target'))), leftBound, rightBound);
            uint256 target = array[targetIndex];

            uint256 index = Search.binarySearchRoundingUp(array, target, leftBound, rightBound);
            assertEq(index, targetIndex, 'Subrange search should find correct index');
        }
    }
}
