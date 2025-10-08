      * This sample program requires V4R2 or later

      *
      * This is a sample of copying an entire directory tree in the IFS
      * to a FTP server.
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

     D opendir         PR              *   EXTPROC('opendir')
     D  dirname                        *   VALUE options(*string)
     D readdir         PR              *   EXTPROC('readdir')
     D  dirp                           *   VALUE
     D closedir        PR            10I 0 EXTPROC('closedir')
     D  dirhandle                      *   VALUE
     D stat            PR            10I 0 ExtProc('stat')
     D   path                          *   value options(*string)
     D   buf                           *   value

     D p_dirent        s               *
     D dirent          ds                  based(p_dirent)
     D   d_reserv1                   16A
     D   d_reserv2                   10U 0
     D   d_fileno                    10U 0
     D   d_reclen                    10U 0
     D   d_reserv3                   10I 0
     D   d_reserv4                    8A
     D   d_nlsinfo                   12A
     D     nls_ccsid                 10I 0 OVERLAY(d_nlsinfo:1)
     D     nls_cntry                  2A   OVERLAY(d_nlsinfo:5)
     D     nls_lang                   3A   OVERLAY(d_nlsinfo:7)
     D     nls_reserv                 3A   OVERLAY(d_nlsinfo:10)
     D   d_namelen                   10U 0
     D   d_name                     640A

     D p_statds        S               *
     D statds          DS                  BASED(p_statds)
     D  st_mode                      10U 0
     D  st_ino                       10U 0
     D  st_nlink                      5U 0
     D  st_pad                        2A
     D  st_uid                       10U 0
     D  st_gid                       10U 0
     D  st_size                      10I 0
     D  st_atime                     10I 0
     D  st_mtime                     10I 0
     D  st_ctime                     10I 0
     D  st_dev                       10U 0
     D  st_blksize                   10U 0
     D  st_alctize                   10U 0
     D  st_objtype                   12A
     D  st_codepag                    5U 0
     D  st_resv11                    62A
     D  st_ino_gen_id                10U 0

     D bitand          PR            10U 0
     D   fact1                       10U 0 value
     D   fact2                       10U 0 value
     D is_dir          PR             1A
     D    peDir                     640A   const
     D do_dir          PR            10I 0
     D   peDir                      640A   const
     D S_ISDIR         PR             1N
     D   mode                        10U 0 value
     D c__errno        PR              *   ExtProc('__errno')
     D strerror        PR              *   ExtProc('strerror')
     D    errnum                     10I 0 value
     D DiagMsg         PR
     D   peMsgTxt                   256A   Const
     D errno           PR            10I 0

     D FTP_ROOT        C                   CONST('/home/klemscot/ftptest')
     D LOCAL_ROOT      C                   CONST('/home')

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
      * in a directory.
      *
      * For each non-subdir in the directory, it calls FTP_PUT
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P do_dir          B
     D do_dir          PI            10I 0
     D   peDir                      640A   const

     D dh              S               *
     D wwDirname       S            640A
     D wwFile          S            640A
     D wwLen           S             10I 0
     D FtpDir          S            640A
     D LocalDir        S            640A
     D LocalFile       S            640A
     D mystat          s                   like(statds)

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

      * Open local directory
     c                   eval      dh = opendir(%trimr(LocalDir))
 B01 c                   if        dh = *NULL
     c                   callp     diagmsg('opendir(): ' +
     c                                      %str(strerror(errno)))
     c                   return    -1
 E01 c                   endif

      * Create/switch to same dir on FTP server
     c                   callp     ftp_mkdir(ftp: FtpDir)
 B01 c                   if        ftp_chdir(ftp: FtpDir) < 0
     c                   callp     closedir(dh)
     c                   callp     DiagMsg(FTP_errorMsg(ftp))
     c                   return    -1
 E01 c                   endif

 B01 c                   dow       1 = 1

      * Read next directory entry
     c                   eval      p_dirent = readdir(dh)
 B02 c                   if        p_dirent = *NULL
     c                   leave
 E02 c                   endif

      * Skip special files "." and ".."
     c                   eval      wwFile = %subst(d_name: 1: d_namelen)
 B02 c                   if        wwFile = '.' or wwFile = '..'
     c                   iter
 E02 c                   endif

      * Get stat structure for local file
     c                   eval      LocalFile = LOCAL_ROOT +
     c                                  %trimr(wwDirName) + '/' + wwFile
 B02 c                   if        stat(%trimr(LocalFile): %addr(mystat))<0
     c                   callp     diagmsg('stat(): ' + %trim(wwFile) +
     c                                ': ' + %str(strerror(errno)))
 E02 c                   endif

      * If local file is a directory, call this procedure again,
      * with the new directory name.
     c                   eval      p_statds = %addr(mystat)
 B02 c                   if        S_ISDIR(st_mode)
 B03 c                   if        do_dir(%trimr(wwDirName) + '/' +
     c                                    wwFile) < 0
     c                   return    -1
 E03 c                   endif
     c                   callp     ftp_chdir(ftp: FtpDir)

      * Otherwise, assume it's a file, and transfer it.
 X02 c                   else
 B03 c                   if        ftp_put(ftp: wwFile: LocalFile) < 0
     c                   callp     diagmsg(FTP_errorMsg(ftp))
 E03 c                   endif
 E02 c                   endif

 E01 c                   enddo

     c                   callp     closedir(dh)
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This tests a file mode to see if a file is a directory.
      *
      * Here is the C code we're trying to duplicate:
      *      #define _S_IFDIR    0040000                                       */
      *      #define S_ISDIR(mode) (((mode) & 0370000) == _S_IFDIR)
      *
      * 1) ((mode) & 0370000) takes the file's mode and performs a
      *      bitwise AND with the octal constant 0370000.  In binary,
      *      that constant looks like: 00000000000000011111000000000000
      *      The effect of this code is to turn off all bits in the
      *      mode, except those marked with a '1' in the binary bitmask.
      *
      * 2) ((result of #1) == _S_IFDIR)  What this does is compare
      *      the result of step 1, above with the _S_IFDIR, which
      *      is defined to be the octal constant 0040000.  In decimal,
      *      that octal constant is 16384.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P S_ISDIR         B
     D S_ISDIR         PI             1N
     D   mode                        10U 0 value

     D                 DS
     D  dirmode                1      4U 0
     D  byte1                  1      1A
     D  byte2                  2      2A
     D  byte3                  3      3A
     D  byte4                  4      4A

      * Turn off bits in the mode, as in step (1) above.
     c                   eval      dirmode = mode

     c                   bitoff    x'FF'         byte1
     c                   bitoff    x'FE'         byte2
     c                   bitoff    x'0F'         byte3
     c                   bitoff    x'FF'         byte4

      * Compare the result to 0040000, and return true or false.
 B01 c                   if        dirmode = 16384
     c                   return    *On
 X01 c                   else
     c                   return    *Off
 E01 c                   endif
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
