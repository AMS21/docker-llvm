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
        -DCMAKE_C_FLAGS="-O3 -w -mtune=native -flto -pipe" -DCMAKE_CXX_FLAGS="-O3 -w -mtune=native -flto -pipe" \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,--push-state -Wl,-whole-archive -Wl,--pop-state -lpthread -lstdc++ -lm -ldl" \
        -DLLVM_ENABLE_PROJECTS="bolt;clang;lld" \
        -DLLVM_HOST_TRIPLE="$(gcc -dumpmachine)" \
        -DCMAKE_INSTALL_PREFIX="/usr" && \
    ninja -C build tools/bolt/all && \
    cmake --build build --target install-llvm-bolt install-merge-fdata install-bolt_rt -j $(nproc) && \
    cd .. && \
    rm -rf llvm-project && rm -rf patches && \
    apk del --purge --no-cache git ninja python3 && \
    rm -rf /var/cache/apk/*
