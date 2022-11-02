// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {BaseTest, console} from "./base/BaseTest.t.sol";
import "../main/Diamond.sol";
import "../main/facets/DiamondCutFacet.sol";
import "../main/facets/DiamondLoupeFacet.sol";
import "../main/facets/OwnershipFacet.sol";
import "../main/facets/MyFacet.sol";
import "../main/upgradeInitializers/DiamondInit.sol";

import "./utils/FunctionSelector.sol";

contract DiamondTest is BaseTest {
    address private constant ZERO_ADDRESS = address(0);

    FunctionSelector private functionSelector;

    Diamond private diamond;
    DiamondInit private diamondInit;

    DiamondCutFacet private diamondCutFacet;
    DiamondLoupeFacet private diamondLoupeFacet;
    OwnershipFacet private ownershipFacet;
    MyFacet private myFacet;

    address private owner;
    address private user1;
    address private user2;

    function setUp() public {
        vm.warp(10000);

        functionSelector = new FunctionSelector();

        diamondCutFacet = new DiamondCutFacet();

        owner = generateAddress("Owner", false, 10 ether);
        user1 = generateAddress("User1", false, 10 ether);
        user2 = generateAddress("User2", false, 10 ether);

        // add diamondCutFacet
        diamond = new Diamond(owner, address(diamondCutFacet));
        diamondInit = new DiamondInit();

        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        bytes4[] memory selectorsInDiamondLoupeFacet = new bytes4[](4);
        selectorsInDiamondLoupeFacet[0] = functionSelector.getSelector(
            "facets()"
        );
        selectorsInDiamondLoupeFacet[1] = functionSelector.getSelector(
            "facetFunctionSelectors(address)"
        );

        selectorsInDiamondLoupeFacet[2] = functionSelector.getSelector(
            "facetAddresses()"
        );

        selectorsInDiamondLoupeFacet[3] = functionSelector.getSelector(
            "facetAddress()"
        );

        cut[0].facetAddress = address(diamondLoupeFacet);
        cut[0].action = IDiamondCut.FacetCutAction.Add;
        cut[0].functionSelectors = selectorsInDiamondLoupeFacet;

        bytes4[] memory selectorsInOwnershipFacet = new bytes4[](2);
        selectorsInOwnershipFacet[0] = functionSelector.getSelector(
            "transferOwnership(address)"
        );

        selectorsInOwnershipFacet[1] = functionSelector.getSelector("owner()");

        cut[1].facetAddress = address(ownershipFacet);
        cut[1].action = IDiamondCut.FacetCutAction.Add;
        cut[1].functionSelectors = selectorsInOwnershipFacet;

        IDiamondCut diamondCut = IDiamondCut(address(diamond));

        // add diamondLoupeFacet and ownershipFacet
        vm.startPrank(owner);
        {
            diamondCut.diamondCut(
                cut,
                address(diamondInit),
                abi.encodeWithSignature("init()")
            );
        }
        vm.stopPrank();
    }

    function test_facetAddresses() public {
        DiamondLoupeFacet nDiamondLoupeFacet = DiamondLoupeFacet(
            address(diamond)
        );

        address[] memory addresses = nDiamondLoupeFacet.facetAddresses();

        assertEq(addresses[0], address(diamondCutFacet));
        assertEq(addresses[1], address(diamondLoupeFacet));
        assertEq(addresses[2], address(ownershipFacet));
    }

    function test_facetSelectors() public {}

    function test_addMyFunc() public {
        MyFacet myFacet = new MyFacet();
        DiamondCutFacet nDiamondCutFacet = DiamondCutFacet(address(diamond));

        bytes4[] memory selectorsInMyFacet = new bytes4[](3);
        selectorsInMyFacet[0] = functionSelector.getSelector("MyFunc1()");

        selectorsInMyFacet[1] = functionSelector.getSelector("MyFunc2()");

        selectorsInMyFacet[2] = functionSelector.getSelector("MyFunc3()");

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        cut[0].facetAddress = address(myFacet);
        cut[0].action = IDiamondCut.FacetCutAction.Add;
        cut[0].functionSelectors = selectorsInMyFacet;

        vm.startPrank(owner);
        {
            nDiamondCutFacet.diamondCut(cut, ZERO_ADDRESS, "0x");
        }
        vm.stopPrank();

        MyFacet nMyFacet = MyFacet(address(diamond));
        uint256 count = nMyFacet.MyFunc2();
        console.logUint(count);
        nMyFacet.MyFunc1();
        count = nMyFacet.MyFunc2();
        console.logUint(count);
        address sender = nMyFacet.MyFunc3();
        console.logAddress(sender);

        count = myFacet.MyFunc2();
        console.logUint(count);

        sender = myFacet.MyFunc3();
        console.logAddress(sender);
    }
}
