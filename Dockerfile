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
COPY patches/Makefile_module.builtin.patch /src/Makefile_module.builtin.patch
RUN patch < Makefile_module.builtin.patch
RUN make -j $(($(nproc) / 2)) modules
# All of this nonsense is to work around software that wasnt designed for static kernels
RUN export KERNELRELEASE=$(cat include/config/kernel.release) \
     && mkdir -p modules/$KERNELRELEASE \
     && cp modules.builtin ./modules/$KERNELRELEASE/ \
     && touch ./modules/$KERNELRELEASE/{modules.alias,modules.dep,modules.devname,modules.order,modules.softdep,modules.symbols,modules.alias.bin,modules.dep.bin,modules.devname.bin,modules.order.bin,modules.softdep.bin,modules.symbols.bin}


FROM scratch AS kernel
COPY --from=kernel-build /src/vmlinux /vmlinux
COPY --from=kernel-build /src/arch/x86/boot/bzImage /vmlinuz
COPY --from=kernel-build /src/modules /modules
