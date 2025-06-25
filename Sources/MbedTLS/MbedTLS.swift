// MbedTLS.swift

import CMbedTLS
import Foundation

// MARK: - Error and Mode Enums

public enum AESMode {
    case ecb
    case cbc
    case xts // Added XTS mode to mirror the C enum 'aes_mode_t'
}

public enum MbedTLSError: Error, LocalizedError {
    case invalidKeySize(Int)
    case cipherSetupFailed(Int32)
    case setKeyFailed(Int32)
    case setIVFailed(Int32)
    case operationFailed(String, Int32)
    case invalidDataSize(String)

    public var errorDescription: String? {
        switch self {
        case .invalidKeySize(let size):
            return "Invalid key size: \(size) bytes."
        case .cipherSetupFailed(let code):
            return "Failed to set up cipher context. MbedTLS error code: \(code)."
        case .setKeyFailed(let code):
            return "Failed to set key. MbedTLS error code: \(code)."
        case .setIVFailed(let code):
            return "Failed to set IV/Tweak. MbedTLS error code: \(code)."
        case .operationFailed(let operation, let code):
            return "MbedTLS operation '\(operation)' failed with error code: \(code)."
        case .invalidDataSize(let reason):
            return "Invalid data size: \(reason)."
        }
    }
}

// MARK: - AESContext for ECB/CBC/XTS

/// A Swift class encapsulating MbedTLS AES context for ECB, CBC, and simulated XTS modes.
public final class AESContext {
    private var encryptContext: mbedtls_cipher_context_t
    private var decryptContext: mbedtls_cipher_context_t
    
    /// Initializes the AES context with a key and mode.
    /// - Parameter key: The cryptographic key. For AES-XTS, this must be 32 bytes (256 bits).
    /// - Parameter mode: The AES operational mode (.ecb, .cbc, or .xts).
    public init(key: Data, mode: AESMode) throws {
        self.encryptContext = mbedtls_cipher_context_t()
        self.decryptContext = mbedtls_cipher_context_t()
        
        mbedtls_cipher_init(&self.encryptContext)
        mbedtls_cipher_init(&self.decryptContext)
        
        guard let cipherInfo = Self.getCipherInfo(key: key, mode: mode) else {
            self.freeContexts()
            throw MbedTLSError.invalidKeySize(key.count)
        }
        
        var result = mbedtls_cipher_setup(&self.decryptContext, cipherInfo)
        if result != 0 { self.freeContexts(); throw MbedTLSError.cipherSetupFailed(result) }
        
        result = mbedtls_cipher_setup(&self.encryptContext, cipherInfo)
        if result != 0 { self.freeContexts(); throw MbedTLSError.cipherSetupFailed(result) }
        
        let keyBitLength = UInt32(key.count * 8)
        
        result = key.withUnsafeBytes { keyPtr in
            mbedtls_cipher_setkey(&self.decryptContext, keyPtr.baseAddress, Int32(keyBitLength), MBEDTLS_DECRYPT)
        }
        if result != 0 { self.freeContexts(); throw MbedTLSError.setKeyFailed(result) }
        
        result = key.withUnsafeBytes { keyPtr in
            mbedtls_cipher_setkey(&self.encryptContext, keyPtr.baseAddress, Int32(keyBitLength), MBEDTLS_ENCRYPT)
        }
        if result != 0 { self.freeContexts(); throw MbedTLSError.setKeyFailed(result) }
    }
    
    deinit {
        freeContexts()
    }
    
    private func freeContexts() {
        mbedtls_cipher_free(&self.encryptContext)
        mbedtls_cipher_free(&self.decryptContext)
    }

    /// Sets the Initialization Vector (IV) or Tweak for the context.
    /// - Parameter iv: A 16-byte Data object for the IV or Tweak.
    public func setIV(_ iv: Data) throws {
        guard iv.count == 16 else { throw MbedTLSError.invalidDataSize("IV/Tweak must be 16 bytes.") }
        
        var result = iv.withUnsafeBytes { ivPtr in
            mbedtls_cipher_set_iv(&self.decryptContext, ivPtr.baseAddress, iv.count)
        }
        if result != 0 { throw MbedTLSError.setIVFailed(result) }
        
        result = iv.withUnsafeBytes { ivPtr in
            mbedtls_cipher_set_iv(&self.encryptContext, ivPtr.baseAddress, iv.count)
        }
        if result != 0 { throw MbedTLSError.setIVFailed(result) }
    }
    
