#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

PATH=/home/nimesh/Desktop/cross_toolchain/install-lnx/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH

set -e
set -u

OUTDIR=/tmp/aeld
#OUTDIR=/media/sf_VM_Share/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper  # Clean old build files
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig  # Load default config for architecture
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all  # Build the kernel
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules  # Build kernel modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs  # Build device tree blobs

fi

echo "Adding the Image in outdir"
mkdir -p /tmp/aesd-autograder
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image /tmp/aesd-autograder/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
#git clone git://busybox.net/busybox.git
git clone https://git.busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    
    # TODO:  Configure busybox
    make distclean  # Clean any previous configurations
    make defconfig  # Load default config

    
    
else
    cd busybox
fi

# TODO: Make and install busybox
make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install


echo "Library dependencies"
cd ${OUTDIR}/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# Ensure lib directories exist before copying
mkdir -p ${OUTDIR}/rootfs/lib
mkdir -p ${OUTDIR}/rootfs/lib64


# TODO: Add library dependencies to rootfs
TOOLCHAIN_DIR=/home/nimesh/Desktop/cross_toolchain/install-lnx/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu
cp ${TOOLCHAIN_DIR}/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1 lib
#cp ${TOOLCHAIN_DIR}/aarch64-none-linux-gnu/libc/lib64/ld-linux-aarch64.so.1 lib64
	   
												   
													
cp ${TOOLCHAIN_DIR}/aarch64-none-linux-gnu/libc/lib64/libm.so.6 lib64
cp ${TOOLCHAIN_DIR}/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2 lib64
cp ${TOOLCHAIN_DIR}/aarch64-none-linux-gnu/libc/lib64/libc.so.6 lib64

# TODO: Make device nodes
mkdir -p ${OUTDIR}/rootfs/dev
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 1 5
#sudo mknod -m 600 dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
#cp writer ${OUTDIR}/rootfs

mkdir -p ${OUTDIR}/rootfs/home
mkdir -p ${OUTDIR}/rootfs/home/conf
cp writer ${OUTDIR}/rootfs/home/


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/username.txt ${OUTDIR}/rootfs/home/conf/
cp ${FINDER_APP_DIR}/conf/assignment.txt ${OUTDIR}/rootfs/home/conf/
#cp ${FINDER_APP_DIR}/conf/* ${OUTDIR}/rootfs/home/conf/
#cp ${FINDER_APP_DIR}/* ${OUTDIR}/rootfs/home/





# TODO: Chown the root directory
#cd rootfs/
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
echo "Create initramfs.cpio.gz"
cd "${OUTDIR}"/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

# Copy Image and initramfs to where the autograder expects them
# Only copy if OUTDIR is different from the autograder path
if [ "$OUTDIR" != "/tmp/aesd-autograder" ]; then
    cp ${OUTDIR}/linux-stable/arch/arm64/boot/Image /tmp/aesd-autograder/Image
    cp ${OUTDIR}/initramfs.cpio.gz /tmp/aesd-autograder/initramfs.cpio.gz
fi




