ARG TOOLCHAIN_IMAGE
FROM ${TOOLCHAIN_IMAGE} AS kernel-src
WORKDIR /src
RUN tar --strip-components=1 -xJf /tmp/linux.tar.xz
ADD https://raw.githubusercontent.com/opencontainers/runc/v1.0.0-rc6/script/check-config.sh /bin/check-config.sh
RUN chmod +x /bin/check-config.sh
RUN make mrproper
COPY config .config

FROM kernel-src AS kernel-build
RUN mkdir -p /usr/bin \
    && ln -s /toolchain/bin/env /usr/bin/env \
    && ln -s /toolchain/bin/true /bin/true \
    && ln -s /toolchain/bin/pwd /bin/pwd
RUN /bin/check-config.sh .config
RUN make -j $(($(nproc) / 2))
RUN make -j $(($(nproc) / 2)) modules
RUN export KERNELRELEASE=$(cat include/config/kernel.release) \
    && make -j $(nproc) modules_install DEPMOD=/toolchain/bin/depmod INSTALL_MOD_PATH=./modules/$KERNELRELEASE \
    && depmod -b ./modules/$KERNELRELEASE $KERNELRELEASE
FROM scratch AS kernel
COPY --from=kernel-build /src/vmlinux /vmlinux
COPY --from=kernel-build /src/arch/x86/boot/bzImage /vmlinuz
COPY --from=kernel-build /src/modules /modules
