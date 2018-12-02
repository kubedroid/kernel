FROM ubuntu:xenial AS kernel
ENV GCC_REPO=https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6
ENV KERNEL_REPOSITORY=https://github.com/maurossi/linux
ENV KERNEL_BRANCH=kernel-4.20rc4
ENV ARCH=x86_64
ENV O=/kernel-build/
ENV CROSS_COMPILE=/src/gcc/bin/x86_64-linux-
ENV INSTALL_MOD_PATH=/kernel/
ENV INSTALL_PATH=/kernel/

WORKDIR /src
RUN apt-get update \
&& apt-get install -y build-essential git bison flex libssl-dev libelf-dev bc python wget \
&& git clone --depth=1 -b $KERNEL_BRANCH $KERNEL_REPOSITORY kernel \
&& git clone --depth=1 -b master $GCC_REPO gcc

WORKDIR /src/kernel

RUN cp arch/x86/configs/android-x86_64_defconfig .config \
&& make ARCH=x86_64 olddefconfig \
&& cp .config arch/x86/configs/android-x86_64_defconfig \
&& git clean -xfd . \
&& BROADCOM_DIR=drivers/net/wireless/broadcom/wl \
&& wget https://docs.broadcom.com/docs-and-downloads/docs/linux_sta/hybrid-v35_64-nodebug-pcoem-6_30_223_271.tar.gz \
&& tar zxf hybrid-v35_64-nodebug-pcoem-6_30_223_271.tar.gz -C $BROADCOM_DIR --overwrite -m \
&& rm -rf hybrid-v35_64-nodebug-pcoem-6_30_223_271.tar.gz \
&& mv $BROADCOM_DIR/lib $BROADCOM_DIR/lib64 \
&& patch -p1 -d $BROADCOM_DIR -i wl.patch \
&& patch -p1 -d $BROADCOM_DIR -i linux-recent.patch \
&& patch -p1 -d $BROADCOM_DIR -i linux-48.patch \
&& patch -p1 -d $BROADCOM_DIR -i linux-411.patch \
&& patch -p1 -d $BROADCOM_DIR -i linux-412.patch \
&& patch -p1 -d $BROADCOM_DIR -i linux-415.patch

RUN make android-x86_64_defconfig \
&& make -j$(nproc --all) \
&& make modules_install \
&& make install
