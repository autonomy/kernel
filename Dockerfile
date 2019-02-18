ARG TOOLCHAIN_VERSION
FROM autonomy/toolchain:${TOOLCHAIN_VERSION} AS kernel-build
WORKDIR /src
RUN curl -L https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.10.tar.xz | tar --strip-components=1 -xvJ
ADD https://raw.githubusercontent.com/opencontainers/runc/v1.0.0-rc6/script/check-config.sh /bin/check-config.sh
RUN chmod +x /bin/check-config.sh
RUN make mrproper
COPY config .config
RUN mkdir -p /usr/bin \
    && ln -s /toolchain/bin/env /usr/bin/env \
    && ln -s /toolchain/bin/true /bin/true \
    && ln -s /toolchain/bin/pwd /bin/pwd
RUN /bin/check-config.sh .config
RUN make -j $(($(nproc) / 2))

FROM scratch AS kernel
COPY --from=kernel-build /src/arch/x86/boot/bzImage /vmlinuz
