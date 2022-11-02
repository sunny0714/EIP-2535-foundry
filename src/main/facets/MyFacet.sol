// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFacet {
	uint256 private count = 0;
	event MyEvent(address something);

	function MyFunc1() external {
		count++;
	}

	function MyFunc2() external view returns (uint256) {
		return count;
	}

	function MyFunc3() external view returns (address) {
		return msg.sender;
	}

	function supportsInterface(bytes4 _interfaceID)
		external
		view
		returns (bool)
	{}
}
