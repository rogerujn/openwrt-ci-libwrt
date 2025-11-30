rm -rf package/emortal/luci-app-athena-led
rm -rf feeds/luci/applications/luci-app-netdata
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led
# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci
# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

./scripts/feeds update -a
# 安装 KMS 核心服务 + LuCI 插件
./scripts/feeds install -p feeds/packages -y vlmcsd
./scripts/feeds install -p feeds/luci -y luci-app-vlmcsd
# 可选：安装中文语言包
./scripts/feeds install -p feeds/luci -y luci-i18n-vlmcsd-zh-cn
./scripts/feeds install -a
