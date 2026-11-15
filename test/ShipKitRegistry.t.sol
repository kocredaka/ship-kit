// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ShipKitRegistry} from "../src/ShipKitRegistry.sol";
import {Greeter} from "../src/Greeter.sol";

contract ShipKitRegistryTest is Test {
    ShipKitRegistry internal registry;
    Greeter internal greeter;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    event ShipmentRecorded(
        address indexed deployer, address indexed contractAddress, uint256 indexed chainId, string name
    );

    function setUp() public {
        registry = new ShipKitRegistry();
        greeter = new Greeter("hello, fuji");
    }

    function test_RecordShipmentStoresAllFields() public {
        vm.prank(alice);
        registry.recordShipment(address(greeter), "greeter-demo", "repo: ship-kit");

        ShipKitRegistry.Shipment memory s = registry.getShipment(address(greeter));
        assertEq(s.deployer, alice);
        assertEq(s.contractAddress, address(greeter));
        assertEq(s.chainId, block.chainid);
        assertEq(s.name, "greeter-demo");
        assertEq(s.metadata, "repo: ship-kit");
        assertEq(s.shippedAt, block.timestamp);
        assertEq(registry.shipmentCount(), 1);
        assertTrue(registry.isRecorded(address(greeter)));
    }

    function test_RecordShipmentEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit ShipmentRecorded(alice, address(greeter), block.chainid, "greeter-demo");
        vm.prank(alice);
        registry.recordShipment(address(greeter), "greeter-demo", "");
    }

    function test_RevertWhen_AddressHasNoCode() public {
        address empty = address(0xE123);
        vm.expectRevert(abi.encodeWithSelector(ShipKitRegistry.NoCodeAtAddress.selector, empty));
        registry.recordShipment(empty, "nothing", "");
    }

    function test_RevertWhen_NameEmpty() public {
        vm.expectRevert(ShipKitRegistry.EmptyName.selector);
        registry.recordShipment(address(greeter), "", "");
    }

    function test_RevertWhen_AlreadyRecorded() public {
        vm.prank(alice);
        registry.recordShipment(address(greeter), "greeter-demo", "");
        vm.expectRevert(
            abi.encodeWithSelector(ShipKitRegistry.AlreadyRecorded.selector, address(greeter), block.chainid)
        );
        vm.prank(bob);
        registry.recordShipment(address(greeter), "greeter-demo", "");
    }

    function test_UpdateMetadataByDeployer() public {
        vm.prank(alice);
        registry.recordShipment(address(greeter), "greeter-demo", "v1");
        vm.prank(alice);
        registry.updateMetadata(address(greeter), "v2");
        assertEq(registry.getShipment(address(greeter)).metadata, "v2");
    }

    function test_RevertWhen_UpdateByNonDeployer() public {
        vm.prank(alice);
        registry.recordShipment(address(greeter), "greeter-demo", "v1");
        vm.expectRevert(abi.encodeWithSelector(ShipKitRegistry.NotDeployer.selector, bob, alice));
        vm.prank(bob);
        registry.updateMetadata(address(greeter), "hijack");
    }

    function test_RevertWhen_GetUnrecorded() public {
        vm.expectRevert(abi.encodeWithSelector(ShipKitRegistry.NotRecorded.selector, address(greeter), block.chainid));
        registry.getShipment(address(greeter));
    }

    function test_ShipmentsByDeployerPreservesOrder() public {
        Greeter second = new Greeter("second");
        vm.startPrank(alice);
        registry.recordShipment(address(greeter), "first", "");
        registry.recordShipment(address(second), "second", "");
        vm.stopPrank();

        ShipKitRegistry.Shipment[] memory list = registry.shipmentsByDeployer(alice);
        assertEq(list.length, 2);
        assertEq(list[0].name, "first");
        assertEq(list[1].name, "second");
        assertEq(registry.shipmentsByDeployer(bob).length, 0);
        assertEq(registry.shipmentCount(), 2);
    }

    function testFuzz_RecordAnyNamedContract(string memory name, string memory metadata) public {
        vm.assume(bytes(name).length > 0);
        registry.recordShipment(address(greeter), name, metadata);
        assertEq(registry.getShipment(address(greeter)).name, name);
        assertEq(registry.getShipment(address(greeter)).metadata, metadata);
    }
}
