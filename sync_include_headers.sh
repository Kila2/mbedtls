# setup.sh
#!/bin/sh
set -x
set -e # 如果任何命令失败，则退出

# 定义源和目标
TARGET_INCLUDE_DIR="Sources/CMbedTLS/include"
SOURCE_MBEDTLS_INCLUDE="include/mbedtls"
SOURCE_PSA_INCLUDE="include/psa"
SOURCE_CONFIG="include/mbedtls/mbedtls_config.h" # 假设你的配置文件在这里

echo "Setting up public headers for CMbedTLS..."

# 清理旧文件
rm -rf "$TARGET_INCLUDE_DIR"
mkdir -p "$TARGET_INCLUDE_DIR"

# 复制头文件，保持结构
cp -R "$SOURCE_MBEDTLS_INCLUDE" "$TARGET_INCLUDE_DIR/"
cp -R "$SOURCE_PSA_INCLUDE" "$TARGET_INCLUDE_DIR/"

# 复制配置文件
cp "$SOURCE_CONFIG" "$TARGET_INCLUDE_DIR/mbedtls_config.h"
# 如果有 psa config 也一起复制
# cp "path/to/your/psa/crypto_config.h" "$TARGET_INCLUDE_DIR/psa/crypto_config.h"

echo "Done."
