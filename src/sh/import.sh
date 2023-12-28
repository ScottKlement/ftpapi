#!/usr/bin/env bash

copymbrs () {

  cd /qsys.lib/libftp.lib/${1}.file || exit 1
  if test "${2}" != "sh"; then
    rm -f ${3}/*.${2} ${3}/*.${2}inc
  fi

  for mbrsuff in *.MBR; do
    mbr=${mbrsuff%.MBR}
    hsuff=${mbr#*_}
    stmf=${mbr}.${2}
    if test "x$hsuff" = "xH"; then
      stmf=${mbr}.${2}inc
    fi
    qsh -c "rfile -rQ 'LIBFTP/${1}(${mbr})'" > ${3}/$stmf
    if test $? -ne 0; then
      exit 1
    fi
  done

}

copymbrs QRPGLESRC rpgle /home/sklement/libftp/src/rpg
copymbrs QCLSRC clle /home/sklement/libftp/src/cl
copymbrs QSRVSRC bnd /home/sklement/libftp/src/srv
copymbrs QSH sh /home/sklement/libftp/src/sh