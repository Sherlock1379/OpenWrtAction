# DS 部署说明（2026-11-22 版）

- 基线源码：`OpenWrt/OpenWrtAction-main`（上游 2026-11-21 更新后的版本）
- 改造副本：`OpenWrt/DS`（本目录，仅含需要改的 9 个文件，保留原相对路径）
- 上一批产物已归档：`OpenWrt/BAK/2026-11-16/`
- 原件未改动：`OpenWrt/OpenWrtAction-main` 与 `OpenWrt/QW` 保持原样

## 1. 覆盖清单（9 个文件 + 本说明）

| 文件 | 行数 | 字节 | SHA-256 |
|---|---|---|---|
| `.github/workflows/Build_Multi_Platform(V6).yml` | 792 | 30207 | `63e84a6e16c5282a4346ed4b67e71dbf8431f0d96e9cfaf1a7241d4423ea992a` |
| `.github/workflows/Cache_Multi_Platform(V6).yml` | 472 | 18042 | `0ca73f3ee2c741f7fcdc779a4933d5d8ebc654ef9d095e47f2e3c28e333ac221` |
| `compile_script/platforms.sh` | 57 | 1968 | `7a8b10fd914f5b7eb7ec458a4730fef24053277232d1d927fb9fa2442cf0959f` |
| `platform_function.sh` | 1028 | 47805 | `29048b58b244f7d3b2e9f89022080850987c27bce3c6a183c199b6598bbca88f` |
| `diy_script/custom_feeds_and_packages.sh` | 113 | 4731 | `889c2ed710bae978274ad6e86c3a7a1c9315831d34be427ed62f4de16814d3b7` |
| `diy_script/openwrt_diy/diy-part2.sh` | 201 | 7047 | `28c7c19a59bb260fae97d83512027389e09ae559c6725872dde19925c9cfc527` |
| `diy_script/immortalwrt_diy/diy-part2.sh` | 193 | 6647 | `83fbb9cff2c46ebc1423e5906c5e2822815424fed893349a482cd03fd2014814` |
| `config/openwrt_config/X86.config` | 9056 | 349858 | `6d203a3d6b1abe7da9f20bb327dbc37fcb7fe17d8e4ffae1cda302226c91b05e` |
| `config/immortalwrt_config/X86.config` | 9483 | 366570 | `09d9563b55647b954ac16be31e45f26469d37492be2903a1524aae78cf75bcd9` |

核对（在仓库根目录跑，9 行哈希应与上表一致）：

    sha256sum ".github/workflows/Build_Multi_Platform(V6).yml" ".github/workflows/Cache_Multi_Platform(V6).yml" \
      compile_script/platforms.sh platform_function.sh diy_script/custom_feeds_and_packages.sh \
      diy_script/openwrt_diy/diy-part2.sh diy_script/immortalwrt_diy/diy-part2.sh \
      config/openwrt_config/X86.config config/immortalwrt_config/X86.config

## 2. 相对上游改了什么（diff 行数）

| 文件 | +行 | -行 |
|---|---|---|
| Build_Multi_Platform(V6).yml | 3 | 36 |
| Cache_Multi_Platform(V6).yml | 3 | 3 |
| compile_script/platforms.sh | 4 | 15 |
| platform_function.sh | 0 | 6 |
| diy_script/custom_feeds_and_packages.sh | 1 | 10 |
| diy_script/openwrt_diy/diy-part2.sh | 18 | 9 |
| diy_script/immortalwrt_diy/diy-part2.sh | 16 | 1 |
| config/openwrt_config/X86.config | 111 | 103 |
| config/immortalwrt_config/X86.config | 114 | 110 |

