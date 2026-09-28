#!/bin/bash

# Bashの安全措置
# + 途中でエラーが発生したら即座に終了
# + 未定義変数はエラー
# + パイプの終了コードを伝播させる
set -euo pipefail

# PID 1の時、Bashはシグナルを受け取った場合にプロセス停止処理を行わない。
# 結果、コンテナの停止時に子プロセスが正常終了せず、10秒ほどして強制終了され落とされる。
# これは好ましいことではないため、PID 1の場合は自前のプロセス停止処理を行う。
# see https://note.shiftinc.jp/n/ndc63c45d9f97
#     https://qiita.com/ko1nksm/items/e8c2fbf58687e6979448
#     https://github.com/Chinachu/Mirakurun/blob/61c4155d2535c56fbf6fd379c5e8aba779fd642b/docker/container-init.sh
if [[ $$ == 1 ]]; then
  function trap_exit() {
    local pids
    pids="$(jobs -p)"
    echo
    if [[ "$pids" != '' ]]; then
      # shellcheck disable=SC2086
      echo '[i] Stopping pid:' ${pids}
      # shellcheck disable=SC2086
      kill $pids > /dev/null 2>&1 || echo '[i] Already killed.'
    fi
    echo '[i] exit.'
  }
  trap 'exit 0' 2 3 15
  trap trap_exit 0
fi

CHANNELS_FILEPATH='/mirakurun-config/channels.yml'
TUNERS_FILEPATH='/mirakurun-config/tuners.yml'
CHSET4_FILEPATH='/edcb-setting/BonDriver_LinuxMirakc(LinuxMirakc).ChSet4.txt'
CHSET5_FILEPATH='/edcb-setting/ChSet5.txt'
SCAN_RESULT_DIRPATH=./isdb-scanner-result
readonly CHANNELS_FILEPATH TUNERS_FILEPATH CHSET4_FILEPATH CHSET5_FILEPATH SCAN_RESULT_DIRPATH

##### 設定ファイルの存在チェック #####
# すでに設定ファイルが作成済みである場合は、以降の処理を行わずに終了する
if [[ -s "${CHANNELS_FILEPATH}" && -s "${TUNERS_FILEPATH}" && -s "${CHSET4_FILEPATH}" && -s "${CHSET5_FILEPATH}" ]]; then
  echo 'All configuration files have been created'
  exit 0
fi

##### ISDBScannerを実行 #####
# Note: コンテナ停止時にISDBScannerを正常終了させるため、バックグラウンド実行しつつwaitコマンドで実行終了まで待機させる。
#       どういう理屈なのか見当がつかないが、これがなければコンテナ停止時に10秒ほど経過した後ISDBScannerを強制終了されてしまう。
isdb-scanner "${SCAN_RESULT_DIRPATH}" &
wait

##### Mirakurun用の設定ファイルを作成 #####
cp "${SCAN_RESULT_DIRPATH}/Mirakurun/channels.yml" "${CHANNELS_FILEPATH}"
cp "${SCAN_RESULT_DIRPATH}/Mirakurun/tuners.yml"   "${TUNERS_FILEPATH}"

##### EDCB用の設定ファイルを作成 #####
cp "${SCAN_RESULT_DIRPATH}/EDCB-Wine/ChSet5.txt" "${CHSET5_FILEPATH}"
cp "${SCAN_RESULT_DIRPATH}/EDCB-Wine/BonDriver_mirakc(BonDriver_mirakc).ChSet4.txt" "${CHSET4_FILEPATH}"