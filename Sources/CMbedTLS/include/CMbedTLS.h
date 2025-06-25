#ifndef CMbedTLS_h
#define CMbedTLS_h

// MbedTLS 主头文件
#include "mbedtls/ssl.h"
#include "mbedtls/net_sockets.h"
#include "mbedtls/error.h"
#include "mbedtls/debug.h"
#include "mbedtls/entropy.h"
#include "mbedtls/ctr_drbg.h"

// X.509 头文件
#include "mbedtls/x509_crt.h"
#include "mbedtls/x509_csr.h"
#include "mbedtls/x509_crl.h"

// PK 头文件
#include "mbedtls/pk.h"

// PSA Crypto API
#include "psa/crypto.h"

#endif /* CMbedTLS_h */
