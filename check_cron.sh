#!/bin/bash

USER=$(whoami)
WORKDIR="/home/${USER}/.nezha-agent"
FILE_PATH="/home/${USER}/.s5"
XRAYR_PATH="/usr/home/${USER}/XrayR-freebsd-64"
XRAYR_CONFIG="${XRAYR_PATH}/config.yml"

CRON_S5="nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
CRON_NEZHA="nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &"
CRON_XRAYR="pgrep -x \"XrayR\" > /dev/null || nohup ${XRAYR_PATH}/XrayR --config ${XRAYR_CONFIG} >/dev/null 2>&1 &"

REBOOT_COMMAND="@reboot pkill -kill -u $(whoami) && $PM2_PATH resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"
REBOOT_XRAYR="nohup ${XRAYR_PATH}/XrayR --config ${XRAYR_CONFIG} >/dev/null 2>&1 &"

echo "检查并添加 crontab 任务"

if [ "$(command -v pm2)" == "/home/${USER}/.npm-global/bin/pm2" ]; then
  echo "已安装 pm2，并返回正确路径，启用 pm2 保活任务"
  (crontab -l | grep -F "$REBOOT_COMMAND") || (crontab -l; echo "$REBOOT_COMMAND") | crontab -
  (crontab -l | grep -F "$CRON_JOB") || (crontab -l; echo "$CRON_JOB") | crontab -
else
  if [ -e "${WORKDIR}/start.sh" ] && [ -e "${FILE_PATH}/config.json" ]; then
    echo "添加 nezha & socks5 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_S5} && ${CRON_NEZHA}") || \
    (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_S5} && ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || \
    (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || \
    (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
  elif [ -e "${WORKDIR}/start.sh" ]; then
    echo "添加 nezha 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_NEZHA}") || \
    (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || \
    (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
  elif [ -e "${FILE_PATH}/config.json" ]; then
    echo "添加 socks5 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") || \
    (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || \
    (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
  fi
fi

# 检查并添加 XrayR 的 crontab 任务
echo "检查并添加 XrayR 的 crontab 任务"
if [ -x "${XRAYR_PATH}/XrayR" ] && [ -f "${XRAYR_CONFIG}" ]; then
  echo "XrayR 文件和配置文件均存在，添加相关 crontab 任务"

  # 添加系统重启时启动任务
  (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${REBOOT_XRAYR}") || \
  (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${REBOOT_XRAYR}") | crontab -

  # 添加定时检查任务（每 12 分钟）
  (crontab -l | grep -F "*/12 * * * * ${CRON_XRAYR}") || \
  (crontab -l; echo "*/12 * * * * ${CRON_XRAYR}") | crontab -
else
  echo "XrayR 或配置文件不存在，跳过添加任务"
fi
