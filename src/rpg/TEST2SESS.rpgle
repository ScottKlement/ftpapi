      *-                                                                            +
      * Copyright (c) 2005-2025 Scott C. Klement                                    +
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


      **  This demonstrates using two open FTPAPI sessions to download
      **  all of the files in a directory.
      **
      **  this is equiv. to the MGET command found in most FTP clients.
      **
      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')

 CPY  /COPY FTPAPI_H
 CPY  /COPY IFSIO_H

     D Download        PR            10I 0
     D   peFd                        10I 0 value
     D   peName                    8192A   options(*varsize)
     D   peNameLen                   10I 0 value

     D CompMsg         PR
     D   peMsgTxt                   256A   Const

     D Logger          PR
     D   peMsgTxt                   256A   Const
     D   peLogFile                   10I 0

     D Logger2         PR
     D   peMsgTxt                   256A   Const
     D   peLogFile                   10I 0

     D rc              S             10I 0
     D ftp1            S             10I 0
     D ftp2            S             10I 0
     D log1            S             10I 0
     D log2            S             10I 0
     D ErrNum          S             10I 0
     D gotfiles        S             10I 0
     D x               S             10I 0

      ****************************************************************
      ** This tells FTPAPIR4 to log the FTP session to the joblog
      **  so we can debug any problems that occur:
      ****************************************************************
     c                   callp     ftp_logging(0: *On)

     c                   eval      log1 = open('/tmp/ftplog1':
     c                              O_WRONLY+O_CREAT+O_TRUNC+O_CODEPAGE:
     c                              511: 37)

     c                   eval      log2 = open('/tmp/ftplog2':
     c                              O_WRONLY+O_CREAT+O_TRUNC+O_CODEPAGE:
     c                              511: 37)


      ****************************************************************
      ** connect to FTP server & log in.  We will do this twice
      ** and use 1 session to get a list of files, and another
      ** session to download each file.
      ****************************************************************
     c                   eval      ftp1 = ftp_open('ftp.freebsd.org')
 B01 c                   if        ftp1 < 0
     c                   callp     CompMsg(FTP_errorMsg(0))
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif
     c                   callp     ftp_exitProc(ftp1: FTP_EXTLOG:
     c                                %paddr('LOGGER'): %addr(log1))
     c                   if        ftp_login(ftp1: 'anonymous') < 0
     c                   callp     CompMsg(FTP_errorMsg(0))
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     C                   eval      ftp2 = ftp_open('ftp.freebsd.org')
 B01 c                   if        ftp2 < 0
     c                   callp     CompMsg(FTP_errorMsg(0))
     c                   callp     FTP_quit(ftp1)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif
     c                   callp     ftp_exitProc(ftp2: FTP_EXTLOG:
     c                                %paddr('LOGGER2'): %addr(log2))
     c                   if        ftp_login(ftp2: 'anonymous') < 0
     c                   callp     CompMsg(FTP_errorMsg(0))
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

      ****************************************************************
      ** get a list of files in the pub/FreeBSD/tools dir
      ** (we intend to download all the of these files)
      ****************************************************************
 B01 c                   if        ftp_chdir(ftp1: 'pub/FreeBSD/tools') < 0
     c                   callp     CompMsg(ftp_errorMsg(ftp1))
     c                   callp     ftp_quit(ftp1)
     c                   callp     ftp_quit(ftp2)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     c                   eval      gotfiles = 0
     c                   eval      rc = ftp_lstraw(ftp1: ' ':
     c                                   ftp2: %paddr('DOWNLOAD'))


 B01 c                   if        rc<0
     c                   callp     ftp_errorMsg(ftp1: ErrNum)

 B02 c                   if        ErrNum <> FTP_NOFILE
     c                   callp     CompMsg(FTP_errorMsg(ftp1))
     c                   callp     ftp_quit(ftp1)
     c                   callp     ftp_quit(ftp2)
     c                   eval      *inlr = *on
     c                   return
 E02 c                   endif

 E01 c                   endif


      ****************************************************************
      **  Close FTP session, and end program:
      ****************************************************************
     c                   callp     ftp_quit(ftp1)
     c                   callp     ftp_quit(ftp2)
     c                   callp     close(log1)
     c                   callp     close(log2)

 B01 c                   if        gotfiles > 0
     c                   callp     CompMsg('Success!')
 X01 c                   else
     c                   callp     CompMsg('No files received!')
 E01 c                   endif

     c                   eval      *inlr = *on


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This downloads a single file from the FTP server
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P Download        B
     D Download        PI            10I 0
     D   peFd                        10I 0 value
     D   peName                    8192A   options(*varsize)
     D   peNameLen                   10I 0 value

     D wwRemote        s            256A
     D wwLocal         s            256A

     c                   eval      wwRemote = 'pub/FreeBSD/tools/' +
     c                               %subst(peName: 1: peNameLen)
     c                   eval      wwLocal = '/tmp/' +
     c                               %subst(peName: 1: peNameLen)

     c                   if        FTP_get(peFD: wwRemote: wwLocal) >= 0
     c                   eval      gotfiles = gotfiles + 1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This sends a completion message to the calling program
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P CompMsg         B
     D CompMsg         PI
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

     D wwMsgLen        S             10I 0
     D wwTheKey        S              4A

     c     ' '           checkr    peMsgTxt      wwMsgLen
     c                   callp     SndPgmMsg('CPF9897': 'QCPFMSG   *LIBL':
     c                               peMsgTxt: wwMsgLen: '*COMP':'*PGMBDY':
     c                               1: wwTheKey: dsEC)

     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This writes the details of each session to a log file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P Logger          B
     D Logger          PI
     D   peMsgTxt                   256A   Const
     D   peLogFile                   10I 0

     D size            s             10I 0
     D text            s            258A
     D msg             s             50A

     c                   if        peLogfile <> log1
     c                   eval      msg = 'Logger(): peLogFile is in error'
     c                   dsply                   msg
     c                   endif

     c                   eval      size = %len(%trimr(peMsgTxt))
     c                   eval      text = %subst(peMsgTxt:1:size) + x'0d25'

     c                   callp     write(peLogFile: %addr(text): size+2)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This writes the details of each session to a log file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P Logger2         B
     D Logger2         PI
     D   peMsgTxt                   256A   Const
     D   peLogFile                   10I 0

     D size            s             10I 0
     D text            s            258A
     D msg             s             50A

     c                   if        peLogfile <> log2
     c                   eval      msg = 'Logger2(): peLogFile is in error'
     c                   dsply                   msg
     c                   endif

     c                   eval      size = %len(%trimr(peMsgTxt))
     c                   eval      text = %subst(peMsgTxt:1:size) + x'0d25'
     c                   callp     write(peLogFile: %addr(text): size+2)

     P                 E
