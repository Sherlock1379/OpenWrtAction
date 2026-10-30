#!/bin/bash
#
# Copyright (c) 2019-2025 SmallProgram <https://github.com/smallprogram>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/smallprogram/OpenWrtAction
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3
# This script will be executed after `make defconfig` and `make download` to fix certain issues.
#

attempts=$1

echo "DiY script part 3: is Runing"

echo "修正相关package的hash值"

# -------------------------smartdns----------------------------------
# echo "正在修正smartdns的hash值到最新版本"
# current_path=$PWD
# cd package/custom_packages/openwrt-smartdns
# LATEST_TAG=$(curl -sL https://api.github.com/repos/pymumu/smartdns/releases/latest | jq -r .tag_name)
# # 过滤掉开头的英文字符，按照openwrt规定
# CLEAN_VERSION=$(echo "$LATEST_TAG" | sed 's/^[a-zA-Z_]*//')
# LATEST_SMARTDNS=$(curl -sL "https://api.github.com/repos/pymumu/smartdns/commits/$LATEST_TAG" | jq -r .sha)
# LATEST_WEBUI=$(curl -sL https://api.github.com/repos/pymumu/smartdns-webui/commits | jq -r '.[0].sha')
# if [ -z "$LATEST_SMARTDNS" ] || [ "$LATEST_SMARTDNS" == "null" ]; then
#     echo "Failed to fetch SmartDNS commit"
#     exit 1
# fi
# echo ">> 获取到 SmartDNS 最新版本: $LATEST_TAG (Commit: $LATEST_SMARTDNS)"
# echo ">> 提取到合法数字版本号: $CLEAN_VERSION (原始Tag: $LATEST_TAG)"
# echo ">> 获取到 WebUI 最新 Commit: $LATEST_WEBUI"
# sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$CLEAN_VERSION/g" Makefile
# sed -i "s/^PKG_RELEASE:=.*/PKG_RELEASE:=1/g" Makefile
# sed -i "s/^PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=$LATEST_SMARTDNS/g" Makefile
# sed -i "s/^SMARTDNS_WEBUI_SOURCE_VERSION:=.*/SMARTDNS_WEBUI_SOURCE_VERSION:=$LATEST_WEBUI/g" Makefile
# sed -i "s/^PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=$LATEST_SMARTDNS/g" Makefile
# sed -i "s/^SMARTDNS_WEBUI_SOURCE_VERSION:=.*/SMARTDNS_WEBUI_SOURCE_VERSION:=$LATEST_WEBUI/g" Makefile
# sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=/g' Makefile
# sed -i 's/^[[:space:]]*MIRROR_HASH:=.*/\tMIRROR_HASH:=/g' Makefile
# cd $current_path
# make defconfig > /dev/null
# make package/custom_packages/openwrt-smartdns/download -j8
# make package/custom_packages/openwrt-smartdns/check FIXUP=1 V=s
# -------------------------end-smartdns----------------------------------

# -------------------------shadowsocksr-libev----------------------------------
# make package/feeds/passwall_packages/shadowsocksr-libev/download -j8
# make package/feeds/passwall_packages/shadowsocksr-libev/check FIXUP=1 V=s
# -------------------------end-shadowsocksr-libev----------------------------------

# ==================== 修改默认LAN口IP为192.168.89.2 ====================
echo "正在修改默认LAN口IP为192.168.89.2"

# 方法1：修改config_generate脚本中的默认IP（核心，影响编译时生成的初始配置）
if [ -f "package/base-files/files/bin/config_generate" ]; then
    # 替换config_generate中所有192.168.1.1为192.168.89.2
    sed -i 's/192\.168\.1\.1/192.168.89.2/g' package/base-files/files/bin/config_generate
    echo ">> 已修改 config_generate 中的默认IP"
else
    echo ">> 警告: config_generate 文件不存在"
fi

# 方法2：修改默认网络配置文件（作为编译时的备选）
if [ -f "package/base-files/files/etc/config/network" ]; then
    sed -i "s/option ipaddr '192\.168\.1\.1'/option ipaddr '192\.168\.89\.2'/g" package/base-files/files/etc/config/network
    sed -i 's/option ipaddr "192\.168\.1\.1"/option ipaddr "192\.168\.89\.2"/g' package/base-files/files/etc/config/network
    sed -i "s/option ipaddr=192\.168\.1\.1/option ipaddr=192\.168\.89\.2/g" package/base-files/files/etc/config/network
    echo ">> 已修改 network 配置文件"
