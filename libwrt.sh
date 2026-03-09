# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ==================== [修复开始] 修复 GCC 14 编译 mbedtls 错误 ====================
# 问题：GCC 14 在 aarch64 架构下编译 mbedtls 时，memset 内联失败
# 解决：在 mbedtls 的 Makefile 中添加 -fno-builtin-memset 标志
MK_FILE="package/libs/mbedtls/Makefile"
if [ -f "$MK_FILE" ]; then
    # 检查是否已经添加过，防止重复
    if ! grep -q "fno-builtin-memset" "$MK_FILE"; then
        # 在文件末尾追加 TARGET_CFLAGS
        echo 'TARGET_CFLAGS += -fno-builtin-memset' >> "$MK_FILE"
        echo "[FIX] Applied patch: Added '-fno-builtin-memset' to mbedtls Makefile for GCC 14 compatibility."
    fi
else
    echo "[WARNING] mbedtls Makefile not found at $MK_FILE, skipping fix."
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
