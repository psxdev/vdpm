#!/bin/bash

[ -d packages ] && rm -rf packages/*

if [ "${HAS_JOSH_K_SEAL_OF_APPROVAL:-false}" ]; then
    export VITASDK=/usr/local/vitasdk
    export PATH=$VITASDK/bin:$PATH
    export CC=arm-vita-eabi-gcc 
    export PKG_CONFIG_PATH=${VITASDK}/lib/pkgconfig/
    mkdir -p "${PKG_CONFIG_PATH}"
    BINTRAY_PKG_VER=$(printf %04d ${TRAVIS_BUILD_NUMBER})
fi

function bintray(){
    package="$1"
    if [ "$TRAVIS_OS_NAME" == "linux" ]; then
        pushd packages
        pkg=$(find * -name "vitasdk-${package}-*.tar.xz")
        curl -T "$pkg" -ujoshdekock:$BINTRAY_APIKEY "https://api.bintray.com/content/vitadev/dist/ports/${BINTRAY_PKG_VER}/$pkg"
        popd
    fi
}

function build(){
    package="$1"
    ./build-pkg.sh "repo/${package}.desc" || { echo "$package" >> packages/broken.list ; return 1; }
    tar xvf packages/vitasdk-${package}*.tar.xz -C $VITASDK
    if [ "${HAS_JOSH_K_SEAL_OF_APPROVAL:-false}" ]; then
        bintray "$package"
    fi
    eval ${package}=true
}

zlib=false
libpng=false
freetype2=false
libexif=false
libjpeg_turbo=false
sqlite=false
fftw=false
jansson=false

# manual dependencies
build zlib && build libpng && build freetype2
build libexif && build libjpeg-turbo
build sqlite
build fftw
build jansson

$libpng && ${libjpegturbo} && $freetype2 && build vita2dlib

[ -f packages/broken.list ] && echo "Broken packages" && cat packages/broken.list

exit 0
