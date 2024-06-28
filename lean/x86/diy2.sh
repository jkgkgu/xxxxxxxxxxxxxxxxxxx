#替换 golang 为 1.22.x 版本
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang

# 拉取仓库数据
git clone --depth=1 https://github.com/fw876/helloworld package/helloworld
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone https://github.com/MilesPoupart/luci-app-vssr package/luci-app-vssr
git clone https://github.com/jerrykuku/lua-maxminddb package/lua-maxminddb
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome

# 添加自定义软件包
echo '
CONFIG_PACKAGE_luci-app-webadmin=y                  #Web管理
CONFIG_PACKAGE_luci-app-ttyd=y                      #ttyd
CONFIG_PACKAGE_luci-app-diskman=y                   #磁盘管理
CONFIG_PACKAGE_luci-app-argon-config=y              #Argon主题设置
CONFIG_PACKAGE_luci-app-poweroff=y                  #关机
CONFIG_PACKAGE_luci-app-passwall=y                  #passwall
CONFIG_PACKAGE_luci-app-vssr=y                      #vssr
CONFIG_PACKAGE_luci-app-v2ray-server=y              #V2ray服务器
CONFIG_PACKAGE_luci-app-adbyby-plus=y               #广告屏蔽大师
CONFIG_PACKAGE_luci-app-adguardhome=y               #adguardhome
CONFIG_PACKAGE_ddns-scripts_cloudflare.com-v4=y     #动态DDNS
CONFIG_PACKAGE_luci-app-ddns-go=y                   #动态DDNS
CONFIG_PACKAGE_ddns-go=y                            #DDNS-GO	
CONFIG_PACKAGE_luci-app-socat=y                     #Socat
CONFIG_PACKAGE_luci-app-cpufreq=y                   #CPU 性能优化调节
' >> .config

# 修改 argon 为默认主题
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 更改 Argon 主题背景
cp -f $GITHUB_WORKSPACE/images/bg2.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
cp -f $GITHUB_WORKSPACE/images/firewall.config package/network/config/firewall/files/firewall.config
cp -f $GITHUB_WORKSPACE/images/dropbear.config package/network/services/dropbear/files/dropbear.config

# 修改欢迎 banner
cp -f $GITHUB_WORKSPACE/images/banner package/base-files/files/etc/banner

# 设置密码为空
sed -i '/CYXluq4wUazHjmCDBCqXF/d' package/lean/default-settings/files/zzz-default-settings

# 修改概览里时间显示为中文数字
sed -i 's/os.date()/os.date("%Y年%m月%d日") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")/g' package/lean/autocore/files/x86/index.htm

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} OpenWrt 定制版 X86/g" package/lean/default-settings/files/zzz-default-settings

echo 'zzz-default-settings自定义'
# 网络配置信息，将从 zzz-default-settings 文件的第2行开始添加 
# 参考 https://github.com/coolsnowwolf/lede/blob/master/package/lean/default-settings/files/zzz-default-settings
# 先替换掉最后一行 exit 0 再追加自定义内容
sed -i '/.*exit 0*/c\# 自定义配置' package/lean/default-settings/files/zzz-default-settings
cat >> package/lean/default-settings/files/zzz-default-settings <<-EOF

# 设置wan口的pppoe拨号
uci set network.wan.proto='pppoe'

uci set network.lan.ipaddr='192.168.9.254'                      # IPv4 地址(openwrt后台地址)
uci set network.lan.netmask='255.255.255.0'                     # IPv4 子网掩码
uci set network.lan.gateway='192.168.9.1'                       # IPv4 网关
uci set network.lan.broadcast='192.168.9.255'                   # IPv4 广播
uci set network.lan.dns='114.114.114.114'             # DNS(多个DNS要用空格分开)
uci delete network.lan.ip6assign                                # 接口→LAN→IPv6 分配长度——关闭，恢复uci set network.lan.ip6assign='64'
uci commit network

uci delete dhcp.lan.ra                                         # 路由通告服务，设置为“已禁用”
uci delete dhcp.lan.ra_management                              # 路由通告服务，设置为“已禁用”
uci delete dhcp.lan.dhcpv6                                     # DHCPv6 服务，设置为“已禁用”
uci set dhcp.lan.ignore='1'                                    # 关闭DHCP功能
uci commit dhcp

uci delete firewall.@defaults[0].syn_flood                     # 防火墙→SYN-flood 防御——关闭；默认开启
uci set firewall.@defaults[0].fullcone='2'                     # 防火墙→FullCone-NAT——启用；默认关闭
uci commit firewall

uci set dropbear.@dropbear[0].PasswordAuth='off'
uci set dropbear.@dropbear[0].RootPasswordAuth='off'
uci set dropbear.@dropbear[0].Port='8822'                      # SSH端口设置为'8822'
uci commit dropbear

uci set system.@system[0].hostname='OpenWrt-J4125'             # 修改主机名称为OpenWrt
uci commit system

uci set ttyd.@ttyd[0].command='/bin/login -f root'             # 设置ttyd免帐号登录
uci commit ttyd

uci set luci.main.mediaurlbase='/luci-static/bootstrap-dark'
uci commit luci


# 设置ddns-go为开启状态
uci set ddns-go.config.@basic[0].enabled=1
uci commit ddns-go

# 设置防火墙默认参数
uci set firewall.@defaults[0].input=ACCEPT
uci set firewall.@defaults[0].output=ACCEPT
uci set firewall.@defaults[0].forward=ACCEPT
uci commit firewall

# 设置lan口参数
uci set firewall.@zone[0].input=ACCEPT
uci set firewall.@zone[0].output=ACCEPT
uci set firewall.@zone[0].forward=ACCEPT
uci set firewall.@zone[0].masq='1'
uci set firewall.@zone[0].mtu_fix='1'
uci commit firewall

# 设置wan口参数
uci set firewall.@zone[1].input=ACCEPT
uci set firewall.@zone[1].output=ACCEPT
uci set firewall.@zone[1].forward=ACCEPT
uci set firewall.@zone[1].masq='1'
uci set firewall.@zone[1].mtu_fix='1'
uci commit firewall

# 设置网络诊断
uci set luci.diag.dns='www.baidu.com'
uci set luci.diag.ping='www.baidu.com'
uci set luci.diag.route='www.baidu.com'
uci commit luci

exit 0
EOF

sed -i '3s/0/1/g' package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config
sed -i '10s/1.1.1.1/8.8.8.8/g' package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config
sed -i '35s/60/10/g' package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config

echo "
config subscribe_list
	option remark '1'
	option url 'https://sub.pigfarmcloud.com/api/v1/client/subscribe?token=610cd9b909a88876dc2b205f69b9fdda'
 config subscribe_list
 	option remark '2'
	option url 'https://sub.pigfarmcloud.com/api/v1/client/subscribe?token=5ea4c7836a4750b1a992a46733310292'
" >> package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config

./scripts/feeds update -a
./scripts/feeds install -a
