FROM debian:bookworm-slim AS builder

# ビルド環境構築
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends -y \
    git \
    make \
    gcc \
    g++ \
    liblua5.2-dev \
    lua-zlib \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# EDCBのビルド
WORKDIR /tmp
RUN git clone -b work-plus-s-260904 --depth=1 \
    https://github.com/xtne6f/EDCB.git
WORKDIR /tmp/EDCB/Document/Unix
RUN make -j "$(nproc)" \
    && make install \
    && make extra -j "$(nproc)" \
    && make install_extra \
    && mkdir -p /var/local/edcb \
    && make setup_ini \
    && sed -i -e 's/^ALLOW_SETTING=.*/ALLOW_SETTING=true/' \
         /var/local/edcb/HttpPublic/legacy/util.lua \
    && rm /var/local/edcb/EpgTimerSrv.ini \
    && cat <<EOF > /var/local/edcb/EpgTimerSrv.ini
[SET]
EnableHttpSrv=2
HttpAccessControlList=+127.0.0.0/8,+10.0.0.0/8,+172.16.0.0/12,+192.168.0.0/16,+169.254.0.0/16,+100.64.0.0/10
CompatFlags=128
RecInfoFolderOnly=1
ApplyExtToRecInfoDel=0
AutoDel=0
BackPriority=1
FixedTunerPriority=1
RetryOtherTuners=0
SeparateFixedTuners=0
CommentAutoAdd=0
FixNoRecToServiceOnly=0
RecNamePlugIn=1
RecNamePlugInFile=RecName_Macro.so
NoChkYen=0
DelReserveMode=2
EnableTCPSrv=1
TCPIPv6=0
TCPPort=4510
TCPAccessControlList=+127.0.0.0/8,+10.0.0.0/8,+172.16.0.0/12,+192.168.0.0/16,+169.254.0.0/16,+100.64.0.0/10
TCPResponseTimeoutSec=120
EpgArchivePeriodHour=0
SaveNotifyLog=0
SaveDebugLog=0
TimeSync=0
AutoDelRecInfo=0
AutoDelRecInfoNum=100
RecInfo2Max=1000
RecInfo2DropChk=2
TSExt=.ts
PresetID=
WakeTime=5
RecEndMode=0
Reboot=0
StartMargin=5
EndMargin=2
RecAppWakeTime=2
RecMinWake=1
RecView=1
RecNW=0
PgInfoLog=1
DropLog=1
RecOverWrite=0
KeepDisk=1
Caption=1
Data=0
[BonDriver_LinuxMirakc.so]
Count=8
GetEpg=1
EPGCount=4
Priority=0
[REC_DEF]
SetName=デフォルト
RecMode=1
NoRecMode=1
Priority=2
TuijyuuFlag=1
ServiceMode=0
PittariFlag=0
BatFilePath=
SuspendMode=4
RebootFlag=0
UseMargineFlag=0
StartMargine=0
EndMargine=0
ContinueRec=0
PartialRec=0
TunerID=0
[REC_DEF_FOLDER]
Count=0
[REC_DEF_FOLDER_1SEG]
Count=0
[NO_SUSPEND]
NoFileStreaming=0
NoStandbyTime=10
EOF \
    && cat <<EOF > /var/local/edcb/Common.ini
[SET]
RecFolderPath0=/record
RecFolderNum=1
EOF \
    && cat <<EOF > /var/local/edcb/RecName_Macro.so.ini
[SET]
RecNameMacro=$SDYYYY$-$SDMM$-$SDDD$-$STHH$$STMM$-$ZtoH(ServiceName)$-$ZtoH(Title2)$.ts
EOF

# EDCB Material WebUIのインストール
WORKDIR /tmp
RUN git clone --depth=1 https://github.com/EMWUI/EDCB_Material_WebUI.git
WORKDIR /tmp/EDCB_Material_WebUI
RUN cp -r HttpPublic /var/local/edcb/ \
    && cp -r Setting /var/local/edcb/

# BonDriver_LinuxMirakcのビルド
WORKDIR /tmp
RUN git clone --depth=1 --recurse-submodules \
    https://github.com/matching/BonDriver_LinuxMirakc.git
WORKDIR /tmp/BonDriver_LinuxMirakc
RUN make -j "$(nproc)" \
    && cp BonDriver_LinuxMirakc.so /usr/local/lib/edcb/ \
    && cat <<EOF > /usr/local/lib/edcb/BonDriver_LinuxMirakc.so.ini
[GLOBAL]
SERVER_HOST="127.0.0.1"
SERVER_PORT=40772

SERVER_SOCKPATH="/var/run/mirakc.sock"

; "http" or "unix"
SERVER_TYPE="http"

; B25(1=enable)
DECODE_B25=0

; Priority(0=Low Priority)
PRIORITY=10

; Service Split(1=enable)
SERVICE_SPLIT=0
EOF

FROM debian:bookworm-slim AS runtime

# ランタイム依存関係のみインストール
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends -y \
    liblua5.2-dev \
    lua-zlib \
    ffmpeg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ビルドステージから必要なファイルをコピー
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/edcb/ /usr/local/lib/edcb/
COPY --from=builder /var/local/edcb/ /var/local/edcb/
RUN chmod 777 /var/local/edcb

# setup-ini.shとget-tuner-count.plをコピーして実行権限付与
COPY --chmod=755 ./setup-ini.sh /usr/local/bin/setup-ini.sh
COPY --chmod=755 ./get-tuner-count.pl /usr/local/bin/get-tuner-count.pl

# デバッグ用に移動しておく
WORKDIR /var/local/edcb

CMD [ "/usr/local/bin/EpgTimerSrv" ]
