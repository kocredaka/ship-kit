// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Greeter} from "../src/Greeter.sol";

contract GreeterTest is Test {
    Greeter internal greeter;
    address internal owner = address(this);
    address internal stranger = address(0x5EED);

    event MessageChanged(string oldMessage, string newMessage);

    function setUp() public {
        greeter = new Greeter("hello, avalanche");
    }

    function test_InitialMessageAndOwner() public view {
        assertEq(greeter.message(), "hello, avalanche");
        assertEq(greeter.owner(), owner);
    }

    function test_RevertWhen_ConstructedEmpty() public {
        vm.expectRevert(Greeter.EmptyMessage.selector);
        new Greeter("");
    }

    function test_SetMessageByOwner() public {
        vm.expectEmit(false, false, false, true);
        emit MessageChanged("hello, avalanche", "hello, fuji");
        greeter.setMessage("hello, fuji");
        assertEq(greeter.message(), "hello, fuji");
    }

    function test_RevertWhen_SetMessageByStranger() public {
        vm.expectRevert(abi.encodeWithSelector(Greeter.NotOwner.selector, stranger, owner));
        vm.prank(stranger);
        greeter.setMessage("hijacked");
    }

    function test_RevertWhen_SetMessageEmpty() public {
        vm.expectRevert(Greeter.EmptyMessage.selector);
        greeter.setMessage("");
    }

    function test_TransferOwnership() public {
        greeter.transferOwnership(stranger);
        assertEq(greeter.owner(), stranger);
        vm.prank(stranger);
        greeter.setMessage("new owner here");
        assertEq(greeter.message(), "new owner here");
    }

    function test_RevertWhen_TransferByStranger() public {
        vm.expectRevert(abi.encodeWithSelector(Greeter.NotOwner.selector, stranger, owner));
        vm.prank(stranger);
        greeter.transferOwnership(stranger);
    }

    function testFuzz_SetMessageRoundTrip(string memory next) public {
        vm.assume(bytes(next).length > 0);
        greeter.setMessage(next);
        assertEq(greeter.message(), next);
    }
}
