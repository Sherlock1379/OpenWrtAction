# DS 部署说明（基于 2026-11-27 上游源码重建）

本目录 DS/ 只包含**需要改动**的 9 个文件，按 fork 仓库的相对路径放置。
上游原件 OpenWrt/OpenWrtAction-main 未做任何改动；部署时把这 9 个文件覆盖到你的 fork 仓库同路径即可。

- 重建脚本：OpenWrt/tools/x3_build.py（从 OpenWrtAction-main 读源码，改写后写入 DS）
- 校验脚本：OpenWrt/tools/x11_verify.py（关键词残留 / workflow 结构 / 目标表比对）、OpenWrt/tools/x12_keep.py（保留清单逐项）
- 上一批产物已归档：OpenWrt/BAK/2026-11-22（10 个文件，与归档前 DS 逐字节一致）
- 本批工作日期：2026-11-27

## 1. 文件清单与 SHA-256（部署后可用 x10_verify_repo.ps1 比对）

| 文件 | 字节 | SHA-256 |
| --- | --- | --- |
| .github/workflows/Build_Multi_Platform(V6).yml | 30207 | 63e84a6e16c5282a4346ed4b67e71dbf8431f0d96e9cfaf1a7241d4423ea992a |
| .github/workflows/Cache_Multi_Platform(V6).yml | 18042 | 0ca73f3ee2c741f7fcdc779a4933d5d8ebc654ef9d095e47f2e3c28e333ac221 |
| compile_script/platforms.sh | 1968 | 7a8b10fd914f5b7eb7ec458a4730fef24053277232d1d927fb9fa2442cf0959f |
| platform_function.sh | 47805 | 29048b58b244f7d3b2e9f89022080850987c27bce3c6a183c199b6598bbca88f |
| diy_script/custom_feeds_and_packages.sh | 4731 | 889c2ed710bae978274ad6e86c3a7a1c9315831d34be427ed62f4de16814d3b7 |
| diy_script/openwrt_diy/diy-part2.sh | 7047 | 28c7c19a59bb260fae97d83512027389e09ae559c6725872dde19925c9cfc527 |
| diy_script/immortalwrt_diy/diy-part2.sh | 6647 | 83fbb9cff2c46ebc1423e5906c5e2822815424fed893349a482cd03fd2014814 |
| config/openwrt_config/X86.config | 350203 | bd862128f3e096d161cceb81d211721a26c03a0d2095e331f28c865aed1e0ee1 |
| config/immortalwrt_config/X86.config | 366385 | 02131d6a814c0ed5bdd2fb7a474fcff551aa62f327953b30e23f41ec5b037d50 |

## 2. 每个文件改了什么

### .github/workflows/Build_Multi_Platform(V6).yml（825 → 793 行，+3 / -36）
- 编译机依赖清单下载地址：`smallprogram/OpenWrtAction` → `${{ github.repository }}`（:381）。
- ghcr 缓存镜像名 ×2（:474 拉取、:636 推送）：`ghcr.io/smallprogram/...` → `ghcr.io/${REPO_OWNER}/openwrt-base-cache-$PLATFORM_NAME:latest`，`REPO_OWNER` 已由脚本 `tr '[:upper:]' '[:lower:]'` 归一化。
- 删除 compile 步骤里的 rustdesk 段（原 :667-671，`chmod/source DIY_P4_SH` + `install_rustdesk_server`）。
- 删除整个 `final-execution-jobs`（原 :795-824），含 `peter-evans/repository-dispatch@v4` 与 `secrets.MY_SECRET_PAT`。

### .github/workflows/Cache_Multi_Platform(V6).yml（472 → 473 行，+3 / -3）
- 同样的依赖 URL 替换（:192）与 ghcr 镜像名 ×2（:285、:443）。

### compile_script/platforms.sh（69 → 58 行，+4 / -15）
- `source_code_platforms=(openwrt immortalwrt)`：删掉 lede 源与 lede_value。
- `openwrt_platforms=(X86)`、`immortalwrt_platforms=(X86)`：矩阵从 36 个编译任务降到 2 个（+2 个 source_init）。
- openwrt_value 删除 `DIY_P4_SH` 键。

### platform_function.sh（+0 / -6）
- 删除 make defconfig 之后按平台执行 diy-part4.sh 并调用 install_rustdesk_server 的整段。

### diy_script/custom_feeds_and_packages.sh（+1 / -10）
- 扩展 feed 只留 `passwall_packages`、`passwall`、`nikki`；删除 passwall2、helloworld、ghfu、accesspolicycontroller 四个 feed。
- 自定义包 clone 保留主题包与 diskman/ramfree/vlmcsd/smartdns 相关；注释掉 mosdns(v5)、netspeedtest、bandix、bandix-plus 的 clone（对应插件本次不保留）。

### diy_script/openwrt_diy/diy-part2.sh（+19 / -10）
- 注入列表精简为：net/vlmcsd；luci-app-diskman、luci-app-ramfree、luci-app-vlmcsd、**luci-app-arpbind**、**luci-app-cifs-mount**（openwrt 源本身没有最后两个，必须靠注入）。
- 默认 IP：`sed 's/192.168.1.1/192.168.89.2/g' package/base-files/files/bin/config_generate`（上游此行原本改的是 10.10.0.253）。
- 删除 rustdesk-server 的 uci-defaults 清理行。
- 新增 `files/etc/uci-defaults/99-set-lan-ip`：`uci set network.lan.ipaddr=192.168.89.2` + netmask 255.255.255.0 + commit，exit 0，不重启网络。

### diy_script/immortalwrt_diy/diy-part2.sh（+16 / -1）
- 默认 IP 同上（:99），同样新增 99-set-lan-ip。

