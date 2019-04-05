pragma solidity >=0.5.0 <0.6.0;

/*
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Forked from https://github.com/0xProject/0x-monorepo
*/

contract LibEIP712 {

    // EIP712 Domain Name value
    string constant internal EIP712_DOMAIN_NAME = "AZTEC_CRYPTOGRAPHY_ENGINE";

    // EIP712 Domain Version value
    string constant internal EIP712_DOMAIN_VERSION = "1";

    // Hash of the EIP712 Domain Separator Schema
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
            "string name,",
            "string version,",
            "address verifyingContract",
        ")"
    ));

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encode(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            address(this)
        ));
    }

    /// @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    /// @param _hashStruct The EIP712 hash struct.
    /// @return EIP712 hash applied to this EIP712 Domain.
    function hashEIP712Message(bytes32 _hashStruct)
        internal
        view
        returns (bytes32 _result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer. We're not going to use it - we're going to overwrite it!
            // We need 0x60 bytes of memory for this hash,
            // cheaper to overwrite the free memory pointer at 0x40, and then replace it, than allocating free memory
            let memPtr := mload(0x40)
            mstore(0x00, 0x1901)               // EIP191 header
            mstore(0x20, eip712DomainHash)     // EIP712 domain hash
            mstore(0x40, _hashStruct)          // Hash of struct
            _result := keccak256(0x1e, 0x42)   // compute hash
            // replace memory pointer
            mstore(0x40, memPtr)
        }
    }

    // /// @dev Extracts the address of the signer with ECDSA.
    // /// @param _message The EIP712 message.
    // /// @param _signature The ECDSA values, v, r and s.
    // /// @return The address of the message signer.
    // function recoverSignature(
    //     bytes32 _message,
    //     bytes memory _signature
    // ) internal view returns (address _signer) {
    //     bool result;
    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //     assembly {
    //         v := mload(add(_signature, 0x20))
    //         r := mload(add(_signature, 0x40))
    //         s := mload(add(_signature, 0x60))
    //         let memPtr := mload(0x40)
    //         mstore(memPtr, _message)
    //         mstore(add(memPtr, 0x20), v)
    //         mstore(add(memPtr, 0x40), r)
    //         mstore(add(memPtr, 0x60), s)
    //         result := and(
    //             and(
    //                 eq(mload(_signature), 0x60),
    //                 or(eq(v, 27), eq(v, 28))
    //             ),
    //             staticcall(gas, 0x01, memPtr, 0x80, memPtr, 0x20)
    //         )
    //         _signer := mload(memPtr)
    //     }
    //     require(result, "signature recovery failed");
    //     require(_signer != address(0), "signer address cannot be 0");
    // }

    /// @dev Extracts the address of the signer with ECDSA.
    /// @param _message The EIP712 message.
    /// @param _signature The ECDSA values, v, r and s.
    /// @return The address of the message signer.
    function recoverSignature(
        bytes32 _message,
        bytes memory _signature
    ) internal  returns (address _signer) {
        bool result;
        assembly {
            // Here's a little trick we can pull. We expect `_signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `_signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile

            // load length as a temporary variable
            let byteLength := mload(_signature)

            // store the signature message
            mstore(_signature, _message)

            // load 'v' - we need it for a condition check
            let v := mload(add(_signature, 0x20))

            result := and(
                and(
                    // validate signature length == 0x60 bytes
                    eq(byteLength, 0x60),
                    // validate v == 27 or v == 28
                    or(eq(v, 27), eq(v, 28))
                ),
                // validate call to precompile succeeds
                staticcall(gas, 0x01, _signature, 0x80, _signature, 0x20)
            )
            _signer := mload(_signature) // load signing address
            mstore(_signature, byteLength) // and put the byte length back where it belongs
        }
        // wrap failure states in a single if test, so that happy path only has 1 conditional jump
        if (!(result && (_signer == address(0x0)))) {
            emit DebugSigner(_signer);
            require(_signer != address(0x0), "signer address cannot be 0");
            require(result, "signature recovery failed");
        }
    }

    event DebugSigner(address signer);
}

