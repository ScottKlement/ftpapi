      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')
CPY  /COPY FTPAPI_H                   

     D ftp             S             10I 0
     D Msg             S             52A

     D Status          PR
     D   Bytes                       16P 0 value
     D   TotBytes                    16P 0 value

     * Connect to an FTP server.
     *    using userid:  anonymous
     *        password:  anon.e.mouse@aol.com
     *
     C                   eval      ftp = ftp_conn('ftp2.freebsd.org':
     C                                            'anonymous':
     C                                            'anon.e.mouse@aol.com')
     * ftp_error will contain
     *  an error msg if ftp is < 0
 B01 c                   if        ftp < 0
     c                   eval      Msg = ftp_errorMsg(0)
     c                   dsply                   Msg
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     * Change to the FreeBSD tools directory on
     *  this FTP server.  Deal with any errors.
 B01 c                   if        ftp_chdir(ftp: 'pub/FreeBSD/tools') < 0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     * Register a 'status' procedure.   FTPAPI will call this
     *   proc whenever data is received, giving us a 'byte count'
 B01 c                   if        ftp_xproc(FTP_EXTSTS          :
     c                                       %paddr('STATUS')    )<0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif


     * Get the FIPS utility (runs under DOS)
     *   save it to the root directory, locally.
     c                   callp     ftp_binaryMode(ftp: *on)
 B01 c                   if        ftp_get(ftp: 'fips.exe': '/fips.exe') < 0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     *  The transfer was successful...
     c                   callp     ftp_quit(ftp)
     c                   eval      Msg = 'Success!'
     c                   dsply                   Msg
     c                   eval      *inlr = *on


     *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *  Example of showing the status of a file transfer.   All this
     *    does is put a status message on the screen showing the number
     *    of bytes transferred.
     *
     *  Note:  You should not do anything here that takes a lot of
     *         time, it will slow down the file transfer.
     *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    P Status          B
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
    P                 E
