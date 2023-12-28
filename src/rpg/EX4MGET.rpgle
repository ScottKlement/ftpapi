      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')
CPY  /COPY FTPAPI_H                   

     D CompMsg         PR
     D   peMsgTxt                   256A   Const

     D Incoming        S            256A   DIM(50)
     D num_files       S             10I 0
     D fileno          S             10I 0
     D rc              S             10I 0
     D fd              S             10I 0
     D ErrNum          S             10I 0
     D gotfiles        S             10I 0

     ****************************************************************
     ** This tells FTPAPIR4 to log the FTP session to the joblog
     **  so we can debug any problems that occur:
     ****************************************************************
     c                   callp     ftp_logging(0: *On)


     ****************************************************************
     ** connect to FTP server.  Log in with user name & password:
     **
     **  Here we also specify that we want to use the default
     **  port for FTP, as well as a time-out value of 120 seconds.
     **
     **  If we don't receive data for 120 seconds, the connection
     **  will "time-out"
     ****************************************************************
     C                   eval      fd = ftp_conn('ftp.freebsd.com':
     C                                           'anonymous':
     C                                           'bgates@microsoft.com':
     C                                            FTP_PORT:
     C                                            120)

 B01 c                   if        fd < 0
     c                   callp     CompMsg(FTP_errorMsg(0))
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif
     ****************************************************************
     ** get a list of up to 50 files in the pub/FreeBSD/tools dir
     ** (we intend to download all the of these files)
     ****************************************************************
 B01 c                   if        ftp_chdir(fd: 'pub/FreeBSD/tools') < 0
     c                   callp     CompMsg(ftp_errorMsg(fd))
     c                   callp     ftp_quit(fd)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     c                   eval      rc = ftp_list(fd: ' ': 50:
     c                                   %addr(incoming): num_files)


 B01 c                   if        rc<0

     c                   callp     ftp_errorMsg(fd: ErrNum)

 B02 c                   if        ErrNum = FTP_NOFILE
     c                   eval      num_files = 0
 X02 c                   else
     c                   callp     CompMsg(FTP_errorMsg(fd))
     c                   callp     ftp_quit(fd)
     c                   eval      *inlr = *on
     c                   return
 E02 c                   endif

 E01 c                   endif

     ****************************************************************
     ** download everything in tools dir into our incoming dir.
     ****************************************************************
     c                   eval      gotfiles = 0

 B01 c     1             do        num_files     fileno

     * download the rest of the files
 B02 c                   if        ftp_get(fd: incoming(fileno):
     c                                  '/incoming/' + incoming(fileno))>=0
     c                   eval      gotfiles = gotfiles + 1
 E02 c                   endif

 E01 c                   enddo

     ****************************************************************
     **  Close FTP session, and end program:
     ****************************************************************
     c                   callp     ftp_quit(fd)

 B01 c                   if        gotfiles > 0
     c                   callp     CompMsg('Success!')
 X01 c                   else
     c                   callp     CompMsg('No files received!')
 E01 c                   endif

     c                   eval      *inlr = *on


     *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *  This sends a completion message to the calling program
     *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    P CompMsg         B
     D CompMsg         PI
     D   peMsgTxt                   256A   Const

     D dsEC            DS
     *                                    Bytes Provided (size of struct)
     D  dsECBytesP             1      4B 0 INZ(256)
     *                                    Bytes Available (returned by API)
     D  dsECBytesA             5      8B 0 INZ(0)
     *                                    Msg ID of Error Msg Returned
     D  dsECMsgID              9     15
     *                                    Reserved
     D  dsECReserv            16     16
     *                                    Msg Data of Error Msg Returned
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

    P                 E
