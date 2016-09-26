#!/bin/bash -eux

# Following build params expected for this script:
# OpenStackBranch
# BcfBranch
# Revision

# mapping for OpenStackBranch to RHOSPVersion, default is latest = 9
# occasionally cleanup when we stop supporting certain versions
RHOSPVersion="9"
case "$OpenStackBranch" in
  *"mitaka"*) RHOSPVersion="9" ;;
  *"liberty"*) RHOSPVersion="8" ;;
  *"kilo"*) RHOSPVersion="7" ;;
esac

# if BcfBranch is not master, append 'bcf-' to it
BosiBranch="$BcfBranch"
if [[ $BcfBranch != "master" ]]
then
    BosiBranch="bcf-$BcfBranch"
fi

# cleanup old stuff
sudo rm -rf *

# get nfvswitch packages
mkdir nfvswitch
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/nfvswitch/centos7-x86_64/latest/* ./nfvswitch

# get nfvswitch-qemu packages
mkdir nfvswitch_qemu
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/rhosp_nfvswitch_qemu/* ./nfvswitch_qemu

# get bsnstacklib packages
mkdir bsnstacklib
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/bsnstacklib/centos7-x86_64/$OpenStackBranch/latest/* ./bsnstacklib

# get horizon-bsn packages
mkdir horizon-bsn
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/horizon-bsn/centos7-x86_64/$OpenStackBranch/latest/* ./horizon-bsn

# get bosi scripts
mkdir bosi
rsync -e 'ssh -o "StrictHostKeyChecking no"' -uva  bigtop:public_html/bosi/$BosiBranch/latest/* ./bosi

# grunt work aka packaging
mkdir tarball
# nfvswitch rpms
mv ./nfvswitch/nfvswitch-*.rpm ./tarball
# nfvswitch_qemu rpms
mv ./nfvswitch_qemu/* ./tarball
# BOSI contains these files namely: customize.sh  README  startup.sh
mv ./bosi/rhosp_resources/nfvswitch/* ./tarball
# Sample yaml files
mv ./bosi/rhosp_resources/yamls ./tarball
# bsnstacklib
mv ./bsnstacklib/*.noarch.rpm ./tarball
# horizon-bsn
mv ./horizon-bsn/*.noarch.rpm ./tarball

get_version () {
    RPM=$1;
    B=${RPM##*/};
    B=${B%-*};
    V=${B##*-};
}

NFVSWITCH_PKG="`ls ./tarball/nfvswitch-debug*`"
get_version $NFVSWITCH_PKG
NFVSWITCH_VERSION=$V

BSNLIB_PKG="`ls ./tarball/python-networking-bigswitch*`"
get_version $BSNLIB_PKG
BSNSTACKLIB_VERSION=$V

HORIZON_PKG="`ls ./tarball/python-horizon-bsn*`"
get_version $HORIZON_PKG
HORIZON_BSN_VERSION=$V

echo "nfvswitch version is" $NFVSWITCH_VERSION
echo "bsnstacklib version is" $BSNSTACKLIB_VERSION
echo "horizon-bsn version is" $HORIZON_BSN_VERSION

sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${nfvswitch_version}/$NFVSWITCH_VERSION/" ./tarball/customize.sh
sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${nfvswitch_version}/$NFVSWITCH_VERSION/" ./tarball/startup_compute.sh
sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${nfvswitch_version}/$NFVSWITCH_VERSION/" ./tarball/startup_controller.sh
sed -i -e "s/\${bsnstacklib_version}/$BSNSTACKLIB_VERSION/" -e "s/\${horizon_bsn_version}/$HORIZON_BSN_VERSION/" -e "s/\${nfvswitch_version}/$NFVSWITCH_VERSION/" ./tarball/README

DATE=`date +%Y-%m-%d`
TAR_NAME="BCF-RHOSP-$RHOSPVersion-plugins-$NFVSWITCH_VERSION.$Revision-$DATE"
mv tarball $TAR_NAME
tar -zcvf $TAR_NAME.tar.gz $TAR_NAME

# Copy built tarball to pkg/
OUTDIR=$(readlink -m "pkg/$OpenStackBranch/$TAR_NAME")
rm -rf "$OUTDIR" && mkdir -p "$OUTDIR"
mv $TAR_NAME.tar.gz "$OUTDIR"
ln -snf $(basename $OUTDIR) $OUTDIR/../latest
