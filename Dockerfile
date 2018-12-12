FROM autonomy/toolchain:f3c960a
WORKDIR /toolchain/usr/local/src/kernel
RUN tar --strip-components=1 -xvJf /toolchain/usr/local/src/linux.tar.xz
ADD https://raw.githubusercontent.com/opencontainers/runc/v1.0.0-rc5/script/check-config.sh /bin/check-config.sh
RUN chmod +x /bin/check-config.sh
RUN make mrproper
COPY config .config
RUN mkdir -p /usr/bin \
    && ln -s /toolchain/bin/env /usr/bin/env \
    && ln -s /toolchain/bin/true /bin/true \
    && ln -s /toolchain/bin/pwd /bin/pwd
RUN check-config.sh .config
RUN make -j $(($(nproc) / 2))
RUN cp arch/x86/boot/bzImage /tmp/vmlinuz

FROM scratch
COPY --from=0 /tmp/vmlinuz /vmlinuz
