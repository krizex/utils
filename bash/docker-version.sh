#!/usr/bin/bash
# set -x
user=xenrtd
password=xensource
command="docker --version"
machines="
BOURNE01
BOURNE02QA
BOURNE03
BOURNE04
BOURNE05
CBGLAB01
FTLSUP701R1
LCY2XACT01
LCYAS01
LCYCC
LCYCLAB01
LCYLAB01
LCYLAB02
LCYOS01
LCYSTF01
LCYSYS10704
LCYSYS10705
LCYSYS201
LCYSYS301
LON01
LON02
MIA01
MIA02
MIA03
MIA04
MIA05
MIA06
MIA07
MIA08
MIA09
MIA10
MIA11
MIAAW01
MIACLM01
MIACLM02
MIALAB01
MIASYS101
MIASYS201
NKG01
NKGAPPD01
SJC01
SJC02
SJC03
SJC04
UKDEV1
"

# while read -r line; do
#     machines="${machines} $line"
# done < ./machines.txt

for machine in ${machines}
do
    ret=`sshpass -p "${password}" ssh -o StrictHostKeyChecking=no ${user}@"${machine}-controller.xenrt.citrite.net" "${command}"`
    printf "%-15s %s\n" ${machine} "${ret}"
done



