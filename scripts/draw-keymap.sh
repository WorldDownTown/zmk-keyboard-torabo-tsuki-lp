#!/bin/sh
# keymap.keymap からレイアウト画像 (SVG / PNG) を生成する。
#
#   ./scripts/draw-keymap.sh [出力ディレクトリ]
#
# 出力ディレクトリの既定は build/keymap。
# GitHub Actions の draw ジョブからも同じ手順で呼ぶ。
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT_DIR=${1:-"${REPO_ROOT}/build/keymap"}
KEYMAP="${REPO_ROOT}/config/keymap.keymap"
LAYOUTS="${REPO_ROOT}/boards/shields/torabo_tsuki_lp/torabo_tsuki_lp_layouts.dtsi"
CONFIG="${REPO_ROOT}/keymap_drawer.config.yaml"

# レイヤー名。keymap.keymap の layer_0..layer_4 と同じ順で並べる。
LAYER_NAMES="Base Mouse Num Sym BT"

# 物理レイアウトのノード名 (chosen の zmk,physical-layout と揃える)
PHYSICAL_LAYOUT=physical_layout_s

mkdir -p "${OUT_DIR}"

# keymap-drawer は compatible = "zmk,physical-layout" を持つノードだけを
# 物理レイアウトとして認識する。シールドの dtsi はこの行を upstream の
# physical_layouts.dtsi から継承しているためファイル単体では見つからない。
# 描画用の写しにだけ補う (元ファイルは変更しない)。
DTS_FOR_DRAW="${OUT_DIR}/layouts-for-draw.dtsi"
sed 's/^\(    physical_layout_[a-z]: physical_layout_[0-9] {\)$/\1\n        compatible = "zmk,physical-layout";/' \
  "${LAYOUTS}" >"${DTS_FOR_DRAW}"

# shellcheck disable=SC2086
keymap -c "${CONFIG}" parse -z "${KEYMAP}" -l ${LAYER_NAMES} >"${OUT_DIR}/keymap.yaml"

keymap -c "${CONFIG}" draw "${OUT_DIR}/keymap.yaml" \
  -d "${DTS_FOR_DRAW}" -l "${PHYSICAL_LAYOUT}" \
  -o "${OUT_DIR}/keymap.svg"

python3 - "${OUT_DIR}/keymap.svg" "${OUT_DIR}/keymap.png" <<'PY'
import sys

import resvg_py

svg_path, png_path = sys.argv[1], sys.argv[2]
with open(png_path, "wb") as f:
    f.write(bytes(resvg_py.svg_to_bytes(svg_path=svg_path)))
PY

echo "generated: ${OUT_DIR}/keymap.svg ${OUT_DIR}/keymap.png"
