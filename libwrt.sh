# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ==================== [核心修复] 修复 GCC 14 编译 mbedtls 错误 ====================
# 问题描述：GCC 14 在 aarch64 架构下编译 mbedtls 时，因 memset 内联优化导致 "target specific option mismatch" 错误。
# 原因：OpenWrt 默认开启 -Werror，将警告视为错误。GCC 14 对内置函数内联检查更严格。
# 解决方案：
# 1. 在 mbedtls 的 Makefile 中添加 PKG_BUILD_FLAGS += no-werror (如果支持)
# 2. 或者更精准地：添加 TARGET_CFLAGS += -Wno-error=inlining-failed -fno-builtin-memset
# 3. 由于 mbedtls 使用 CMake，我们需要确保这些标志传递给 CMake。
#    在 OpenWrt 中，修改 Makefile 中的 CMAKE_OPTIONS 是最稳妥的。

MK_FILE="package/libs/mbedtls/Makefile"
if [ -f "$MK_FILE" ]; then
    echo "[FIX] Patching mbedtls Makefile for GCC 14 compatibility..."
    
    # 方法：在 Makefile 中查找 CMAKE_OPTIONS 行，追加标志。
    # 如果没有 CMAKE_OPTIONS 行，则添加一行。
    # 同时添加 -Wno-error=inlining-failed 以防止内联警告变成错误
    
    # 检查是否已经修复过
    if ! grep -q "fno-builtin-memset" "$MK_FILE"; then
        # 尝试在 CMAKE_OPTIONS 行追加
        if grep -q "^CMAKE_OPTIONS" "$MK_FILE"; then
            sed -i '/^CMAKE_OPTIONS/s/$/ -DCMAKE_C_FLAGS="-fno-builtin-memset -Wno-error=inlining-failed"/' "$MK_FILE"
        else
            # 如果没有 CMAKE_OPTIONS，就在 PKG_LICENSE 或其他定义后插入
            # 或者直接追加到文件末尾（OpenWrt Makefile 通常允许这样）
            echo 'CMAKE_OPTIONS += -DCMAKE_C_FLAGS="-fno-builtin-memset -Wno-error=inlining-failed"' >> "$MK_FILE"
        fi
        
        # 备用方案：有些版本的 OpenWrt mbedtls Makefile 使用 PKG_BUILD_FLAGS
        # 添加 no-werror 标志（如果可用）
        # echo 'PKG_BUILD_FLAGS += no-werror' >> "$MK_FILE" 
        
        echo "[FIX] Patch applied successfully."
    else
        echo "[FIX] Patch already applied, skipping."
    fi
else
    echo "[ERROR] mbedtls Makefile not found at $MK_FILE"
fi
# ==================== [修复结束] ====================

# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci
# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh
# ddns-go
git_sparse_clone master https://github.com/jeessy2/ddns-go .

./scripts/feeds update -a
./scripts/feeds install -a
