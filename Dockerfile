FROM debian:trixie-slim AS build

ENV RCON_PASSWD="REPLACE_ME"
ENV MAX_PLAYER="16"

EXPOSE 27015/tcp
EXPOSE 27015/udp

RUN apt update && apt install -y git build-essential cmake python3 wget libdbus-1-3 libsdl3-0

RUN mkdir -p /box64 && cd /box64 && \
	git clone https://github.com/ptitSeb/box64 --depth 1 --branch v0.3.8 --single-branch . && \
    mkdir build && cd build && \
    cmake .. -D ARM_DYNAREC=ON -D CMAKE_BUILD_TYPE=RelWithDebInfo -D BOX32=ON -D BOX32_BINFMT=ON && \
    make -j$(nproc) && make install && \
    cd / && rm -r /box64 && \
    ctest

ENV BOX64_DYNAREC_CALLRET=1
ENV BOX64_DYNAREC_SAFEMMAP=1
ENV BOX64_DYNAREC_FASTROUND=0
ENV BOX64_DYNAREC_FASTNAN=0
ENV BOX64_DYNAREC_LOG=0
ENV BOX64_DYNACACHE=1
ENV BOX64_LOG=0

WORKDIR /steamcmd

RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
	tar -xvzf steamcmd_linux.tar.gz

WORKDIR /server

RUN mkdir -p /root/.steam/sdk64 && \
	ln -s /steamcmd/linux64/steamclient.so /root/.steam/sdk64/

CMD bash /steamcmd/steamcmd.sh +login anonymous +app_update 730 validate +quit && \
	cd /root/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/game/bin/linuxsteamrt64 && \
	BOX64_ADDLIBS=libv8_libcpp.so:libtier0.so:/steamcmd/linux64/steamclient.so \
	./cs2 -dedicated -usercon -maxplayers_override ${MAX_PLAYER} +bot_quota 0 +game_type 0 +game_mode 1 +map de_mirage +rcon_password ${RCON_PASSWD}
