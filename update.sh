#!/bin/bash

set -x

export CURDIR="$(cd "$(dirname $0)"; pwd)"

function update_geodata() {
	local type="$1"
	local repo="$2"
	local res="$3"
	local tag ver sha line

	tag="$(gh api "repos/$repo/releases/latest" | jq -r ".tag_name")"
	[ -n "$tag" ] || return 1

	ver="$(awk -F "${type}_VER:=" '{print $2}' "$CURDIR/Makefile" | xargs)"
	[ "$tag" != "$ver" ] || return 2

	sha="$(curl -fsSL "https://github.com/$repo/releases/download/$tag/$res" | awk '{print $1}')"
	[ -n "$sha" ] || return 1

	line="$(awk "/FILE:=\\$\(${type}_FILE\)/ {print NR}" "$CURDIR/Makefile")"
	sed -i -e "s/${type}_VER:=.*/${type}_VER:=$tag/" \
	       -e "$((line + 1))s/HASH:=.*/HASH:=$sha/" \
		"$CURDIR/Makefile"
}

# 记录更新结果
updated_count=0
error_count=0

# 更新 GEOIP
echo "Updating GEOIP..."
update_geodata "GEOIP" "Loyalsoldier/v2ray-rules-dat" "geoip.dat.sha256sum"
ret=$?
if [ $ret -eq 0 ]; then
	echo "GEOIP updated successfully"
	updated_count=$((updated_count + 1))
elif [ $ret -eq 2 ]; then
	echo "GEOIP is already up to date"
else
	echo "GEOIP update failed"
	error_count=$((error_count + 1))
fi

# 更新 GEOSITE
echo "Updating GEOSITE..."
update_geodata "GEOSITE" "Loyalsoldier/v2ray-rules-dat" "geosite.dat.sha256sum"
ret=$?
if [ $ret -eq 0 ]; then
	echo "GEOSITE updated successfully"
	updated_count=$((updated_count + 1))
elif [ $ret -eq 2 ]; then
	echo "GEOSITE is already up to date"
else
	echo "GEOSITE update failed"
	error_count=$((error_count + 1))
fi

# 更新 GEOSITE_IRAN
echo "Updating GEOSITE_IRAN..."
update_geodata "GEOSITE_IRAN" "bootmortis/iran-hosted-domains" "iran.dat.sha256"
ret=$?
if [ $ret -eq 0 ]; then
	echo "GEOSITE_IRAN updated successfully"
	updated_count=$((updated_count + 1))
elif [ $ret -eq 2 ]; then
	echo "GEOSITE_IRAN is already up to date"
else
	echo "GEOSITE_IRAN update failed"
	error_count=$((error_count + 1))
fi

# 输出总结
echo "=========================================="
echo "Update Summary:"
echo "  Updated: $updated_count"
echo "  Errors: $error_count"
echo "=========================================="

# 只有当所有更新都失败时才返回错误码
# 如果有任何一个成功更新，或者全部都是最新版本，都返回成功
if [ $updated_count -eq 0 ] && [ $error_count -gt 0 ]; then
	echo "All updates failed"
	exit 1
fi

# 有更新或全部已是最新版本，都返回成功
exit 0
