FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y patch
RUN apt-get install -y gcc-7 
RUN apt-get install -y texinfo
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7
RUN apt-get install -y make

COPY . /home/68k
WORKDIR /home/68k

# Extract binutils and apply patch
RUN tar -xf binutils-2.23.tar.gz
RUN mv binutils-2.23 binutils
RUN cd binutils && patch -p1 ../binutils-fix-ineffectual-zero-of-cache.patch

# Compile binutils
# Turning off compiler warnings introduced in later GCC versions
ENV CFLAGS "-Wimplicit-fallthrough=0 -Wno-unused-value -Wno-cast-function-type -Wno-shift-negative-value -Wno-pointer-compare"
RUN cd binutils && sh ./configure --target=m6811-elf --program-prefix=m6811-elf-
RUN cd binutils && make && make install

# Compile last gcc release that supported m68hc1x
RUN tar -xf gcc-3.3.6-s12x-20121024.tar.gz
RUN mv gcc-3.3.6-s12x gcc-m68hc1x
RUN cd gcc-m68hc1x && sh ./configure --target=m6811-elf --program-prefix=m6811-elf- --enable-languages=c
RUN cd gcc-m68hc1x && make && make install

# Compile gdb
RUN apt-get install -y libncurses5-dev
RUN tar -xf gdb-6.2.1a.tar.gz
RUN mv gdb-6.2.1/ gdb-6.2-m68hc1x
RUN cd gdb-6.2-m68hc1x && sh ./configure --target=m6811-elf --program-prefix=m6811-elf-make
# TODO: Figure out how to fix
# needed to change register variable being used, still will not compile. Think extern inline might be the cause of the issue
# RUN cd gdb-6.2-m68hc1x && make && make install

# Compile newlib
RUN targ -xf newlib-1.16.0.tar.gz
RUN mv newlib-1.16.0 newlib-1.16.0-m68hc1x
RUN mkdir build-newlib
RUN cd build-newlib && ../newlib-1.16.0-m68hc1x/configure --disable-newlib-io-float --disable-newlib-multithread --target=m6811-elf --program-prefix=m6811-elf-
# TODO: Also broken, these might be the same issue with inline
# RUN cd build-newlib && make CFLAGS="-g -Os -Wall"