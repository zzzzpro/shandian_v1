#!/bin/bash

CLIENT_DIR="/usr/local/shandian_status"
CLIENT_EXEC_NAME="client"
SERVICE_NAME="shandian_status.service"
BASE_URL="https://github.com/zzzzpro/shandian_v1/releases"

VERSION_TAG="latest"

TEMP_DIR="/tmp/shandian_update_$$"

error_exit() {
    echo "错误: $1" >&2
    if [ -d "${TEMP_DIR}" ]; then
        rm -rf "${TEMP_DIR}"
    fi
    exit 1
}

cleanup() {
    if [ -d "${TEMP_DIR}" ]; then
        rm -rf "${TEMP_DIR}"
    fi
}
trap cleanup EXIT

echo "Shandian V1 客户端更新程序 (版本: ${VERSION_TAG})"

if [ "$(id -u)" -ne 0 ]; then
    error_exit "此脚本必须以root用户权限运行。"
fi

CLIENT_ARCH=""
ARCH=$(uname -m)
case ${ARCH} in
    x86_64) CLIENT_ARCH="amd64" ;;
    amd64) CLIENT_ARCH="amd64" ;;
    aarch64) CLIENT_ARCH="arm64" ;;
    arm64) CLIENT_ARCH="arm64" ;;
    *)
        error_exit "不支持的系统架构: ${ARCH}"
        ;;
esac

CLIENT_FILE_NAME="shandian_status-${CLIENT_ARCH}.tar.gz"
DOWNLOAD_URL="${BASE_URL}/download/${VERSION_TAG}/${CLIENT_FILE_NAME}"
if [ "${VERSION_TAG}" == "latest" ]; then
    DOWNLOAD_URL="${BASE_URL}/latest/download/${CLIENT_FILE_NAME}"
fi

echo "架构: ${CLIENT_ARCH}, 下载: ${DOWNLOAD_URL}"

echo "正在停止 ${SERVICE_NAME} 服务..."
if systemctl is-active --quiet ${SERVICE_NAME}; then
    systemctl stop ${SERVICE_NAME} || error_exit "停止 ${SERVICE_NAME} 服务失败。"
fi

mkdir -p "${TEMP_DIR}" || error_exit "创建临时目录 ${TEMP_DIR} 失败。"
cd "${TEMP_DIR}" || error_exit "无法进入临时目录 ${TEMP_DIR}。"

echo "正在下载客户端..."
if command -v curl > /dev/null; then
    curl -Ls -o "${CLIENT_FILE_NAME}" "${DOWNLOAD_URL}"
elif command -v wget > /dev/null; then
    wget -q -O "${CLIENT_FILE_NAME}" "${DOWNLOAD_URL}"
else
    error_exit "未找到 curl 或 wget，无法下载文件。"
fi

if [ $? -ne 0 ] || [ ! -f "${CLIENT_FILE_NAME}" ]; then
    error_exit "下载客户端 ${CLIENT_FILE_NAME} 失败。请检查版本标签 '${VERSION_TAG}' 是否存在以及文件是否可用。"
fi

echo "正在解压和替换客户端..."
tar -xzf "${CLIENT_FILE_NAME}" || error_exit "解压 ${CLIENT_FILE_NAME} 失败。"

EXTRACTED_BINARY_PATH="shandian_status/client"
if [ ! -f "${EXTRACTED_BINARY_PATH}" ]; then
    error_exit "解压后未在预期的路径 '${EXTRACTED_BINARY_PATH}' 找到客户端文件。"
fi

TARGET_CLIENT_FILE="${CLIENT_DIR}/${CLIENT_EXEC_NAME}"
if [ ! -d "${CLIENT_DIR}" ]; then
    error_exit "安装目录 ${CLIENT_DIR} 不存在。请先确保客户端已正确安装。"
fi

mv "${EXTRACTED_BINARY_PATH}" "${TARGET_CLIENT_FILE}" || error_exit "替换客户端文件 ${TARGET_CLIENT_FILE} 失败。"
chmod +x "${TARGET_CLIENT_FILE}" || error_exit "为 ${TARGET_CLIENT_FILE} 设置执行权限失败。"

echo "正在启动 ${SERVICE_NAME} 服务..."
systemctl daemon-reload
systemctl start ${SERVICE_NAME} || error_exit "启动 ${SERVICE_NAME} 服务失败。请使用 'systemctl status ${SERVICE_NAME}' 和 'journalctl -u ${SERVICE_NAME} -n 50' 查看详情。"

sleep 1
if systemctl is-active --quiet ${SERVICE_NAME}; then
    echo "客户端更新成功 (版本: ${VERSION_TAG})，服务正在运行。"
else
    error_exit "${SERVICE_NAME} 服务未能成功启动。请检查日志。"
fi

exit 0
