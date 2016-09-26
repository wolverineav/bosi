#!/bin/bash -eux

# Following build params expected for this script:
# OpenStackBranch
# BcfBranch
# Revision
# IvsBranch (optional)

# mapping for OpenStackBranch to RHOSPVersion, default is latest = 9
# occasionally cleanup when we stop supporting certain versions
RHOSPVersion="9"
case "$OpenStackBranch" in
  *"mitaka"*) RHOSPVersion="9" ;;
  *"liberty"*) RHOSPVersion="8" ;;
  *"kilo"*) RHOSPVersion="7" ;;
esac

# if IvsBranch is not specified, it is same as BcfBranch
if [ -z  $IvsBranch  ]
then
    IvsBranch="$BcfBranch"
fi

# if branch is not master, append 'v' e.g. v3.7.0
if [ $IvsBranch != "master" ]
then
    IvsBranch="v$IvsBranch"
fi

# if BcfBranch is not master, append 'bcf-' to it
BosiBranch="$BcfBranch"
if [ $BcfBranch != "master" ]
then
    BosiBranch="bcf-$BcfBranch"
fi


# cleanup old stuff
sudo rm -rf *

# get ivs packages
mkdir ivs
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/xenon-bsn/centos7-x86_64/ivs/$IvsBranch/latest/* ./ivs

# get bsnstacklib packages
mkdir bsnstacklib
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/bsnstacklib/centos7-x86_64/$OpenStackBranch/latest/* ./bsnstacklib

# get horizon-bsn packages
mkdir horizon-bsn
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/horizon-bsn/centos7-x86_64/$OpenStackBranch/latest/* ./horizon-bsn

# get bosi packages
mkdir bosi
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/bosi/origin/$BosiBranch/latest/* ./bosi

# grunt work aka packaging
mkdir tarball
mv ./bosi/rhosp_resources/ivs/customize.sh ./tarball
mv ./bosi/rhosp_resources/ivs/README ./tarball
mv ./bosi/rhosp_resources/ivs/startup.sh ./tarball
mv ./bosi/rhosp_resources/yamls ./tarball
mv ./bsnstacklib/*.noarch.rpm ./tarball
mv ./horizon-bsn/*.noarch.rpm ./tarball
mv ./ivs/*.rpm ./tarball

get_version () {
    RPM=$1;
    B=${RPM##*/};
    B=${B%-*};
    V=${B##*-};
}

IVS_PKG="`ls ./tarball/ivs-debug*`"
get_version $IVS_PKG
IVS_VERSION=$V

BSNLIB_PKG="`ls ./tarball/python-networking-bigswitch*`"
get_version $BSNLIB_PKG
BSNSTACKLIB_VERSION=$V

HORIZON_PKG="`ls ./tarball/python-horizon-bsn*`"
get_version $HORIZON_PKG
HORIZON_BSN_VERSION=$V

echo "ivs version is" $IVS_VERSION
echo "bsnstacklib version is" $BSNSTACKLIB_VERSION
echo "horizon-bsn version is" $HORIZON_BSN_VERSION

sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${ivs_version}/$IVS_VERSION/" ./tarball/customize.sh
sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${ivs_version}/$IVS_VERSION/" ./tarball/startup.sh
sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${ivs_version}/$IVS_VERSION/" ./tarball/README

DATE=`date +%Y-%m-%d`
TAR_NAME="BCF-RHOSP-$RHOSPVersion-plugins-$IVS_VERSION.$Revision-$DATE"
mv tarball $TAR_NAME
tar -zcvf $TAR_NAME.tar.gz $TAR_NAME

# Copy built tarball to pkg/
OUTDIR=$(readlink -m "pkg/$OpenStackBranch/$TAR_NAME")
rm -rf "$OUTDIR" && mkdir -p "$OUTDIR"
mv $TAR_NAME.tar.gz "$OUTDIR"
ln -snf $(basename $OUTDIR) $OUTDIR/../latest
