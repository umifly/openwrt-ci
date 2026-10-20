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
rm -rf feeds/packages/net/{mosdns,v2ray-geodata}
rm -rf feeds/luci/applications/luci-app-mosdns

# iStore
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-quickstart
git_sparse_clone main https://github.com/kiddin9/op-packages quickstart

#mosdns
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

#easymesh
git clone --depth=1 https://github.com/arafatrahmanzami/luci-app-easymesh package/luci-app-easymesh

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by umifly/g" package/lean/default-settings/files/zzz-default-settings

# 修复 batman-adv 2026.x 与 Linux 5.10 内核不兼容问题（锁定 routing 源为 openwrt-23.05 分支）
sed -i 's|^src-git routing .*|src-git routing https://github.com/openwrt/routing.git;openwrt-23.05|' feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a
