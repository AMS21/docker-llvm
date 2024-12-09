FROM alpine:3.21

ARG VERSION

ADD patches/ patches/

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache cmake gcc git g++ ninja python3 && \
    git clone --depth 1 --branch "${VERSION}" https://github.com/llvm/llvm-project.git && \
    cd llvm-project && \
    if [[ -d "../patches/${VERSION}" ]]; then git apply ../patches/${VERSION}/*.patch; fi && \
    cmake -S llvm -B build -G "Ninja" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_C_FLAGS="-O3 -w -mtune=native -flto -pipe" -DCMAKE_CXX_FLAGS="-O3 -w -mtune=native -flto -pipe" \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
        -DCLANG_TIDY_ENABLE_STATIC_ANALYZER=ON \
        -DLLVM_HOST_TRIPLE="$(gcc -dumpmachine)" \
        -DCMAKE_INSTALL_PREFIX="/usr" && \
    cmake --build build --target install-clang-tidy -j $(nproc) && \
    cd .. && \
    rm -rf llvm-project && rm -rf patches && \
    apk del --purge --no-cache cmake gcc git g++ ninja && \
    rm -rf /var/cache/apk/*
