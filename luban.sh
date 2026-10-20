# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 移除要替换的包
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/v2ray-geodata


# iStore
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-quickstart
git_sparse_clone main https://github.com/kiddin9/op-packages quickstart

#mosdns
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

#easymesh
git clone --depth=1 https://github.com/arafatrahmanzami/luci-app-easymesh package/luci-app-easymesh

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by umifly/g" package/lean/default-settings/files/zzz-default-settings

# 修复 batman-adv 2026.x 与 Linux 5.10 内核不兼容问题（锁定 routing 源为 openwrt-23.05 分支）
sed -i 's|^src-git routing .*|src-git routing https://github.com/openwrt/routing.git;openwrt-22.03|' feeds.conf.default

# 2. 修复 shadowsocksr-libev 找不到 OpenSSL 头文件的问题（必须在 feeds update 之后、install 之前或之后执行）
if [ -f feeds/helloworld/shadowsocksr-libev/Makefile ]; then
  # 强制在 DEPENDS 中加入 +libopenssl，确保并发编译时先编译安装 openssl
  sed -i 's/DEPENDS:=/DEPENDS:=+libopenssl /g' feeds/helloworld/shadowsocksr-libev/Makefile
  # 显式传入 staging_dir 下的 openssl 路径，防止 pcre2-config 污染头文件路径
  sed -i '/CONFIGURE_ARGS +=/a \	--with-openssl="$(STAGING_DIR)/usr" \\' feeds/helloworld/shadowsocksr-libev/Makefile
fi

./scripts/feeds update -a
./scripts/feeds install -a