### config/openwrt_config/X86.config（+111 / -103）
- 关闭 26 个应用族共 102 个 =y 符号（含全部 INCLUDE_* 与 i18n）：passwall2、ssr-plus、homeproxy、mosdns、adguardhome、openvpn、ddns-go、cloudflared、zerotier、tailscale-community、udpxy、udp2raw 缺项、nmap-full、accesspolicycontroller、ghfu、hd-idle、keepalived、uhttpd(LuCI 前端，保留 uhttpd 本体)、netspeedtest、wol、wechatpush、bandix(+plus)、eqos、statistics(+collectd 全家)、vnstat2、rustdesk-server。
- 强制开启 7 项：nikki、luci-app-nikki、luci-i18n-nikki-zh-cn、luci-app-arpbind、luci-i18n-arpbind-zh-cn、luci-app-cifs-mount、luci-i18n-cifs-mount-zh-cn（openclash 上游本就 =y，保持）。
- `CONFIG_TARGET_PREINIT_IP="192.168.89.2"`。
- 结果：CONFIG_PACKAGE_*.=y 从 776 → 681（全 CONFIG_=y 从 1404 → 1309）。

### config/immortalwrt_config/X86.config（+114 / -110）
- 关闭 109 个 =y 符号，集合同上，另加 luci-app-rclone 的两个 INCLUDE、luci-app-zerotier。
- 强制开启 nikki 3 项；`CONFIG_TARGET_PREINIT_IP="192.168.89.2"`。
- 结果：CONFIG_PACKAGE_*.=y 从 808 → 702（全 CONFIG_=y 从 1471 → 1365）。

## 3. 本次保留的插件（用户清单）

- 代理/网络：**passwall**（含 16 个 luci-app-passwall_INCLUDE_* 全部 =y）、**smartdns**、**upnp**、**openclash**、**nikki**。
- 系统/工具：commands、ramfree、diskman、cifs-mount、package-manager、ttyd、vlmcsd、firewall、acme、arpbind、banip、openssh-server、openssh-sftp-server。
- 主题/界面：UI Themes and Interfaces 全保留 —— 7dollar、argon(+argon-config)、ctmodem、kucat(+kucat-config)、aurora、material3、Arwi、alpha(+alpha-config)、bootstrap、footstrap、material、openwrt、openwrt-2020、vantage app/theme、**vantage-aps**、**vantage-traffic**（后两个是上游 2026-11-26 新增，本次一并保留并在插件目标.txt 第 68-69 行）。
- 校验结果：x12_keep.py 两份 config 均 `keep/themes missing_or_off=0`。

## 4. 有意保留、可能被问到的几项

- `openssh-server` / `openssh-sftp-server`：保留。diy-part2 里的 `99-custom-ssh-config` 会给 OpenSSH 写 sshd_config 并在 22 端口起服务，删了这段会报错；不想用可在 SSH 配置生成段落里一并去掉。
- `ruby` 及其 8 个模块：保留（OpenClash 的部分脚本依赖 ruby，关闭后个别功能会异常）。
- `uhttpd`、`uhttpd-mod-ubus`：保留（LuCI 的 Web 服务本体，只关了 LuCI 页面 `luci-app-uhttpd`）。
- `kmod-wireguard` / `wireguard-tools`：保留，只关了 LuCI 前端 `luci-proto-wireguard`。
- `timeout 25m make download -j8`：未改动（改小时可能让部分包下载失败，故障会推迟到编译阶段才暴露）。

## 5. 部署步骤

1. 把这 9 个文件按相同相对路径覆盖到你的 fork 仓库（**两个 .github/workflows/*.yml 必须一起换**，只换 platforms.sh 会重现 `source: ... is a directory` 与 ghcr permission_denied 两个报错）。
2. 提交并推送（建议单独一个 commit，方便回滚）。
3. 手动触发 Build_Multi_Platform(V6)：预期矩阵只有 openwrt-X86、immortalwrt-X86 两个编译任务 + 两个 source_init。
4. 首次运行会在 `ghcr.io/sherlock1379` 下新建 `openwrt-base-cache-openwrt-x86`、`openwrt-base-cache-immortalwrt-x86` 两个包，需要 packages:write 权限。
5. 部署后自检（只读）：`powershell -NoProfile -File tools/x10_verify_repo.ps1 -Repo <你的本地 fork 路径>`，应报 9/9 MATCH、关键词 0 命中。
6. 写入本地 fork（覆盖这 9 条路径，其它文件不动）：`powershell -NoProfile -File tools/x9_deploy.ps1 -Repo <你的本地 fork 路径>`，先加 `-WhatIf` 干跑。

## 6. 回滚

- 上一批产物：`OpenWrt/BAK/2026-11-22/`（10 个文件，含旧 DEPLOY.md），目录结构与 DS 一致。
- 仓库侧回滚：`git revert <本次 commit>`，或直接从上游拉回同名文件。
- 上游当前源码仍在 `OpenWrt/OpenWrtAction-main`，未被修改。

## 7. 已知风险

- 两个 X86.config 是从「上游最新 config + 批量关停」生成的，上游若继续新增默认开启的插件，下次更新时不会自动进入关停清单，需要在 tools/disable_*.json 里补条目。
- 26 个被关应用的 INCLUDE_*/i18n 已一并处理；若 defconfig 因依赖把它们重新打开，说明有保留包依赖它，需要看日志确认。
- 默认 LAN IP 由三处共同保证：config 的 `CONFIG_TARGET_PREINIT_IP`、config_generate 的 sed、首次启动的 99-set-lan-ip。三处一致改，避免只改一处导致刷机后仍是默认 IP。
