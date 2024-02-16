#!/usr/bin/env qsh

set -x
INPREF=/qsys.lib/$1.lib
MAKEDIR=$2
OUTPREF=/tmp/ftpapi

############################################
# copy each member to a stream file
# Note: We use CPYTOSTMF instead of CAT
#       because it trims trailing blanks.
############################################

copyemall() {

  while read f; do
    FILE=$(echo $f | cut -c 3-)
    INFULL="${INPREF}/${FILE}"
    OUTFULL="${OUTPREF}/${FILE}"
    echo "infull = $INFULL"
    echo "outfull = $OUTFULL"
    if [ -d $INFULL ]; then
      echo "mkdir $OUTFULL"
      mkdir $OUTFULL || exit 1
    else
      echo "system -v \"CPYTOSTMF FROMMBR('${INFULL}') TOSTMF('${OUTFULL}') STMFOPT(*REPLACE) STMFCODPAG(819)\""
      system -v "CPYTOSTMF FROMMBR('${INFULL}') TOSTMF('${OUTFULL}') STMFOPT(*REPLACE) STMFCODPAG(819)" || exit
    fi
  done

}

############################################
# make output dir
############################################

cd ${INPREF} || exit 1
rm -rf ${OUTPREF}
mkdir ${OUTPREF} || exit 1

############################################
# make a list of members to include
############################################

eval TMPFILE=/tmp/ftpapi_pkg$$
find . | grep -i '^..[QE].*FILE' > $TMPFILE
copyemall < $TMPFILE

cd ${OUTPREF} 
cd ..
rm -f ${MAKEDIR}/build/ftpapi.zip
zip -r ${MAKEDIR}/build/ftpapi.zip ftpapi
