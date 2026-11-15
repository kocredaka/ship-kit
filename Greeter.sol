// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Greeter
/// @notice Smallest useful demo contract for the Ship Kit walkthrough:
///         stores one message, readable by anyone, changeable only by owner.
/// @dev Demo / reference code. No third-party audit.
contract Greeter {
    string private _message;
    address private _owner;

    event MessageChanged(string oldMessage, string newMessage);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner(address caller, address owner);
    error EmptyMessage();

    constructor(string memory initialMessage) {
        if (bytes(initialMessage).length == 0) revert EmptyMessage();
        _message = initialMessage;
        _owner = msg.sender;
    }

    /// @notice Current greeting message.
    function message() external view returns (string memory) {
        return _message;
    }

    /// @notice Contract owner (the deployer, unless transferred).
    function owner() external view returns (address) {
        return _owner;
    }

    /// @notice Change the message. Owner only.
    function setMessage(string calldata newMessage) external {
        if (msg.sender != _owner) revert NotOwner(msg.sender, _owner);
        if (bytes(newMessage).length == 0) revert EmptyMessage();
        string memory oldMessage = _message;
        _message = newMessage;
        emit MessageChanged(oldMessage, newMessage);
    }

    /// @notice Transfer ownership. Owner only.
    function transferOwnership(address newOwner) external {
        if (msg.sender != _owner) revert NotOwner(msg.sender, _owner);
        require(newOwner != address(0), "Greeter: zero address");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
