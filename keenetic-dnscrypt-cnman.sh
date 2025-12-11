#!/bin/sh
set -e

BASE="/opt/etc"
CONF="$BASE/dnscrypt-proxy.toml"
RULES="$BASE/forwarding-rules.txt"
PROXY_DIR="$BASE/proxy-group"

echo "[1] 下载 CNMan 配置仓库..."
cd "$BASE"
rm -rf dnscrypt-proxy-config
git clone --depth=1 https://github.com/CNMan/dnscrypt-proxy-config.git

echo "[2] 安装主配置文件..."
cp dnscrypt-proxy-config/dnscrypt-proxy.toml "$CONF"

echo "[3] 生成精简版国内直连规则..."
# 提取域名部分，删除空行和注释，去重
awk '{print $1}' dnscrypt-proxy-config/dnscrypt-forwarding-rules.txt \
  | sed '/^#/d;/^$/d' \
  | sort -u > "$RULES"

echo "[4] 写入国内直连 DNS（114/223/119）..."
sed -i "s|^#*forwarding_resolvers =.*|forwarding_resolvers = ['114.114.114.114:53','223.5.5.5:53','119.29.29.29:53']|" "$CONF"
sed -i "s|^#*forwarding_rules =.*|forwarding_rules = 'forwarding-rules.txt'|" "$CONF"

echo "[5] 禁用 IPv6..."
sed -i "s|^#*ipv6_servers =.*|ipv6_servers = false|" "$CONF"
sed -i "s|^#*force_tcp =.*|force_tcp = false|" "$CONF"

echo "[6] 设置监听端口为 5300..."
sed -i "s|^listen_addresses =.*|listen_addresses = ['127.0.0.1:5300']|" "$CONF"

echo "[7] 安装 proxy-group..."
rm -rf "$PROXY_DIR"
cp -r dnscrypt-proxy-config/proxy-group "$PROXY_DIR"

echo "[8] 重启 dnscrypt-proxy..."
/opt/etc/init.d/S09dnscrypt-proxy restart

echo "[9] 设置 Keenetic DNS 指向 127.0.0.1:5300（需在 Web 或 RCI 完成）"
echo "=== Keenetic 完成 ==="
