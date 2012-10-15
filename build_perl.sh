#!/bin/bash

function die() {
  echo "$1" 1>&2
  exit 1
}

URL=$1
test -z "$URL" && URL="http://cpan.weepeetelecom.nl/src/perl-5.16.1.tar.bz2"

test -x "/usr/bin/make" || die "no make! (apt-get install build-essential? or maybe it's Xcode?)"

TARBALL=$(basename $URL)
RELEASE=$(basename $TARBALL .tar.bz2)
VERSION_NUM=${RELEASE/perl-/}
PREFIX=$HOME/$RELEASE
PERL_LIB=$PREFIX/lib
ARCH_LIB=$PREFIX/archlib
BUILD_DIR=$(mktemp -d /tmp/perl.XXXXXXXXX)

trap "echo removing $BUILD_DIR...; rm -rf $BUILD_DIR; echo" EXIT

cd "$BUILD_DIR" && ( wget -O "$BUILD_DIR/$TARBALL" $URL || curl $URL > "$BUILD_DIR/$TARBALL" )
( test -f "$TARBALL" && test -s "$TARBALL" ) || die "can't find $TARBALL"

echo untarring $TARBALL && tar -xjf "$BUILD_DIR/$TARBALL" && cd "$BUILD_DIR/$RELEASE"
test -f Configure || die "can't find Configure in $PWD"

./Configure                         \
  -des                              \
  -Dusedevel                        \
  -Dprefix=$PREFIX                  \
  -Dinc_version_list=none           \
  -Dprivlib=$PERL_LIB               \
  -Dsitelib=$PERL_LIB               \
  -Darchlib=$ARCH_LIB               \
  -Dsitearch=$ARCH_LIB

test -f Makefile || die "can't find Makefile in $PWD"

make
( test -x perl || test -x "perl$VERSION_NUM" ) || die "can't find freshly built perl/perl$VERSION_NUM binary in $PWD"

test -n "$TEST_PERL" && ( make test || die "test suite failed" )

make install

test -x "$PREFIX/bin/perl$VERSION_NUM" || die "can't find installed perl$VERSION_NUM binary in $PREFIX/bin"
test -x "$PREFIX/bin/perl" || ( ln -s $PREFIX/bin/perl$VERSION_NUM $PREFIX/bin/perl; ln -s $PREFIX/bin/cpan$VERSION_NUM $PREFIX/bin/cpan )

echo -e "\n\nexport PATH=$PREFIX/bin:$PREFIX/site/bin:\$PATH\n\n"
