#!/bin/sh -x

set -e

releasedir=$1
cephver=$2
debsubver=$3
dists=$4

[ -z "$releasedir" ] && echo specify releasedir && exit 1
[ -z "$cephver" ] && echo specify version && exit 1
[ -z "$debsubver" ] && debsubver=1
[ -z "$dists" ] && dists="sid squeeze lenny maverick lucid"

bindir=`dirname $0`
echo "$bindir" | grep -v -q '^/' && bindir=`pwd`"/$bindir"

debver="$cephver-$debsubver"

echo debver $debver

cd $releasedir/$cephver || exit 1

echo "(re)extracting"

[ -d "ceph-$cephver" ] && rm -r ceph-$cephver
tar zxvf ceph_$cephver.orig.tar.gz

# add debian dir
echo "copying in debian/"
cp -a debian ceph-$cephver

# take note 
echo $dists > debian_dists
echo $debver > debian_version

for dist in $dists
do
    echo building $dist dsc

    bpver=`$bindir/gen_debian_version.sh $debver $dist`

    # add to changelog?
    chvers=`head -1 debian/changelog | perl -ne 's/.*\(//; s/\).*//; print'`
    if [ "$chvers" != "$bpver" ]; then
	cd ceph-$cephver
	DEBEMAIL="sage@newdream.net" dch -D $dist --force-distribution -b -v "$bpver" "$comment"
	cd ..
    fi

    # hack
    [ "$dist" == "lenny" ] && sed -i 's/, libgoogle-perftools-dev//' ceph-$cephver/debian/control

    dpkg-source -b ceph-$cephver

done

rm -r ceph-$cephver
echo done