else
    echo ">> 警告: network 配置文件不存在"
fi

# 方法3：创建uci-defaults脚本（首次启动时自动执行，双重保险确保IP生效）
mkdir -p files/etc/uci-defaults/
cat > files/etc/uci-defaults/99-set-lan-ip << 'UCI_EOF'
#!/bin/sh
# 修改LAN口IP地址
uci set network.lan.ipaddr='192.168.89.2'
uci set network.lan.netmask='255.255.255.0'
uci commit network
# 重启网络服务使配置生效
/etc/init.d/network restart 2>/dev/null
echo "LAN口IP已设置为192.168.89.2"
UCI_EOF
chmod +x files/etc/uci-defaults/99-set-lan-ip
echo ">> 已创建 uci-defaults 首次启动脚本"

# 方法4：同时修改预初始化IP（确保早期启动阶段也使用正确IP）
if [ -f "package/base-files/files/bin/preinit" ]; then
    sed -i 's/192\.168\.1\.1/192.168.89.2/g' package/base-files/files/bin/preinit
    echo ">> 已修改 preinit 中的IP配置"
fi

echo "默认LAN口IP修改完成: 192.168.89.2"
# ==================== 修改完成 ====================

echo "修正完成"


echo "DiY script part 3: is Completed"

# set -e
# if [ $attempts -eq 3 ]; then
#   make -j$(nproc) V=s \
#     package/feeds/passwall/luci-app-passwall/compile \
#     package/feeds/passwall2/luci-app-passwall2/compile \
#     package/feeds/helloworld/luci-app-ssr-plus/compile \
#     package/feeds/OpenClash/luci-app-openclash/compile \
#     package/feeds/nikki/luci-app-nikki/compile \
#     package/custom_packages/luci-app-alpha-config/compile \
#     package/custom_packages/luci-app-argon-config/compile \
#     package/custom_packages/luci-app-bandix/luci-app-bandix/compile \
#     package/custom_packages/openwrt-bandix/openwrt-bandix/compile \
#     package/custom_packages/luci-app-kucat-config/compile \
#     package/custom_packages/luci-theme-alpha/compile \
#     package/custom_packages/luci-theme-alpha-reborn/compile \
#     package/custom_packages/luci-theme-argon/compile \
#     package/custom_packages/luci-theme-aurora/compile \
#     package/custom_packages/luci-theme-kucat/compile \
#     package/custom_packages/luci-theme-material3/compile \
#     package/custom_packages/mosdns/luci-app-mosdns/compile \
#     package/custom_packages/netspeedtest/luci-app-netspeedtest/compile
    
# else
#   make -j$(nproc) \
#     package/feeds/passwall/luci-app-passwall/compile \
#     package/feeds/passwall2/luci-app-passwall2/compile \
#     package/feeds/helloworld/luci-app-ssr-plus/compile \
#     package/feeds/OpenClash/luci-app-openclash/compile \
#     package/feeds/nikki/luci-app-nikki/compile \
#     package/custom_packages/luci-app-alpha-config/compile \
#     package/custom_packages/luci-app-argon-config/compile \
#     package/custom_packages/luci-app-bandix/luci-app-bandix/compile \
#     package/custom_packages/openwrt-bandix/openwrt-bandix/compile \
#     package/custom_packages/luci-app-kucat-config/compile \
#     package/custom_packages/luci-theme-alpha/compile \
#     package/custom_packages/luci-theme-alpha-reborn/compile \
#     package/custom_packages/luci-theme-argon/compile \
#     package/custom_packages/luci-theme-aurora/compile \
#     package/custom_packages/luci-theme-kucat/compile \
#     package/custom_packages/luci-theme-material3/compile \
#     package/custom_packages/mosdns/luci-app-mosdns/compile \
#     package/custom_packages/netspeedtest/luci-app-netspeedtest/compile
# fi

# echo "DiY script part 3: is Disabled"
