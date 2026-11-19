#!/bin/bash
#
export DISAGG_SCRIPTS_DIR=$PWD
export MODEL_NAME=DeepSeek-V4-Pro
export MODEL_DIR=/shared_nfs/models/deepseek-ai
export SHARED_MOUNT=/shared_nfs
export LOG_ROOT=/shared_nfs/$USER/disagg_logs
export IMAGE=vllm/vllm-openai-rocm@sha256:f049ae6061c2fbc180f441146daceea2ba1b980149eb8e887998412bd227b04e
# TP8 1P1D unless overridden: `WIDE_EP_MODE=1 bash test.sh` runs 1P1D EP8, and
# `WIDE_EP_MODE=1 xP=2 yD=2 bash test.sh` runs 2P2D EP16.
export WIDE_EP_MODE=${WIDE_EP_MODE:-0}
export xP=${xP:-1}
export yD=${yD:-1}
export RUN_AFTER_HEALTH=accuracy
export ROUTER_TYPE=vllm-router
export CLUSTER_ENV_IN=/vllm-workspace/.buildkite/amd-disagg/cluster_crs.sh
export SKIP_IONIC_MOUNTS=1

WORKSPACE_DIR=/shared_nfs/$USER/qa-workspace
mkdir -p "$WORKSPACE_DIR"
JOB_SCRIPT=$(mktemp /tmp/run_xPyD_disagg-XXXXXX.slurm)
sed "s|/data/\$(id -un):/workspace|$WORKSPACE_DIR:/workspace|" run_xPyD_disagg.slurm > "$JOB_SCRIPT"

sbatch --account=amd-aifw-di --partition=amd-aig-sw-shared --qos=amd-aifw-di-qos \
       --nodes=$((xP + yD)) --ntasks-per-node=1 --gres=gpu:8 --exclusive --time=04:00:00 \
       --exclude=crsuse2-m2m-v3-093,crsuse2-m2m-v3-108 \
       --output=/shared_nfs/csrikris/disagg_logs/spur-%j.out --error=/shared_nfs/csrikris/disagg_logs/spur-%j.err \
       "$JOB_SCRIPT"
rm -f "$JOB_SCRIPT"
