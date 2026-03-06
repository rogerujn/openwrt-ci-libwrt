#!/bin/bash
# apply_mbedtls_fix.sh - 直接修改mbedtls Makefile修复GCC 14.3.0兼容性问题

set -e  # 遇到错误立即退出

echo "正在修复mbedtls GCC 14.3.0兼容性问题..."

# 检查是否在正确的目录结构中
if [ ! -d "openwrt" ]; then
    echo "错误: 没有找到openwrt目录。请确保此脚本在包含openwrt子目录的位置运行。"
    exit 1
fi

cd openwrt

# 检查目标文件是否存在
MBEDTLS_MAKEFILE="package/libs/mbedtls/Makefile"
if [ ! -f "$MBEDTLS_MAKEFILE" ]; then
    echo "错误: 没有找到 $MBEDTLS_MAKEFILE"
    exit 1
fi

echo "找到mbedtls Makefile，正在应用修复..."

# 检查是否已经应用过修复
if grep -q "Wno-unterminated-string-initialization" "$MBEDTLS_MAKEFILE"; then
    echo "检测到已存在修复，跳过..."
else
    echo "应用GCC 14.3.0兼容性修复..."

    # 创建备份
    cp "$MBEDTLS_MAKEFILE" "${MBEDTLS_MAKEFILE}.backup"
    echo "已创建备份: ${MBEDTLS_MAKEFILE}.backup"

    # 使用sed在CMAKE_OPTIONS定义后插入修复内容
    temp_file=$(mktemp)
    
    # 找到CMAKE_OPTIONS行并插入修复内容
    awk '
    /^CMAKE_OPTIONS \+=$/ {
        print $0
        print "\t-DUSE_SHARED_MBEDTLS_LIBRARY=OFF \\"
        print ""
        print "# Fix for GCC 14.3.0 compatibility"
        print "TARGET_CFLAGS += -Wno-unterminated-string-initialization"
        print "TARGET_CXXFLAGS += -Wno-unterminated-string-initialization"
        print "CMAKE_OPTIONS += -DCMAKE_C_FLAGS=\"$(TARGET_CFLAGS)\" -DCMAKE_CXX_FLAGS=\"$(TARGET_CXXFLAGS)\""
        print ""
        next
    }
    {
        print $0
    }
    ' "$MBEDTLS_MAKEFILE" > "$temp_file" && mv "$temp_file" "$MBEDTLS_MAKEFILE"

    # 如果上面的替换没有生效，使用另一种方式
    if ! grep -q "Wno-unterminated-string-initialization" "$MBEDTLS_MAKEFILE"; then
        # 查找PKG_CONFIG_DEPENDS定义后的位置并插入
        sed -i '/-DMBEDTLS_FATAL_WARNINGS=OFF/a \
\
# Fix for GCC 14.3.0 compatibility\
TARGET_CFLAGS += -Wno-unterminated-string-initialization\
TARGET_CXXFLAGS += -Wno-unterminated-string-initialization\
CMAKE_OPTIONS += -DCMAKE_C_FLAGS="$(TARGET_CFLAGS)" -DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS)"\
' "$MBEDTLS_MAKEFILE"
    fi

    # 验证修复是否成功
    if grep -q "Wno-unterminated-string-initialization" "$MBEDTLS_MAKEFILE"; then
        echo "✓ mbedtls Makefile 修复成功!"
        
        # 显示修改内容
        echo "修改内容预览:"
        grep -A 4 -B 1 "Wno-unterminated-string-initialization" "$MBEDTLS_MAKEFILE"
    else
        echo "✗ 修复可能失败，正在恢复备份..."
        mv "${MBEDTLS_MAKEFILE}.backup" "$MBEDTLS_MAKEFILE"
        exit 1
    fi
fi

echo "mbedtls修复完成！"