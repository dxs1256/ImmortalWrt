#!/bin/bash
# 将 Imagebuilder 默认 repositories 切换到 Cernet 教育网镜像源，避免下载失败
OFFICIAL="https://downloads.immortalwrt.org"
MIRROR="https://mirrors.cernet.edu.cn/immortalwrt"
echo ">>> switching to mirror source"
BASE_URL="$MIRROR"
echo "Using BASE_URL = $BASE_URL"
echo "========================================"
echo "Updating repositories"
echo "========================================"
# 24.10 opkg 使用 repositories.conf，25.12 apk 使用 repositories
REPO_CONF=""
if [ -f "/home/build/immortalwrt/repositories.conf" ]; then
  REPO_CONF="/home/build/immortalwrt/repositories.conf"
elif [ -f "repositories.conf" ]; then
  REPO_CONF="repositories.conf"
elif [ -f "/home/build/immortalwrt/repositories" ]; then
  REPO_CONF="/home/build/immortalwrt/repositories"
elif [ -f "repositories" ]; then
  REPO_CONF="repositories"
fi
if [ -n "$REPO_CONF" ] && [ -f "$REPO_CONF" ]; then
  sed -i "s#${OFFICIAL}#${BASE_URL}#g" "$REPO_CONF"
  cat "$REPO_CONF"
else
  echo "未找到 repositories.conf / repositories 文件，跳过镜像源切换"
fi