    public func encrypt(data: Data) throws -> Data {
        mbedtls_cipher_reset(&self.encryptContext)
        var outputData = Data(count: data.count)
        var outputLen: Int = 0
        
        let result = data.withUnsafeBytes { inputPtr in
            outputData.withUnsafeMutableBytes { outputPtr in
                mbedtls_cipher_update(&self.encryptContext, inputPtr.baseAddress, data.count, outputPtr.baseAddress, &outputLen)
            }
        }
        if result != 0 { throw MbedTLSError.operationFailed("encrypt update", result) }
        
        // No padding in these modes, so finish does nothing but can be called for correctness.
        mbedtls_cipher_finish(&self.encryptContext, nil, nil)
        
        outputData.count = outputLen
        return outputData
    }
    
    public func decrypt(data: Data) throws -> Data {
        mbedtls_cipher_reset(&self.decryptContext)
        var outputData = Data(count: data.count)
        var outputLen: Int = 0
        
        let result = data.withUnsafeBytes { inputPtr in
            outputData.withUnsafeMutableBytes { outputPtr in
                mbedtls_cipher_update(&self.decryptContext, inputPtr.baseAddress, data.count, outputPtr.baseAddress, &outputLen)
            }
        }
        if result != 0 { throw MbedTLSError.operationFailed("decrypt update", result) }
        
        // No padding in these modes, so finish does nothing.
        mbedtls_cipher_finish(&self.decryptContext, nil, nil)
        
        outputData.count = outputLen
        return outputData
    }

    private static func getCipherInfo(key: Data, mode: AESMode) -> UnsafePointer<mbedtls_cipher_info_t>? {
        let keySize = key.count
        let cipherType: mbedtls_cipher_type_t
        
        switch mode {
        case .ecb:
            switch keySize {
            case 16: cipherType = MBEDTLS_CIPHER_AES_128_ECB
            case 24: cipherType = MBEDTLS_CIPHER_AES_192_ECB
            case 32: cipherType = MBEDTLS_CIPHER_AES_256_ECB
            default: return nil
            }
        case .cbc:
            switch keySize {
            case 16: cipherType = MBEDTLS_CIPHER_AES_128_CBC
            case 24: cipherType = MBEDTLS_CIPHER_AES_192_CBC
            case 32: cipherType = MBEDTLS_CIPHER_AES_256_CBC
            default: return nil
            }
        case .xts:
            switch keySize {
            case 32: cipherType = MBEDTLS_CIPHER_AES_128_XTS // 32 bytes = 2 * 16-byte keys
            case 64: cipherType = MBEDTLS_CIPHER_AES_256_XTS // 64 bytes = 2 * 32-byte keys
            default: return nil
            }
        }
        return mbedtls_cipher_info_from_type(cipherType)
    }
}

// MARK: - Static CMAC Calculation

/// A static function to calculate AES-CMAC.
public enum CryptoUtils {
    public static func calculateCMAC(data: Data, key: Data) throws -> Data {
        guard key.count == 16 else { throw MbedTLSError.invalidKeySize(key.count) }
        
        var m_ctx = mbedtls_cipher_context_t()
        mbedtls_cipher_init(&m_ctx)
        defer { mbedtls_cipher_free(&m_ctx) }
        
        guard let cipherInfo = mbedtls_cipher_info_from_type(MBEDTLS_CIPHER_AES_128_ECB) else {
            throw MbedTLSError.operationFailed("cmac get_info", -1)
        }

        var result = mbedtls_cipher_setup(&m_ctx, cipherInfo)
        if result != 0 { throw MbedTLSError.operationFailed("cmac setup", result) }
        
        result = key.withUnsafeBytes { keyPtr in
            mbedtls_cipher_cmac_starts(&m_ctx, keyPtr.baseAddress, 128)
        }
        if result != 0 { throw MbedTLSError.operationFailed("cmac starts", result) }
        
        result = data.withUnsafeBytes { dataPtr in
            mbedtls_cipher_cmac_update(&m_ctx, dataPtr.baseAddress, data.count)
        }
        if result != 0 { throw MbedTLSError.operationFailed("cmac update", result) }
        
        var output = Data(count: 16)
        result = output.withUnsafeMutableBytes { outputPtr in
            mbedtls_cipher_cmac_finish(&m_ctx, outputPtr.baseAddress)
        }
        if result != 0 { throw MbedTLSError.operationFailed("cmac finish", result) }
        
        return output
    }
}
