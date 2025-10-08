      *-                                                                            +
      * Copyright (c) 2001-2025 Scott C. Klement                                    +
      * All rights reserved.                                                        +
      *                                                                             +
      * Redistribution and use in source and binary forms, with or without          +
      * modification, are permitted provided that the following conditions          +
      * are met:                                                                    +
      * 1. Redistributions of source code must retain the above copyright           +
      *    notice, this list of conditions and the following disclaimer.            +
      * 2. Redistributions in binary form must reproduce the above copyright        +
      *    notice, this list of conditions and the following disclaimer in the      +
      *    documentation and/or other materials provided with the distribution.     +
      *                                                                             +
      * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ''AS IS'' AND      +
      * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE       +
      * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  +
      * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE     +
      * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL  +
      * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS     +
      * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)       +
      * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT  +
      * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY   +
      * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      +
      * SUCH DAMAGE.                                                                +
      *                                                                             +
      */                                                                            +

      * This code contains contributions from Thomas Raddatz:
      *    -- Added STRPRPRC statements to allow easier object creation.

      *   >>PRE-COMPILER<<
      *
      *     >>CRTCMD<<  CRTRPGMOD    MODULE(&LI/&OB) +
      *                              SRCFILE(&SL/&SF) +
      *                              SRCMBR(&SM);
      *
      *     >>COMPILE<<
      *       >>PARM<< TRUNCNBR(*NO);
      *       >>PARM<< DBGVIEW(*LIST);
      *     >>END-COMPILE<<
      *
      *     >>EXECUTE<<
      *
      *     >>CMD<<     CRTPGM       PGM(&LI/&OB) +
      *                              MODULE(*PGM) +
      *                              BNDSRVPGM(&LI/FTPAPIR4) +
      *                              ACTGRP(*NEW);
      *
      *   >>END-PRE-COMPILER<<
      *

      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')

      *  This is a simple example of using the FTPAPI to download a file
      *  from ftp.freebsd.org.
      *
      *  1)  Connect to the server
      *  2)  switch to the pub/FreeBSD/tools directory
      *  3)  download fips.exe in binary mode.
      *  4)  Log Out.
      *
 CPY  /COPY FTPAPI_H

     D ftp             S             10I 0
     D Msg             S             52A

     D Status          PR
     D   Bytes                       16P 0 value
     D   TotBytes                    16P 0 value

      * Connect to an FTP server.
      *    using userid:  anonymous
      *        password:  anon.e.mouse@aol.com
      *
     C                   eval      ftp = ftp_conn('ftp2.freebsd.org':
     C                                            'anonymous':
     C                                            'anon.e.mouse@aol.com')
      * ftp_error will contain
      *  an error msg if ftp is < 0
 B01 c                   if        ftp < 0
     c                   eval      Msg = ftp_errorMsg(0)
     c                   dsply                   Msg
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

      * Change to the FreeBSD tools directory on
      *  this FTP server.  Deal with any errors.
 B01 c                   if        ftp_chdir(ftp: 'pub/FreeBSD/tools') < 0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

      * Register a 'status' procedure.   FTPAPI will call this
      *   proc whenever data is received, giving us a 'byte count'
     c                   if        ftp_xproc(FTP_EXTSTS        :
     c                                       %paddr('STATUS')  ) < 0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif


      * Get the FIPS utility (runs under DOS)
      *   save it to the root directory, locally.
     c                   callp     ftp_binaryMode(ftp: *on)
 B01 c                   if        ftp_get(ftp: 'fips.exe': '/fips.exe') < 0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

      *  The transfer was successful...
     c                   callp     ftp_quit(ftp)
     c                   eval      Msg = 'Success!'
     c                   dsply                   Msg
     c                   eval      *inlr = *on


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Example of showing the status of a file transfer.   All this
      *    does is put a status message on the screen showing the number
      *    of bytes transferred.
      *
      *  Note:  You should not do anything here that takes a lot of
      *         time, it will slow down the file transfer.
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P Status          B
     D Status          PI
     D   Bytes                       16P 0 value
     D   TotBytes                    16P 0 value

     D SndPgmMsg       PR                  ExtPgm('QMHSNDPM')
     D   MessageID                    7A   Const
     D   QualMsgF                    20A   Const
     D   MsgData                    256A   Const
     D   MsgDtaLen                   10I 0 Const
     D   MsgType                     10A   Const
     D   CallStkEnt                  10A   Const
     D   CallStkCnt                  10I 0 Const
     D   MessageKey                   4A
     D   ErrorCode                    1A

     D dsEC            DS
     D  dsECBytesP                   10I 0 inz(0)
     D  dsECBytesA                   10I 0 inz(0)

     D wwBytes         S             16A
     D wwTotal         S             16A
     D wwMsg           S             55A
     D wwTheKey        S              4A

     c                   move      Bytes         wwBytes
     c                   move      TotBytes      wwTotal
     c                   eval      wwMsg = 'Bytes transferred: ' + wwBytes +
     c                               ' of ' + wwTotal

     c                   callp     SndPgmMsg('CPF9897': 'QCPFMSG   *LIBL':
     c                               wwMsg: %size(wwMsg): '*STATUS':
     c                               '*EXT': 0: wwTheKey: dsEC)

     c                   return
     P                 E
