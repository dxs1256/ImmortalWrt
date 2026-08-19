#!/bin/bash
# Log file for debugging
source shell/apk-custom-packages.sh
echo "第三方APK软件包: $CUSTOM_PACKAGES"
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
# yml 传入的路由器型号 PROFILE
echo "Building for profile: $PROFILE"
# yml 传入的固件大小 ROOTFS_PARTSIZE
echo "Building for ROOTFS_PARTSIZE: $ROOTFS_PARTSIZE"

echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入环境变量ENABLE_PPPOE等 写入配置文件 供99-custom.sh读取
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择 任何第三方软件包"
else
  # ============= 同步第三方插件库==============
  # 同步第三方软件仓库run/apk
  echo "🔄 正在同步第三方软件仓库 Cloning run file repo..."
  git clone --depth=1 https://github.com/wukongdaily/apk.git /tmp/store-apk-repo

  # 拷贝 run/arm64 下所有 run 文件和apk文件 到 extra-packages 目录
  mkdir -p /home/build/immortalwrt/extra-packages
  cp -r /tmp/store-apk-repo/run/arm64/* /home/build/immortalwrt/extra-packages/

  echo "✅ Run files copied to extra-packages:"
  # 解压并拷贝apk到packages目录
  sh shell/apk-prepare-packages.sh
  ls -lah /home/build/immortalwrt/packages/
  # 复制 shell/ 下的自定义 APK 到 packages/
  echo "📦 复制自定义 APK 到 packages/..."
  if [ -d /home/build/immortalwrt/shell/pushbot ]; then
    cp -v /home/build/immortalwrt/shell/pushbot/*.apk /home/build/immortalwrt/packages/ 2>/dev/null || true
  fi
  if [ -d /home/build/immortalwrt/shell/openlist2 ]; then
    cp -v /home/build/immortalwrt/shell/openlist2/*.apk /home/build/immortalwrt/packages/ 2>/dev/null || true
  fi
  if [ -d /home/build/immortalwrt/shell/accesscontrol ]; then
    cp -v /home/build/immortalwrt/shell/accesscontrol/*.apk /home/build/immortalwrt/packages/ 2>/dev/null || true
  fi
  echo "✅ packages 目录最终内容:"
  ls -lah /home/build/immortalwrt/packages/
fi

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."
echo "查看repositories信息——————"
cat repositories
# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-theme-argon"
# 判断是否需要编译 Docker 插件
# 注意：25.12 (apk) 构建必须同时加入 docker/dockerd 引擎本体，
# 否则勾选 docker 只会装 luci-app-dockerman 界面，固件里没有 docker 服务。
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES docker dockerd luci-i18n-dockerman-zh-cn"
    echo "Adding packages: docker dockerd luci-i18n-dockerman-zh-cn"
fi
# ======== shell/custom-packages.sh =======
# 合并imm仓库以外的第三方插件
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE=$PROFILE PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$ROOTFS_PARTSIZE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."

echo "===== 实际安装的软件包清单（来自 apk 真实安装记录） ====="
MANIFEST=$(find bin/targets -name "*.manifest" -type f 2>/dev/null | head -1)
if [ -n "$MANIFEST" ]; then
    echo "来源文件: $MANIFEST"
    cat "$MANIFEST"
else
    echo "未找到 .manifest 文件"
fi
