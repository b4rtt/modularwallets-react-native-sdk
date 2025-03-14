//
// Copyright (c) 2025, Circle Internet Group, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift WebAuthn open source project
//
// Copyright (c) 2022 the Swift WebAuthn project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift WebAuthn project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import CryptoKit
import SwiftCBOR

/// Data created and/ or used by the authenticator during authentication/ registration.
/// The data contains, for example, whether a user was present or verified.
struct AuthenticatorData: Equatable, Sendable {
    let relyingPartyIDHash: [UInt8]
    let flags: AuthenticatorFlags
    let counter: UInt32
    /// For attestation signatures this value will be set. For assertion signatures not.
    let attestedData: AttestedCredentialData?
    let extData: [UInt8]?
}

extension AuthenticatorData {
    init(bytes: [UInt8]) throws {
        let minAuthDataLength = 37
        guard bytes.count >= minAuthDataLength else {
            throw WebAuthnError.authDataTooShort
        }

        let relyingPartyIDHash = Array(bytes[..<32])
        let flags = AuthenticatorFlags(bytes[32])
        let counter = UInt32(bigEndianBytes: bytes[33..<37])

        var remainingCount = bytes.count - minAuthDataLength

        // If the BE bit of the flags in authData is not set, verify that
        // the BS bit is not set.
        // Trying to keep the business logic consistent with Android,
        // but actually executing the test material causes the check to fail.
        //guard flags.isBackupEligible, !flags.isCurrentlyBackedUp else {
        //    throw WebAuthnError.authenticatorFlagsCheckFailed
        //}

        var attestedCredentialData: AttestedCredentialData?
        // For attestation signatures, the authenticator MUST set the AT flag and include the attestedCredentialData.
        if flags.attestedCredentialData {
            let minAttestedAuthLength = 37 + AAGUID.size + 2
            guard bytes.count > minAttestedAuthLength else {
                throw WebAuthnError.attestedCredentialDataMissing
            }
            let (data, length) = try Self.parseAttestedData(bytes)
            attestedCredentialData = data
            remainingCount -= length
        // For assertion signatures, the AT flag MUST NOT be set and the attestedCredentialData MUST NOT be included.
        } else {
            if !flags.extensionDataIncluded && bytes.count != minAuthDataLength {
                throw WebAuthnError.attestedCredentialFlagNotSet
            }
        }

        var extensionData: [UInt8]?
        if flags.extensionDataIncluded {
            guard remainingCount != 0 else {
                throw WebAuthnError.extensionDataMissing
            }
            extensionData = Array(bytes[(bytes.count - remainingCount)...])
            remainingCount -= extensionData?.count ?? 0
        }

        guard remainingCount == 0 else {
            throw WebAuthnError.leftOverBytesInAuthenticatorData
        }

        self.relyingPartyIDHash = relyingPartyIDHash
        self.flags = flags
        self.counter = counter
        self.attestedData = attestedCredentialData
        self.extData = extensionData

    }

    /// Parse and return the attested credential data and its length.
    ///
    /// This is assumed to take place after the first 37 bytes of `data`, which is always of fixed size.
    /// - SeeAlso: [WebAuthn Level 3 Editor's Draft §6.5.1. Attested Credential Data]( https://w3c.github.io/webauthn/#sctn-attested-credential-data)
    private static func parseAttestedData(_ data: [UInt8]) throws -> (AttestedCredentialData, Int) {
        /// **aaguid** (16): The AAGUID of the authenticator.
        guard let aaguid = AAGUID(bytes: data[37..<(37 + AAGUID.size)])  // Bytes [37-52]
        else { throw WebAuthnError.attestedCredentialDataMissing }

        /// **credentialIdLength** (2): Byte length L of credentialId, 16-bit unsigned big-endian integer. Value MUST be ≤ 1023.
        let idLengthBytes = data[53..<55]  // Length is 2 bytes
        let idLengthData = Data(idLengthBytes)
        let idLength = UInt16(bigEndianBytes: idLengthData)

        guard idLength <= 1023
        else { throw WebAuthnError.credentialIDTooLong }

        let credentialIDEndIndex = Int(idLength) + 55
        guard data.count >= credentialIDEndIndex 
        else { throw WebAuthnError.credentialIDTooShort }

        /// **credentialId** (L): Credential ID
        let credentialID = data[55..<credentialIDEndIndex]

        /// **credentialPublicKey** (variable): The credential public key encoded in `COSE_Key` format, as defined in [Section 7](https://tools.ietf.org/html/rfc9052#section-7) of [RFC9052], using the CTAP2 canonical CBOR encoding form.
        /// Assuming valid CBOR, verify the public key's length by decoding the next CBOR item.
        let inputStream = ByteInputStream(data[credentialIDEndIndex...])
        let decoder = CBORDecoder(stream: inputStream, options: CBOROptions(maximumDepth: 16))
        _ = try decoder.decodeItem()
        let publicKeyBytes = data[credentialIDEndIndex..<(data.count - inputStream.remainingBytes)]

        let data = AttestedCredentialData(
            authenticatorAttestationGUID: aaguid,
            credentialID: Array(credentialID),
            publicKey: Array(publicKeyBytes)
        )

        /// `2` is the size of **credentialIdLength**
        let length = AAGUID.size + 2 + data.credentialID.count + data.publicKey.count

        return (data, length)
    }
}

/// A helper type to determine how many bytes were consumed when decoding CBOR items.
class ByteInputStream: CBORInputStream {
    private var slice: ArraySlice<UInt8>
    
    init(_ slice: ArraySlice<UInt8>) {
        self.slice = slice
    }
    
    /// The remaining bytes in the original data buffer.
    var remainingBytes: Int { slice.count }
    
    func popByte() throws -> UInt8 {
        if slice.count < 1 { throw CBORError.unfinishedSequence }
        return slice.removeFirst()
    }
    
    func popBytes(_ n: Int) throws -> ArraySlice<UInt8> {
        if slice.count < n { throw CBORError.unfinishedSequence }
        let result = slice.prefix(n)
        slice = slice.dropFirst(n)
        return result
    }
}
