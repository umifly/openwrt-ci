# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 1. 修复 batman-adv 与 Linux 5.10 内核不兼容问题（锁定为 openwrt-22.03 分支）
sed -i 's|^src-git routing .*|src-git routing https://github.com/openwrt/routing.git;openwrt-22.03|' feeds.conf.default

# 2. 先更新 Feeds
./scripts/feeds update -a

# 3. 修复 shadowsocksr-libev 找不到 OpenSSL 头文件的问题
if [ -f feeds/helloworld/shadowsocksr-libev/Makefile ]; then
  sed -i 's/DEPENDS:=/DEPENDS:=+libopenssl /g' feeds/helloworld/shadowsocksr-libev/Makefile
  sed -i '/CONFIGURE_ARGS +=/a \	--with-openssl="$(STAGING_DIR)/usr" \\' feeds/helloworld/shadowsocksr-libev/Makefile
fi

# 4. 移除 Feeds 中自带的旧版 mosdns 和 v2ray-geodata（防止与 sbwml 版本冲突）
rm -rf feeds/packages/net/{mosdns,v2ray-geodata}
rm -rf feeds/luci/applications/luci-app-mosdns

# 5. 安装 Feeds
./scripts/feeds install -a

# 6. 拉取第三方插件放到 package 目录（放在 feeds install 之后最安全，不会被覆盖）
# iStore
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-quickstart
git_sparse_clone main https://github.com/kiddin9/op-packages quickstart

# mosdns 及其必需的依赖包 v2ray-geodata
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# easymesh
git clone --depth=1 https://github.com/arafatrahmanzami/luci-app-easymesh package/luci-app-easymesh

# 7. 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by umifly/g" package/lean/default-settings/files/zzz-default-settings