1. **编译矩阵**：`platforms.sh` 只留 `openwrt`、`immortalwrt` 两个源，各只 `X86`（2 个编译任务 + 2 个 source_init）；lede 源与其 16 台机型全部移除；`DIY_P4_SH` 键删除。
2. **ghcr 命名空间用 fork 属主**：`IMAGE_NAME="ghcr.io/${REPO_OWNER}/openwrt-base-cache-$PLATFORM_NAME:latest"`，共 4 处（Build 474/636、Cache 288/446），`REPO_OWNER` 取自 `github.repository_owner` 并转小写。
3. **依赖清单 URL**：`https://github.com/smallprogram/OpenWrtAction/raw/main/diy_script/` → `https://github.com/${{ github.repository }}/raw/main/diy_script/`（Build、Cache 各 1 处）。
4. **rustdesk 全链路拔除**：Build 编译步骤里的 `if [[ ... == "openwrt" ]]; then ... install_rustdesk_server; fi` 块（5 行）、`platform_function.sh` 的 `install_rustdesk_server()`（6 行）、两个 `diy-part2.sh` 里的 `rm -rf feeds/luci/applications/luci-app-rustdesk-server/root/etc/uci-defaults`、两份 config 里的 `luci-app-rustdesk-server` / `rustdesk-server` / `luci-i18n-rustdesk-server-*`。
   > 顺带拔掉历史报错③的根因：`diy-part4.sh:63` 的 curl+grep 在 API 限流时返回空串，`grep` 退出码 1 在 `set -e` 下让整个 job 静默失败。
5. **删除末尾 `final-execution-jobs`**：含 `peter-evans/repository-dispatch@v4`（`token: secrets.MY_SECRET_PAT` + `repository: smallprogram/MyAction`），fork 无此 secret 必报 `Parameter token or opts.auth is required`；没有其它 job 依赖它。
6. **feeds**：删掉 `passwall2`、`helloworld`、`ghfu`、`accesspolicycontroller` 4 条扩展 feed；新增 `src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main`；删掉 6 个自定义包 clone（`luci-app-mosdns -b v5`、`netspeedtest`、`openwrt-bandix`、`luci-app-bandix`、`openwrt-bandix-plus`、`luci-app-bandix-plus`）。保留 `passwall_packages`、`passwall`、`OpenClash` 三个 feed 与全部主题 clone。
7. **默认 LAN IP 192.168.89.2**（两个源的 diy-part2 各 3 处）：
   - `sed -i 's/192.168.1.1/192.168.89.2/g' package/base-files/files/bin/config_generate`（改源码里的默认生成值）
   - 新增 `files/etc/uci-defaults/99-set-lan-ip`：`uci -q set network.lan.ipaddr='192.168.89.2'` + netmask + `uci -q commit network` + `exit 0`，并 `chmod +x`
   - 两份 config 的 `CONFIG_TARGET_PREINIT_IP="192.168.89.2"`（刷机后首次启动的兜底 IP，QW 那版漏了这项）
8. **插件精简**：`CONFIG_PACKAGE_*=y` 符号数 openwrt 1400 → 1305、immortalwrt 1467 → 1361（分别关掉 102 / 109 个已启用符号）。补充：
   - Nikki 三件套 `CONFIG_PACKAGE_nikki` / `luci-app-nikki` / `luci-i18n-nikki-zh-cn` **强制 =y**（新源码两份 config 里原本没有 nikki，只靠 feeds 装了不会编进去）
   - OpenClash 保持 =y（新源码本来开着，脚本里也做了兜底不关）
   - openwrt 源缺 `luci-app-arpbind`、`luci-app-cifs-mount`，因此在 openwrt 的 diy-part2 里补注入（从 immortalwrt luci feed 取），并在 openwrt config 里补 4 条 =y
   - `uhttpd` 与 `uhttpd-mod-ubus`（Web 服务本体）保留，只关 `luci-app-uhttpd` 及其 i18n
   - `openssh-server`、`openssh-sftp-server` 保留（`99-custom-ssh-config` 依赖 22 端口）

## 3. 保留清单（两份 config 均实测 =y）

- 代理/网络：`luci-app-passwall`（含 16 条 `INCLUDE_*`）、`luci-app-smartdns`、`luci-app-upnp`、`luci-app-openclash`、`luci-app-nikki`、`luci-app-firewall`、`luci-app-acme`、`luci-app-arpbind`、`luci-app-banip`
- 系统：`luci-app-commands`、`luci-app-ramfree`、`luci-app-diskman`、`luci-app-cifs-mount`、`luci-app-package-manager`、`luci-app-ttyd`、`luci-app-vlmcsd`
- 主题/界面 18 项：argon(+argon-config)、7dollar、carbon、kucat(+kucat-config)、aurora、material3、Arwi、alpha(+alpha-config)、bootstrap、footstrap、material、openwrt、openwrt-2020、vantage(app+theme)

