#!/bin/bash

CLIENT_DIR="/root/shandian_client"
CLIENT_EXEC_NAME="client"
SERVICE_NAME="shandian_client.service"
GITHUB_RELEASES_BASE_URL="https://github.com/zzzzpro/shandian_v1/releases"
TEMP_DOWNLOAD_DIR="/tmp/shandian_update_$$"

error_exit() {
    echo "错误: $1" >&2
    if [ -d "${TEMP_DOWNLOAD_DIR}" ]; then
        rm -rf "${TEMP_DOWNLOAD_DIR}"
    fi
    exit 1
}

cleanup() {
    if [ -d "${TEMP_DOWNLOAD_DIR}" ]; then
        rm -rf "${TEMP_DOWNLOAD_DIR}"
    fi
}
trap cleanup EXIT

echo "Shandian V1 客户端更新程序"

if [ "$(id -u)" -ne 0 ]; then
    error_exit "此脚本必须以root用户权限运行。"
fi

OS_NAME=""
CLIENT_ARCH_SUFFIX=""
OS_TYPE_DETECTED=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_DETECTED=$(uname -m)

case ${OS_TYPE_DETECTED} in
    linux) OS_NAME="linux" ;;
    darwin) OS_NAME="darwin" ;;
    *) error_exit "不支持的操作系统: ${OS_TYPE_DETECTED}" ;;
esac

case ${ARCH_DETECTED} in
    x86_64 | amd64) CLIENT_ARCH_SUFFIX="amd64" ;;
    aarch64 | arm64) CLIENT_ARCH_SUFFIX="arm64" ;;
    *) error_exit "不支持的系统架构: ${ARCH_DETECTED} on ${OS_NAME}" ;;
esac

if [ -z "${OS_NAME}" ] || [ -z "${CLIENT_ARCH_SUFFIX}" ]; then
    error_exit "未能确定操作系统或架构。"
fi

DOWNLOAD_FILE_NAME="client_${OS_NAME}_${CLIENT_ARCH_SUFFIX}.tar.gz"
DOWNLOAD_URL="${GITHUB_RELEASES_BASE_URL}/latest/download/${DOWNLOAD_FILE_NAME}"
echo "系统: ${OS_NAME}-${CLIENT_ARCH_SUFFIX}, 下载: ${DOWNLOAD_FILE_NAME}"

echo "正在停止 ${SERVICE_NAME} 服务..."
if systemctl is-active --quiet ${SERVICE_NAME}; then
    systemctl stop ${SERVICE_NAME} || error_exit "停止 ${SERVICE_NAME} 服务失败。"
fi

mkdir -p "${TEMP_DOWNLOAD_DIR}" || error_exit "创建临时目录 ${TEMP_DOWNLOAD_DIR} 失败。"
cd "${TEMP_DOWNLOAD_DIR}" || error_exit "无法进入临时目录 ${TEMP_DOWNLOAD_DIR}。"

echo "正在下载 ${DOWNLOAD_URL}..."
if command -v curl > /dev/null; then
    curl -L -s -o "${DOWNLOAD_FILE_NAME}" "${DOWNLOAD_URL}"
elif command -v wget > /dev/null; then
    wget -q -O "${DOWNLOAD_FILE_NAME}" "${DOWNLOAD_URL}"
else
    error_exit "未找到 curl 或 wget。"
fi
if [ $? -ne 0 ] || [ ! -f "${DOWNLOAD_FILE_NAME}" ]; then
    error_exit "下载 ${DOWNLOAD_FILE_NAME} 失败。"
fi

echo "正在解压和替换客户端..."
tar -xzf "${DOWNLOAD_FILE_NAME}" || error_exit "解压 ${DOWNLOAD_FILE_NAME} 失败。"

EXTRACTED_BINARY_PATH="shandian_status/client"
if [ ! -f "${EXTRACTED_BINARY_PATH}" ]; then
    error_exit "解压后未找到 ${EXTRACTED_BINARY_PATH}。"
fi

TARGET_CLIENT_FILE="${CLIENT_DIR}/${CLIENT_EXEC_NAME}"
if [ ! -d "${CLIENT_DIR}" ]; then
    error_exit "安装目录 ${CLIENT_DIR} 不存在。"
fi
mv "${EXTRACTED_BINARY_PATH}" "${TARGET_CLIENT_FILE}" || error_exit "替换客户端文件 ${TARGET_CLIENT_FILE} 失败。"
chmod +x "${TARGET_CLIENT_FILE}" || error_exit "为 ${TARGET_CLIENT_FILE} 设置执行权限失败。"

echo "正在启动 ${SERVICE_NAME} 服务..."
systemctl daemon-reload
systemctl start ${SERVICE_NAME} || error_exit "启动 ${SERVICE_NAME} 服务失败。请使用 'systemctl status ${SERVICE_NAME}' 和 'journalctl -u ${SERVICE_NAME} -n 50' 查看详情。"

sleep 1
if systemctl is-active --quiet ${SERVICE_NAME}; then
    echo "客户端更新成功，服务正在运行。"
else
    error_exit "${SERVICE_NAME} 服务未能成功启动。请检查日志。"
fi

exit 0
