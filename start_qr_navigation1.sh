#!/usr/bin/env bash
set -eo pipefail
# 捕获退出信号，Ctrl+C同时杀掉二维码Python程序
trap 'echo "[EXIT] 关闭二维码扫码程序"; pkill -f "python3.*二维码.py" || true; exit 0' EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 二维码Python脚本固定路径
QR_PY_SCRIPT="/userdata/dev_ws/二维码.py"
# 方向标记文件路径
CLOCK_FILE="/userdata/dev_ws/clockwise.txt"
COUNTER_FILE="/userdata/dev_ws/counterclockwise.txt"

# 启动前清理历史方向文件
echo "[清理] 删除旧方向标记文件，等待到达首点后扫码识别方向"
rm -f "${CLOCK_FILE}" "${COUNTER_FILE}"

# 二维码Python脚本固定路径
QR_PY_SCRIPT="/userdata/dev_ws/二维码.py"

export START_CAMERA="${START_CAMERA:-1}"
# 一键启动 USB 相机、二维码识别、多点巡航。
export START_QR_DETECTOR="${START_QR_DETECTOR:-1}"
export START_MULTI_POINT="${START_MULTI_POINT:-1}"
export ENABLE_QR_SKIP_FIRST="${ENABLE_QR_SKIP_FIRST:-true}"
export QR_TOPIC="${QR_TOPIC:-/qr_info}"
export QR_IMAGE_TOPIC="${QR_IMAGE_TOPIC:-/image}"
export QR_SCAN_HZ="${QR_SCAN_HZ:-30.0}"
export QR_DETECTOR_ENGINE="${QR_DETECTOR_ENGINE:-opencv}"
export QR_RESIZE_WIDTH="${QR_RESIZE_WIDTH:-0}"
export QR_REPEAT_PUBLISH_INTERVAL="${QR_REPEAT_PUBLISH_INTERVAL:-5.0}"
# 通道速度参数：
# LINEAR_SPEED：通道外/普通路段线速度，单位 m/s；不在 CHANNEL_WAYPOINT_RANGES 范围内时使用。
# CHANNEL_LINEAR_SPEED：通道内线速度，单位 m/s；窄通道或大部分赛道速度主要改这里。
# CHANNEL_WAYPOINT_RANGES：哪些航点范围使用通道速度，按 1 开始计数，例如 2-17。
export LINEAR_SPEED="${LINEAR_SPEED:-0.80}"
export CHANNEL_LINEAR_SPEED="${CHANNEL_LINEAR_SPEED:-0.70}"
export CHANNEL_WAYPOINT_RANGES="${CHANNEL_WAYPOINT_RANGES:-2-15}"
# 避障启用航点：
# 0 表示从启动开始全程开启避障；设成 5 表示从第 5 个航点开始避障。
export OBSTACLE_ENABLE_FROM_WAYPOINT="${OBSTACLE_ENABLE_FROM_WAYPOINT:-0}"
# 前方避障参数：
# OBSTACLE_STOP_DISTANCE：急停距离，单位 m；前方障碍物小于该值时停车/触发倒车脱困。
# OBSTACLE_SLOW_DISTANCE：减速距离，单位 m；前方障碍物小于该值时开始降速。
# OBSTACLE_AVOID_DISTANCE：避让距离，单位 m；前方障碍物小于该值时向空旷一侧转向。
# FRONT_ANGLE_DEG：前方检测扇区半角，单位度；窄通道误判侧墙时可适当调小。
export OBSTACLE_STOP_DISTANCE="${OBSTACLE_STOP_DISTANCE:-0.30}"
export OBSTACLE_SLOW_DISTANCE="${OBSTACLE_SLOW_DISTANCE:-1.20}"
export OBSTACLE_AVOID_DISTANCE="${OBSTACLE_AVOID_DISTANCE:-0.70}"
export FRONT_ANGLE_DEG="${FRONT_ANGLE_DEG:-30.0}"
# 倒车脱困参数：
# BACKUP_TRIGGER_TIME：急停后等待多久开始倒车，单位 s；0.0 表示立刻倒车。
# BACKUP_DURATION：每次倒车持续时间，单位 s。
# BACKUP_SPEED：倒车速度，单位 m/s；数值不要太大，避免后退撞到后方物体。
# BACKUP_ANGULAR_Z：倒车时附带的转向角速度，单位 rad/s；帮助小车斜着退出来。
# BACKUP_STOP_DISTANCE：后方安全距离，单位 m；后方障碍物小于该值时禁止倒车。
export BACKUP_TRIGGER_TIME="${BACKUP_TRIGGER_TIME:-0.0}"
export BACKUP_DURATION="${BACKUP_DURATION:-0.80}"
export BACKUP_SPEED="${BACKUP_SPEED:-0.15}"
export BACKUP_ANGULAR_Z="${BACKUP_ANGULAR_Z:-0.0}"
export BACKUP_STOP_DISTANCE="${BACKUP_STOP_DISTANCE:-0.30}"

# 启动二维码识别
QR_PID=""
if [[ "${START_CAMERA}" == "1" ]]; then
    if [ -f "${QR_PY_SCRIPT}" ]; then
        echo "[QR启动] 启动二维码识别程序：${QR_PY_SCRIPT}"
        python3 "${QR_PY_SCRIPT}" &
        QR_PID=$!
        echo "[QR启动] 二维码进程PID：${QR_PID}"
        sleep 1
    else
        echo "[警告] 未找到二维码脚本 ${QR_PY_SCRIPT}，跳过扫码程序"
    fi
fi

# 直接进入导航脚本，等待小车跑完第一个点再扫码
exec bash "${SCRIPT_DIR}/start_navigation.sh"