关闭的应用族（INCLUDE_* 与 i18n 一起关，避免半残）：adguardhome、ddns-go、homeproxy、mosdns、passwall2、openvpn、ssr-plus、tailscale-community、udp2raw、udpxy、luci-proto-wireguard、cloudflared、zerotier、rustdesk-server、accesspolicycontroller、ghfu、hd-idle、keepalived、luci-app-uhttpd、netspeedtest、wol、wechatpush、bandix(+plus)、eqos、statistics、vnstat2；另关 collectd 全家、ruby 全家（主要是 immortalwrt 侧孤儿依赖）、nmap-full、ucode-mod-rtnl 等。

## 4. 验收结果（本轮实测）

- `bash -n`：5 个 shell 脚本全部通过
- 矩阵实跑：矩阵 2 条（openwrt/X86、immortalwrt/X86）、source_matrix 2 条，无 `DIY_P4_SH`
- 关键词残留（DS 全目录）：`ghcr.io/smallprogram` 0、`repository-dispatch` 0、`DIY_P4_SH` 0、`10.10.0.253` 0；`rustdesk` 只剩 `# CONFIG_... is not set` 行；`192.168.1.1` 只剩 sed 的模式行
- 结构：Build 6 个 job（job_init / job_source_init / job_generate_release_tag / job_compile_and_upload / job_organize_tags / rerun-failed-jobs，无 final-execution-jobs）、58 个 step；Cache 4 个 job、29 个 step
- 被移除 feed 的相关符号 =y 计数全为 0（passwall2、ssr-plus、ghfu、accesspolicycontroller、mosdns、bandix、netspeedtest）

## 5. 部署到你的 fork

本地 clone 的话，把这 9 个文件按同路径覆盖过去（除这 9 条路径外不要动上游文件）：

    # 在 fork 的 clone 根目录执行；DS_DIR 指向本目录
    DS_DIR=/path/to/OpenWrt/DS
    for p in ".github/workflows/Build_Multi_Platform(V6).yml" \
             ".github/workflows/Cache_Multi_Platform(V6).yml" \
             compile_script/platforms.sh platform_function.sh \
             diy_script/custom_feeds_and_packages.sh \
             diy_script/openwrt_diy/diy-part2.sh \
             diy_script/immortalwrt_diy/diy-part2.sh \
             config/openwrt_config/X86.config config/immortalwrt_config/X86.config; do
      mkdir -p "$(dirname "$p")"; cp "$DS_DIR/$p" "$p"
    done
    git add -A && git commit -m "chore: slim x86 builds for openwrt/immortalwrt" && git push

首次运行会在 `sherlock1379` 账号下自动新建两个包：`openwrt-base-cache-openwrt-X86`、`openwrt-base-cache-immortalwrt-X86`（默认 private）。第一次没有缓存可拉，编译会慢；跑完 `Cache_Multi_Platform(V6).yml` 再跑 Build 就能复用缓存。

## 6. 回滚

- 回到本批之前那一版：`OpenWrt/BAK/2026-11-16/` 里是同路径的 9 个文件 + 说明，拷回仓库即可。
- 回到上游原版：`git checkout -- <path>`，或 `git reset --hard origin/main`。

## 7. 已知事项 / 风险

- 精简是靠改 `.config` 关符号实现的，`make defconfig` 仍可能因依赖把个别包拉回来；首次构建看日志里 `WARNING: ... is not set, but selected` 一类提示即可。若被拉回，把该包补进 `tools/disable_*.json` 并重跑 `tools/x3_build.py`。
- `nikki` 依赖上游 `nikkinikki-org/OpenWrt-nikki` 的分支名 `main`；若上游改名，`feeds update` 会失败，备选是注释掉该 feed 并删掉两份 config 里的三行 nikki。
- `make download` 超时仍是上游的 `timeout 25m make download -j8`（Build:656），本轮未改。QW 那版改 12m 偏紧，缓存冷启动时容易在下载阶段超时，靠 `continue-on-error` 拖到编译阶段才暴露。
- 新源码里 `diy_script/openwrt_diy/diy-part4.sh` 仍然存在，但已无人调用（`DIY_P4_SH` 键与调度步都删了），属死文件，留着无害。
- 上一版（QW 参考）在 diy-part3 里再 sed `192.168.1.1` 是空操作：diy-part2 已把源码默认值改成 `10.10.0.253`，找不到目标。本版统一由 diy-part2 的 sed + `99-set-lan-ip` + `CONFIG_TARGET_PREINIT_IP` 三处承担。
