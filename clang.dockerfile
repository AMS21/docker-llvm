FROM alpine:3.19

ARG VERSION

ADD patches/ patches/

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache cmake gcc git g++ ninja python3 && \
    git clone --depth 1 --branch "${VERSION}" https://github.com/llvm/llvm-project.git && \
    cd llvm-project && \
    if [[ -d "../patches/${VERSION}" ]]; then git apply ../patches/${VERSION}/*.patch; fi && \
    cmake -S llvm -B build -G "Ninja" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_C_FLAGS="-O3 -w -mtune=native -static-libgcc -static-libstdc++ -pipe" \
        -DCMAKE_CXX_FLAGS="-O3 -w -mtune=native -static-libgcc -static-libstdc++ -pipe" \
        -DLLVM_ENABLE_PROJECTS="clang" \
        -DLLVM_HOST_TRIPLE="$(gcc -dumpmachine)" \
        -DCMAKE_INSTALL_PREFIX="/usr" && \
    cmake --build build --target install-clang -j $(nproc) && \
    cd .. && \
    rm -rf llvm-project && rm -rf patches && \
    apk del --purge --no-cache cmake gcc git g++ ninja python3 && \
    rm -rf /var/cache/apk/*

ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++
