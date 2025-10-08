      * This sample program requires V4R2 or later

      *
      * This is a sample of copying an entire directory tree from an
      * FTP server to the IFS on your IBM i
      *

      *-                                                                            +
      * Copyright (c) 2002-2025 Scott C. Klement                                    +
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
     H OPTION(*SRCSTMT: *NODEBUGIO: *NOSHOWCPY)
     H BNDDIR('QC2LE') BNDDIR('FTPAPI')

 CPY  /COPY FTPAPI_H

     D chdir           PR            10I 0 ExtProc('chdir')
     D   path                          *   Value Options(*string)

     D mkdir           PR            10I 0 ExtProc('mkdir')
     D   path                          *   Value options(*string)
     D   mode                        10U 0 Value

     D bitand          PR            10U 0
     D   fact1                       10U 0 value
     D   fact2                       10U 0 value
     D is_dir          PR             1A
     D    peDir                     640A   const
     D do_dir          PR            10I 0
     D   peDir                      640A   const
     D c__errno        PR              *   ExtProc('__errno')
     D strerror        PR              *   ExtProc('strerror')
     D    errnum                     10I 0 value
     D DiagMsg         PR
     D   peMsgTxt                   256A   Const
     D errno           PR            10I 0

     D FTP_ROOT        C                   CONST('/home/klemscot/ftptest')
     D LOCAL_ROOT      C                   CONST('/testhome')

     D msg             S             52A
     D ftp             S             10I 0

     c                   eval      *inlr = *On

     c                   eval      ftp = ftp_conn('ftp.example.com':
     c                                            'myuserid':
     c                                            'mypasswd')
 B01 c                   if        ftp < 0
     c                   eval      msg = FTP_errorMsg(0)
     c                   dsply                   msg
     c                   return
 E01 c                   endif

     c                   callp     ftp_binaryMode(ftp: *ON)

     c                   callp     do_dir(*blanks)

     c                   callp     ftp_quit(ftp)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * This procedure calls itself recursively for each subdirectory
      * in each directory on the FTP server.
      *
      * It only handles the first 100 files in a directory.
      *
      * It uses FTP_chdir to determine if each file is a directory.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P do_dir          B
     D do_dir          PI            10I 0
     D   peDir                      640A   const

     D wwDirname       S            640A
     D wwLen           S             10I 0
     D FtpDir          S            640A
     D LocalFile       S            640A
     D LocalDir        S            640A
     D Files           S            256A   dim(100)
     D FilesFound      S             10I 0
     D x               S             10I 0


      * Strip off trailing '/'
     c                   eval      wwLen = %len(%trimr(peDir))
 B01 c                   if        wwLen>1 and %subst(peDir:wwLen:1) = '/'
     c                   eval      wwDirname = %subst(peDir:1:wwLen-1)
 X01 c                   else
     c                   eval      wwDirname = peDir
 E01 c                   endif

      * Add prefixes for local & remote directory names
     c                   eval      LocalDir= LOCAL_ROOT + %trimr(wwDirName)
     c                   eval      FtpDir = FTP_ROOT + %trimr(wwDirName)

      * Change FTP server to requested directory
 B01 c                   if        ftp_chdir(ftp: FtpDir) < 0
     c                   return    -1
 E01 c                   endif

      * Get list of files in directory
 B01 c                   if        ftp_list(ftp: '': 100: %addr(Files):
     c                                 FilesFound) < 0
     c                   callp     diagmsg('ftp_dir(): ' + FTP_errorMsg(ftp))
     c                   return    0
 E01 c                   endif

      * Create/switch to the local directory
     c                   callp     mkdir(%trimr(LocalDir): 511)
 B01 c                   if        chdir(%trimr(LocalDir)) < 0
     c                   callp     DiagMsg('chdir(): ' +
     c                                  %str(strerror(errno)))
     c                   return    -1
 E01 c                   endif

 B01 c                   do        FilesFound    X

      * Skip special files "." and ".."
 B02 c                   if        Files(X) = '.' or Files(X) = '..'
     c                   iter
 E02 c                   endif

      * Check if the file is a directory, and if so, call ourself
      * with the new directory name:
 B02 c                   if        ftp_chdir(ftp: files(X)) >= 0

 B03 c                   if        do_dir(%trimr(wwDirName) + '/' +
     c                                    Files(X)) < 0
     c                   return    -1
 E03 c                   endif

     c                   callp     ftp_chdir(ftp: FtpDir)

      * Otherwise, assume it's a file, and transfer it.
 X02 c                   else

     c                   eval      LocalFile = LOCAL_ROOT +
     c                               %trimr(wwDirName) + '/' + Files(X)

 B03 c                   if        ftp_get(ftp: Files(X): LocalFile) < 0
     c                   callp     diagmsg(FTP_errorMsg(ftp))
 E03 c                   endif
 E02 c                   endif

 E01 c                   enddo

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This puts a diagnostic message into the job log
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P DiagMsg         B
     D DiagMsg         PI
     D   peMsgTxt                   256A   Const

     D dsEC            DS
      *                                    Bytes Provided (size of struct)
     D  dsECBytesP             1      4B 0 INZ(256)
      *                                    Bytes Available (returned by API)
     D  dsECBytesA             5      8B 0 INZ(0)
      *                                    Msg ID of Error Msg Returned
     D  dsECMsgID              9     15
      *                                    Reserved
     D  dsECReserv            16     16
      *                                    Msg Data of Error Msg Returned
     D  dsECMsgDta            17    256

     D SndTheMsg       PR                  ExtPgm('QMHSNDPM')
     D   MessageID                    7A   Const
     D   QualMsgF                    20A   Const
     D   MsgData                    256A   Const
     D   MsgDtaLen                   10I 0 Const
     D   MsgType                     10A   Const
     D   CallStkEnt                  10A   Const
     D   CallStkCnt                  10I 0 Const
     D   MessageKey                   4A
     D   ErrorCode                    1A

     D wwMsgLen        S             10I 0
     D wwTheKey        S              4A

     c                   eval      wwMsgLen = %len(%trimr(peMsgTxt))
     c                   callp     SndTheMsg('CPF9897': 'QCPFMSG   *LIBL':
     c                               peMsgTxt: wwMsgLen: '*DIAG':
     c                               '*': 0: wwTheKey: dsEC)

     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Get the UNIX/C error number
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P errno           B
     D errno           PI            10I 0
     D p_errno         S               *
     D wwreturn        S             10I 0 based(p_errno)
     C                   eval      p_errno = c__errno
     c                   return    wwreturn
     P                 E
