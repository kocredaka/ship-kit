// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ShipKitRegistry
/// @notice Minimal on-chain registry where builders record contracts they have
///         shipped on an Avalanche chain (Fuji testnet or C-Chain mainnet).
/// @dev Non-custodial: this contract never holds funds. It only stores
///      shipment records (who shipped what, where, and when) so a builder's
///      shipping history is publicly verifiable on Snowtrace.
///      Demo / reference code. No third-party audit. Do not treat records
///      here as proof of code quality or security.
contract ShipKitRegistry {
    struct Shipment {
        address deployer;
        address contractAddress;
        uint256 chainId;
        string name;
        string metadata; // e.g. IPFS CID, repo URL, or short note
        uint64 shippedAt;
    }

    /// @notice Emitted when a shipment is recorded.
    event ShipmentRecorded(
        address indexed deployer, address indexed contractAddress, uint256 indexed chainId, string name
    );

    /// @notice Emitted when a shipment's metadata is updated by its deployer.
    event ShipmentUpdated(address indexed contractAddress, uint256 indexed chainId, string metadata);

    error NoCodeAtAddress(address contractAddress);
    error AlreadyRecorded(address contractAddress, uint256 chainId);
    error NotRecorded(address contractAddress, uint256 chainId);
    error NotDeployer(address caller, address deployer);
    error EmptyName();

    // chainId => contract address => shipment
    mapping(uint256 => mapping(address => Shipment)) private _shipments;
    // chainId => contract address => recorded?
    mapping(uint256 => mapping(address => bool)) private _recorded;
    // deployer => list of (chainId, contract) pairs, in record order
    mapping(address => Shipment[]) private _byDeployer;
    uint256 private _shipmentCount;

    /// @notice Record a contract you shipped. The address must contain code.
    /// @param contractAddress The deployed contract address on this chain.
    /// @param name Human-readable project/contract name (non-empty).
    /// @param metadata Optional free-form metadata (repo URL, IPFS CID, note).
    function recordShipment(address contractAddress, string calldata name, string calldata metadata) external {
        if (contractAddress.code.length == 0) revert NoCodeAtAddress(contractAddress);
        if (bytes(name).length == 0) revert EmptyName();
        if (_recorded[block.chainid][contractAddress]) {
            revert AlreadyRecorded(contractAddress, block.chainid);
        }

        Shipment memory shipment = Shipment({
            deployer: msg.sender,
            contractAddress: contractAddress,
            chainId: block.chainid,
            name: name,
            metadata: metadata,
            // Safe: block.timestamp fits in uint64 for ~584 billion years.
            // forge-lint: disable-next-line(unsafe-typecast)
            shippedAt: uint64(block.timestamp)
        });

        _shipments[block.chainid][contractAddress] = shipment;
        _recorded[block.chainid][contractAddress] = true;
        _byDeployer[msg.sender].push(shipment);
        unchecked {
            ++_shipmentCount;
        }

        emit ShipmentRecorded(msg.sender, contractAddress, block.chainid, name);
    }

    /// @notice Update the metadata of your own shipment record.
    function updateMetadata(address contractAddress, string calldata metadata) external {
        Shipment storage shipment = _shipments[block.chainid][contractAddress];
        if (!_recorded[block.chainid][contractAddress]) {
            revert NotRecorded(contractAddress, block.chainid);
        }
        if (shipment.deployer != msg.sender) {
            revert NotDeployer(msg.sender, shipment.deployer);
        }
        shipment.metadata = metadata;
        emit ShipmentUpdated(contractAddress, block.chainid, metadata);
    }

    /// @notice Read a shipment record for this chain.
    function getShipment(address contractAddress) external view returns (Shipment memory) {
        if (!_recorded[block.chainid][contractAddress]) {
            revert NotRecorded(contractAddress, block.chainid);
        }
        return _shipments[block.chainid][contractAddress];
    }

    /// @notice True if the address has a shipment record on this chain.
    function isRecorded(address contractAddress) external view returns (bool) {
        return _recorded[block.chainid][contractAddress];
    }

    /// @notice Total shipments recorded in this registry deployment.
    function shipmentCount() external view returns (uint256) {
        return _shipmentCount;
    }

    /// @notice All shipments recorded by one deployer, in record order.
    function shipmentsByDeployer(address deployer) external view returns (Shipment[] memory) {
        return _byDeployer[deployer];
    }
}
