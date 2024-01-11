      /copy VERSION

      *-                                                                            +
      * Copyright (c) 2001-2023 Scott C. Klement                                    +
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
      */

      **  This is the File Transfer Protocol API service program.
      **                                              SCK (began) 09/13/00
      **  To build this:
      **        CRTRPGMOD FTPAPIR4 DBGVIEW(*LIST)
      **        CRTSRVPGM FTPAPIR4 SRCFILE(LIBSOR/QSRVSRC) BNDDIR(QC2LE) +
      **                  ACTGRP(*CALLER)
      **
      ** To bind it into your own programs:
      **        put a D/COPY mylib/QRPGLESRC,FTPAPI_H  in your D-specs
      **        CRTRPGMOD yourprogram
      **        CRTPGM yourprogram BNDSRVPGM(FTPAPIR4)
      **
      ** TODO List:
      **
      **    Create wrappers for use from CL programs, or in the case
      **      of FTP_url_get(), the command-line.
      **
      **    Create wrappers for use from QShell & QShell scripts.
      **
      **    Split this file into smaller modules, it's getting waaaay too
      **    big.  When doing this, it might be a good idea to create
      **    a framework that allows the user to write his own modules for
      **    accessing different types of files, different communications
      **    methods, etc... similar to the way TN5250 does it.
      **
      **    Implement SSL (possibly as one of the modules listed above)
      **
      **    Document the source code more, and more consistently.
      **
      **    Create "how to use" documentation.
      **
      **    Better prototypes for write_data & read_data.  Let them
      **        use parms that show the max size of the buffers, etc.
      **
      **    Set socket options for type of service, etc...
      **
      **   Additional commands to implement:
      **    (from RFC959)
      **   ABORT (ABOR)
      **

     H NOMAIN

      ** Default remote codepage
     D DFT_RMT_CP      C                   CONST(437)
      ** Default local codepage
     D DFT_LOC_CP      C                   CONST(37)
      ** Default local file mode
     D DFT_MODE        C                   CONST(511)

      /copy SOCKET_H
      /copy IFSIO_H
      /copy FTPAPI_H
      /copy RECIO_H
      /copy FTPTCP_H

      *  Operation would have caused the process to block
     D EAGAIN          C                   3406
      *  A connection has already been establish
     D EISCONN         C                   3431
      *  Operation in progress.
     D EINPROGR        C                   3430
      * invalid argument (also used for "connection refused")
     D EINVAL          C                   3021

     D upper           C                   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     D lower           C                   'abcdefghijklmnopqrstuvwxyz'
     D ASCII_LF        C                   x'0A'

     D Reply           PR            10I 0
     D   peSocket                    10I 0 value
     D   peRespMsg                  256A   options(*nopass)

     D RecvLine        PR            10I 0
     D   peSocket                    10I 0
     D   peLine                     512A

     D BufLine         PR            10I 0
     D   peSocket                    10I 0 value
     D   peLine                        *   value
     D   peLength                    10I 0 value
     D   peCrLf                       2A   const

     D SendLine        PR            10I 0
     D   peSocket                    10I 0 value
     D   peData                     261A   const

     D SendLine2       PR            10I 0
     D   peSocket                    10I 0 value
     D   peData                    1005A   const

     D get_block       PR            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value

     D get_byline      PR            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value

     D get_byrec       PR            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value
     D   peRecLen                    10I 0 value

     D put_block       PR            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value

     D TCP_Conn        PR            10I 0
     D   peHost                     256A   Const
     D   pePort                       5U 0 Value
     D   peTimeout                    5U 0 value options(*nopass)

     D portcmd         PR            10I 0
     D   peCtrlSock                  10I 0 value

     D pasvcmd         PR            10I 0
     D   peCtrlSock                  10I 0 value

     D RestartPt       PR            10i 0

     D SetType         PR            10I 0
     D   peSocket                    10I 0 value

     D geterror        PR            10I 0
     D   peErrMsg                   256A   options(*nopass)

     D SetError        PR
     D   peErrNum                    10I 0 value
     D   peErrMsg                    60A   const

     D SetSessionError...
     D                 PR

     D List2Array      PR            10I 0
     D   peDescr                     10I 0 value
     D   peEntry                   8192A   options(*varsize)
     D   peLength                    10I 0 value

     D NumToChar       PR            17A
     D   pePacked                    15S 5 VALUE

     D DiagLog         PR
     D   peMsgTxt                   256A   Const

     D DiagMsg         PR
     D   peMsgTxt                   256A   Const
     D   peSession                   10I 0 value

     D wkLogProc       S               *   procptr inz(*NULL)
     D LogProc         PR                  ExtProc(wkLogProc)
     D   peMsgTxt                   256A   Const
     D   peExtra                       *   value

     D wkStsProc       S               *   procptr inz(*NULL)
     D StatusProc      PR                  ExtProc(wkStsProc)
     D   peBytes                     16P 0 value
     D   peTotBytes                  16P 0 value
     D   peExtra                       *   value

     D OpnFile         PR            10I 0
     D   pePath                     256A   const
     D   peRWFlag                     1A   const
     D   peRdWrProc                    *   procptr
     D   peClosProc                    *   procptr
     D   peSess                      10I 0 value

     D ParsePath       PR            10I 0
     D   pePath                     256A   const
     D   peLibrary                   10A
     D   peObject                    10A
     D   peMember                    10A
     D   peType                      10A

     D fixpath         PR           256A
     D   pePath                     256A   const
     D   peObjType                   10A
     D   peCodePg                    10I 0

     D GetFileAtr      PR            10I 0
     D   peFileName                  10A   const
     D   peFileLib                   10A   const
     D   peFileMbr                   10A   const
     D   peMakeFile                   1A   const
     D   peRtnMbr                    10A
     D   peAttrib                    10A
     D   peSrcFile                    1A

     D getdir          PR           256A

     D S_ISNATIVE      PR             1A
     D    peMode                     10U 0 value

     D S_ISLNK         PR             1A
     D    peMode                     10U 0 value

     D Cmd             PR            10I 0
     D  Command                     200A   const

     D iconv_open      PR            52A   ExtProc('QtqIconvOpen')
     D   ToCode                        *   value
     D   FromCode                      *   value

     D iconv           PR            10I 0 ExtProc('iconv')
     D   Descriptor                  52A   value
     D   p_p_inbuf                     *   value
     D   in_left                     10U 0
     D   p_p_outbuf                    *   value
     D   out_left                    10U 0

     D iconv_clos      PR            10I 0 ExtProc('iconv_close')
     D   descrip                     52A   value

     D InitIConv       PR            10I 0
     D    peFile                      1A   const

     D ToASCII         PR            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value

     D ToEBCDIC        PR            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value

     D ToASCIIF        PR            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value

     D ToEBCDICF       PR            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value

     D SetSessionProc  PR            10I 0
     D   peSessIdx                   10I 0 value
     D   peExitPnt                   10I 0 value
     D   peProc                        *   procptr value
     D   peExtra                       *   value

     D rf_read         PR            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D rf_write        PR            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D src_read        PR            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D src_write       PR            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D rf_close        PR            10I 0
     D   peFilDes                    10I 0 value

     D if_read         PR            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D if_write        PR            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D if_close        PR            10I 0
     D   peFilDes                    10I 0 value

     D rtvJobCp        PR            10I 0

     D lclFileSiz      PR            16P 0
     D   pePath                     256A   const

     D GetTrimLen      PR            16P 0
     D   peBuffer                 32766A   options(*varsize)
     D   peRecEnd                    10I 0 value

     D qusrjobi        PR                         extpgm('QUSRJOBI')
     D   peRcvVar                 32767A          options(*varsize)
     D   peRcvVarLen                 10I 0 const
     D   peFormat                     8A   const
     D   peQJob                      26A   const
     D   peIntJobID                  16A   const
     D   peErrCode                32767A          options(*varsize :
     D                                                    *nopass  )

     D selectSession...
     D                 PR            10I 0
     D   peSocket                    10I 0 const

     D getSessionIdx...
     D                 PR            10I 0
     D   peSocket                    10I 0 const

     D findFreeSession...
     D                 PR            10I 0

     D createSession...
     D                 PR
     D   peSessionIdx                10I 0 const
     D   peSocket                    10I 0 const

     D copySession...
     D                 PR
     D   peFromIdx                   10I 0 const
     D   peToIdx                     10I 0 const

     D cmd_occurSession...
     D                 PR
     D  peSessionIdx                 10I 0 const

     D cmd_resetSession...
     D                 PR

     D initFtpApi...
     D                 PR

      *  "Socket Descriptor" to identify the default session.
      *  The default session is the session that is used in
      *  case that there is no session, e.g. FTP_conn().
     D DFT_SESSION     C                   const(-99)

      *  Default session index.
     D DFT_SESSION_IDX...
     D                 C                   const(1)

      *  Maximum number of session that the FTP API service
      *  program can manage.
     D MAX_SESSION     C                   const(16)

      *  Integer "*NULL" value.
     D INT_NULL        C                   const(-1)

      * The unicode representation of the PIPE character
      * this is a variant character in EBCDIC so we code
      * it in Unicode to ensure proper encoding 
     D UCS_PIPE        C                   const(u'007c')

      *  Indicator to initialize the FTP API service program.
     D wkDoInitFtpApi  S              1A   inz(*ON )

      *  Index to access the "Session" multiple occurence
      *  data structure.
     D wkSessionIdx    S             10I 0 inz(INT_NULL)

      *  Session. A session is used to store the attributes
      *  on a FTP connection .
     D wkSession       DS                  occurs(MAX_SESSION)
     D  wkActive                      1A   INZ(*OFF)
     D  wkErrMsg                     60A   INZ
     D  wkErrNum                     10I 0 INZ
     D  wkSocket                     10I 0 INZ(INT_NULL)
     D  wkBinary                      1A   INZ(*ON)
     D  wkPassive                     1A   INZ(*ON)
     D  wkLineMode                    1A   INZ(*OFF)
     D  wkDebug                       1A   INZ(*ON)
     D  wkUsrXLate                    1A   INZ(*OFF)
     D  wkTrim                        1A   INZ(*OFF)
     D  wkRtnSize                    10I 0 INZ
     D  wkMaxEntry                   10I 0 INZ
     D  wkRF                               like(RFILE)
     D  wk_p_RtnList                   *   INZ(*NULL)
     D  wk_p_RtnPos                    *   INZ(*NULL)
     D  wkRecLen                      5I 0 INZ
     D  wkXLInit                      1A   INZ(*OFF)
     D  wkXLFInit                     1A   INZ(*OFF)
     D  wkXlatHack                    1A   INZ(*OFF)
     D  wkIBuf                    32766A   INZ
     D  wkIBLen                       5I 0 INZ
     D  wkTimeout                    10I 0 INZ
     D  wkTotBytes                   16P 0 INZ
     D  wkSizereq                     1A   INZ(*ON)
     D  wkLogExit                      *   procptr inz(*NULL)
     D  wkStsExit                      *   procptr inz(*NULL)
     D  wkLogExtra                     *   inz(*NULL)
     D  wkStsExtra                     *   inz(*NULL)
     D  wkRestPt                     10u 0 inz
     D  wkEnhSupp                     1N   inz(*ON)
     D  wkTLSMode                    10i 0 inz(FTPS_NONE)
     D  wkTLSCtrl                    10i 0 inz(FTPS_PRIVATE)
     D  wkTLSData                    10i 0 inz(FTPS_PRIVATE)
     D  wkAppId                     128a   varying inz('')
     D  wkKeyPath                   256a   varying inz('')
     D  wkKeyPass                   128A   varying inz('')
     D  wkKeyLabel                  128A   varying inz('')

     D wkLastSocketUsed...
     D                 S             10I 0 INZ(INT_NULL)

     D  wkDsSrcRec     DS                  occurs(MAX_SESSION)
     D   wkDsSrcLin                   6S 2
     D   wkDsSrcDat                   6S 0
     D   wkDsSrcDta                 250A

     D  wkDsToASC      DS                  occurs(MAX_SESSION)
     D   wkICORV_A                   10I 0
     D   wkICOC_A                    10I 0 dim(12)

     D  wkDsToEBC      DS                  occurs(MAX_SESSION)
     D   wkICORV_E                   10I 0
     D   wkICOC_E                    10I 0 dim(12)

     D  wkDsFileASC    DS                  occurs(MAX_SESSION)
     D   wkICORV_AF                  10I 0 inz(-1)
     D   wkICOC_AF                   10I 0 dim(12)

     D  wkDsFileEBC    DS                  occurs(MAX_SESSION)
     D   wkICORV_EF                  10I 0 inz(-1)
     D   wkICOC_EF                   10I 0 dim(12)

     D  wkDsASCII      DS                  occurs(MAX_SESSION)
     D   wkASCII_cp                  10I 0 INZ(DFT_RMT_CP)
     D   wkASCII_ca                  10I 0 INZ(0)
     D   wkASCII_sa                  10I 0 INZ(0)
     D   wkASCII_ss                  10I 0 INZ(1)
     D   wkASCII_il                  10I 0 INZ(0)
     D   wkASCII_eo                  10I 0 INZ(1)
     D   wkASCII_r                    8A   INZ(*allx'00')

     D  wkDsEBCDIC     DS                  occurs(MAX_SESSION)
     D   wkEBCDIC_cp                 10I 0 INZ(DFT_LOC_CP)
     D   wkEBCDIC_ca                 10I 0 INZ(0)
     D   wkEBCDIC_sa                 10I 0 INZ(0)
     D   wkEBCDIC_ss                 10I 0 INZ(1)
     D   wkEBCDIC_il                 10I 0 INZ(0)
     D   wkEBCDIC_eo                 10I 0 INZ(1)
     D   wkEBCDIC_r                   8A   INZ(*allx'00')

     D  wkDsASCIIF     DS                  occurs(MAX_SESSION)
     D   wkASCIIF_cp                 10I 0 INZ(DFT_RMT_CP)
     D   wkASCIIF_ca                 10I 0 INZ(0)
     D   wkASCIIF_sa                 10I 0 INZ(0)
     D   wkASCIIF_ss                 10I 0 INZ(1)
     D   wkASCIIF_il                 10I 0 INZ(0)
     D   wkASCIIF_eo                 10I 0 INZ(1)
     D   wkASCIIF_r                   8A   INZ(*allx'00')

     D  wkDsEBCDICF    DS                  occurs(MAX_SESSION)
     D   wkEBCDICF_cp                10I 0 INZ(DFT_LOC_CP)
     D   wkEBCDICF_ca                10I 0 INZ(0)
     D   wkEBCDICF_sa                10I 0 INZ(0)
     D   wkEBCDICF_ss                10I 0 INZ(1)
     D   wkEBCDICF_il                10I 0 INZ(0)
     D   wkEBCDICF_eo                10I 0 INZ(1)
     D   wkEBCDICF_r                  8A   INZ(*allx'00')

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_Conn:  Connect and log-in to an FTP server.
      *
      *     peHost = Host name of FTP server
      *     peUser = user name of FTP server (or "anonymous")
      *     pePass = Password to use on FTP server (or "user@host")
      *     pePort = (optional) port to connect to.  If not supplied
      *              the value of the constant FTP_PORT will be used.
      *  peTimeout = (optional) number of seconds to wait for data before
      *              assuming the connection is dead and giving up.
      *              if not given, or set to 0, we wait indefinitely.
      *     peAcct = (optional) account (if required by server)
      *              if not given, a blank account name will be tried
      *              if the server requests an account.
      *
      * Returns a new FTPAPI session descriptor upon success,
      *            or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_Conn        B                   EXPORT
     D FTP_Conn        PI            10I 0
     D   peHost                     256A   const
     D   peUser                      32A   const
     D   pePass                      64A   const
     D   pePort                      10I 0 value options(*nopass)
     D   peTimeout                   10I 0 value options(*nopass)
     D   peAcct                      32A   const options(*nopass)

     D wwPort          S             10I 0 inz(-1)
     D wwSock          S             10I 0 inz(-1)
     D wwAcct          S             32A   inz('*DEFAULT')
     D wwTimeout       S             10I 0 inz(-1)

      **************************************************************
      * Optional parms:  We set these to values that mean "not
      *      available, use defaults" in the D-specs above, and
      *      only change that if the user supplied a value.
      **************************************************************
     c                   if        %parms >= 4
     c                   eval      wwPort = pePort
     c                   endif

     c                   if        %parms >= 5
     c                   eval      wwTimeout = peTimeout
     c                   endif

     c                   if        %parms >= 6
     c                   eval      wwAcct = peAcct
     c                   endif

      **************************************************************
      * Call FTP_open() to connect to an FTP server
      **************************************************************
     c                   eval      wwSock = FTP_open(peHost:
     c                                               wwPort:
     c                                               wwTimeout)
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

      **************************************************************
      * Call FTP_LoginLong() To log the user in to the server.
      **************************************************************
     c                   if        FTP_loginLong( wwSock
     c                                          : peUser
     c                                          : pePass
     c                                          : wwAcct ) < 0
     c                   callp     ftptcp_close(wwSock)
     c                   callp     cmd_resetSession
     c                   return    -1
     c                   endif

     c                   return    wwSock
     P                 E

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_ConnLong:  Connect and log-in to an FTP server
      *                  w/long user, password and acct names
      *
      *     peHost = Host name of FTP server
      *     peUser = user name of FTP server (or "anonymous")
      *     pePass = Password to use on FTP server (or "user@host")
      *     pePort = (optional) port to connect to.  If not supplied
      *              the value of the constant FTP_PORT will be used.
      *  peTimeout = (optional) number of seconds to wait for data before
      *              assuming the connection is dead and giving up.
      *              if not given, or set to 0, we wait indefinitely.
      *     peAcct = (optional) account (if required by server)
      *              if not given, a blank account name will be tried
      *              if the server requests an account.
      *
      * Returns a new FTPAPI session descriptor upon success,
      *            or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_ConnLong    B                   EXPORT
     D FTP_ConnLong    PI            10I 0
     D   peHost                     256A   const
     D   peUser                    1000A   const
     D   pePass                    1000A   const
     D   pePort                      10I 0 value options(*nopass)
     D   peTimeout                   10I 0 value options(*nopass)
     D   peAcct                    1000A   const options(*nopass)

     D wwPort          S             10I 0 inz(-1)
     D wwSock          S             10I 0 inz(-1)
     D wwAcct          S           1000A   inz('*DEFAULT')
     D wwTimeout       S             10I 0 inz(-1)

      **************************************************************
      * Optional parms:  We set these to values that mean "not
      *      available, use defaults" in the D-specs above, and
      *      only change that if the user supplied a value.
      **************************************************************
     c                   if        %parms >= 4
     c                   eval      wwPort = pePort
     c                   endif

     c                   if        %parms >= 5
     c                   eval      wwTimeout = peTimeout
     c                   endif

     c                   if        %parms >= 6
     c                   eval      wwAcct = peAcct
     c                   endif

      **************************************************************
      * Call FTP_open() to connect to an FTP server
      **************************************************************
     c                   eval      wwSock = FTP_open(peHost:
     c                                               wwPort:
     c                                               wwTimeout)
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

      **************************************************************
      * Call FTP_LoginLong() To log the user in to the server.
      **************************************************************
     c                   if        FTP_loginLong( wwSock
     c                                          : peUser
     c                                          : pePass
     c                                          : wwAcct ) < 0
     c                   callp     ftptcp_close(wwSock)
     c                   callp     cmd_resetSession
     c                   return    -1
     c                   endif

     c                   return    wwSock
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Change directory on FTP server
      *
      *       input: peSession = descriptor returned by ftp_conn
      *              peNewDir  = directory to change to.
      *
      *  returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_chdir       B                   EXPORT
     D FTP_chdir       PI            10I 0
     D   peSession                   10I 0 value
     D   peNewDir                   256A   const

     D wwReply         S              5I 0
     D wwRepMsg        S            256A

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        peNewDir = '..'
     c                   if        SendLine(wkSocket: 'CDUP') < 0
     c                   return    -1
     c                   endif
     c                   else
     c                   if        SendLine(wkSocket: 'CWD '+peNewDir)<0
     c                   return    -1
     c                   endif
     c                   endif

     c                   eval      wwReply = Reply(peSession: wwRepMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply < 200
     c                               or wwReply > 299
     c                   callp     SetError(FTP_ERRCWD: wwRepMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_binaryMode
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_binary:  Set file transfer mode to/from binary
      *
      *    peSetting   = Setting of binary  *ON = Turn binary mode on
      *                                    *OFF = Turn binary mode off.
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_Binary      B                   EXPORT
     D FTP_Binary      PI            10I 0
     D   peSetting                    1A   const

     D i               s             10I 0

     c                   for       i = 1 to MAX_SESSION
     c                   callp     FTP_binaryMode(i: peSetting)
     c                   endfor

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_binaryMode:  Set file transfer mode to/from binary
      *
      *    peSession = Session descriptor returned by FTP_conn
      *    peSetting = Setting of binary  *ON = Turn binary mode on
      *                                  *OFF = Turn binary mode off.
      *
      *    Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_binaryMode  B                   EXPORT
     D FTP_binaryMode  PI            10I 0
     D   peSession                   10I 0 value
     D   peSetting                    1A   const

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        peSetting <> *ON
     c                               and peSetting<>*OFF
     c                   callp     SetError(FTP_PESETT: 'Binary mode ' +
     c                               ' setting must be *ON or *OFF')
     c                   return    -1
     c                   endif

     c                   eval      wkBinary = peSetting
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_lineMode
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_LinMod:  Set/Unset line-at-a-time file transfer mode
      *
      *    peSetting = Setting of line mode  *ON = Turn line mode on
      *                                     *OFF = Turn line mode off.
      *                                        R = Use "record mode"
      *     peRecLen = (optional) Size of each record (if peSetting='R')
      *                [you do not need to specify a record length unless]
      *                [you're calling FTP_getraw().                     ]
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_LinMod      B                   EXPORT
     D FTP_LinMod      PI            10I 0
     D   peSetting                    1A   const
     D   peRecLen                     5I 0 value options(*nopass)

     D i               s             10I 0

     c                   for       i = 1 to MAX_SESSION

     c                   if        %parms >= 2
     c                   callp     FTP_lineMode(i: peSetting: peReclen)
     c                   else
     c                   callp     FTP_lineMode(i: peSetting)
     c                   endif

     c                   endfor

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_lineMode:    Set/Unset line-at-a-time file transfer mode
      *
      *    peSession = session descriptor returned by FTP_conn
      *    peSetting = Setting of line mode  *ON = Turn line mode on
      *                                     *OFF = Turn line mode off.
      *                                        R = Use "record mode"
      *     peRecLen = (optional) Size of each record (if peSetting='R')
      *                [you do not need to specify a record length unless]
      *                [you're calling FTP_getraw().                     ]
      *
      *    Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_lineMode    B                   EXPORT
     D FTP_lineMode    PI            10I 0
     D   peSession                   10I 0 value
     D   peSetting                    1A   const
     D   peRecLen                     5I 0 value options(*nopass)

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        peSetting <> *ON
     c                               and peSetting<>*OFF
     C                               and peSetting<>'R'
     c                   callp     SetError(FTP_PESETT: 'Line mode ' +
     c                               ' setting must be *ON,*OFF or ''R'' ')
     c                   return    -1
     c                   endif

     c                   if        %parms >= 3
     c                   eval      wkRecLen = peRecLen
     c                   endif

     c                   eval      wkLineMode = peSetting
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_passiveMode
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_passiv:   Turn passive mode transfers on or off
      *
      *     peSetting = passive mode setting.   *ON = Turn passive on
      *                                        *OFF = Turn passive off
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_passiv      B                   EXPORT
     D FTP_passiv      PI            10I 0
     D   peSetting                    1A   const

     D i               s             10I 0

     c                   for       i = 1 to MAX_SESSION
     c                   callp     FTP_passiveMode(i: peSetting)
     c                   endfor

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_passiveMode: Turn passive mode transfers on or off
      *
      *    peSession = Session descriptor returned by FTP_conn
      *    peSetting = passive mode setting.   *ON = Turn passive on
      *                                       *OFF = Turn passive off
      *
      *    Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_passiveMode...
     P                 B                                  EXPORT
     D FTP_passiveMode...
     D                 PI            10I 0
     D   peSession                   10I 0 value
     D   peSetting                    1A   const

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        peSetting <> *ON
     c                               and peSetting <> *OFF
     c                   callp     SetError(FTP_PESETT: 'Passive mode' +
     c                               ' must be *ON or *OFF ')
     c                   return    -1
     c                   endif

     c                   eval      wkPassive = peSetting
     c                   eval      wkEnhSupp = *on
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_logging
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_log:  Turn on/off logging of session to joblog
      *
      *    peSetting = Setting of logging *ON = Turn logging mode on
      *                                  *OFF = Turn logging mode off.
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_Log         B                   EXPORT
     D FTP_Log         PI            10I 0
     D   peSetting                    1A   const

     D i               s             10I 0

     c                   for       i = 1 to MAX_SESSION
     c                   callp     FTP_logging(i: peSetting)
     c                   endfor

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_logging:     Turn on/off logging of session to joblog
      *
      *    peSession = Session descriptor returned by FTP_conn
      *    peSetting = Setting of logging *ON = Turn logging mode on
      *                                  *OFF = Turn logging mode off.
      *
      *    Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_logging     B                   EXPORT
     D FTP_logging     PI            10I 0
     D   peSession                   10I 0 value
     D   peSetting                    1A   const

     D savSessionIdx   S                   like(wkSessionIdx)

     c                   callp     initFtpApi

     c                   if        peSession <= 0
     c                   eval      savSessionIdx = wkSessionIdx
     c                   callp     cmd_occurSession(DFT_SESSION_IDX)
     c                   else
     c                   eval      savSessionIdx = -1
     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif
     c                   endif

     c                   if        peSetting <> *ON
     c                               and peSetting<>*OFF
     c                   callp     SetError(FTP_PESETT: 'Logging mode ' +
     c                               ' setting must be *ON or *OFF')
     c                   if        savSessionIdx <> -1
     c                   callp     cmd_occurSession(savSessionIdx)
     c                   endif
     c                   return    -1
     c                   endif

     c                   eval      wkDebug = peSetting
     c                   if        savSessionIdx <> -1
     c                   callp     cmd_occurSession(savSessionIdx)
     c                   endif
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_rename:   Rename a file on an FTP server
      *
      *     peSession = Session descriptor returned by FTP_conn
      *     peOldName = Original File Name
      *     peNewName = New name to assign.
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_rename      B                   EXPORT
     D FTP_rename      PI            10I 0
     D   peSession                   10I 0 value
     D   peOldName                  256A   const
     D   peNewName                  256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Here's the name we want to RENAME FROM (RNFR)
     c                   if        SendLine(wkSocket:'RNFR ' + peOldName)<0
     c                   return    -1
     c                   endif

      * 350 File exists, ready for destination name
     c                   eval      wwReply = Reply(peSession:wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 350
     c                   callp     SetError(FTP_RNFERR: wwMsg)
     c                   return    -1
     c                   endif

      * Here's the name we want to RENAME TO (RNTO)
     c                   if        SendLine(wkSocket:'RNTO ' + peNewName)<0
     c                   return    -1
     c                   endif

      * 250 Rename successful.
     c                   eval      wwReply = Reply(peSession:wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_RNTERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_delete:   Delete a file on the FTP server
      *
      *     peSession = Session descriptor returned by FTP_Conn
      *        peFile = File to delete
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_delete      B                   EXPORT
     D FTP_delete      PI            10I 0
     D   peSession                   10I 0 value
     D   peFile                     256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Send delete command to server:
     c                   if        SendLine(wkSocket: 'DELE ' + peFile)<0
     c                   return    -1
     c                   endif

      * 250 DELE command succesful.
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_DELERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_noop:  keep connection alive
      *
      *     peSession = Session descriptor returned by FTP_Conn
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_noop        B                   EXPORT
     D FTP_noop        PI            10I 0
     D   peSession                   10I 0 value

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Send NOOP command to server:
     c                   if        SendLine(wkSocket: 'NOOP')<0
     c                   return    -1
     c                   endif

      * 250 NOOP command succesful.
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_NOOPERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_rmdir:  Delete a directory from an FTP server
      *
      *     peSession = Session descriptor returned by FTP_Conn
      *     peDirName = directory to delete
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_rmdir       B                   EXPORT
     D FTP_rmdir       PI            10I 0
     D   peSession                   10I 0 value
     D   peDirName                  256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send remove directory command:
     c                   if        SendLine(wkSocket:'RMD ' + peDirName)<0
     c                   return    -1
     c                   endif

      * 250 RMD command succesful.
     c                   eval      wwReply = Reply(peSession:wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_RMDERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_mkdir:  Create a directory on the FTP server
      *
      *     peSession = Session descriptor returned by FTP_Conn
      *     peDirName = directory to create
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_mkdir       B                   EXPORT
     D FTP_mkdir       PI            10I 0
     D   peSession                   10I 0 value
     D   peDirName                  256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send make directory command:
     c                   if        SendLine(wkSocket: 'MKD ' + peDirName)<0
     c                   return    -1
     c                   endif

      * 257 MKD command succesful.
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 257
     c                   callp     SetError(FTP_MKDERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_rtvcwd:  Retrieve the current working directory name
      *         from the server.
      *
      *     peSession = Session descriptor returned by FTP_Conn
      *
      *     Returns the directory name, or *BLANKS upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_rtvcwd      B                   EXPORT
     D FTP_rtvcwd      PI           256A
     D   peSession                   10I 0 value

     D wwMsg           S            256A
     D wwDir           S            256A
     D wwMsgLen        S              5I 0
     D wwLen           S              5I 0
     D wwPos           S              5I 0
     D wwState         S              5I 0
     D wwCh            S              1A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    *blanks
     c                   endif

      * send print working directory command:
     c                   if        SendLine(wkSocket: 'PWD')<0
     c                   return    *blanks
     c                   endif

      * 257 "/directory/on/server" is current directory.
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    *blanks
     c                   endif
     c                   if        wwReply <> 257
     c                   callp     SetError(FTP_PWDERR: wwMsg)
     c                   return    *blanks
     c                   endif

      * This state-machine parses the reply to PWD, extracting
      *  the actual directory name.
     c                   eval      wwDir = *blanks
     c                   eval      wwLen = 0
     c                   eval      wwState = 0
     C     ' '           checkr    wwMsg         wwMsgLen

     c                   do        wwMsgLen      wwPos
     c                   eval      wwCh = %subst(wwMsg:wwPos:1)
     c                   select
     c                   when      wwState = 0
     c                   if        wwCh = '"'
     c                   eval      wwState = 1
     c                   endif
     c                   when      wwState = 1
     c                   if        wwCh = '"'
     c                   eval      wwState = 2
     c                   else
     c                   eval      wwLen = wwLen + 1
     c                   eval      %subst(wwDir:wwLen:1) = wwCh
     c                   endif
     c                   when      wwState = 2
     c                   if        wwCh = '"'
     c                   eval      wwLen = wwLen + 1
     c                   eval      %subst(wwDir:wwLen:1) = '"'
     c                   eval      wwState = 1
     c                   else
     c                   leave
     c                   endif
     c                   endsl
     c                   enddo

      * If we got something, return it... otherwise error.
     c                   if        wwLen < 1
     c                   callp     SetError(FTP_DIRPRS: 'Unable to parse -
     c                             directory name from PWD response')
     c                   return    *blanks
     c                   endif

     c                   return    wwDir
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_quote:  Send a raw, unadulterated, command to the
      *         FTP server, and receive the reply.
      *
      *    peSession = Session descriptor returned by FTP_conn
      *    peCommand = command to send to server.
      *
      *     Returns the FTP server's reply code,
      *             or -1 upon a socket/network error.
      *
      *  This procedure will not attempt to determine if the quoted
      *  command was successful.  You'll need to check the FTP
      *  server's reply code to see if you get what you expect to.
      *
      *  The message text accompanying the reply code will be available
      *  by calling the FTP_ERROR routine.  The error number returned
      *  for the reply code will always be FTP_QTEMSG
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_quote       B                   EXPORT
     D FTP_quote       PI            10I 0
     D   peSession                   10I 0 value
     D   peCommand                  256A   const

     D wwReply         S             10I 0
     D wwMsg           S            256A

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Make sure we've got something to send.
     c                   if        peCommand = *blanks
     c                   callp     SetError(FTP_NOCMD: 'You must supply ' +
     c                              'a command.')
     c                   return    -1
     c                   endif

      * send whatever command was given to us:
     c                   if        SendLine(wkSocket: peCommand) < 0
     c                   return    -1
     c                   endif

      * We don't know what responses are valid...
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   callp     SetError(FTP_QTEMSG: wwMsg)

     c                   return    wwReply
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_size:  Get the size of a file on an FTP server.
      *
      * NOTE: This is not part of the official FTP standard, and
      *       is not supported by many FTP servers, INCLUDING THE
      *       IBM i FTP SERVER.
      *
      *    peSession = Session descriptor returned by FTP_conn
      *       peFile = file to look up the size of
      *
      *     Returns -1 upon error, or the size of the file upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_size        B                   EXPORT
     D FTP_size        PI            16P 0
     D   peSession                   10I 0 value
     D   peFile                     256A   const

     D wwMsg           S            256A
     D wwLen           S             10I 0
     D wwSize16        S             16A
     D wwRtnSize       S             16P 0
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Return if Size function switched off                                    LM
     c                   if        wkSizereq = *off                             LM
     c                   return    -1                                           LM
     c                   endif                                                  LM

      * Size can differ between ASCII and BINARY transfers, so make
      * sure we're in the correct mode before requesting SIZE
     c                   if        SetType(wkSocket) < 0
     c                   return    -1
     c                   endif

      * send size command:
     c                   if        SendLine(wkSocket: 'SIZE ' + peFile)<0
     c                   return    -1
     c                   endif

      * 213 <byte size>
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 213
     c                   callp     SetError(FTP_SIZERR: wwMsg)
     c                   return    -1
     c                   endif

      * Get the size from the returned message
     c                   eval      wwMsg = %trim(wwMsg)
     c     ' '           checkr    wwMsg         wwLen
     c                   if        wwLen < 16
     c                   eval      wwMsg = %subst('0000000000000000':
     c                                   1:16-wwLen) + wwMsg
     c                   endif
     c                   if        wwLen > 16
     c                   eval      wwMsg = %subst(wwMsg:wwLen-15: 16)
     c                   endif
     c                   movel     wwMsg         wwSize16
     c                   testn                   wwSize16             10
     c                   if        *in10 = *off
     c                   callp     SetError(FTP_SIZPRS: 'Unable to parse '+
     c                               ' reply to SIZE command.')
     c                   return    -1
     c                   endif

      * return size
     c                   move      wwSize16      wwRtnSize
     c                   return    wwRtnSize
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_mtime: Get modification time of a file on an FTP server
      *
      * NOTE: This is not part of the official FTP standard, and
      *       is not supported by many FTP servers, INCLUDING THE
      *       IBM i FTP SERVER.
      *
      *    peSession = Session descriptor returned by FTP_conn
      *       peFile = file to look up the size of
      *    peModTime = Modification time returned by server
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_mtime       B                   EXPORT
     D FTP_mtime       PI            16P 0
     D   peSession                   10I 0 value
     D   peFile                     256A   const
     D   peModTime                     Z

     D wwMsg           S            256A
     D wwLen           S             10I 0
     D wwTemp14        S             14A
     D wwISO           S              8  0
     D wwHMS           S              6  0
     D wwDateFld       S               D
     D wwTimeFld       S               T
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send mod time command:
     c                   if        SendLine(wkSocket: 'MDTM ' + peFile)<0
     c                   return    -1
     c                   endif

      * 213 YYYYMMDDHHMMSS
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 213
     c                   callp     SetError(FTP_MODERR: wwMsg)
     c                   return    -1
     c                   endif

      * This extracts the date & time from the returned value:
     c                   eval      wwMsg = %trim(wwMsg)
     c     ' '           checkr    wwMsg         wwLen
     c                   if        wwLen <> 14
     c                   callp     SetError(FTP_MODPRS: 'Mod time format '+
     c                               'not recognized ')
     c                   return    -1
     c                   endif

     c                   eval      wwTemp14 = wwMsg
     c                   testn                   wwTemp14             10
     c                   if        *in10 = *off
     c                   callp     SetError(FTP_MODPRS: 'Mod time format '+
     c                               'not recognized ')
     c                   return    -1
     c                   endif

      * This tests the date for validity
     c                   movel     wwTemp14      wwISO
     c     *ISO          test(D)                 wwISO                  10
     c                   if        *in10 = *on
     c                   callp     SetError(FTP_MODPRS: 'Mod time format '+
     c                               'not recognized ')
     c                   return    -1
     c                   endif

      * This tests the time for validity
     c                   move      wwTemp14      wwHMS
     c     *HMS          test(T)                 wwHMS                  10
     c                   if        *in10 = *on
     c                   callp     SetError(FTP_MODPRS: 'Mod time format '+
     c                               'not recognized ')
     c                   return    -1
     c                   endif

      * return timestamp
     c                   eval      peModTime = z'0001-01-01-00.00.00.000000'
     c     *ISO          move      wwISO         wwDateFld
     c                   move      wwDateFld     peModTime
     c     *HMS          move      wwHMS         wwTimeFld
     c                   move      wwTimeFld     peModTime

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_AddPfm:  Add member to a physical file (ADDPFM)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSession = Session descriptor returned by FTP_conn
      *       peParms = String of parms to the ADDPFM command on
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_AddPfm      B                   EXPORT
     D FTP_AddPfm      PI            16P 0
     D   peSession                   10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send add member command:
     c                   if        SendLine(wkSocket: 'ADDM ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Member Added.
     c                   eval      wwReply = Reply(peSession: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_ADMERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_AddPvm:  Add variable length file member (ADDPVLM)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *      peParms = String of parms to the ADDPVLM command
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_AddPvm      B                   EXPORT
     D FTP_AddPvm      PI            16P 0
     D   peSocket                    10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send add variable length member command:
     c                   if        SendLine(wkSocket: 'ADDV ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Member Added.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_ADVERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_CrtLib:  Create Library (CRTLIB)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *      peParms = String of parms to the CRTLIB command
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_CrtLib      B                   EXPORT
     D FTP_CrtLib      PI            16P 0
     D   peSocket                    10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send create library command:
     c                   if        SendLine(wkSocket: 'CRTL ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Member Added.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_CRLERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_CrtPf:  Create Physical File (CRTPF)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *      peParms = String of parms to the CRTPF command
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_CrtPF       B                   EXPORT
     D FTP_CrtPF       PI            16P 0
     D   peSocket                    10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send create PF command:
     c                   if        SendLine(wkSocket: 'CRTP ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Success.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_CRPERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_CrtSrc:  Create Source Physical File (CRTSRCPF)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *      peParms = String of parms to the CRTSRCPF command
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_CrtSrc      B                   EXPORT
     D FTP_CrtSrc      PI            16P 0
     D   peSocket                    10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send create src pf command:
     c                   if        SendLine(wkSocket: 'CRTS ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Success.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_CRSERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_DltF:  Delete File (DLTF)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *      peParms = String of parms to the DLTF command
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_DltF        B                   EXPORT
     D FTP_DltF        PI            16P 0
     D   peSocket                    10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send delete file command:
     c                   if        SendLine(wkSocket: 'DLTF ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Success.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_DLFERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_DltLib:  Delete Library (DLTLIB)
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *      peParms = String of parms to the DLTF command
      *                 on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_DltLib      B                   EXPORT
     D FTP_DltLib      PI            16P 0
     D   peSocket                    10I 0 value
     D   peParms                    256A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send delete lib command:
     c                   if        SendLine(wkSocket: 'DLTL ' + peParms)<0
     c                   return    -1
     c                   endif

      * 250 Success.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_DLLERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_RmtCmd:  Run a command on the IBM i
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      * NOTE: Commands executed this way may be run in batch as
      *       a seperate job, and may not complete immediately.
      *
      *     peSocket = socket number returned by FTP_conn
      *    peCommand = Command to run on the IBM i.
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_RmtCmd      B                   EXPORT
     D FTP_RmtCmd      PI            16P 0
     D   peSocket                    10I 0 value
     D   peCommand                 1000A   const

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send remote command:
     c                   if        SendLine2(wkSocket: 'RCMD '+peCommand)<0
     c                   return    -1
     c                   endif

      * 250 Success.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_RCMERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_NamFmt:  Set the IBM i's Name Format (NAMEFMT) parm
      *
      * NOTE: This command is specific to the IBM i FTP server
      *       and may not work on other systems.
      *
      *     peSocket = socket number returned by FTP_conn
      *     peFormat = Name Fmt  0=MYLIB/MYFILE.MYMBR
      *                          1=/Filesys/MYLIB.LIB/MYFILE.FILE/MYMBR.MBR
      *
      *     Returns -1 upon error, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_NamFmt      B                   EXPORT
     D FTP_NamFmt      PI            16P 0
     D   peSocket                    10I 0 value
     D   peFormat                     5I 0 value

     D wwMsg           S            256A
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * send namefmt command:
     c                   if        SendLine(wkSocket: 'SITE NAMEFMT ' +
     c                                  %trim(NumToChar(peFormat))) < 0
     c                   return    -1
     c                   endif

      * 250 Success.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 250
     c                   callp     SetError(FTP_NMFERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_dir   Gets a listing of files in a directory on the
      *               FTP server.
      *
      *         peSocket = descriptor returned by ftp_conn proc.
      *      pePathArg   = Argument to pass to the LIST command on
      *                    the FTP server.  for example, it might be
      *                    something like '*.txt' or '/windows/*.exe'
      *     peMaxEntry   = max number of directory entries to return
      *      peRtnList   = pointer to an array.  Each line of the directory
      *                    returned by the server will be placed into this
      *                    array, up to the max number of entries (above)
      *      peRtnSize   = Actual number of array elements that could be
      *                    returned.  (can be larger than peMaxEntry if
      *                    your array wasnt large enough)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_dir         B                   EXPORT
     D FTP_dir         PI            10I 0
     D   peSocket                    10I 0 value
     D   pePathArg                  256A   const
     D   peMaxEntry                  10I 0 value
     D   peRtnList                     *   value
     D   peRtnSize                   10I 0

     D wwRC            S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      wkRtnSize = 0
     c                   eval      wkMaxEntry = peMaxEntry
     c                   eval      wk_p_RtnList = peRtnList
     c                   eval      wk_p_RtnPos  = wk_p_RtnList

     c                   eval      wwRC = FTP_dirraw(peSocket: pePathArg:
     c                                      -1: %paddr('LIST2ARRAY'))
     c                   if        wwRC < 0
     c                   return    -1
     c                   endif

     c                   eval      peRtnSize = wkRtnSize
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_dirraw:  Gets a listing of files in a directory on the
      *               FTP server.
      *
      *         peSocket = descriptor returned by ftp_conn proc.
      *      pePathArg   = Argument to pass to the LIST command on
      *                    the FTP server.  for example, it might be
      *                    something like '*.txt' or '/windows/*.exe'
      *        peDescr   = descriptor to pass to peFunction below
      *     peFunction   = procedure to call for each directory entry
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_dirraw      B                   EXPORT
     D FTP_dirraw      PI            10I 0
     D   peSocket                    10I 0 value
     D   pePathArg                  256A   const
     D   peDescr                     10I 0 value
     D   peFunction                    *   PROCPTR value

     D wwSock          S             10I 0
     D wwMsg           S            256A
     D wwReply         S             10I 0
     D wwBinary        S              1A

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      wwBinary = wkBinary
     c                   eval      wkBinary = *OFF
     c                   if        SetType(wkSocket) < 0
     c                   return    -1
     c                   endif
     c                   eval      wkBinary = wwBinary

     c                   if        wkPassive = *On
     c                   eval      wwSock = pasvcmd(peSocket)
     c                   else
     c                   eval      wwSock = portcmd(peSocket)
     c                   endif
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

      * Tell server to do a directory list
     c                   if        SendLine(wkSocket: 'LIST ' + pePathArg)<0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * 550 No Such File or Directory...
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
     c                   if        wwReply = 550
     c                   callp     SetError(FTP_NOFILE: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
      * 150 Starting transfer now
     c                   if        wwReply <> 150
     c                               and wwReply <> 125
     c                   callp     SetError(FTP_BADLST: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * Do the actual file transfer
     c                   eval      wkXlatHack = *on
     c                   eval      wkBinary = *OFF
     c                   if        get_byline(wwSock: peDescr: peFunction)<0
     c                   eval      wkXlatHack = *off
     c                   eval      wkBinary = wwBinary
     c                   return    -1
     c                   endif
     c                   eval      wkXlatHack = *off
     c                   eval      wkBinary = wwBinary

      * 226 Transfer Complete.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply<>226 and wwReply<>250
     c                   callp     SetError(FTP_XFRERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_list: Gets a listing of files in a directory on the
      *               FTP server. (filenames only)
      *
      *         peSocket = descriptor returned by ftp_conn proc.
      *      pePathArg   = Argument to pass to the NLST command on
      *                    the FTP server.  for example, it might be
      *                    something like '*.txt' or '/windows/*.exe'
      *     peMaxEntry   = max number of directory entries to return
      *      peRtnList   = pointer to an array.  Each filename in the dir
      *                    returned by the server will be placed into this
      *                    array, up to the max number of entries (above)
      *      peRtnSize   = Actual number of array elements that could be
      *                    returned.  (can be larger than peMaxEntry if
      *                    your array wasnt large enough)
      *
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_list        B                   EXPORT
     D FTP_list        PI            10I 0
     D   peSocket                    10I 0 value
     D   pePathArg                  256A   const
     D   peMaxEntry                  10I 0 value
     D   peRtnList                     *   value
     D   peRtnSize                   10I 0

     D wwRC            S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      wkRtnSize = 0
     c                   eval      wkMaxEntry = peMaxEntry
     c                   eval      wk_p_RtnList = peRtnList
     c                   eval      wk_p_RtnPos  = wk_p_RtnList

     c                   eval      wwRC = FTP_lstraw(peSocket: pePathArg:
     c                                      -1: %paddr('LIST2ARRAY'))
     c                   if        wwRC < 0
     c                   return    -1
     c                   endif

     c                   eval      peRtnSize = wkRtnSize
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_lstraw: Gets a listing of files in a directory on the
      *               FTP server. (filenames only)
      *
      *         peSocket = descriptor returned by ftp_conn proc.
      *      pePathArg   = Argument to pass to the LIST command on
      *                    the FTP server.  for example, it might be
      *                    something like '*.txt' or '/windows/*.exe'
      *        peDescr   = descriptor to pass to peFunction below
      *     peFunction   = Procedure to send each line of the resulting
      *                    listing to.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_lstraw      B                   EXPORT
     D FTP_lstraw      PI            10I 0
     D   peSocket                    10I 0 value
     D   pePathArg                  256A   const
     D   peDescr                     10I 0 value
     D   peFunction                    *   PROCPTR value

     D wwSock          S             10I 0
     D wwMsg           S            256A
     D wwReply         S             10I 0
     D wwBinary        S              1A

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      wwBinary = wkBinary
     c                   eval      wkBinary = *OFF
     c                   if        SetType(wkSocket) < 0
     c                   return    -1
     c                   endif
     c                   eval      wkBinary = wwBinary

     c                   if        wkPassive = *On
     c                   eval      wwSock = pasvcmd(peSocket)
     c                   else
     c                   eval      wwSock = portcmd(peSocket)
     c                   endif
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

      * Tell server to do a directory list
     c                   if        SendLine(wkSocket: 'NLST ' + pePathArg)<0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * 550 No Such File or Directory...
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
     c                   if        wwReply = 550
     c                   callp     SetError(FTP_NOFILE: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
      * 150 Starting transfer now
     c                   if        wwReply <> 150
     c                               and wwReply <> 125
     c                   callp     SetError(FTP_BADNLS: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * Do the actual file transfer
     c                   eval      wkXlatHack = *on
     c                   eval      wkBinary = *OFF
     c                   if        get_byline(wwSock: peDescr: peFunction)<0
     c                   eval      wkXlatHack = *off
     c                   eval      wkBinary = wwBinary
     c                   return    -1
     c                   endif
     c                   eval      wkBinary = wwBinary
     c                   eval      wkXlatHack = *off

      * 226 Transfer Complete.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply<>226 and wwReply<>250
     c                   callp     SetError(FTP_XFRERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_Get(): Retrieve a file from FTP server
      *
      *  peSocket = Session ID returned by FTP_open / FTP_Conn
      *  peRemote = filename to request from FTP server.
      *   peLocal = filename to store file on local server.
      *             (MUST BE IN IFS-STYLE FORMAT = NAMEFMT 1)
      *             If not passed, the peRemote filename is used.
      *
      *   returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_get         B                   EXPORT
     D FTP_get         PI            10I 0
     D   peSocket                    10I 0 value
     D   peRemote                   256A   const
     D   peLocal                    256A   const options(*nopass)

     d p_close         S               *   procptr
     D CloseMe         PR            10I 0 ExtProc(p_close)
     D   descriptor                  10I 0 value

     D wwLocal         S            257A
     D wwErrMsg        S            256A
     D wwFD            S             10I 0
     D wwRC            S             10I 0
     D p_write         S               *   procptr
     D wwSaveDbg       s                   like(wkDebug)
     D wwSaveMode      s              1A

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * figure out pathname
     c                   if        %parms >= 3
     c                   eval      wwLocal = peLocal
     c                   else
     c                   eval      wwLocal = peRemote
     c                   endif

      * get total number of bytes to receive
      *
      * HACK: I'm not logging this because it fails most of the
      *       time.  The failure doesn't matter (we ignore it)
      *       but the message being in the log confuses people.
     c                   eval      wwSaveDbg = wkDebug
     c                   eval      wkDebug = *Off
     c                   eval      wkTotBytes = FTP_size(peSocket :
     c                                                   peRemote )
     c                   eval      wkDebug = wwSaveDbg

      * open the file to retrieve
     c                   eval      wwSaveMode = wkLineMode
     c                   eval      wwFD = OpnFile( wwLocal
     C                                           : 'W'
     C                                           : p_write
     C                                           : p_close
     C                                           : peSocket )
     c                   if        wwFD < 0
     c                   eval      wkLineMode = wwSaveMode
     c                   return    -1
     c                   endif

      * download into the file...
     c                   eval      wwRC = FTP_getraw(peSocket: peRemote:
     c                                     wwFD: p_write)
     c                   if        wwRC < 0
     c                   eval      wkLineMode = wwSaveMode
     c                   callp     CloseMe(wwFD)
     c                   return    -1
     c                   endif

      * we're done... woohoo
     c                   eval      wkLineMode = wwSaveMode
     c                   callp     CloseMe(wwFD)
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Send a file to FTP server:
      *
      *    parms:    peSocket = descriptor returned by ftp_conn
      *              peRemote = filename of file on remote server
      *               peLocal = filename on this server (optional)
      *                     if not given, we'll assume that its the
      *                     same as the local server's filename.
      *
      *   returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_put         B                   EXPORT
     D FTP_put         PI            10I 0
     D   peSocket                    10I 0 value
     D   peRemote                   256A   const
     D   peLocal                    256A   const options(*nopass)

     D p_close         S               *   procptr
     D CloseMe         PR            10I 0 ExtProc(p_close)
     D   descriptor                  10I 0 value

     D wwLocal         S            257A
     D wwErrMsg        S            256A
     D wwFD            S             10I 0
     D wwRC            S             10I 0
     D p_read          S               *   procptr
     D wwSaveMode      s              1A

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * figure out pathname
     c                   if        %parms > 2
     c                   eval      wwLocal = peLocal
     c                   else
     c                   eval      wwLocal = peRemote
     c                   endif

      * get total number of bytes to send
     c                   eval      wkTotBytes = lclFileSiz(wwLocal)

      * open the file to send
     c                   eval      wwSaveMode = wkLineMode
     c                   eval      wwFD = OpnFile(wwLocal: 'R': p_read:
     c                                         p_close: peSocket)
     c                   if        wwFD < 0
     c                   eval      wkLineMode = wwSaveMode
     c                   return    -1
     c                   endif

      * upload data from the file...
     c                   if        FTP_putraw(peSocket: peRemote: wwFD:
     c                                     p_read) < 0
     c                   eval      wkLineMode = wwSaveMode
     c                   callp     CloseMe(wwFD)
     c                   return    -1
     c                   endif

      * we're done... woohoo
     c                   eval      wkLineMode = wwSaveMode
     c                   callp     CloseMe(wwFD)
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_getraw:   Get a file *from* the FTP server.
      *
      *       peSocket = descriptor returned by ftp_conn proc.
      *      peRemote = Remote filename to request.
      *       peDescr = descriptor to pass to the peRetProc procedure
      *     peWrtProc = Procedure to send the received data to.
      *         int writeproc(int fd, void *buf, int nbytes);
      *
      * Note that the format for the writeproc very deliberately
      *    matches that of the write() API, allowing us to write
      *    directly to the IFS or a socket just by passing that
      *    procedure.
      *
      *  returns 0 upon success, or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_getraw      B                   EXPORT
     D FTP_getraw      PI            10I 0
     D   peSocket                    10I 0 value
     D   peRemote                   256A   const
     D   peDescr                     10I 0 value
     D   peWrtProc                     *   PROCPTR value

     D wwMsg           S            256A
     D wwSock          S             10I 0
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        SetType(wkSocket) < 0
     c                   return    -1
     c                   endif

      *************************************************
      * Negotiate data channel (PASSIVE or PORT)
      *************************************************
     c                   if        wkPassive = *On
     c                   eval      wwSock = pasvcmd(peSocket)
     c                   else
     c                   eval      wwSock = portcmd(peSocket)
     c                   endif
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

     c                   if        RestartPt = -1
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif


      *************************************************
      * Start download
      *************************************************
     c                   if        SendLine(wkSocket: 'RETR ' + peRemote)<0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * 150 Opening transfer now...
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 150
     c                               and wwReply <> 125
     c                   callp     SetError(FTP_BADRTR: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * Do the actual file transfer
     c                   select
     c                   when      wkLineMode = 'R'
     c                   if        get_byrec(wwSock: peDescr: peWrtProc:
     c                                    wkRecLen) < 0
     c                   return    -1
     c                   endif
     c                   when      wkLineMode = *Off
     c                   if        get_block(wwSock: peDescr: peWrtProc)<0
     c                   return    -1
     c                   endif
     c                   other
     c                   if        get_byline(wwSock: peDescr: peWrtProc)<0
     c                   return    -1
     c                   endif
     c                   endsl

      * 226 Transfer Complete.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply<>226 and wwReply<>250
     c                   callp     SetError(FTP_XFRERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_putraw:   Put a file *to* the FTP server.
      *
      *       peSocket = descriptor returned by ftp_conn proc.
      *      peRemote = Remote filename to request.
      *       peDescr = descriptor to pass to the peReadProc procedure
      *    peReadProc = Procedure to call to read more data from
      *         int readproc(int fd, void *buf, int nbytes);
      *
      * Note that the format for the readproc very deliberately
      *    matches that of the write() API, allowing us to write
      *    directly to the IFS or a socket just by passing that
      *    procedure.
      *
      *  returns 0 upon success, or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_putraw      B                   EXPORT
     D FTP_putraw      PI            10I 0
     D   peSocket                    10I 0 value
     D   peRemote                   256A   const
     D   peDescr                     10I 0 value
     D   peReadProc                    *   PROCPTR value

     D wwMsg           S            256A
     D wwSock          S             10I 0
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        SetType(wkSocket) < 0
     c                   return    -1
     c                   endif

     c                   if        wkPassive = *On
     c                   eval      wwSock = pasvcmd(peSocket)
     c                   else
     c                   eval      wwSock = portcmd(peSocket)
     c                   endif
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

     c                   if        RestartPt = -1
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

     c                   if        SendLine(wkSocket: 'STOR ' + peRemote)<0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * 150 Opening transfer now...
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 150
     c                               and wwReply <> 125
     c                   callp     SetError(FTP_BADSTO: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * note that we don't do "line mode" for a put.
      *   it'd be kinda pointless, since we're not reading
      *   the results...  plus, all it would be is a custom read proc...
     c                   if        put_block(wwSock: peDescr: peReadProc)<0
     c                   return    -1
     c                   endif

      * 226 Transfer Complete.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply<>226 and wwReply<>250
     c                   callp     SetError(FTP_XFRERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_quit:
      *        parms:   peSocket = descriptor returned by ftp_conn
      *
      *  This procedure logs off of the FTP server and closes
      *  the network connection.
      *
      *  Returns 0 upon success, or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_quit        B                   EXPORT
     D FTP_quit        PI            10I 0
     D   peSocket                    10I 0 value

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        SendLine(wkSocket: 'QUIT') >= 0
     c                   callp     Reply(peSocket)
     c                   endif

     C                   callp     ftptcp_close(peSocket)

     C                   callp     cmd_resetSession

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_errorMsg
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  returns the error message that occurred when one of the
      *  above routines return -1.
      *
      *  optionally also returns the error number, which will
      *  match one of the constants defined in FTPAPI_H.  This
      *  can be used by programs to anticipate/handle errors.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_error       B                   EXPORT
     D FTP_error       PI            60A
     D   peErrorNum                  10I 0 options(*nopass)

     c                   if        %parms >= 1
     c                   return    FTP_errorMsg(wkLastSocketUsed:
     c                                          peErrorNum      )
     c                   else
     c                   return    FTP_errorMsg(wkLastSocketUsed)
     c                   endif
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  returns the error message that occurred when one of the
      *  above routines return -1.
      *
      *    peSocket  = socket number returned by FTP_conn
      *
      *  optionally also returns the error number, which will
      *  match one of the constants defined in FTPAPI_H.  This
      *  can be used by programs to anticipate/handle errors.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_errorMsg    B                   EXPORT
     D FTP_errorMsg    PI            60A
     D   peSocket                    10I 0 value
     D   peErrorNum                  10I 0 options(*nopass)

     D wwErrMsg        S                   like(wkErrMsg    )
     D wwErrNum        S                   like(wkErrNum    )

     D sessionIdx      S                   like(wkSessionIdx)
     D savSessionIdx   S                   like(wkSessionIdx)

     c                   callp     initFtpApi

     c                   if        peSocket <= 0
     c                   eval      sessionIdx = DFT_SESSION_IDX
     c                   else
     c                   eval      sessionIdx = getSessionIdx(peSocket)
     c                   endif

      * Invalid session index
     c                   if        sessionIdx < 0
     c                   eval      wwErrMsg = 'Invalid session index.'
     c                   eval      wwErrNum = FTP_BADIDX
     c                   else
      * Save session index
     c                   eval      savSessionIdx = wkSessionIdx
      * Select session
     c                   callp     cmd_occurSession(sessionIdx)
      * Get error information
     c                   eval      wwErrMsg = wkErrMsg
     c                   eval      wwErrNum = wkErrNum
      * Restore session
     c                   callp     cmd_occurSession(savSessionIdx)
     c                   endif

      * Return error information
     c                   if        %parms >= 2
     c                   eval      peErrorNum = wwErrNum
     c                   endif

     c                   return    wwErrMsg
     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This is used by FTP_dir and FTP_list to make an array of the
      *  returned directory entries.
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P List2Array      B                   EXPORT
     D List2Array      PI            10I 0
     D   peDescr                     10I 0 value
     D   peEntry                   8192A   options(*varsize)
     D   peLength                    10I 0 value

     D p_Entry         s               *
     D wwEntry         s            256A   based(p_Entry)

      * skip blank lines
     c                   if        peLength < 1
     c                   return    0
     c                   endif

      * skip anything past max size
     c                   eval      wkRtnSize = wkRtnSize + 1
     c                   if        wkRtnSize > wkMaxEntry
     c                   return    0
     c                   endif

      * add this entry to array
     c                   eval      p_Entry = wk_p_RtnPos
     c                   eval      wwEntry = %subst(peEntry:1:peLength)

      * move to next array position
     c                   if        wkRtnSize < wkMaxEntry
     c                   eval      wk_p_RtnPos = wk_p_RtnPos +
     c                                  %size(wwEntry)
     c                   endif

     c                   return    peLength
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_codePage
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Set file translation options for ASCII mode:
      *
      *     peASCII -- codepage to use when translating to/from ASCII
      *     peEBCDIC -- codepage to use when translating to/from EBCDIC
      *
      *  Return 0 for success, -1 upon error
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_codepg      B                   EXPORT
     D FTP_codepg      PI            10I 0
     D   peASCII                     10I 0 value
     D   peEBCDIC                    10I 0 value

     D i               s             10I 0

     c                   for       i = 1 to MAX_SESSION
     c                   callp     FTP_codePage( i
     c                                         : peASCII
     c                                         : peEBCDIC )
     c                   endfor

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Set file translation options for ASCII mode:
      *
      *    peSocket  = socket number returned by FTP_conn
      *    peASCII   = codepage to use when translating to/from ASCII
      *    peEBCDIC  = codepage to use when translating to/from EBCDIC
      *
      *    Return 0 for success, -1 upon error
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_codePage    B                   EXPORT
     D FTP_codePage    PI            10I 0
     D   peSocket                    10I 0 value
     D   peASCII                     10I 0 value
     D   peEBCDIC                    10I 0 value

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      wkXLFinit = *Off
     c                   eval      wkASCIIF_cp = peASCII
     c                   if        peEBCDIC = FTP_EBC_CP
     c                   eval      wkEBCDICF_cp = rtvJobCp
     c                   else
     c                   eval      wkEBCDICF_cp = peEBCDIC
     c                   endif
     c                   eval      wkUsrXlate = *On

     c                   return    InitIConv(*ON)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_exitProc
      *
      *  WARNING: FTP_xproc() for backwards compatibility, FTP_xproc
      *     changes the exit procedure of *ALL* sessions.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_xproc:  Register a procedure to be called at a given
      *        exit point:
      *
      *     peExitPnt = Exit point to register a procedure for
      *           FTP_EXTLOG = Procedure to call when logging control
      *                   session commands.
      *           FTP_EXTSTS = Procedure to call when showing the
      *                   current status of a file transfer.
      *     peProc    = Procedure to register (pass *NULL to disable)
      *
      *  Returns -1 upon error, 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_xproc       B                   EXPORT
     D FTP_xproc       PI            10I 0
     D   peExitPnt                   10I 0 value
     D   peProc                        *   procptr value

     D i               s             10I 0

     c                   callp     initFtpApi

     c                   for       i = 1 to MAX_SESSION
     c                   callp     SetSessionProc(i: peExitPnt:
     c                                            peProc: *NULL)
     c                   endfor

     c                   return    0

     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * SetSessionProc:  Set the exit proc for a given session index
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P SetSessionProc  B
     D SetSessionProc  PI            10I 0
     D   peSessIdx                   10I 0 value
     D   peExitPnt                   10I 0 value
     D   peProc                        *   procptr value
     D   peExtra                       *   value

     D wwSaveIdx       s             10I 0

     c                   if        peSessIdx<1 or peSessIdx>MAX_SESSION
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      wwSaveIdx = wkSessionIdx
     c                   callp     cmd_occursession(peSessIdx)

     c                   select
     c                   when      peExitPnt = FTP_EXTLOG
     c                   eval      wkLogExit = peProc
     c                   eval      wkLogProc = peProc
     c                   eval      wkLogExtra = peExtra
     c                   when      peExitPnt = FTP_EXTSTS
     c                   eval      wkStsExit = peProc
     c                   eval      wkStsProc = peProc
     c                   eval      wkStsExtra = peExtra
     c                   other
     c                   callp     cmd_occursession(wwSaveIdx)
     c                   callp     SetError(FTP_BADPNT: 'Invalid exit ' +
     c                                'point ')
     c                   return    -1
     c                   endsl

     c                   callp     cmd_occursession(wwSaveIdx)
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to read from a record-based file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P rf_read         B                   export
     D rf_read         PI            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     c                   callp     initFtpApi

      ** Read a record:
     c                   eval      p_RIOFB_t = Rreadn(wkRF: %addr(peBuffer):
     c                                peBufLen: DFT)

      ** Add CRLF and convert to ASCII if desired:
     c                   if        wkBinary=*Off and RI_nbytes>0
     c                   if        wkTrim = *On
     c                   eval      RI_nbytes= GetTrimLen(peBuffer:RI_Nbytes)
     c                   endif
     c                   if        RI_nbytes >= peBufLen
     c                   eval      RI_nbytes = peBufLen -2
     c                   endif
     c                   eval      %subst(peBuffer:RI_nbytes+1:2) = x'0D25'
     c                   eval      RI_nbytes = RI_nbytes + 2
     c                   callp     ToASCIIF(peBuffer: RI_nbytes)
     c                   endif

      * Return number of bytes read:
     c                   return    RI_nbytes
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  write a record to a record-based file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P rf_write        B                   export
     D rf_write        PI            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     c                   callp     initFtpApi

     c                   if        wkBinary = *Off
     c                   callp     ToEBCDICF(peBuffer: peBufLen)
     c                   endif

     c                   eval      p_RIOFB_t = Rwrite( wkRF
     c                                               : %addr(peBuffer)
     c                                               : wkRecLen)

      * Return bytes written
     c                   if        RI_nbytes < 1
     c                   return    -1
     c                   else
     c                   return    RI_nbytes
     c                   endif
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to read from a record-based source file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P src_read        B                   export
     D src_read        PI            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     D wwBuf           S            256A

     c                   callp     initFtpApi

      ** Read a record:
     c                   eval      p_RIOFB_t = Rreadn(wkRF: %addr(wwBuf):
     c                                %size(wwBuf): DFT)

     c                   if        RI_NBytes < 13
     c                   return    0
     c                   endif

      ** Add CRLF and convert to ASCII if desired:
     c                   if        wkBinary=*Off
     c     ' '           checkr    wwBuf         RI_NBytes
     c                   if        RI_NBytes<12
     c                   eval      RI_NBytes=0
     c                   else
     c                   eval      RI_NBytes = RI_NBytes - 12
     c                   endif
     c                   eval      %subst(peBuffer:1:peBufLen) =
     c                               %trimr(%subst(wwBuf:13:RI_NBytes))
     c                               + x'0D25'
     c                   eval      RI_NBytes = RI_NBytes + 2
     c                   callp     ToASCIIF(peBuffer: RI_nbytes)
     c                   else
     c                   eval      RI_NBytes = RI_NBytes - 12
     c                   eval      %subst(peBuffer: 1: peBufLen) =
     c                                        %subst(wwBuf:13:RI_NBytes)
     c                   endif

      * Return number of bytes read:
     c                   return    RI_nbytes
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to write to a record-based source file...  note that
      *  data comes is raw chunks, we need to convert it back to
      *  records.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P src_write       B                   export
     D src_write       PI            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     c                   callp     initFtpApi

     c                   if        wkBinary = *Off
     c                   callp     ToEBCDICF(peBuffer: peBufLen)
     c                   endif

     c                   eval      wkDsSrcLin = wkDsSrcLin + 0.01
     c                   eval      wkDsSrcDta = %subst(peBuffer:1:peBufLen)

     c                   eval      p_RIOFB_t = Rwrite(wkRF: %addr(wkDsSrcRec):
     c                                      wkRecLen)

      * Return bytes written
     c                   if        RI_nbytes < 1
     c                   return    -1
     c                   else
     c                   return    RI_nbytes
     c                   endif

     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to close a record-based file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P rf_close        B                   export
     D rf_close        PI            10I 0
     D   peFilDes                    10I 0 value

     c                   callp     initFtpApi

     c                   return    Rclose(wkRF)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to read from a stream file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P if_read         B                   export
     D if_read         PI            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value
     D wwRC            S             10I 0

     c                   callp     initFtpApi

     C                   eval      wwRC = read(peFilDes: %addr(peBuffer):
     c                                       peBufLen)

     c                   if        wwRC>0 and wkBinary=*Off
     c                   callp     ToASCIIF(peBuffer: wwRC)
     c                   endif

     c                   return    wwRC
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to write to a stream file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P if_write        B                   export
     D if_write        PI            10I 0
     D   peFilDes                    10I 0 value
     D   peBuffer                 32766A   options(*varsize)
     D   peBufLen                    10I 0 value

     c                   callp     initFtpApi

     c                   if        peBufLen>0 and wkBinary=*Off
     c                   callp     ToEBCDICF(peBuffer: peBufLen)
     c                   endif

     C                   return    write(peFilDes: %addr(peBuffer):
     c                                       peBufLen)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Procedure to close a stream file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P if_close        B                   export
     D if_close        PI            10I 0
     D   peFilDes                    10I 0 value

     c                   callp     initFtpApi

     c                   return    close(peFilDes)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Add a file to the end of one that is on an FTP server:
      *
      *    parms:    peSocket = descriptor returned by ftp_conn
      *              peRemote = filename of file on remote server
      *               peLocal = filename on this server (optional)
      *                     if not given, we'll assume that its the
      *                     same as the local server's filename.
      *
      *   returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_append      B                   EXPORT
     D FTP_append      PI            10I 0
     D   peSocket                    10I 0 value
     D   peRemote                   256A   const
     D   peLocal                    256A   const options(*nopass)

     D p_close         S               *   procptr
     D CloseMe         PR            10I 0 ExtProc(p_close)
     D   descriptor                  10I 0 value

     D wwLocal         S            257A
     D wwErrMsg        S            256A
     D wwFD            S             10I 0
     D wwRC            S             10I 0
     D p_read          S               *   procptr
     D wwSaveMode      s              1A

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * figure out pathname
     c                   if        %parms > 2
     c                   eval      wwLocal = peLocal
     c                   else
     c                   eval      wwLocal = peRemote
     c                   endif

      * get total number of bytes to send
     c                   eval      wkTotBytes = lclFileSiz(wwLocal)

      * open the file to send
     c                   eval      wwSaveMode = wkLineMode
     c                   eval      wwFD = OpnFile(wwLocal: 'R': p_read:
     c                                         p_close: peSocket)
     c                   if        wwFD < 0
     c                   eval      wkLineMode = wwSaveMode
     c                   return    -1
     c                   endif

      * upload data from the file...
     c                   if        FTP_appraw(peSocket: peRemote: wwFD:
     c                                     p_read) < 0
     c                   eval      wkLineMode = wwSaveMode
     c                   callp     CloseMe(wwFD)
     c                   return    -1
     c                   endif

      * we're done... woohoo
     c                   eval      wkLineMode = wwSaveMode
     c                   callp     CloseMe(wwFD)
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_appraw:  Append a file *to* the FTP server.
      *
      *       peSocket = descriptor returned by ftp_conn proc.
      *      peRemote = Remote filename to request.
      *       peDescr = descriptor to pass to the peReadProc procedure
      *    peReadProc = Procedure to call to read more data from
      *         int readproc(int fd, void *buf, int nbytes);
      *
      * Note that the format for the readproc very deliberately
      *    matches that of the write() API, allowing us to write
      *    directly to the IFS or a socket just by passing that
      *    procedure.
      *
      *  returns 0 upon success, or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_appraw      B                   EXPORT
     D FTP_appraw      PI            10I 0
     D   peSocket                    10I 0 value
     D   peRemote                   256A   const
     D   peDescr                     10I 0 value
     D   peReadProc                    *   PROCPTR value

     D wwMsg           S            256A
     D wwSock          S             10I 0
     D wwReply         S             10I 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        SetType(wkSocket) < 0
     c                   return    -1
     c                   endif

     c                   if        wkPassive = *On
     c                   eval      wwSock = pasvcmd(peSocket)
     c                   else
     c                   eval      wwSock = portcmd(peSocket)
     c                   endif
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif

     c                   if        RestartPt = -1
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

     c                   if        SendLine(wkSocket: 'APPE ' + peRemote)<0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * 150 Opening transfer now...
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 150
     c                               and wwReply <> 125
     c                   callp     SetError(FTP_BADAPP: wwMsg)
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * note that we don't do "line mode" for a put.
      *   it'd be kinda pointless, since we're not reading
      *   the results...  plus, all it would be is a custom read proc...
     c                   if        put_block(wwSock: peDescr: peReadProc)<0
     c                   return    -1
     c                   endif

      * 226 Transfer Complete.
     c                   eval      wwReply = Reply(peSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply<>226 and wwReply<>250
     c                   callp     SetError(FTP_XFRERR: wwMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *      Deprecated. See: FTP_trimMode
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_trim:  Set the "trim mode" for record-based files that
      *            you PUT in ASCII (non-binary) mode.
      *
      *  Note that this has no affect on GETs, binary-mode transfers,
      *       stream files, or source members.
      *
      *     peSetting = Should be *ON if you want trailing blanks
      *           to be trimmed, or *OFF otherwise.  *OFF is used
      *           by default
      *
      *  returns 0 upon success, or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_trim        B                   EXPORT
     D FTP_trim        PI            10I 0
     D   peSetting                    1A   const

     D i               s             10I 0

     c                   for       i = 1 to MAX_SESSION
     c                   if        FTP_trimMode(i: peSetting) < 0
     c                   return    -1
     c                   endif
     c                   endfor

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_trimMode:     Set the "trim mode" for record-based files that
      *                   you PUT in ASCII (non-binary) mode.
      *
      *  Note that this has no affect on GETs, binary-mode transfers,
      *       stream files, or source members.
      *
      *    peSocket  = socket number returned by FTP_conn
      *    peSetting = Should be *ON if you want trailing blanks
      *          to be trimmed, or *OFF otherwise.  *OFF is used
      *          by default
      *
      *    returns 0 upon success, or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_trimMode    B                   EXPORT
     D FTP_trimMode    PI            10I 0
     D   peSocket                    10I 0 value
     D   peSetting                    1A   const

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        peSetting <> *ON
     c                               and peSetting<>*OFF
     c                   callp     SetError(FTP_PESETT: 'Trim mode ' +
     c                               ' setting must be *ON or *OFF')
     c                   return    -1
     c                   endif

     c                   eval      wkTrim = peSetting
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This gets a reply to an FTP command.   Here are some examples
      *  of the format of the reply that the FTP servers give:
      *
      * Single line format:
      *      200 Successful completion
      *
      * Multi-Line format:
      *      201-This is my FTP server
      *      201-Its really neat
      *        Other stuff can be here
      *      201 Done with message.
      *
      * (For more info see RFC959 "File Transfer Protocol" which
      *  is the internet standards document on FTP)
      *
      *  This routine will return the message number, as well as
      *  (optionally) the text of the message.  If there is a multi
      *  line message, the text will be for just the first line.
      *
      *  Returns:
      *        Returns the message number upon success.
      *        -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P Reply           B
     D Reply           PI            10I 0
     D   peSocket                    10I 0 value
     D   peRespMsg                  256A   options(*nopass)

     D wwLine          S            512A
     D wwReply         S              3  0
     D wwNum           S              3  0
     D wwChar3         S              3A

      * Get a of text
     c                   if        RecvLine(peSocket: wwLine) < 0
     c                   return    -1
     c                   endif

      * Grab 3-digit reply code
     c                   movel     wwLine        wwChar3
     c                   testn                   wwChar3              99
     c                   if        *in99 = *off
     c                   callp     SetError(FTP_BADRES: 'Not a valid FTP ' +
     c                                ' reply line ')
     c                   return    -1
     c                   endif

     c                   move      wwChar3       wwReply
     c                   if        %parms > 1
     c                   eval      peRespMsg = %subst(wwLine:5)
     c                   endif

      * If this is a single line reply, we're done.
     c                   if        %subst(wwLine:4:1) <> '-'
     c                   return    wwReply
     c                   endif

      * If not, get all lines of reply
     c                   dou       wwNum = wwReply
     c                               and %subst(wwLine:4:1) <> '-'
     c                   if        RecvLine(peSocket: wwLine) < 0
     c                   return    -1
     c                   endif
     c                   movel     wwLine        wwChar3
     c                   testn                   wwChar3              99
     c   99              move      wwChar3       wwNum
     c  N99              eval      wwNum = 0
     c                   enddo

     c                   return    wwReply
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *   Sub-procedure to read one line of text from a socket.
      *
      * Automatically converts to EBCDIC, strips the CR/LF
      * and converts to a fixed-length (blank padded) variable.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P RecvLine        B
     D RecvLine        PI            10I 0
     D  peSocket                     10I 0
     D  peLine                      512A

     D wwLen           S              5  0
     D rc              S             10I 0
     D wwErrmsg        S            256A
     D buf             s            512a

     c                   eval      rc = ftptcp_readln( peSocket
     c                                               : %addr(buf)
     c                                               : %size(buf)
     c                                               : ASCII_LF)

     c                   if        rc = -1
     c                   return    -1
     c                   endif

     c                   eval      wwLen = rc
     c                   if        wwLen = 0
     c                   eval      peLine = *blanks
     c                   else
     c                   eval      peLine = %subst(buf:1:wwLen)
     c                   endif

     c                   if        wwLen >= 1
     c                             and %subst(peLine:wwLen:1) = x'0a'
     c                   eval      %subst(peLine:wwLen:1) = ' '
     c                   eval      wwLen -= 1
     c                   endif

     c                   if        wwLen >= 1
     c                             and %subst(peLine:wwLen:1) = x'0d'
     c                   eval      %subst(peLine:wwLen:1) = ' '
     c                   eval      wwLen -= 1
     c                   endif

      * translate line to EBCDIC
     c                   if        wwLen > 0
     c                   callp     ToEBCDIC(peLine: wwLen)
     c                   endif

     c                   if        wkDebug = *On
     c                               and wwLen > 0
     c                   callp     DiagLog(peLine)
     c                   endif

     c                   return    wwLen
     p                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * This reads one "line" of text data from a socket, and does
      *  input buffering (for performance purposes)
      *
      *   peSocket = socket to read from
      *   peLine   = a pointer to a variable to put the line of text into
      *   peLength = max possible length of data to stuff into peLine
      *   peCrLf   = Carriage return & line feed chars to use
      *
      *  returns length of data read, or -1 for no data available.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P BufLine         B
     D BufLine         PI            10I 0
     D   peSocket                    10I 0 value
     D   peLine                        *   value
     D   peLength                    10I 0 value
     D   peCrLf                       2A   const

     D wwBuf           S          32766A   based(peLine)
     D wwLen           S             10I 0
     D wwCR            S              1A
     D wwLF            S              1A

     c                   eval      wwCR = %subst(peCrLf:1:1)
     c                   eval      wwLF = %subst(peCrLf:2:1)

      * make sure our buffer is bigger than caller's
     c                   if        peLength > 32200
     c                   return    -1
     c                   endif

     c                   eval      %subst(wwBuf:1:peLength) = *blanks

     c                   eval      wwLen = ftptcp_readln( peSocket
     c                                                  : peLine
     c                                                  : peLength
     c                                                  : wwLF )

      *************************************************
      ** Strip CR if found
      *************************************************
     c                   if        wwLen >= 1
     c                             and %subst(wwBuf:wwLen:1) = wwLF
     c                   eval      %subst(wwBuf:wwLen:1) = ' '
     c                   eval      wwLen -= 1
     c                   endif

     c                   if        wwLen >= 1
     c                             and %subst(wwBuf:wwLen:1) = wwCR
     c                   eval      %subst(wwBuf:wwLen:1) = ' '
     c                   eval      wwLen -= 1
     c                   endif

     c                   return    wwLen
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Send one line of text
      *
      * Automatically converts the data to ASCII, strips extra blanks
      *  from the end, calculates the length and adds a CR/LF.
      *
      * returns the length of the data sent.   A short count
      *   indicates an error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P SendLine        B
     D SendLine        PI            10I 0
     D   peSocket                    10I 0 value
     D   peData                     261A   const
     D wwLen           S             10I 0
     D p_Data          S               *
     D wwBigger        S            263A

     c                   eval      wwBigger = peData
     c     ' '           checkr    wwBigger      wwLen

     c                   if        wkDebug = *On
     c                               and wwLen > 0
     c                   callp     DiagLog('> ' + peData)
     c                   endif

     c                   if        wwLen > 0
     c                   callp     ToASCII(wwBigger: wwLen)
     c                   endif

     c                   eval      %subst(wwBigger:wwLen+1:2) = x'0D0A'
     c                   eval      p_Data = %addr(wwBigger)

     c                   return    ftptcp_write( peSocket
     c                                         : p_Data
     c                                         : wwLen+2 )
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Send one line of text
      *
      * Automatically converts the data to ASCII, strips extra blanks
      *  from the end, calculates the length and adds a CR/LF.
      *
      * returns the length of the data sent.   A short count
      *   indicates an error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P SendLine2       B
     D SendLine2       PI            10I 0
     D   peSocket                    10I 0 value
     D   peData                    1005A   const

     D wwLen           S             10I 0
     D p_Data          S               *
     D wwBigger        S           1007A

     c                   eval      wwBigger = peData
     c     ' '           checkr    wwBigger      wwLen

     c                   if        wkDebug = *On
     c                               and wwLen > 0
     c                   callp     DiagLog('> ' + peData)
     c                   endif

     c                   if        wwLen > 0
     c                   callp     ToASCII(wwBigger: wwLen)
     c                   endif

     c                   eval      %subst(wwBigger:wwLen+1:2) = x'0D0A'
     c                   eval      p_Data = %addr(wwBigger)

     c                   return    ftptcp_write( peSocket
     c                                         : p_Data
     c                                         : wwLen+2 )
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  get_block:
      *      This downloads a file from an FTP server in block mode.
      *      Meaning that data is returned in arbitrary size chunks,
      *      (as opposed to the line by line mode used in get_byline)
      *      Unlike the line mode, this does not convert the data
      *      from ASCII to EBCDIC.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P get_block       B
     D get_block       PI            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value

     D write_data      PR            10I 0 ExtProc(peFunction)
     D   filedes                     10I 0 value
     D   data                          *   value
     D   length                      10U 0 value

     D wwBuffer        S           8192A
     D wwRC            S             10I 0
     D wwSock          S             10I 0
     D wwSession       s             10I 0
     D wwBytes         s             16p 0

      * get the data connection  
     c                   if        wkPassive = *On
     c                   eval      wwSock = peSocket
     c                   else
     c                   eval      wwSock = ftptcp_accept( peSocket
     c                                                   : *omit
     c                                                   : *omit )  
     c                   callp     ftptcp_close(peSocket)
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif
     c                   endif

      * if TLS is enabled the data conn should also be TLS    
     c                   if        wkTlsData = FTPS_PRIVATE
     c                   if        ftptcp_upgrade( wwSock
     c                                           : FTPTCP_CLIENT_SESSION
     c                                           : wkAppId
     c                                           : wkKeyPath
     c                                           : wkKeyPass
     c                                           : wkKeyLabel) = -1
     c                   return    -1
     c                   endif
     c                   endif
 


     c                   eval      wwBytes   = wkRestPt
     c                   eval      wkRestPt  = 0
     c                   eval      wwSession = wkSocket

      * download file:
     C                   dou       1 = 0

     C                   eval      wwRC = ftptcp_read( wwSock
     C                                               : %addr(wwBuffer)
     C                                               : %size(wwBuffer) )
     c                   if        wwRC = -1
     c                   callp     ftptcp_close(wwSock)
     c                   return    0
     c                   endif

     c                   add       wwRC          wwBytes

     c                   eval      wwRC = write_data( peFiledes
     c                                              : %addr(wwBuffer)
     c                                              : wwRC )
     c                   callp     selectSession(wwSession)
     c                   if        wwRC < 0
     c                   callp     SetError(FTP_GETBWR: 'Binary Recv: ' +
     c                                ' Write proc returned an error.')
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

     c                   if        wkStsProc <> *NULL
     c                   callp     StatusProc( wwBytes
     c                                       : wkTotBytes
     c                                       : wkStsExtra )
     c                   callp     selectSession(wwSession)
     c                   endif

     c                   enddo
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  get_byrec:
      *      This downloads a file from an FTP server, by fixed length
      *      records.  This is as opposed to get_block which uses an
      *      arbitrary buffer size, or get_byline which writes data
      *      in delimited lines.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P get_byrec       B
     D get_byrec       PI            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value
     D   peRecLen                    10I 0 value

     D write_data      PR            10I 0 ExtProc(peFunction)
     D   filedes                     10I 0 value
     D   data                          *   value
     D   length                      10U 0 value

     D wwBuffer        S              1A   dim(32766)
     D wwRC            S             10I 0
     D wwSock          S             10I 0
     D wwBufPos        S              5U 0
     D wwNeeded        S              5U 0
     D wwBytes         S             16P 0
     D wwSession       S             10I 0

      * get data connection:
     c                   if        wkPassive = *On
     c                   eval      wwSock = peSocket
     c                   else
     c                   eval      wwSock = ftptcp_accept( peSocket
     c                                                   : *omit
     c                                                   : *omit )  
     c                   callp     ftptcp_close(peSocket)
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif
     c                   endif

      * if TLS is enabled the data conn should also be TLS    
     c                   if        wkTlsData = FTPS_PRIVATE
     c                   if        ftptcp_upgrade( wwSock
     c                                           : FTPTCP_CLIENT_SESSION
     c                                           : wkAppId
     c                                           : wkKeyPath
     c                                           : wkKeyPass
     c                                           : wkKeyLabel) = -1
     c                   return    -1
     c                   endif
     c                   endif

     c                   eval      wwSession = wkSocket
     c                   eval      wwBytes   = wkRestPt
     c                   eval      wkRestPt  = 0

      * download file:
     C                   dou       1 = 0

     c                   eval      wwNeeded = peRecLen
     c                   eval      wwBufPos = 1

      * receive one record of data
     c                   dou       wwNeeded = 0

     c                   eval      wwRC = ftptcp_read( wwSock
     c                                               : %addr(wwBuffer(wwBufPos))
     c                                               : wwNeeded )
     c                   if        wwRC < 1
     c                   callp     ftptcp_close(wwSock)
     c                   return    0
     c                   endif

     c                   eval      wwBufPos = wwBufPos + wwRC
     c                   eval      wwNeeded = wwNeeded - wwRC

     c                   enddo

      * write data record
     c                   add       peRecLen      wwBytes

     c                   eval      wwRC = write_data( peFiledes
     c                                              : %addr(wwBuffer)
     c                                              : peRecLen)
     c                   callp     selectSession(wwSession)

     c                   if        wwRC < 0
     c                   callp     SetError(FTP_GETBWR: 'Record Recv: ' +
     c                                ' Write proc returned an error.')
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

      * show status
     c                   if        wkStsProc <> *NULL
     c                   callp     StatusProc( wwBytes
     c                                       : wkTotBytes
     c                                       : wkStsExtra)
     c                   callp     selectSession(wwSession)
     c                   endif

     c                   enddo
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  get_byline:
      *      This downloads data (using FTP's ASCII mode) from the
      *      FTP server.
      *
      *      Data is returned to the write procedure one line at
      *      a time, which makes this easy to use for things like
      *      reading a text file, or directory.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P get_byline      B
     D get_byline      PI            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value

     D write_data      PR            10I 0 ExtProc(peFunction)
     D   filedes                     10I 0 value
     D   data                          *   value
     D   length                      10U 0 value

     D wwBuffer        S          32200A
     D wwRC            S             10I 0
     D wwSock          S             10I 0
     D wwCrLf          S              2A
     D wwSession       s             10I 0
     D wwBytes         s             16p 0

      * get data connection:
     c                   if        wkPassive = *On
     c                   eval      wwSock = peSocket
     c                   else
     c                   eval      wwSock = ftptcp_accept( peSocket
     c                                                   : *omit
     c                                                   : *omit )  
     c                   callp     ftptcp_close(peSocket)
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif
     c                   endif

      * if TLS is enabled the data conn should also be TLS    
     c                   if        wkTlsData = FTPS_PRIVATE
     c                   if        ftptcp_upgrade( wwSock
     c                                           : FTPTCP_CLIENT_SESSION
     c                                           : wkAppId
     c                                           : wkKeyPath
     c                                           : wkKeyPass
     c                                           : wkKeyLabel) = -1
     c                   return    -1
     c                   endif
     c                   endif

     c                   eval      wwSession = wkSocket
     c                   eval      wwBytes   = wkRestPt
     c                   eval      wkRestPt  = 0

      * CR/LF in EBCDIC is 0D and 25.  IF we're translating the
      *   data however, what we're reading may be in another codepage...
     c                   eval      wwCrLf = x'0D25'
     c                   if        wkBinary = *Off
     c                   if        wkXlatHack = *on
     c                   callp     ToASCII(wwCrLf:2)
     c                   else
     c                   callp     ToASCIIF(wwCrLf:2)
     c                   endif
     c                   endif

      * download file:
     C                   dou       1 = 0

      * read one line of data
     c                   eval      wwRC = BufLine( wwSock
     c                                           : %addr(wwBuffer)
     c                                           : %size(wwBuffer)
     c                                           : wwCrLf )
     c                   if        wwRC < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    0
     c                   endif

      * Older versions of FTPAPI called RecvLine for directories and
      *   that translated ASCII to EBCDIC.  This hack is to avoid
      *   breaking that backward compatability:
     c                   if        wkXlatHack = *On
     c                   callp     ToEBCDIC(wwBuffer: wwRC)
     c                   endif

      * write one line of data
     c                   add       wwRC          wwBytes

     c                   eval      wwRC = write_data( peFiledes
     c                                              : %addr(wwBuffer)
     c                                              : wwRC)
     c                   callp     selectSession(wwSession)

     c                   if        wwRC < 0
     c                   callp     ftptcp_close(wwSock)
     c                   callp     SetError(FTP_GETAWR: 'ByLine Recv: ' +
     c                                ' Write proc returned an error.')
     c                   return    -1
     c                   endif

      * report status
     c                   if        wkStsProc <> *NULL
     c                   callp     StatusProc( wwBytes
     c                                       : wkTotBytes
     c                                       : wkStsExtra)
     c                   callp     selectSession(wwSession)
     c                   endif

     c                   enddo
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  put_block:
      *      Upload a file to a FTP server
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P put_block       B
     D put_block       PI            10I 0
     D   peSocket                    10I 0 value
     D   peFiledes                   10I 0 value
     D   peFunction                    *   PROCPTR value

     D read_data       PR            10I 0 ExtProc(peFunction)
     D   filedes                     10I 0 value
     D   data                          *   value
     D   length                      10U 0 value

     D wwBuffer        S          32766A
     D wwRC            S             10I 0
     D wwSock          S             10I 0
     D wwBytes         S             16P 0
     D wwSession       s             10I 0

      * get data connection:
     c                   if        wkPassive = *On
     c                   eval      wwSock = peSocket
     c                   else
     c                   eval      wwSock = ftptcp_accept( peSocket
     c                                                   : *omit
     c                                                   : *omit )  
     c                   callp     ftptcp_close(peSocket)
     c                   if        wwSock < 0
     c                   return    -1
     c                   endif
     c                   endif

      * if TLS is enabled the data conn should also be TLS    
     c                   if        wkTlsData = FTPS_PRIVATE
     c                   if        ftptcp_upgrade( wwSock
     c                                           : FTPTCP_CLIENT_SESSION
     c                                           : wkAppId
     c                                           : wkKeyPath
     c                                           : wkKeyPass
     c                                           : wkKeyLabel) = -1
     c                   return    -1
     c                   endif
     c                   endif

     c                   eval      wwSession = wkSocket
     c                   eval      wwBytes   = wkRestPt
     c                   eval      wkRestPt  = 0

      * upload file:
     c                   dou       0 = 1

     C                   eval      wwRC = read_data( peFiledes
     c                                             : %addr(wwBuffer)
     c                                             : %size(wwBuffer))
     c                   callp     selectSession(wwSession)

     c                   if        wwRC < 1
     c                   leave
     c                   endif

     c                   add       wwRC          wwBytes

     c                   eval      wwRC = ftptcp_write( wwSock
     c                                                : %addr(wwBuffer)
     c                                                : wwRC )
     c                   if        wwRC < 0
     c                   callp     ftptcp_close(wwSock)
     c                   return    -1
     c                   endif

     c                   if        wkStsProc <> *NULL
     c                   callp     StatusProc( wwBytes
     c                                       : wkTotBytes
     c                                       : wkStsExtra)
     c                   callp     selectSession(wwSession)
     c                   endif

     c                   enddo

     c                   callp     ftptcp_close(wwSock)
     c                   return    0
     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  TCP Connect
      *    General interface for creating & connecting a TCP socket
      *    to a remote port.
      *
      *  Input:      peHost -- Domain name or dotted-decimal format of
      *                        the host to connect to.
      *              pePort -- port number to connect to.
      *           peTimeout -- (optional) if given, sockets will be
      *                        put in non-blocking mode, and the
      *                        connection will time out after this
      *                        many seconds if no data is received.
      *
      *  Returns:    socket descriptor upon success
      *               or -1 upon failure
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P TCP_Conn        B
     D TCP_Conn        PI            10I 0
     D   peHost                     256A   Const
     D   pePort                       5U 0 Value
     D   peTimeout                    5U 0 value options(*nopass)

     D wwIP            S             10U 0
     D wwSocket        S             10I 0
     D wwAddrBuf       S             16A
     D wwErrMsg        S            256A
     D wwSet           S             28A
     D wwTO            S              8A
     D wwErr           S             10I 0
     D wwTimeout       S              5I 0
     D wwRC            S             10I 0
     D wwFlags         S             10I 0

      * Handle optional args
     c                   if        %parms > 2
     c                   eval      wwTimeout = peTimeout
     c                   else
     c                   eval      wwTimeout = 0
     c                   endif

      * build a socket.  A TCP
      * socket is a "stream" socket (SOCK_STREAM)
      * using Internet Protocol (AF_INET)
     C                   eval      wwSocket = ftptcp_socket( wwTimeout : -1)
     c                   if        wwSocket < 0
     c                   return    -1
     c                   endif

      * connect to remote site
     c                   if        ftptcp_connect( wwSocket
     c                                           : %trim(peHost)
     c                                           : pePort ) = -1
     c                   return    -1
     c                   endif

      * return socket desc
     c                   return    wwSocket
     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This creates a TCP port thats listening for a connection.
      *  and sends details of that connection to the server using the
      *  FTP PORT subcommand.
      *
      *  This is used for normal (non-passive) file transfers
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P portcmd         B
     D portcmd         PI            10I 0
     D   peCtrlSock                  10I 0 value

     D wwSocket        S             10I 0
     D wwDotted        S             16A   varying
     D wwErrMsg        S            256A
     D wwMsg           S            256A
     D wwPort          S              5U 0
     D wwPortStr       S             80A
     D wwLen           S             10I 0
     D wwMSB           S             10I 0
     D wwLSB           S             10I 0
     D wwReply         S             10I 0
     D wwEPRTStr       S             80A
     D SaveDbg         s              1n

     C                   eval      wwSocket = ftptcp_socket( wkTimeout: -1)

     C                   if        ftptcp_listenTo( wwSocket
     C                                            : 0
     C                                            : 10
     C                                            : peCtrlSock
     C                                            : wwDotted
     C                                            : wwPort ) = -1
     C                   return    -1
     c                   endif

      *******************************************
      * Build port string.  Should be like this:
      *  a,b,c,d,e,f
      *   where a-d = octets of IP address
      *           e = most significant octet of port #
      *           f = least significant octet of port #
      * example:
      *  127,0,0,1,39,2 would be:
      *    IP 127.0.0.1 and port 9986.
      *******************************************
     c                   eval      wwPortStr = %xlate('.':',':wwDotted)
     c     wwPort        div       256           wwMSB
     c                   mvr                     wwLSB
     c                   eval      wwPortStr = %trimr(wwPortStr) + ',' +
     c                                   %trimr(NumToChar(wwMSB)) + ',' +
     c                                   %trimr(NumToChar(wwLSB))

      *******************************************
      * Build EPRT string.  Should be like this:
      *  |prot|addr|port|
      *   where prot = protocol number 1=ipv4 2=ipv6
      *         addr = the entire ip address 
      *         port = entire port number
      * example:
      *  |1|127.0.0.1|9986|
      *  |2|1080::8:800:200C:417A|5282|
      *
      *
      *  EPRT works like this:
      *   - we disable logging because users
      *     get unhappy if they see EPRT errors
      *   - We try the EPRT command
      *   - if it succeeds, we log it
      *   - if it fails, turn off enhanced mode
      *     for the rest of the session, which
      *     will cause the PORT command to be 
      *     used as normal.
      *******************************************
     c                   if         wkEnhSupp = *on

     c                   eval      SaveDbg = wkDebug
     c                   eval      wkDebug = *Off

     c                   eval       wwEPrtStr = %char(UCS_PIPE)
     c                                        + '1'
     c                                        + %char(UCS_PIPE)
     c                                        + %trim(wwDotted)
     c                                        + %char(UCS_PIPE)
     c                                        + %char(wwPort)
     c                                        + %char(UCS_PIPE)

     c                   if        SendLine(peCtrlSock: 'EPRT '+wwEPrtStr) < 0
     c                   eval      wkDebug = SaveDbg
     c                   callp     ftptcp_close(wwSocket)
     c                   return    -1
     c                   endif

     c                   eval      wwReply = Reply(peCtrlSock: wwMsg)
     c                   if        wwReply < 0
     c                   eval      wkDebug = SaveDbg
     c                   callp     ftptcp_close(wwSocket)
     c                   return    -1
     c                   endif

      * 200 EPRT command successful.
     c                   if        wwReply = 200
     c                   eval      wkEnhSupp = *on
     c                   if        SaveDbg = *on
     c                   callp     DiagLog('> EPRT ' + wwEPrtStr)
     c                   callp     DiagLog('200 ' + wwMsg)
     c                   endif
     c                   else
     c                   eval      wkEnhSupp = *off
     c                   endif

     c                   eval      wkDebug = SaveDbg
     c                   endif

      *******************************************
      * Send the PORT string to the server.
      *******************************************
     c                   if        wkEnhSupp = *off

     c                   if        SendLine(peCtrlSock: 'PORT '+wwPortStr) < 0
     c                   callp     ftptcp_close(wwSocket)
     c                   return    -1
     c                   endif

      * 200 PORT command successful.
     c                   eval      wwReply = Reply(peCtrlSock: wwMsg)
     c                   if        wwReply < 0
     c                   callp     ftptcp_close(wwSocket)
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 200
     c                   callp     SetError(FTP_PRTERR: wwMsg)
     c                   callp     ftptcp_close(wwSocket)
     c                   return    -1
     c                   endif

     c                   endif

      *******************************************
      * wow.  it appears to have worked?
      *******************************************
     c                   return    wwSocket
     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This is used to send the PASV (passive-mode FTP) command to
      *  the server, interpret the results, and connect...
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P pasvcmd         B
     D pasvcmd         PI            10I 0
     D   peCtrlSock                  10I 0 value

     D atoi            PR            10I 0 ExtProc('atoi')
     D  string                         *   value options(*string)

     D sscanf          PR                  ExtProc('sscanf')
     D  src_str                   32766A   options(*varsize)
     D  format_str                32766A   options(*varsize)
     D  I1                           10U 0
     D  I2                           10U 0
     D  I3                           10U 0
     D  I4                           10U 0
     D  P1                           10U 0
     D  P2                           10U 0
     
     D I1              s             10U 0
     D I2              s             10U 0
     D I3              s             10U 0
     D I4              s             10U 0
     D P1              s             10U 0
     D P2              s             10U 0

     D wwEnd           S              5I 0
     D wwStart         S              5I 0
     D wwLen           S              5I 0
     D wwFormat        S             17A
     D wwHost          S             16A
     D wwLSB           S              5I 0
     D wwMSB           S              5I 0
     D wwPasStr        S             80A
     D wwMsg           S            256A
     D wwPort          s              5U 0
     D wwReply         S             10I 0
     D wwChrPort       s             20a     varying
     D SaveDbg         s              1n

     c                   if        wkEnhSupp = *on
     c                   exsr      try_epsv
     c                   endif

     c                   if        wkEnhSupp = *off
     c                   exsr      try_pasv
     c                   endif

     c                   return    tcp_conn(wwHost: wwPort)

      *==========================================================
      * This tries to use enhanced passive (EPSV) mode. If this
      * fails, wkEnhSupp will be turned off.
      *==========================================================
     c     try_epsv      begsr
      *-----------------------
     c                   eval      SaveDbg = wkDebug
     c                   eval      wkDebug = *off

     c                   if        SendLine(peCtrlSock: 'EPSV') < 0
     c                   eval      wkDebug = SaveDbg
     c                   return    -1
     c                   endif

     c                   eval      wwReply = Reply(peCtrlSock: wwMsg)
     c                   if        wwReply < 0
     c                   eval      wkDebug = SaveDbg
     c                   return    -1
     c                   endif

      * 229 Entering Extended Passive Mode (|||1234|)
     c                   if        wwReply <> 229
     c                   eval      wkEnhSupp = *off
     c                   leavesr
     c                   endif

     c                   eval      wwStart = %scan( '('
     c                                            + %char(UCS_PIPE)
     c                                            + %char(UCS_PIPE)
     c                                            + %char(UCS_PIPE)
     c                                            : wwMsg)
     c                   if        wwStart < 1
     c                   eval      wkEnhSupp = *off
     c                   eval      wkDebug = SaveDbg
     c                   leavesr
     c                   endif

     c                   eval      wwEnd = %scan( %char(UCS_PIPE) + ')'
     c                                          : wwMsg)
     c                   if        wwEnd < 1
     c                             or wwEnd <= wwStart
     c                   eval      wkEnhSupp = *off
     c                   eval      wkDebug = SaveDbg
     c                   leavesr
     c                   endif
     
     c                   eval      wwStart = wwStart + 4
     c                   eval      wwLen = wwEnd - wwStart
     c                   if        wwLen < 1
     c                   eval      wkEnhSupp = *off
     c                   eval      wkDebug = SaveDbg
     c                   leavesr
     c                   endif

     c                   eval      wwHost = ftptcp_getPeerAddr(peCtrlSock)
     c                   if        wwHost = ''
     c                   eval      wkEnhSupp = *off
     c                   eval      wkDebug = SaveDbg
     c                   leavesr
     c                   endif

     c                   eval      wwChrPort = %subst(wwMsg: wwStart: wwLen)
     c                   eval      wwPort = atoi(wwChrPort)
     c                   eval      wkEnhSupp = *on

     c                   if        SaveDbg = *on
     c                   callp     DiagLog('> EPSV')
     c                   callp     DiagLog('229 ' + wwMsg)
     c                   endif

     c                   eval      wkDebug = SaveDbg
      *-----------------------
     c                   endsr


      *==========================================================
      * This implements the normal FTP PASV command and parses
      * its response.
      *==========================================================
     c     try_pasv      begsr
      *-----------------------
     c                   if        SendLine(peCtrlSock: 'PASV') < 0
     c                   return    -1
     c                   endif

      * 227 Entering Passive Mode (Port string)
     c                   eval      wwReply = Reply(peCtrlSock: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 227
     c                   callp     SetError(FTP_PASERR: wwMsg)
     c                   return    -1
     c                   endif

      *******************************************
      * Extract the PORT & IP string from the
      *   reply to the PASV command
      *******************************************
     c     '('           scan      wwMsg         wwStart
     c                   if        wwStart = 0
     c                   callp     SetError(FTP_PASRPY: 'Unable to find ' +
     c                               'conn details in PASV reply.')
     c                   return    -1
     c                   endif
     c     ')'           scan      wwMsg         wwEnd
     c                   if        wwEnd < (wwStart + 8)
     c                   callp     SetError(FTP_PASRPY: 'Unable to find ' +
     c                               'conn details in PASV reply.')
     c                   return    -1
     c                   endif
     c                   eval      wwStart = wwStart + 1
     c                   eval      wwLen = wwEnd - wwStart
     c                   eval      wwPasStr = %subst(wwMsg: wwStart: wwLen)
     c                                  + x'00'

      *******************************************
      * Build actual port and IP values from
      *   the data in the PASV string
      *******************************************
     c                   eval      wwFormat = '%u,%u,%u,%u,%u,%u' + x'00'
     c                   callp     sscanf(wwPasStr: wwFormat:
     c                               i1: i2: i3: i4: p1: p2)
     c                   eval      wwPort = (p1*256) + p2
     c                   eval      wwHost = %trimr(NumToChar(i1)) + '.' +
     c                                      %trimr(NumToChar(i2)) + '.' +
     c                                      %trimr(NumToChar(i3)) + '.' +
     c                                      %trimr(NumToChar(i4))
      *-----------------------
     c                   endsr
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * RestartPt(): Tell the FTP server the point to use when
      *              resuming an FTP transfer.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P RestartPt       B
     D RestartPt       PI            10i 0

     D wwPoint         s             10u 0
     D wwReply         s             10u 0
     D wwMsg           s            256a

      *************************************************
      * do NOT allow the restart point to persist
      * past a single transfer
      *************************************************
     c                   if        wkRestPt < 1
     c                   return    0
     c                   endif

     c                   eval      wwPoint = wkRestPt

      *************************************************
      * Send the restart point to the FTP server
      *************************************************
     c                   if        SendLine(wkSocket: 'REST '
     c                                     + %trim(NumToChar(wwPoint)))<0
     c                   return    -1
     c                   endif

     c                   eval      wwReply = Reply(wkSocket: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif

      *************************************************
      * Anything but 350 means we can't restart...
      *************************************************
     c                   if        wwReply<>350
     c                   callp     SetError(FTP_BADRTR: wwMsg)
     c                   return    -1
     c                   endif

     C                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  SetType: Set file transfer type (ASCII/BINARY)
      *
      *     peSocket = descriptor returned by the ftp_conn proc
      *
      *     This sets the file transfer type to ASCII or BINARY
      *     depending on what was set with the FTP_Binary proc.
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P SetType         B
     D SetType         PI            10I 0
     D   peSocket                    10I 0 value

     D wwLine          S             20A
     D wwReply         S             10I 0
     D wwRepMsg        S            256A

      * Which mode did we want?
     c                   if        wkBinary = *ON
     c                   eval      wwLine = 'TYPE I'
     c                   else
     c                   eval      wwLine = 'TYPE A'
     c                   endif

      * Tell server about it (and make sure
      *   server understands it)
     c                   if        SendLine(peSocket: wwLine) < 0
     c                   return    -1
     c                   endif

      * What? How could an FTP server not implement this?
     c                   eval      wwReply = Reply(peSocket: wwRepMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply < 200
     c                               or wwReply > 299
     c                   callp     SetError(FTP_ERRTYP: wwRepMsg)
     c                   return    -1
     c                   endif

     c                   return    0
     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Sets the error number and message that occurs in this service
      *  program.   The FTP_ERROR proc can be used to retrieve it.
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P SetError        B                   export
     D SetError        PI
     D   peErrNum                    10I 0 value
     D   peErrMsg                    60A   const

     D savSessionIdx   S                   like(wkSessionIdx)

      *  Write error message to current session
     c                   eval      wkErrNum = peErrNum
     c                   eval      wkErrMsg = peErrMsg

      *  Duplicate error message to default session
     c                   if        wkSocket <> DFT_SESSION

      *      Save current session index
     c                   eval      savSessionIdx = wkSessionIdx

      *      Select default session
     c                   callp     cmd_occurSession(DFT_SESSION_IDX)
     c                   eval      wkErrNum = peErrNum
     c                   eval      wkErrMsg = peErrMsg

      *      Restore Session
     c                   callp     cmd_occurSession(savSessionIdx)
     c                   endif

     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Set "Session not found" error.
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P SetSessionError...
     P                 B
     D SetSessionError...
     D                 PI

     D savSessionIdx   S                   like(wkSessionIdx)

      *  Save current session index
     c                   eval      savSessionIdx = wkSessionIdx

      *  Select default session
     c                   callp     cmd_occurSession(DFT_SESSION_IDX)

      *  Write error message to default session
     c                   callp     SetError(FTP_BADHDL :
     c                                      'Session handle not found')

      *  Restore Session
     c                   callp     cmd_occurSession(savSessionIdx)

     P                 E


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  geterror, gets the error message number "errno" as well as
      *     (optionally) the text of the error message.
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P geterror        B
     D geterror        PI            10I 0
     D   peErrMsg                   256A   options(*nopass)

     D geterrno        PR              *   extproc('__errno')
     D strerror        PR              *   extproc('strerror')
     D   errno                       10I 0 value

     D p_error         S               *   INZ(*NULL)
     D wwError         S             10I 0 based(p_Error)
     D p_errmsg        S               *
     D wwErrMsg        S            256A   based(p_errmsg)
     D wwLen           S             10I 0

     C                   eval      p_error = geterrno

     c                   if        %parms >= 1
     c                   eval      p_errmsg = strerror(wwError)
     c     x'00'         scan      wwErrMsg      wwLen
     c                   eval      peErrMsg = %subst(wwErrMsg:1:wwLen)
     c                   endif

     c                   return    wwError
     p                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Sub procedure to format a numeric field into a character
      *   field, so that its easy to read.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P NumToChar       B
     D NumToChar       PI            17A
     D  pePacked                     15S 5 VALUE

     D wkReturn        S             17A
     D wkWhole         S             10A
     D wkDec           S              5A
     D wkPos           S              5I 0

     c                   eval      wkReturn = *blanks

      * handle neg sign
     c                   if        pePacked < 0
     c                   eval      wkReturn = '-'
     c                   eval      pePacked = 0 - pePacked
     c                   endif

      * Handle numbers before
      * decimal place
     c                   movel     pePacked      wkWhole
     c     '0'           check     wkWhole       wkPos
     c                   if        wkPos > 0
     c                   eval      wkReturn = %trim(wkReturn) +
     c                                          %subst(wkWhole:wkPos)
     c                   endif

      * Handle numbers after
      * decimal place
     c                   move      pePacked      wkDec
     c     '0'           checkr    wkDec         wkPos
     c                   if        wkPos > 0
     c                   eval      wkReturn = %trim(wkReturn) + '.' +
     c                                          %subst(wkDec:1:wkPos)
     c                   endif

      * Return 0 instead of *BLANKS
     c                   if        wkReturn = *BLANKS
     c                   eval      wkReturn = '0'
     c                   endif


     c                   Return    wkReturn
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This logs a diagnostic message
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P DiagLog         B
     D DiagLog         PI
     D   peMsgTxt                   256A   Const
     D wwSocket        s             10I 0
     c                   eval      wwSocket = wkSocket
     c                   if        wkLogProc = *NULL
     c                   callp     DiagMsg(peMsgTxt: wwSocket)
     c                   else
     c                   callp     LogProc(peMsgTxt: wkLogExtra)
     c                   callp     selectSession(wwSocket)
     c                   endif
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This puts a diagnostic message into the job log
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P DiagMsg         B
     D DiagMsg         PI
     D   peMsgTxt                   256A   Const
     D   peSession                   10I 0 value

     D dsEC            DS
     D  dsECBytesP                   10I 0 INZ(0)
     D  dsECBytesA                   10I 0 INZ(0)

     D QMHSNDPM        PR                  ExtPgm('QMHSNDPM')
     D   MessageID                    7A   Const
     D   QualMsgF                    20A   Const
     D   MsgData                    256A   Const
     D   MsgDtaLen                   10I 0 Const
     D   MsgType                     10A   Const
     D   CallStkEnt                  10A   Const
     D   CallStkCnt                  10I 0 Const
     D   MessageKey                   4A
     D   ErrorCode                 1024A   options(*varsize)

     D wwMsgTxt        s            268A
     D wwMsgLen        S             10I 0
     D wwTheKey        S              4A

     c                   eval      wwMsgTxt = %trim(%editc(peSession:'L')) 
     c                                      + ': ' + peMsgTxt

     c     ' '           checkr    wwMsgTxt      wwMsgLen
     c                   callp     QMHSNDPM( 'CPF9897'
     c                                     : 'QCPFMSG   *LIBL'
     c                                     : wwMsgTxt
     c                                     : wwMsgLen
     c                                     : '*DIAG'
     c                                     : '*'
     c                                     : 0
     c                                     : wwTheKey
     c                                     : dsEC )

     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Open a file & decide which read/write procs are appropriate:
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P OpnFile         B
     D OpnFile         PI            10I 0
     D   pePath                     256A   const
     D   peRWFlag                     1A   const
     D   peRdWrProc                    *   procptr
     D   peClosProc                    *   procptr
     D   peSess                      10I 0 value

     D wwPath          S            257A
     D wwLcPath        S            257A
     D wwType          S             10A
     D wwTmpType       S             10A
     D wwCP            S             10I 0
     D wwNewCP         S             10I 0
     D wwTmpMbr        S             10A
     D wwMbr           S             10A
     D wwLib           S             10A
     D wwObj           S             10A
     D wwAttr          S             10A
     D wwExists        S              1A
     D wwFD            S             10I 0
     D wwRFFlags       S             10U 0
     D wwWFFlags       S             10U 0
     D wwRRFlags       S             60A
     D wwWRFlags       S             60A
     D wwRFile         S             35A
     D wwSrc           S              1A
     D wwTS            S             12  0
     D wwDate6         S              6  0
     D wwDateFld       S               D
     D wwMsg           S            256A
     D wwNew           S              1A   inz(*on)
     d wwChkSavf       s              5
     d wwPathLen       s             10i 0

      *************************************************
      * Resolve any symlink's into their real pathnames,
      *  and retrieve the object type and codepage.
      *************************************************
     c                   eval      wwExists = *On

     c                   eval      wwPath = pePath
     c                   eval      wwPathLen = %len(%trimr(pePath))
     c                   if        wwPathLen > 5
     c     upper:lower   xlate     wwPath        wwLcPath
     c                   if        %scan('.lib': wwLcPath) > 0
     c                   eval      wwChkSavf = %subst( wwPath
     c                                               : wwPathLen - 4
     c                                               : 5)
     c     'savf':'SAVF' xlate     wwChkSavf     wwChkSavf
     c                   if        wwChkSavf = '.SAVF'
     c                   eval      %subst( wwPath
     c                                   : wwPathLen - 4
     c                                   : 5) = '.FILE'
     c                   endif
     c                   endif
     c                   endif

     c                   eval      wwPath = fixpath(wwPath: wwType: wwCP)
     c                   if        wwType=*blanks
     c                   eval      wwExists = *Off
     c                   endif

     c                   eval      wwNew = *On
     c                   if        peRWFlag = 'R'
     c                   eval      wwNew = *Off
     c                   endif

     c                   if        wwExists = *Off and peRWflag = 'R'
     c                   return    -1
     c                   endif

     c                   if        wwExists = *Off and wkRestPt>0
     c                   return    -1
     c                   endif

      *************************************************
      * Parse the pathname that was given to us, so
      *  we know the library/filename when in QSYS.LIB
      *************************************************
     c                   if        wwType='*FILE' or wwType='*MBR'
     c                                or wwExists = *Off
     c                   if        ParsePath(wwPath: wwLib: wwObj:
     c                                wwTmpMbr: wwTmpType) < 0
     c                   return    -1
     c                   endif
     c                   endif

     c                   if        wwChkSavf = '.SAVF'
     c                   eval      wwTmpType='*SAVF'
     c                   endif
      *************************************************
      * Determine file attributes for PF/LF/SAVF/etc
      *************************************************
     c                   if        wwExists = *Off
     c                   eval      wwMbr = wwTmpMbr
     c                   eval      wwType = wwTmpType
     c                   eval      wwAttr = 'PF'
     c                   eval      wwSrc=*Off
     c                   if        wwTmpType=*blanks
     c                   eval      wwType = '*STMF'
     c                   endif
     c                   if        wwTmpType='*SAVF'
     c                   eval      wwType='*FILE'
     c                   eval      wwAttr='SAVF'
     c                   endif
     c                   endif

     c                   if        wwType='*FILE' or wwType='*MBR'
     c                   if        GetFileAtr(wwObj: wwLib: wwTmpMbr:
     c                                wwNew: wwMbr: wwAttr: wwSrc) < 0
     c                   return    -1
     c                   endif
     c                   endif

      *************************************************
      * Now we've collected all the info, let's do
      *   some validity checking:
      *************************************************
     c                   select
     c                   when      (wwType='*FILE' and wwAttr='SAVF')
     c                               or wwType='*SAVF'
     c                   if        wkBinary = *Off
     C                   callp     SetError(FTP_SAVBIN: 'Save Files must ' +
     c                               'use binary mode ')
     c                   return    -1
     c                   endif

     C                   when      (wwType='*FILE' or wwType='*MBR')
     C                                and wwSrc=*on
      * XXX: Do we really want to do this?
     c                   if        wkBinary = *On
     C                   callp     SetError(FTP_SRCASC: 'Source files ' +
     c                               'should be transferred in ASCII mode ')
     c                   return    -1
     c                   endif

     c                   when      (wwType='*FILE' or wwType='*MBR')
     c                               and (wwAttr='PF' or wwAttr='LF')

     c                   when      wwType='*FILE' or wwType='*MBR'
     C                   callp     SetError(FTP_INVFIL:'Invalid file type '+
     c                              'for FTP transfer ')
     c                   return    -1

     c                   when      wwType='*STMF'
     c                   when      wwType='*DSTMF'
     c                   when      wwType='*DOC'
     c                   when      wwType='*USRSPC'
     c                   if        wkBinary = *Off
     c                   callp     SetError(FTP_USPBIN: 'User spaces ' +
     c                               'require BINARY mode ')
     c                   return    -1
     c                   endif

     c                   other
     c                   callp     SetError(FTP_INVOBJ: 'Invalid object' +
     c                               ' type.  (Make a savefile )')
     c                   return    -1
     c                   endsl

      *************************************************
      * (This is a bit of a kludge.) The open flag of
      *  'wr' should automatically clear any data
      *  from the file, but this doesn't appear to
      *  work for save files, so we do it manually...
      *************************************************
     c                   if        wwExists=*On and peRWFlag='W'
     c                               and wwType='*FILE' and wwAttr='SAVF'
     c                               and wkRestPt=0
     c                   if        Cmd('CLRSAVF FILE(' +%trim(wwLib)+'/'+
     c                                 %trim(wwObj)+')') < 0
     c                   callp     SetError(FTP_CLRSAV:'Unable to clear '+
     c                                'existing save file ')
     c                   return    -1
     c                   endif
     c                   endif

      *************************************************
      * These flags tell how the open will work:
      *************************************************
     c                   if        wkRestPt > 0
     c                   eval      wwWFFlags = O_CODEPAGE
     C                                       + O_WRONLY
     C                                       + O_APPEND
     c                   eval      wwWRFlags ='ar, arrseq=Y, secure=Y'+x'00'
     c                   else
     c                   eval      wwWFFlags = O_TRUNC
     C                                       + O_CREAT
     C                                       + O_CODEPAGE
     C                                       + O_WRONLY
     c                   eval      wwWRFlags ='wr, arrseq=Y, secure=Y'+x'00'
     c                   endif

     c                   eval      wwRFFlags = O_RDONLY
     c                   eval      wwRRFlags ='rr, arrseq=Y, secure=Y'+x'00'

     c                   if        wwMbr = *blanks
     c                   eval      wwRFile=%trim(wwLib)+'/'+%trim(wwObj)+
     c                                 x'00'
     c                   else
     c                   eval      wwRFile = %trim(wwLib)+'/'+%trim(wwObj)
     c                                 + '(' + %trim(wwMbr) + ')'+x'00'
     c                   endif

     c                   eval      wwPath = %trim(wwPath) + x'00'

      *************************************************
      * If the user hasn't specifically set ASCII
      *  to EBCDIC translation codepages, we'll
      *  set them now.
      *************************************************
     c                   if        wkBinary = *Off
     c                   if        wwExists = *Off
     c                              or wwCP < 1
     c                   eval      wwCP = wkEBCDICF_cp
     c                   endif
     c                   if        wkUsrXLate = *Off
     c                   callp     ftp_codepg(DFT_RMT_CP: wwCP)
     c                   eval      wkUsrXlate = *Off
     c                   endif
     c                   endif

      * codepage of new stream files:
     c                   if        wkBinary = *On
     c                   eval      wwNewCP = wkASCIIF_cp
     c                   else
     c                   eval      wwNewCP = wwCP
     c                   endif

      *************************************************
      *  Geez... open the damned file already
      *************************************************
     c                   select
     c                   when      peRWFlag='R'
     c                               and (wwType='*FILE' or wwType='*MBR')
     c                   eval      wkRF = Ropen(%addr(wwRfile):
     c                                          %addr(wwRRflags))
     c                   if        wkRF = *NULL
     c                   callp     geterror(wwMsg)
     c                   callp     SetError(FTP_ROPENR:wwMsg)
     c                   return    -1
     c                   endif
     c                   eval      p_xxopfb = Ropnfbk(wkRF)
     c                   eval      wwFD = 1
     c                   if        wwSrc = *On
     c                   eval      peRdWrProc = %paddr('SRC_READ')
     c                   else
     c                   eval      peRdWrProc = %paddr('RF_READ')
     c                   endif
     c                   eval      peClosProc = %paddr('RF_CLOSE')
     c                   if        wkBinary = *On
     c                   callp     ftp_linemode(peSess: 'R': pgm_reclen)
     c                   else
     c                   callp     ftp_linemode(peSess: *on: pgm_reclen)
     c                   endif

     c                   when      peRWFlag='W'
     c                               and (wwType='*FILE' or wwType='*MBR')
     c                   eval      wkRF = Ropen(%addr(wwRfile):
     c                                          %addr(wwWRflags))
     c                   if        wkRF = *NULL
     c                   callp     geterror(wwMsg)
     c                   callp     SetError(FTP_ROPENW:wwMsg)
     c                   return    -1
     c                   endif
     c                   eval      p_xxopfb = Ropnfbk(wkRF)
     c                   eval      wkRecLen = pgm_reclen
     c                   eval      wwFD = 1
     c                   if        wwSrc = *On
     c                   eval      peRdWrProc = %paddr('SRC_WRITE')
     c                   else
     c                   eval      peRdWrProc = %paddr('RF_WRITE')
     c                   endif
     c                   eval      peClosProc = %paddr('RF_CLOSE')
     c                   if        wkBinary = *On
     c                   callp     ftp_linemode(peSess: 'R')
     c                   else
     c                   callp     ftp_linemode(peSess: *on)
     c                   endif

     c                   when      peRWflag='R'
     c                   eval      wwFD = open(%addr(wwPath): wwRFflags)
     c                   if        wwFD < 0
     c                   callp     geterror(wwMsg)
     c                   callp     SetError(FTP_OPNERR:wwMsg)
     c                   return    -1
     c                   endif
     c                   eval      peRdWrProc = %paddr('IF_READ')
     c                   eval      peClosProc = %paddr('IF_CLOSE')

     c                   when      peRWflag='W'
     c                   eval      wwFD = open(%addr(wwPath): wwWFflags:
     c                                      DFT_MODE: wwNewCP)
     c                   if        wwFD < 0
     c                   callp     geterror(wwMsg)
     c                   callp     SetError(FTP_OPNERR:wwMsg)
     c                   return    -1
     c                   endif
     c                   eval      peRdWrProc = %paddr('IF_WRITE')
     c                   eval      peClosProc = %paddr('IF_CLOSE')

     c                   other
     c                   callp     SetError(FTP_UNKNWN:'Unknown error: ' +
     c                              'This shouldn''t happen ')
     c                   return    -1
     c                   eval      peRdWrProc = *NULL
     c                   eval      peClosProc = *NULL
     c                   endsl

     c                   if        wwSrc = *on
     c                   time                    wwTS
     c                   move      wwTS          wwDate6
     c     *JOBRUN       move      wwDate6       wwDateFld
     c     *YMD          move      wwDateFld     wkDsSrcDat
     c                   eval      wkDsSrcLin = 0
     c                   endif

     c                   return    wwFD
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Get file attributes. If file doesn't exist, create one and
      *  get those attributes.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P GetFileAtr      B
     D GetFileAtr      PI            10I 0
     D   peFileName                  10A   const
     D   peFileLib                   10A   const
     D   peFileMbr                   10A   const
     D   peMakeFile                   1A   const
     D   peRtnMbr                    10A
     D   peAttrib                    10A
     D   peSrcFile                    1A

     D RtvObjd         PR                  ExtPgm('QUSROBJD')
     D   RcvVar                   32766A   options(*varsize)
     D   LenRcvVar                   10I 0 const
     D   Format                       8A   const
     D   QualObj                     20A   const
     D   ObjType                     10A   const
     D   ErrorCode                32766A   options(*varsize)

     D RtvMbrd         PR                  ExtPgm('QUSRMBRD')
     D   RcvVar                   32766A   options(*varsize)
     D   LenRcvVar                   10I 0 const
     D   Format                       8A   const
     D   QualDBF                     20A   const
     D   Member                      10A   const
     D   Overrides                    1A   const
     D   errorcode                32766A   options(*varsize)

     D dsMBRD0100      DS
     D   dsMBytRtn                   10I 0
     D   dsMBytAvl                   10I 0
     D   dsMFileNam                  10A
     D   dsMFileLib                  10A
     D   dsMMbrName                  10A
     D   dsMAttrib                   10A
     D   dsMSrcTyp                   10A
     D   dsMCrtTS                    13A
     D   dsMChgTS                    13A
     D   dsMMbrTxt                   50A
     D   dsMSrcFile                   1A

     D dsObjD0200      DS
     D   dsOBytRtn                   10I 0
     D   dsOBytAvl                   10I 0
     D   dsOObjName                  10A
     D   dsOObjLib                   10A
     D   dsOObjType                  10A
     D   dsORtnLib                   10A
     D   dsOASP                      10I 0
     D   dsOOwner                    10A
     D   dsODomain                    2A
     D   dsOCrtTS                    13A
     D   dsOChgTS                    13A
     D   dsOExtAtr                   10A
     D   dsOText                     50A
     D   dsOSrcFile                  10A
     D   dsOSrcLib                   10A
     D   dsOSrcMbr                   10A

     D dsEC            DS
     D  dsECBytesP             1      4I 0 INZ(256)
     D  dsECBytesA             5      8I 0 INZ(0)
     D  dsECMsgID              9     15
     D  dsECReserv            16     16
     D  dsECMsgDta            17    256

     D wwFileMbr       S             10A
     D wwNewMbr        S             10A
     D wwRetry         S              1A   inz(*off)

     c                   eval      peSrcFile = *Off
     c                   eval      peRtnMbr = *blanks

      *************************************************
      * Get object attr.  If not found, make one,
      *  and retrieve again...
      *************************************************
     c                   dou       wwRetry = *Off

     c                   eval      wwRetry = *Off
     c                   eval      dsECBytesA = 0

     c                   callp     RtvObjD( dsObjD0200
     c                                    : %size(dsOBJD0200)
     c                                    : 'OBJD0200'
     c                                    : peFileName + peFileLib
     c                                    : '*FILE'
     c                                    : dsEC )

      **********************************
      * Object exists...
      **********************************
     c                   select
     c                   when      dsECBytesA = 0

      **********************************
      * An error occurred besides
      * "file not found"
      **********************************
     c                   when      dsECMsgID <> 'CPF9812'
     c                               and dsECMsgID <> 'CPF9801'

     c                   callp     DiagMsg('QUSROBJD API failed with ' +
     c                                 dsECMsgID: wkSocket)
     c                   callp     SetError(FTP_RTVOBJ:'Unable to retrieve'+
     c                               ' an object description ')
     c                   return    -1

      **********************************
      * File wasnt found, but we're not
      * supposed to create it...
      **********************************
     c                   when      peMakeFile = *OFF

     c                   callp     DiagMsg('QUSROBJD API failed with ' +
     c                                 dsECMsgID: wkSocket)
     c                   callp     SetError(FTP_RTVOBJ:'Unable to retrieve'+
     c                               ' an object description ')
     c                   return    -1

      **********************************
      * SAVF object not found
      **********************************
     c                   when      peAttrib = 'SAVF'

     c                   if        Cmd('CRTSAVF FILE('+%trim(peFileLib)+'/'+
     c                               %trim(peFileName)+')') < 0
     c                   callp     SetError(FTP_BLDSAV: 'Unable to make'+
     c                               ' a savefile to receive data into ')
     c                   return    -1
     c                   endif

     c                   eval      wwRetry = *On

      **********************************
      * Any other file not found --
      * assume that it's a PF with
      * a 1024 byte record.
      **********************************
     c                   other

     c                   if        Cmd('CRTPF FILE('+%trim(peFileLib)+'/'+
     c                               %trim(peFileName)+') RCDLEN(1024) ' +
     c                               'FILETYPE(*DATA) MBR(*NONE)') < 0
     c                   callp     SetError(FTP_BLDPF: 'Unable to build ' +
     c                              'a physical file to receive data into ')
     c                   return    -1
     c                   endif

     c                   eval      wwRetry = *On
     c                   endsl

     c                   enddo

     c                   eval      peAttrib = dsOExtAtr

     c                   if        dsOExtAtr<>'PF' and dsOExtAtr<>'LF'
     c                   return    0
     c                   endif

     c                   eval      wwFileMbr = peFileMbr
     c                   eval      wwNewMbr = peFileMbr
     c                   if        wwFileMbr = *blanks
     c                   eval      wwFileMbr = '*FIRST'
     c                   eval      wwNewMbr = peFileName
     c                   endif

      *************************************************
      * Get member attributes.  Create one if needed
      *************************************************
     c                   dou       wwRetry=*off
     c                   eval      wwRetry=*off
     c                   callp     RtvMbrd(dsMBRD0100: %size(dsMbrD0100):
     c                                'MBRD0100':peFileName+peFileLib:
     c                                 wwFileMbr: *OFF: dsEC)
     c                   if        dsECBytesA>0 and peMakeFile=*On
     c                               and (dsECMsgID='CPF3C27'
     c                                 or dsECMsgID='CPF3C26'
     c                                 or dsECMsgID='CPF9815')
     c                   if        Cmd('ADDPFM FILE('+%trim(peFileLib)+'/'+
     c                               %trim(peFileName)+') MBR('+
     c                               %trim(wwNewMbr)+')') < 0
     c                   callp     SetError(FTP_ADPFER: 'Unable to add a '+
     c                               'new member to receive data into ')
     c                   return    -1
     c                   endif
     c                   eval      wwRetry=*on
     c                   endif
     c                   enddo

     c                   if        dsECBytesA > 0
     c                   callp     DiagMsg('QUSRMBRD API failed with ' +
     c                                 dsECMsgID: wkSocket)
     c                   callp     SetError(FTP_RTVMBR:'Unable to retrieve'+
     c                               ' a member description ')
     c                   return    -1
     c                   endif

     c                   eval      peRtnMbr = dsMMbrName
     c                   eval      peSrcFile = dsMSrcFile
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This fixes the pathname to a file so that it'll contain the
      *   full, true pathname (not a symlink or relative pathname)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P ParsePath       B
     D ParsePath       PI            10I 0
     D   pePath                     256A   const
     D   peLibrary                   10A
     D   peObject                    10A
     D   peMember                    10A
     D   peType                      10A

     D QLG_CHAR_SINGLE...
     D                 c                   0

     D Qlg_Path_Name_T...
     D                 ds                  align
     D   CCSID                       10I 0
     D   Country_ID                   2A
     D   Language_ID                  3A
     D   Reserved                     3A
     D   Path_Type                   10U 0
     D   Path_Length                 10I 0
     D   Path_Name_Delimiter...
     D                                2A
     D   Reserved2                   10A
     D   Path_Name                  256A

     D QSYS0100        ds
     D   BytesRtn                    10I 0
     D   BytesAvl                    10I 0
     D   CCSID_out                   10I 0
     D   LibName                     28A
     D   LibType                     20A
     D   ObjName                     28A
     D   ObjType                     20A
     D   MbrName                     28A
     D   MbrType                     20A
     D   AspName                     28A

     D dsEC            DS
     D  dsECBytesP                   10I 0 inz(%size(dsEC))
     D  dsECBytesA                   10I 0 inz(0)
     D  dsECMsgID                     7A
     D  dsECReserv                    1A
     D  dsECMsgDta                 1000A

     D CvtPath         PR                  ExtProc('Qp0lCvtPathToQSYSObjName')
     D   Path                              like(Qlg_Path_Name_T)
     D   QSysInfo                          like(QSYS0100)
     D   Format                       8A   const
     D   BytesProv                   10U 0 value
     D   des_CCSID                   10U 0 value
     D   ErrorCode                 8000A   options(*varsize)

     c                   eval      peLibrary = *blanks
     c                   eval      peObject  = *blanks
     c                   eval      peMember  = *blanks
     c                   eval      peType    = *blanks

     c                   eval      Qlg_Path_Name_T = *ALLx'00'
     c                   eval      CCSID = 37
     c                   eval      Country_ID = 'US'
     c                   eval      Language_ID = 'ENU'
     c                   eval      Path_Name_Delimiter = '/'
     c                   eval      Path_Type = QLG_CHAR_SINGLE
     c                   eval      Path_Length = %len(%trimr(pePath))
     c                   eval      Path_Name = pePath

     c                   callp     CvtPath( Qlg_Path_Name_T
     c                                    :  QSYS0100
     c                                    : 'QSYS0100'
     c                                    : %size(QSYS0100)
     c                                    : 0
     c                                    : dsEC
     c                                    )

     c                   if        dsECBytesA > 0
     c                                and dsECMsgID <> 'CPFA0DB'
     c                                and dsECMsgID <> 'CPFA0A7'
     c                   return    -1
     c                   endif

     c                   if        dsECBytesA = 0

     c                   eval      peLibrary = %str(%addr(LibName))
     c                   eval      peObject  = %str(%addr(ObjName))
     c                   eval      peMember  = %str(%addr(MbrName))
     c                   eval      peType    = %str(%addr(ObjType))

     c                   if        peMember <> *blanks
     c                   eval      peType = %str(%addr(MbrType))
     c                   endif

     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This fixes the pathname to a file so that it'll contain the
      *   full, true pathname (not a symlink or relative pathname)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P fixpath         B
     D fixpath         PI           256A
     D   pePath                     256A   const
     D   peObjType                   10A
     D   peCodePg                    10I 0

     D wwPath          S            257A
     D wwReal          S            256A
     D st              ds                  likeds(statds64)
     D wwSymlink       S              1A   inz(*off)
     D wwPos           S              5I 0
     D wwErrMsg        S            256A
     D rc              S             10I 0

     c                   eval      wwPath = %trimr(%trim(pePath):x'00')
     c                   eval      st.st_codepage = DFT_LOC_CP
     c                   eval      st.st_objtype  = *blanks

      *************************************************
      * Resolve wwPath to a real link (not a symlink)
      *  and get the statds for it
      *************************************************
     c                   dou       wwSymlink = *Off

     c                   eval      wwSymLink = *Off
     c                   if        lstat64(%trimr(wwPath): st) < 0
     c                   callp     geterror(wwErrMsg)
     c                   callp     SetError(FTP_LSTAT: wwErrMsg)
     c                   leave
     c                   endif

     c                   if        s_isLnk(st.st_mode) = *on
     c                   eval      rc = readlink( %trimr(wwPath)
     c                                          : %addr(wwReal)
     c                                          : %size(wwReal))
     c                   if        rc > 0
     c                   eval      wwSymLink = *On
     c                   eval      wwPath = %subst(wwReal:1:rc)
     c                   endif
     c                   endif

     c                   enddo

      *************************************************
      *  Is wwPath a relative path?  If so, add the
      *    current directory into it...
      *************************************************
     c                   if        %subst(wwPath:1:1) <> '/'
     c                   eval      wwPath = %trimr(getdir) + wwPath
     c                   endif

     c                   eval      peObjType = st.st_objtype
     c                   eval      peCodePg = st.st_codepage

     c                   return    wwPath
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Get current working directory  (wrapper for getcwd)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P getdir          B
     D getdir          PI           256A

     D wwRetVal        S            256A
     D wwPos           S              5I 0

     c                   if        getcwd(%addr(wwRetVal): 256) = *NULL
     c                   return    './'
     c                   endif

     c     x'00'         scan      wwRetVal      wwPos
     c                   if        wwPos < 2
     c                   return    './'
     c                   endif

     c                   eval      wwRetVal = %subst(wwRetVal:1:wwPos-1)
     c                   if        %subst(wwRetVal:wwPos-1:1) <> '/'
     c                   eval      %subst(wwRetVal:wwPos:1) = '/'
     c                   endif

     c                   return    wwRetVal
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  S_ISNATIVE -- this (comparatively inefficiently) emulates the
      *      C macro to determine if an object is a "native" object.
      *
      *     #define _S_IFNATIVE 0200000     /* IBM i native object */
      *     #ifndef S_ISNATIVE
      *        #define S_ISNATIVE(m)  (((m) & 0370000) == _S_IFNATIVE)
      *     #endif
      *
      * Note that when IBM refers to a "native object" they seem to mean
      *   that the object won't work on any other operating system :)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P S_ISNATIVE      B
     D S_ISNATIVE      PI             1A
     D    peMode                     10U 0 value

     D                 ds
     D  dsmode                 1      4U 0
     D  dsbyte1                1      1A
     D  dsbyte2                2      2A
     D  dsbyte3                3      3A
     D  dsbyte4                4      4A

     c                   move      peMode        dsMode
     c                   bitoff    x'FF'         dsbyte1
     c                   bitoff    x'FE'         dsbyte2
     c                   bitoff    x'0F'         dsbyte3
     c                   bitoff    x'FF'         dsbyte4

     c                   if        dsmode = 65536
     c                   return    *on
     c                   else
     c                   return    *off
     c                   endif
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  S_ISLNK -- Is this a symbolic link?
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P S_ISLNK         B
     D S_ISLNK         PI             1A
     D    peMode                     10U 0 value

     D                 ds
     D  dsmode                 1      4U 0
     D  dsbyte1                1      1A
     D  dsbyte2                2      2A
     D  dsbyte3                3      3A
     D  dsbyte4                4      4A

     c                   move      peMode        dsMode
     c                   bitoff    x'FF'         dsbyte1
     c                   bitoff    x'FE'         dsbyte2
     c                   bitoff    x'0F'         dsbyte3
     c                   bitoff    x'FF'         dsbyte4

     c                   if        dsmode = 40960
     c                   return    *on
     c                   else
     c                   return    *off
     c                   endif
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *   Execute OS/400 command
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P Cmd             B
     D Cmd             PI            10I 0
     D  peCommand                   200A   const
     D system          PR            10I 0 ExtProc('system')
     D   cmdptr                        *   value
     D wwCmd           S            201A
     D wwRC            S             10I 0
     c                   eval      wwCmd = %trim(peCommand)+x'00'
     c                   eval      wwRC = system(%addr(wwCmd))
     c                   if        wwRC=1 or wwRC=-1
     c                   return    -1
     c                   else
     c                   return    0
     c                   endif
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  This initializes the iconv() API for character conversion
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P InitIConv       B
     D InitIConv       PI            10I 0
     D    peFile                      1A   const

      ******************************************************
      * Initialize trans tables used to talk to server
      *    on the "control connection"
      ******************************************************
     c                   if        peFile = *Off

      * Don't initialize more than once:
     c                   if        wkXLInit = *ON
     c                   return    0
     c                   endif

      * Initialize ASCII conv table:
     c                   eval      wkEBCDIC_cp = rtvJobCp
     c                   eval      wkDsToASC = iconv_open(%addr(wkDsASCII)  :
     c                                                    %addr(wkDsEBCDIC) )
     c                   if        wkICORV_A < 0
     c                   return    -1
     c                   endif

      * Initialize EBCDIC conv table:
     c                   eval      wkDsToEBC = iconv_open(%addr(wkDsEBCDIC) :
     c                                                    %addr(wkDsASCII)  )
     c                   if        wkICORV_E < 0
     c                   return    -1
     c                   endif

     c                   eval      wkXLInit = *ON
     c                   return    0
     c                   endif

      ******************************************************
      *  Initialize trans tables used to translate files
      ******************************************************
      * Don't initialize more than once:
     c                   if        wkXLFInit = *ON
     c                   return    0
     c                   endif

     c                   if        wkICORV_AF > -1
     c                   callp     iconv_clos(wkDsFileASC)
     c                   eval      wkICORV_AF = -1
     c                   endif
     c                   if        wkICORV_EF > -1
     c                   callp     iconv_clos(wkDsFileASC)
     c                   eval      wkICORV_EF = -1
     c                   endif

      * Initialize ASCII conv table:
     c                   eval      wkDsFileASC = iconv_open(%addr(wkDsASCIIF ) :
     c                                                      %addr(wkDsEBCDICF) )
     c                   if        wkICORV_AF < 0
     c                   return    -1
     c                   endif

      * Initialize EBCDIC conv table:
     c                   eval      wkDsFileEBC = iconv_open(%addr(wkDsEBCDICF) :
     c                                                      %addr(wkDsASCIIF)  )
     c                   if        wkICORV_EF < 0
     c                   return    -1
     c                   endif

     c                   eval      wkXLFInit = *ON
     c                   return    0
     c
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Translate a buffer from EBCDIC codepage 37 to ASCII 437
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P ToASCII         B
     D ToASCII         PI            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value
     D p_Buffer        S               *
     c                   if        initiconv(*OFF) < 0
     c                   return     -1
     c                   endif
     c                   eval      p_buffer = %addr(peBuffer)
     c                   return    iconv(wkDsToASC: %addr(p_buffer):peBufSize:
     c                                              %addr(p_buffer):peBufSize)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Translate a buffer from ASCII codepage 437 to EBCDIC 37
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P ToEBCDIC        B
     D ToEBCDIC        PI            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value
     D p_Buffer        S               *
     c                   if        initiconv(*OFF) < 0
     c                   return     -1
     c                   endif
     c                   eval      p_buffer = %addr(peBuffer)
     c                   return    iconv(wkDsToEBC: %addr(p_buffer):peBufSize:
     c                                              %addr(p_buffer):peBufSize)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Translate a buffer to ascii using options set by ftp_codepg
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P ToASCIIF        B
     D ToASCIIF        PI            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value
     D p_Buffer        S               *
     c                   if        initiconv(*ON) < 0
     c                   return     -1
     c                   endif
     c                   eval      p_buffer = %addr(peBuffer)
     c                   return    iconv(wkDsFileASC: %addr(p_buffer):peBufSize:
     c                                                %addr(p_buffer):peBufSize)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Translate a buffer to ebcdic using options set by ftp_codepg
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P ToEBCDICF       B
     D ToEBCDICF       PI            10I 0
     D   peBuffer                 32766A   options(*varsize)
     D   peBufSize                   10U 0 value
     D p_Buffer        S               *
     c                   if        initiconv(*ON) < 0
     c                   return     -1
     c                   endif
     c                   eval      p_buffer = %addr(peBuffer)
     c                   return    iconv(wkDsFileEBC: %addr(p_buffer):peBufSize:
     c                                                %addr(p_buffer):peBufSize)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  rtvJobCp  retrieve job codepage
      *
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P rtvJobCp        B
     D rtvJobCp        PI            10I 0

     D wwIntJobID      S             16A   inz
     D dsQJob          DS
     D   dsQ_Job                     10A   inz('*')
     D   dsQ_User                    10A   inz
     D   dsQ_Nbr                      6A   inz
     D dsJobi0400      DS
     D   dsBytRet              1      4I 0 inz
     D   dsBytAvl              5      8I 0 inz
     D   dsJob                 9     18A   inz
     D   dsName               19     28A   inz
     D   dsNbr                29     34A   inz
     D   dsCcsid             373    376I 0 inz

     c                   Callp     qusrjobi(dsJobi0400        :
     c                                      %size(dsJobi0400) :
     c                                      'JOBI0400'        :
     c                                      dsQJob            :
     c                                      wwIntJobID        )

     c                   if        dsCcsid = 65535
     c                   eval      dsCcsid = DFT_LOC_CP
     c                   endif

     c                   return    dsCcsid
     P                 E

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  lclFileSiz  determine the local file size
      *
      *  pePath  = path to local file
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P lclFileSiz      B
     D lclFileSiz      PI            16P 0
     D   pePath                     256A   const

     D wwPath          S            256A
     D st              DS                  likeds(statds64)
     D wwType          S             10A
     D wwCP            S             10I 0

     c                   eval      wwPath = fixpath(pePath: wwType: wwCP)

     c                   if        lstat64(%trimr(wwPath): st) < 0
     c                   return    0
     c                   endif

     c                   return    st.st_size
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  GetTrimLen  determine the length of a record if trimmed
      *
      *     peBuffer = record to calc trimmed len of
      *     peRecEnd = ending position of record
      *
      *  Returns the record length.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P GetTrimLen      B
     D GetTrimLen      PI            16P 0
     D   peBuffer                 32766A   options(*varsize)
     D   peRecEnd                    10I 0 value

     D X               S             10I 0

     c                   eval      X = peRecEnd

     c                   dow       %subst(peBuffer:x:1)=' '
     c                   eval      X = X -1
     c                   if        x < 1
     c                   leave
     c                   endif
     c                   enddo

     c                   return    X
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Select session.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P selectSession...
     P                 B
     D selectSession...
     D                 PI            10I 0
     D   peSocket                    10I 0 const

     D i               S                   like(wkSessionIdx)
     D savSessionIdx   S                   like(wkSessionIdx)

     c                   if        (wkSocket = peSocket)   and
     c                             (wkActive = *ON     )
     c                   return    0
     c                   endif

      *  Save session index
     c                   eval      savSessionIdx = wkSessionIdx

      *  Find session
     c     1             do        MAX_SESSION   i
     c                   callp     cmd_occurSession(i)
     c                   if        (wkSocket = peSocket)   and
     c                             (wkActive = *ON     )
     c                   eval      wkLastSocketUsed = peSocket
     c                   return    0
     c                   endif
     c                   enddo

      *  Restore session
     c                   callp     cmd_occurSession(savSessionIdx)

     c                   return    -1
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Get session index from socket descriptor.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P getSessionIdx...
     P                 B
     D getSessionIdx...
     D                 PI            10I 0
     D   peSocket                    10I 0 const

     D i               S                   like(wkSessionIdx)
     D savSessionIdx   S                   like(wkSessionIdx)

     c                   if        (wkSocket = peSocket)   and
     c                             (wkActive = *ON     )
     c                   return    wkSessionIdx
     c                   endif

      *  Save session index
     c                   eval      savSessionIdx = wkSessionIdx

      *  Find session
     c     1             do        MAX_SESSION   i
     c                   callp     cmd_occurSession(i)
     c                   if        (wkSocket = peSocket)   and
     c                             (wkActive = *ON     )
      *      Restore Session
     c                   callp     cmd_occurSession(savSessionIdx)
      *      Return session index
     c                   return    i
     c                   endif
     c                   enddo

      *  Restore session
     c                   callp     cmd_occurSession(savSessionIdx)

     c                   return    -1
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Find a free session index.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P findFreeSession...
     P                 B
     D findFreeSession...
     D                 PI            10I 0

     D newSessionIdx   S                   like(wkSessionIdx)  inz(-1)
     D i               S                   like(wkSessionIdx)
     D savSessionIdx   S                   like(wkSessionIdx)

      *  Save session index
     c                   eval      savSessionIdx = wkSessionIdx

      *  Spin through session
     c     1             do        MAX_SESSION   i
     c                   callp     cmd_occurSession(i)
     c                   if        wkActive = *OFF
      *      Preserve the new session index
     c                   eval      newSessionIdx = i
     c                   leave
     c                   endif
     c                   enddo

      *  Restore session
     c                   callp     cmd_occurSession(savSessionIdx)

     c                   return    newSessionIdx
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Create a new session.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P createSession...
     P                 B
     D createSession...
     D                 PI
     D   peSessionIdx                10I 0 const
     D   peSocket                    10I 0 const

     D savSessionIdx   S                   like(wkSessionIdx)

      *  Save session index
     c                   eval      savSessionIdx = wkSessionIdx

      *  Select session
     c                   callp     cmd_occurSession(peSessionIdx)
      *  Reset session data structures
     c                   callp     cmd_resetSession
      *  Copy session data from default session
      *  (Only if we are not initializing the FTP API service program.)
     c                   if        wkDoInitFtpApi = *OFF
     c                   callp     copySession(DFT_SESSION_IDX :
     c                                         peSessionIdx    )
     c                   endif
      *  Activate session
     c                   eval      wkActive     = *ON
     c                   eval      wkSocket     = peSocket

      *  Restore session
      *  (Only if we are not initializing the FTP API service program.)
     c                   if        wkDoInitFtpApi = *OFF
     c                   callp     cmd_occurSession(savSessionIdx)
     c                   endif

     c                   return
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Copy seesion
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P copySession...
     P                 B
     D copySession...
     D                 PI
     D   peFromIdx                   10I 0 const
     D   peToIdx                     10I 0 const

     D bufSession      S                   like(wkSession   )
     D buf_p_RtnList   S                   like(wk_p_RtnList)
     D buf_p_RtnPos    S                   like(wk_p_RtnPos )
     D bufDsSrcRec     S                   like(wkDsSrcRec  )
     D bufDsToASC      S                   like(wkDsToASC   )
     D bufDsToEBC      S                   like(wkDsToEBC   )
     D bufDsFileASC    S                   like(wkDsFileASC )
     D bufDsFileEBC    S                   like(wkDsFileEBC )
     D bufDsASCII      S                   like(wkDsASCII   )
     D bufDsEBCDIC     S                   like(wkDsEBCDIC  )
     D bufDsASCIIF     S                   like(wkDsASCIIF  )
     D bufDsEBCDICF    S                   like(wkDsEBCDICF )

     D savSessionIdx   S                   like(wkSessionIdx)

      *  Save session index
     c                   eval      savSessionIdx = wkSessionIdx

      *  Select from-session
     c                   callp     cmd_occurSession(peFromIdx)
      *     buffer session data
     c                   eval      bufSession    = wkSession
     c                   eval      buf_p_RtnList = wk_p_RtnList
     c                   eval      buf_p_RtnPos  = wk_p_RtnPos
     c                   eval      bufDsSrcRec   = wkDsSrcRec
     c                   eval      bufDsToASC    = wkDsToASC
     c                   eval      bufDsToEBC    = wkDsToEBC
     c                   eval      bufDsFileASC  = wkDsFileASC
     c                   eval      bufDsFileEBC  = wkDsFileEBC
     c                   eval      bufDsASCII    = wkDsASCII
     c                   eval      bufDsEBCDIC   = wkDsEBCDIC
     c                   eval      bufDsASCIIF   = wkDsASCIIF
     c                   eval      bufDsEBCDICF  = wkDsEBCDICF

      *  Select to-session
     c                   callp     cmd_occurSession(peToIdx)
      *     copy session data
     c                   eval      wkSession    = bufSession
     c                   eval      wk_p_RtnList = buf_p_RtnList
     c                   eval      wk_p_RtnPos  = buf_p_RtnPos
     c                   eval      wkDsSrcRec   = bufDsSrcRec
     c                   eval      wkDsToASC    = bufDsToASC
     c                   eval      wkDsToEBC    = bufDsToEBC
     c                   eval      wkDsFileASC  = bufDsFileASC
     c                   eval      wkDsFileEBC  = bufDsFileEBC
     c                   eval      wkDsASCII    = bufDsASCII
     c                   eval      wkDsEBCDIC   = bufDsEBCDIC
     c                   eval      wkDsASCIIF   = bufDsASCIIF
     c                   eval      wkDsEBCDICF  = bufDsEBCDICF

      *  Restore session data
     c                   callp     cmd_occurSession(savSessionIdx)

     c                   return
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Occur Session.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P cmd_occurSession...
     P                 B
     D cmd_occurSession...
     D                 PI
     D  peSessionIdx                 10I 0 const

     c                   eval      wkSessionIdx = peSessionIdx

     c     wkSessionIdx  occur     wkSession
     c     wkSessionIdx  occur     wkDsSrcRec
     c     wkSessionIdx  occur     wkDsToASC
     c     wkSessionIdx  occur     wkDsToEBC
     c     wkSessionIdx  occur     wkDsFileASC
     c     wkSessionIdx  occur     wkDsFileEBC
     c     wkSessionIdx  occur     wkDsASCII
     c     wkSessionIdx  occur     wkDsEBCDIC
     c     wkSessionIdx  occur     wkDsASCIIF
     c     wkSessionIdx  occur     wkDsEBCDICF

     c                   eval      wkLogProc = wkLogExit
     c                   eval      wkStsProc = wkStsExit

     c                   return
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Reset session data structures.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P cmd_resetSession...
     P                 B
     D cmd_resetSession...
     D                 PI

     D isDftSession    S              1A
     D bufActive       S                   like(wkActive)
     D bufSocket       S                   like(wkSocket)

      *  Save default session active-flag and socket descriptor
     c                   if        wkSocket = DFT_SESSION
     c                   eval      isDftSession = *ON
     c                   eval      bufActive    = wkActive
     c                   eval      bufSocket    = wkSocket
     c                   else
     c                   eval      isDftSession = *OFF
     c                   eval      bufActive    = *OFF
     c                   eval      bufSocket    = 0
     c                   endif

     c                   reset                   wkSession
     c                   reset                   wkDsSrcRec
     c                   reset                   wkDsToASC
     c                   reset                   wkDsToEBC
     c                   reset                   wkDsFileASC
     c                   reset                   wkDsFileEBC
     c                   reset                   wkDsASCII
     c                   reset                   wkDsEBCDIC
     c                   reset                   wkDsASCIIF
     c                   reset                   wkDsEBCDICF

      *  Retain default session active-flag and socket descriptor
     c                   if        isDftSession = *ON
     c                   eval      wkActive = *ON
     c                   eval      wkSocket = DFT_SESSION
     c                   endif

     c                   return
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Initialize the FTP API service program.
      * (Must be called from every exported function.)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P initFtpApi...
     P                 B
     D initFtpApi...
     D                 PI

      *  Initialize the FTP API service program
     c                   if        wkDoInitFtpApi = *ON
     c                   callp     DiagMsg('FTPAPI version ' +
     c                                      FTPAPI_VERSION   +
     c                                      ' released on '  +
     c                                      FTPAPI_RELDATE: 0)
     c                   callp     createSession(DFT_SESSION_IDX :
     c                                           DFT_SESSION     )
     c                   eval      wkDoInitFtpApi = *OFF
     c                   endif

     c                   return
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_sizereq:  Turn Size request on or off
      *
      *  Normally, FTPAPI attempts to determine the size of a file
      *  before downloading it.  You can use this function to disable
      *  or re-enable that functionality.
      *
      *     peSetting = Size request setting.   *ON = Turn size request on
      *                                        *OFF = Turn size request off
      *
      *     Returns -1 upon error, or 0 upon success.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_sizereq     B                   EXPORT
     D FTP_sizereq     PI            10I 0
     D   peSocket                    10I 0 value
     D   peSetting                    1A   const

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   if        peSetting <> *ON
     c                               and peSetting <> *OFF
     c                   callp     SetError(FTP_PESETT: 'Size request' +
     c                               ' must be *ON or *OFF ')
     c                   return    -1
     c                   endif

     c                   eval      wkSizereq = peSetting
     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_ParseURL(): Parse URL into it's component parts
      *
      *  Breaks a uniform resource locator (URL) into it's component
      *  pieces for use with the ftp: protocols.
      *
      *  peURL = URL that needs to be parsed.
      *  peService = service name from URL (i.e. ftp)
      *  peUserName = user name given, or *blanks
      *  pePassword = password given, or *blanks
      *  peHost = hostname given in URL. (could be domain name or IP)
      *  pePort = port number to connect to, if specified, otherwise 0.
      *  pePath = remaining path/request for server.
      *
      *  returns -1 upon failure, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P ftp_ParseURL    B                   export
     D ftp_ParseURL    PI            10I 0
     D  peURL                       256A   const
     D  peService                    32A
     D  peUserName                   32A
     D  pePassword                   32A
     D  peHost                      256A
     D  pePort                       10I 0
     D  pePath                      256A

     D atoi            PR            10I 0 ExtProc('atoi')
     D  string                         *   value options(*string)

     D wwLen           S             10I 0
     D wwURL           S            256A
     D wwTemp          S             65A
     D wwPos           S             10I 0

     c                   eval      peService = *Blanks
     c                   eval      peUserName = *blanks
     c                   eval      pePassword = *blanks
     c                   eval      peHost = *blanks
     c                   eval      pePort = 0
     c                   eval      pePath = *blanks
     c                   eval      wwURL = %trim(peURL)

     C****************************************************************
     C*  A valid FTP url should look like:
     C*    ftp://www.server.com/somedir/somefile.ext
     C*
     C*  and may optionally contain a user name, password & port number:
     C*
     C*    ftp://user:passwd@www.server.com:21/somedir/somefile.ext
     C****************************************************************

     C* First, extract the URL's "scheme" (which in the case of ftp
     C*  is the service's name as well):
     c                   eval      wwPos = %scan(':': wwURL)
     c                   if        wwPos < 2 or wwPos > 255
     c                   callp     SetError(FTP_BADURL:'Relative URLs '+
     c                              'are not supported ')
     c                   return    -1
     c                   endif

     c                   eval      peService = %subst(wwURL:1:wwPos-1)
     c                   eval      wwURL = %subst(wwURL:wwPos+1)
     c     upper:lower   xlate     peService     peService

     c                   if        peService<>'ftp'
     c                   callp     SetError(FTP_BADURL:'Only the FTP ' +
     c                              'protocol is available ')
     c                   return    -1
     c                   endif

     C* now the URL should be //www.server.com/mydir/somefile.ext
     C*   make sure it does start with the //, and strip that off.

     c                   if        %subst(wwURL:1:2) <> '//'
     c                   callp     SetError(FTP_BADURL:'Relative URLs '+
     c                              'are not supported ')
     c                   return    -1
     c                   endif

     c                   eval      wwURL = %subst(wwURL:3)

     C* now, either everything up to the first '/' is part of the
     C*  host name, or the entire string is a hostname.

     c                   eval      wwPos = %scan('/': wwURL)
     c                   if        wwPos = 0
     c                   eval      wwPos = %len(%trimr(wwURL)) + 1
     c                   endif

     c                   eval      peHost = %subst(wwURL:1:wwPos-1)
     c                   eval      wwURL = %subst(wwURL:wwPos)

     C* the host name may optionally contain a user name,
     C*  and possibly also a password:
     c                   eval      wwPos = %scan('@': peHost)
     c                   if        wwPos > 1 and wwPos < 256
     c                   eval      wwTemp = %subst(peHost:1:wwPos-1)
     c                   eval      peHost = %subst(peHost:wwPos+1)
     c                   eval      wwPos = %scan(':': wwTemp)
     c                   if        wwPos > 1 and wwPos < 65
     c                   eval      peUserName = %subst(wwTemp:1:wwPos-1)
     c                   eval      pePassword = %subst(wwTemp:wwPos+1)
     c                   else
     c                   eval      peUserName = wwTemp
     c                   endif
     c                   endif

     C* the host name may also specify a port number:
     c                   eval      wwPos = %scan(':': peHost)
     c                   if        wwPos > 1 and wwPos < 256
     c                   eval      wwTemp = %subst(peHost:wwPos+1)
     c                   eval      peHost = %subst(peHost:1:wwPos-1)
     c                   eval      pePort = atoi(%trimr(wwTemp))
     c                   endif

     c* After all that, do we still have a hostname?
     c                   if        peHost = *blanks
     c                   callp     SetError(FTP_BADURL:'URL does not'+
     c                              ' contain a hostname ')
     c                   return    -1
     c                   endif

     C* Whatever is left should now be the pathname to the file itself.
     c                   eval      pePath = wwURL
     c                   if        pePath = *blanks
     c                   eval      pePath = '/'
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_url_get_raw(): Retrieve a file specified via URL
      *
      *      peURL = URL to retrieve file from
      *    peDescr = Descriptor to pass to write proc
      *  peWrtProc = procedure to call to write file to disk
      *    peASCII = (optional) Use ASCII mode if *ON
      *  peTimeout = (optional) time to wait for connection to complete
      *     peAcct = (optional) account name
      *
      *  returns -1 upon failure, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_url_get_raw...
     P                 B                   EXPORT
     D FTP_url_get_raw...
     D                 PI            10I 0
     D  peURL                       256A   const
     D  peDescr                      10I 0 value
     D  peWrtProc                      *   PROCPTR value
     D  peASCII                       1N   const options(*nopass)
     D  peTimeout                    10I 0 value options(*nopass)
     D  peAcct                       32A   const options(*nopass)

     D wwSession       s             10I 0
     D wwSrv           s             32A
     D wwUsr           s             32A
     D wwPass          s             32A
     D wwHost          s            256A
     D wwPort          s             10I 0
     D wwPath          s            256A
     D wwTimeout       s             10I 0
     D wwAcct          s             32A
     D wwBinary        s              1N
     D wwRC            s             10I 0

      *********************************************************
      ** Set up defaults for any parameters that weren't passed
      *********************************************************
     c                   if        %parms >= 4
     c                   eval      wwBinary = (peASCII = *OFF)
     c                   else
     c                   eval      wwBinary = *ON
     c                   endif

     c                   if        %parms >= 5
     c                   eval      wwTimeout = peTimeout
     c                   else
     c                   eval      wwTimeout = 0
     c                   endif

     c                   if        %parms >= 6
     c                   eval      wwAcct = peAcct
     c                   else
     c                   eval      wwAcct = *blanks
     c                   endif

      *********************************************************
      ** Parse the URL
      *********************************************************
     c                   if        FTP_ParseURL(peURL: wwSrv: wwUsr:
     c                                  wwPass: wwHost: wwPort: wwPath) < 0
     c                   return    -1
     c                   endif

      *********************************************************
      ** Fill in defaults for any pieces of the URL not given
      *********************************************************
     c                   if        wwUsr = *blanks
     c                   eval      wwUsr = 'anonymous'
     c                   eval      wwPass = 'unknown@unknown.unknown'
     c                   endif

     c                   if        wwPort = 0
     c                   eval      wwPort = FTP_PORT
     c                   endif

      *********************************************************
      **  Connect to FTP server & log in
      *********************************************************
     c                   eval      wwSession = FTP_Conn(wwHost:
     c                                                  wwUsr:
     c                                                  wwPass:
     c                                                  wwPort:
     c                                                  wwTimeout)
     c                   if        wwSession < 0
     c                   return    -1
     c                   endif

      *********************************************************
      ** Retrieve the requested file
      *********************************************************
     c                   if        FTP_binaryMode(wwSession: wwBinary) <0
     c                   callp     FTP_quit(wwSession)
     c                   return    -1
     c                   endif

     c                   eval      wwRC = FTP_getraw(wwSession: wwPath:
     c                                               peDescr: peWrtProc)
     c                   callp     FTP_quit(wwSession)

     c                   return    wwRC
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_url_get(): Retrieve a file specified via URL
      *
      *      peURL = URL to retrieve file from
      *    peLocal = (optional) pathname of file to save on local disk
      *    peASCII = (optional) Use ASCII mode if *ON
      *  peTimeout = (optional) time to wait for connection to complete
      *     peAcct = (optional) account name
      *
      *  returns -1 upon failure, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_url_get     B                   EXPORT
     D FTP_url_get     PI            10I 0
     D  peURL                       256A   const
     D  peLocal                     256A   const options(*nopass)
     D  peASCII                       1N   const options(*nopass)
     D  peTimeout                    10I 0 value options(*nopass)
     D  peAcct                       32A   const options(*nopass)

     D wwSession       s             10I 0
     D wwSrv           s             32A
     D wwUsr           s             32A
     D wwPass          s             32A
     D wwHost          s            256A
     D wwPort          s             10I 0
     D wwPath          s            256A
     D wwTimeout       s             10I 0
     D wwAcct          s             32A
     D wwBinary        s              1N
     D wwRC            s             10I 0
     D wwLocal         s            256A

      *********************************************************
      ** Set up defaults for any parameters that weren't passed
      *********************************************************
     c                   if        %parms >= 2
     c                   eval      wwLocal = peLocal
     c                   else
     c                   eval      wwLocal = *blanks
     c                   endif

     c                   if        %parms >= 3
     c                   eval      wwBinary = (peASCII = *OFF)
     c                   else
     c                   eval      wwBinary = *ON
     c                   endif

     c                   if        %parms >= 4
     c                   eval      wwTimeout = peTimeout
     c                   else
     c                   eval      wwTimeout = 0
     c                   endif

     c                   if        %parms >= 5
     c                   eval      wwAcct = peAcct
     c                   else
     c                   eval      wwAcct = *blanks
     c                   endif

      *********************************************************
      ** Parse the URL
      *********************************************************
     c                   if        FTP_ParseURL(peURL: wwSrv: wwUsr:
     c                                  wwPass: wwHost: wwPort: wwPath) < 0
     c                   return    -1
     c                   endif

      *********************************************************
      ** Fill in defaults for any pieces of the URL not given
      *********************************************************
     c                   if        wwUsr = *blanks
     c                   eval      wwUsr = 'anonymous'
     c                   eval      wwPass = 'unknown@unknown.unknown'
     c                   endif

     c                   if        wwPort = 0
     c                   eval      wwPort = FTP_PORT
     c                   endif

     c                   if        wwLocal = *blanks
     c                   eval      wwLocal = wwPath
     c                   endif

      *********************************************************
      **  Connect to FTP server & log in
      *********************************************************
     c                   eval      wwSession = FTP_Conn(wwHost:
     c                                                  wwUsr:
     c                                                  wwPass:
     c                                                  wwPort:
     c                                                  wwTimeout)
     c                   if        wwSession < 0
     c                   return    -1
     c                   endif

      *********************************************************
      ** Retrieve the requested file
      *********************************************************
     c                   if        FTP_binaryMode(wwSession: wwBinary) <0
     c                   callp     FTP_quit(wwSession)
     c                   return    -1
     c                   endif

     c                   eval      wwRC = FTP_get(wwSession: wwPath:
     c                                            wwLocal)
     c                   callp     FTP_quit(wwSession)

     c                   return    wwRC
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  FTP_open(): Open a connection to an FTP server
      *
      *     peHost = host to connect to.
      *     pePort = (optional) port number to connect to. Pass 0 for the
      *              default value. The default be port 21 (standard FTP) 
      *              unless TLS is set to implcit, in which case 990 
      *              (FTPS implicit) is used.
      *  peTimeout = (optional) time (in seconds) to wait for data from 
      *               server before giving up.  Pass 0 for the default value
      *               The default is 180 (3 minutes.)
      *  peTLSMode = (optional) One of the following constants:
      *                - FTPS_NONE = TLS is not used (default)
      *                - FTPS_IMPLICIT = TLS is enabled implicitly when the
      *                                  connection is established
      *                - FTPS_TLS  = After a connection is established,
      *                               TLS is explicitly requested from the
      *                               server via AUTH SSL or AUTH TLS
      *  peTLSCtrl = (optional) One of the following constants
      *                - FTPS_PRIVATE = (default) The control channel where
      *                                  FTP commands are transmitted is 
      *                                  encrypted with TLS
      *                - FTPS_CLEAR   = The control channel uses TLS for
      *                                  login only, then drops encryption
      *                                  (needed by some older firewalls)
      *  peTLSData = (optional) One of the following constants
      *                - FTPS_PRIVATE = (default) Data channels used for
      *                                   file transfer are encrypted
      *                - FTPS_CLEAR   = Data channels are not encrypted
      *  peAppId    = (optional) digital certificate manager application id
      *  peKeyPath  = (optional) Path to GSKit keystore file
      *  peKeyPass  = (optional) Password for GSKit keystore file
      *  peKeyLabel = (optional) key store label to use
      *
      *  NOTE: If the AppId is passed, it will be used to look up TLS settings
      *        in the digital certificate manager. If not passed, the KeyPath
      *        will be used. If KeyPass and KeyLabel are provided they will
      *        be used together with the KeyPath. If neither the AppId nor 
      *        the KeyPath is provided, the system certificate store will be
      *        used with default values.
      *
      * Returns a new socket representing an FTPAPI session.
      *            or -1 upon error.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_open        B                   EXPORT
     D FTP_open        PI            10I 0
     D   peHost                     256A   const
     D   pePort                      10I 0 value options(*nopass)
     D   peTimeout                   10I 0 value options(*nopass)
     D   peTLSMode                   10i 0 value options(*nopass)
     D   peTLSCtrl                   10i 0 value options(*nopass)
     D   peTLSData                   10i 0 value options(*nopass)
     D   peAppId                    128a   varying const options(*nopass:*omit)
     D   peKeyPath                  256a   varying const options(*nopass:*omit)
     D   peKeyPass                  128A   varying const options(*nopass:*omit)
     D   peKeyLabel                 128A   varying const options(*nopass:*omit)

     D wwPort          S              5u 0 inz(FTP_PORT)
     D wwSock          S             10I 0
     D wwSessionIdx    S             10I 0

     c                   callp     initFtpApi

      * Switch to the default session to take errors
      * and to temporarily store the attributes of the new session.
     c                   if        selectSession(DFT_SESSION) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Search for a free session index
     c                   eval      wwSessionIdx = findFreeSession
     c                   if        wwSessionIdx < 0
     c                   callp     SetError(FTP_CRTHDL :
     c                                      'Can not create new session handle')
     c                   return    -1
     c                   endif

      * Reset session data structures
     c                   callp     cmd_resetSession

      * User supplied port?
     c                   if        %parms>=2 and pePort<>-1
     c                   eval      wwPort = pePort
     c                   endif

      * If FTPS is enabled in implicit mode, 
      * default port should be 990
     c                   if        %parms >= 4 
     c                             and peTlsMode = FTPS_IMPLICIT 
     c                             and pePort = -1
     c                   eval      wwPort = 990
     c                   endif

      * Set a timeout value?
     c                   if        %parms>=3 and peTimeout<>-1
     c                   eval      wkTimeout = peTimeout
     c                   else
     c                   eval      wkTimeout = 0
     c                   endif

      *************************************************
      * Connect to server:
      *************************************************
     c                   eval      wwSock = TCP_Conn(peHost: wwPort:
     c                                               wkTimeout)
     C                   if        wwSock < 0
     c                   return    -1
     c                   endif

      *************************************************
      * Put new connection into a session structure
      * to allow logging under the session ID.
      *************************************************
     c                   callp     createSession(wwSessionIdx: wwSock)
     c                   callp     selectSession(wwSock)

      *************************************************
      * Save all the TLS parameters into the session
      *************************************************
     c                   if        %parms >= 4
     c                   eval      wkTlsMode = peTlsMode
     c                   endif

     c                   if        %parms >= 5
     c                   eval      wkTlsCtrl = peTlsCtrl
     c                   endif

     c                   if        %parms >= 6
     c                   eval      wkTlsData = peTlsData
     c                   endif

     c                   if        %parms >= 7
     c                   eval      wkAppId = peAppId
     c                   endif

     c                   if        %parms >= 8
     c                   eval      wkKeyPath = peKeyPath
     c                   endif

     c                   if        %parms >= 9
     c                   eval      wkKeyPass = peKeyPass
     c                   endif

     c                   if        %parms >= 10
     c                   eval      wkKeyLabel = peKeyLabel
     c                   endif

     c                   return    wwSock
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_Login(): Log in to an FTP server.
      *
      *   peSocket = Socket created with FTP_open()
      *     peUser = user name of FTP server (or "anonymous")
      *     pePass = Password to use on FTP server (or "user@host")
      *     peAcct = (optional) account (if required by server)
      *              if not given, a blank account name will be tried
      *              if the server requests an account.
      *
      * Returns 0 if successful, -1 upon error
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_Login       B                   EXPORT
     D FTP_Login       PI            10I 0
     D   peSocket                    10I 0 value
     D   peUser                      32A   const
     D   pePass                      64A   const options(*nopass)
     D   peAcct                      32A   const options(*nopass)
     D p               s             10i 0
     C                   eval      p = %parms
     C                   select
     c                   when      p = 3
     C                   return    FTP_LoginLong( peSocket
     C                                          : peUser
     C                                          : pePass )
     c                   when      p = 4
     C                   return    FTP_LoginLong( peSocket
     C                                          : peUser
     C                                          : pePass
     C                                          : peAcct )
     c                   other
     C                   return    FTP_LoginLong( peSocket
     C                                          : peUser  )
     c                   endsl
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_LoginLong(): Log in to an FTP server w/longer fields
      *
      *   peSocket = Socket created with FTP_open()
      *     peUser = user name of FTP server (or "anonymous")
      *     pePass = Password to use on FTP server (or "user@host")
      *     peAcct = (optional) account (if required by server)
      *              if not given, a blank account name will be tried
      *              if the server requests an account.
      *
      * Returns 0 if successful, -1 upon error
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_LoginLong   B                   EXPORT
     D FTP_LoginLong   PI            10i 0
     D   peSocket                    10i 0 value
     D   peUser                    1000a   varying const
     D   pePass                    1000a   varying const options(*nopass)
     D   peAcct                    1000a   varying const options(*nopass)

     D wwMsg           S            256A
     D wwSock          S             10I 0
     D wwSaveDbg       S              1A
     D wwReply         S             10I 0
     D wwPass          s           1000a   varying inz('user@host')
     D wwAcct          S           1000A   varying

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

      * Set password
     c                   if        %parms >= 3 and pePass<>'*DEFAULT'
     c                   eval      wwPass = pePass
     c                   endif

      * Set an account name
     c                   if        %parms >= 4 and peAcct<>'*DEFAULT'
     c                   eval      wwAcct = peAcct
     c                   endif


      *************************************************
      * If in implicit mode, start TLS now
      *************************************************
     c                   if        wkTlsMode = FTPS_IMPLICIT

     c                   if        ftptcp_upgrade( peSocket
     c                                           : FTPTCP_CLIENT_SESSION
     c                                           : wkAppId
     c                                           : wkKeyPath
     c                                           : wkKeyPass
     c                                           : wkKeyLabel) = -1
     c                   return    -1
     c                   endif
     
     c                   endif

      *************************************************
      * 220 myserver.mydomain.com FTP server ready
      *************************************************
     c                   eval      wwSock = peSocket
     c                   eval      wwReply = Reply(wwSock)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 220
     c                   callp     SetError(FTP_STRRES: 'FTP Server ' +
     c                               ' didn''t give a starting response ' +
     c                               ' of 220 ')
     c                   return    -1
     c                   endif

      *************************************************
      * Enable explcit TLS with the AUTH TLS command
      *  
      * NOTE: If AUTH TLS fails, we silently try to
      *       fall back to the older 'AUTH SSL', but
      *       this is not put in the log
      *************************************************
     c                   if        wkTlsMode = FTPS_TLS

     c                   if        SendLine2(wwSock: 'AUTH TLS') < 0
     c                   return    -1
     c                   endif

     c                   eval      wwSaveDbg = wkDebug
     c                   eval      wkDebug = *off

     c                   eval      wwReply = Reply(wwSock: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif

     c                   if        wwReply = 234
     c                   callp     DiagLog(wwMsg)
     c                   eval      wkDebug = wwSaveDbg
     c                   else
     c                   callp     SendLine2(wwSock: 'AUTH SSL')
     c                   eval      wkDebug = wwSaveDbg
     c                   eval      wwReply = Reply(wwSock: wwMsg)
     c                   endif

     c                   if        wwReply <> 234
     c                   callp     setError( FTP_STRTLS
     c                                     : 'Server rejected request to +
     c                                        use TLS/SSL')
     c                   return    -1
     c                   endif
     
     c                   if        ftptcp_upgrade( wwSock
     c                                           : FTPTCP_CLIENT_SESSION
     c                                           : wkAppId
     c                                           : wkKeyPath
     c                                           : wkKeyPass
     c                                           : wkKeyLabel) = -1
     c                   return    -1
     c                   endif

     c                   endif

      *************************************************
      * Send userid:
      *************************************************
     c                   if        SendLine2(wwSock: 'USER ' + peUser) < 0
     c                   return    -1
     c                   endif

      * 230 User logged in
      * 331 Password required for user
      * 332 Account required for user
     c                   eval      wwReply = Reply(wwSock: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        (wwReply <> 230)  and
     c                             (wwReply <> 331)  and
     c                             (wwReply <> 332)
     c                   callp     SetError(FTP_BADUSR: wwMsg)
     c                   return    -1
     c                   endif

      *************************************************
      * Send password, if required ...
      *************************************************
     c                   if        wwReply = 331

      * ... Hide password from logging:
     c                   eval      wwSaveDbg = wkDebug
     c                   eval      wkDebug = *Off
     c                   if        wwSaveDbg = *On
     c                   callp     DiagLog('> PASS **********')
     c                   endif

      * ... Send password:
     c                   if        SendLine2(wwSock: 'PASS ' + wwPass) < 0
     c                   callp     ftptcp_close(wwSock)
     c                   eval      wkDebug = wwSaveDbg
     c                   return    -1
     c                   endif

     c                   eval      wkDebug = wwSaveDbg

      * ... 230 User logged in
      * ... 202 command not implemented/superfluous
      * ... 332 Account required for user
     c                   eval      wwReply = Reply(wwSock: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 230
     c                              and wwReply<> 202
     c                              and wwReply<> 332
     c                   callp     SetError(FTP_BADPAS: wwMsg)
     c                   return    -1
     c                   endif

     c                   endif                                                  ==> wwReply <> 331

      *************************************************
      * Send account information (believe it or not,
      *  some systems still use this )
      *************************************************
     c                   if        wwReply = 332

      * ... Hide account from logging:
     c                   eval      wwSaveDbg = wkDebug
     c                   eval      wkDebug = *Off
     c                   if        wwSaveDbg = *On
     c                   callp     DiagLog('> ACCT **********')
     c                   endif

     c                   if        SendLine2(wwSock: 'ACCT ' + wwAcct) < 0
     c                   eval      wkDebug = wwSaveDbg
     c                   return    -1
     c                   endif

     c                   eval      wkDebug = wwSaveDbg

     c                   eval      wwReply = Reply(wwSock: wwMsg)
     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 230
     c                              and wwReply<> 202
     c                   callp     SetError(FTP_BADACT: wwMsg)
     c                   return    -1
     c                   endif

     c                   endif


      *************************************************
      * FTP over TLS requires that we establish the
      * protection level of the data channel
      *
      *   - PBSZ is the maximum buffer size. RFC4217
      *       claims that PBSZ 0 is reasonable for a
      *       streaming protocol.  
      *   - PROT P means that data connections are
      *       encrypted with TLS. (C would mean clear)
      *************************************************
     c                   if        wkTlsMode <> FTPS_NONE

     c                   callp     SendLine2(wwSock: 'PBSZ 0')
     c                   eval      wwReply = Reply(wwSock: wwMsg)

     c                   if        wwReply = 200
     c                   if        wkTlsData = FTPS_PRIVATE
     c                   callp     SendLine2(wwSock: 'PROT P')
     c                   else
     c                   callp     SendLine2(wwSock: 'PROT C')
     c                   endif
     c                   eval      wwReply = Reply(wwSock)
     c                   endif

     c                   if        wwReply < 0
     c                   return    -1
     c                   endif
     c                   if        wwReply <> 200
     c                   callp     SetError(FTP_TLSDTA: wwMsg)
     c                   return    -1
     c                   endif

     c                   endif

      *************************************************
      * clear command channel if needed
      *  (I hate that this even exists -- it should 
      *   only be needed when a server does not support
      *   the EPSV command, and a NAT gateway doesn't
      *   understand FTPS)
      *************************************************
     c                   if        wkTlsCtrl = FTPS_CLEAR

     c                   callp     SendLine2(wwSock: 'CCC')

     c                   if        Reply(wwSock) = 200
     c                   callp     ftptcp_downgrade(wwSock)
     c                   else
     c                   callp     SetError( FTP_ENDTLS
     c                                     : 'Server is unwilling to clear +
     c                                     the control channel' )
     c                   return    -1
     c                   endif
     
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_exitProc: Register a procedure to be called at a given
      *               exit point:
      *
      *    ** PLEASE DO NOT USE FTP_CONN WITH FTP_EXITPROC **
      *
      *    FTP_Conn() is a combination of calling FTP_open() followed
      *    by FTP_login().  However, you need to register your exit
      *    proc in-between those two calls.
      *
      *    Instead of FTP_Conn, follow these steps:
      *         1) Call FTP_open() to connect to your FTP server.
      *         2) Call FTP_exitProc() and register the proc with
      *              the session number returned by FTP_open()
      *         3) Call FTP_login() to complete the login process.
      *
      *  parameters are:
      *     peSession = FTP session handle returned by FTP_open()
      *     peExitPnt = Exit point to register a procedure for
      *           FTP_EXTLOG = Procedure to call when logging control
      *                   session commands.
      *           FTP_EXTSTS = Procedure to call when showing the
      *                   current status of a file transfer.
      *     peProc    = Procedure to register (pass *NULL to disable)
      *    peExtra    = pointer to extra data you want passed to each
      *                   call of your exit proc, or *NULL for none.
      *
      *  Returns -1 upon error, 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_exitProc    B                   EXPORT
     D FTP_exitProc    PI            10I 0
     D   peSession                   10I 0 value
     D   peExitPnt                   10I 0 value
     D   peProc                        *   procptr value
     D   peExtra                       *   value

     c                   callp     initFtpApi

     c                   if        selectSession(peSession) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   return    SetSessionProc(wkSessionIdx:
     c                                            peExitPnt:
     c                                            peProc:
     c                                            peExtra)
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_Crash():  Send CPF9897 Escape Message
      *
      *    peSocket = (input) socket/session number from FTP_open()
      *       peMsg = (input/optional) Error message to send
      *
      *  If peMsg is not given, the last error message from FTPAPI
      *  will be used instead.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_Crash       B                   export
     D FTP_Crash       PI
     D    peSocket                   10i 0 value
     D    peMsg                     256a   const options(*nopass)

     D QMHSNDPM        PR                  ExtPgm('QMHSNDPM')
     D   MessageID                    7A   Const
     D   QualMsgF                    20A   Const
     D   MsgData                    256A   Const
     D   MsgDtaLen                   10I 0 Const
     D   MsgType                     10A   Const
     D   CallStkEnt                  10A   Const
     D   CallStkCnt                  10I 0 Const
     D   MessageKey                   4A
     D   ErrorCode                 1024A   options(*varsize)

     D wwMsgDta        s            256a
     D wwMsgKey        s              4a
     D wwErrorNull     s              8a

     c                   if        %parms >= 2
     c                   eval      wwMsgDta = peMsg
     C                   else
     c                   eval      wwMsgDta = FTP_errorMsg(peSocket)
     c                   endif

     C                   eval      wwErrorNull = *ALLx'00'
     C                   eval      wwMsgKey    = *ALLx'00'

     C                   callp     FTP_Quit( peSocket )

     C                   callp     QMHSNDPM( 'CPF9897'
     C                                     : 'QCPFMSG   *LIBL'
     C                                     : wwMsgDta
     C                                     : %Len(%Trimr(wwMsgDta))
     C                                     : '*ESCAPE'
     C                                     : '*PGMBDY'
     C                                     : 1
     C                                     : wwMsgKey
     C                                     : wwErrorNull )
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_Restart(): Restart a previously failed file transfer
      *                from a given byte position.
      *
      *    peSocket = (input) socket/session number from FTP_open()
      *
      *      peFile = (input) Calculate the resume position by looking
      *                       up the length of this file. (Pass *OMIT
      *                       if you do not want to use this option.)
      *
      *       pePos = (input) byte position to resume at (FTPAPI only
      *                       uses this field if peFile=*OMIT)
      *
      *  returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_Restart     B                   export
     D FTP_Restart     PI            10i 0
     D    peSocket                   10i 0 value
     D    peFile                    256A   const options(*omit)
     D    pePos                      10u 0 const options(*nopass:*omit)

     D CEETSTA         PR
     D   given                       10i 0
     D   parmno                      10i 0 const
     D   fc                          12a   options(*omit)

     D given           s             10i 0

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     C                   eval      wkRestPt = 0

     C                   callp     CEETSTA(given: 2: *omit)
     c                   if        given = 1
     c                   eval      wkRestPt = lclFileSiz(peFile)
     c                   return    0
     c                   endif

     c                   if        %parms >= 3
     C                   callp     CEETSTA(given: 3: *omit)
     c                   if        given = 1
     c                   eval      wkRestPt = pePos
     c                   endif
     c                   endif

     c                   return    0
     P                 E


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * FTP_Feat(): Ask the server for the list of supported optional
      *             features
      *
      *    peSocket = (input) socket/session number from FTP_open()
      *  peFeatures = (output) comma separated list of features 
      *
      *  returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FTP_feat        B                   export
     D FTP_feat        PI            10i 0
     D    peSocket                   10i 0 value
     D    peFeatures              32767a   varying 

     D Line            S            512A
     D replyCode       S              3P 0
     D num             S              3P 0
     D char3           S              3A

     c                   callp     initFtpApi

     c                   if        selectSession(peSocket) < 0
     c                   callp     SetSessionError
     c                   return    -1
     c                   endif

     c                   eval      peFeatures = ''

     c                   if        SendLine(wkSocket: 'FEAT') < 0
     c                   return    -1
     c                   endif

      * Get a of text
     c                   if        RecvLine(peSocket: line) < 0
     c                   return    -1
     c                   endif

      * Grab 3-digit reply code
     c                   eval      Char3 = %subst(line:1:3)
     c                   testn                   Char3                99
     c                   if        *in99 = *off
     c                   callp     SetError(FTP_BADRES: 'Not a valid FTP ' +
     c                                ' reply line ')
     c                   return    -1
     c                   endif

     c                   eval      num = 0
     c                   eval      replyCode = %int(char3)

      * If this is a single line reply, we're done.
     c                   if        %subst(line:4:1) <> '-'
     c                   return    0
     c                   endif

      * If not, get all lines of reply
      * anything that doesn't start with a reply number should be
      * a feature that this server supports.
     c                   dou       num = replyCode
     c                               and %subst(line:4:1) <> '-'

     c                   if        RecvLine(peSocket: line) < 0
     c                   return    -1
     c                   endif
     
     c                   eval      Char3 = %subst(line:1:3)
     c                   testn                   Char3                99
     
     c                   if        *in99 = *on
     c                   eval      num = %int(char3)
     
     c                   else
     c                   eval      num = 0
     c                   eval      peFeatures += %trim(%subst(line:5)) + ','
     c                   endif
     
     c                   enddo

      * there may be an extra trailing comma at the end.  Get rid of it.
     c                   if        %len(peFeatures) > 1 
     c                   eval      peFeatures = %trimr(peFeatures:',')
     c                   endif

     c                   return    0
     P                 E
   

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P QueryFeat       B                         
     D                 PI            10i 0
     D    peSocket                   10i 0 value

     D feats           s          32767a   varying 

      /free

        if FTP_feat(peSocket: feats) = -1;
          return -1;
        endif;

        feats = %xlate(lower:upper: feats);

        if %scan('CCC': feats) > 0;
        endif;

        if %scan('AUTH TLS': feats) > 0;
        endif;

        if %scan('AUTH SSL': feats) > 0;
        endif;

        return 0;
        
      /end-free
     P                 E                         

