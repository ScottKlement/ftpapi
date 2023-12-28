      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')
CPY  /COPY FTPAPI_H
     D Msg             S             52A
     D sess            S             10I 0

     * connect to FTP server.  If an error occurs,
     *  display an error message and exit.
     c                   eval      sess = ftp_conn('ftpserv.mydomain.com':
     c                                        'myname':
     c                                        'mypassword')
 B01 c                   if        sess < 0
     c                   eval      Msg = ftp_errorMsg(0)
     c                   dsply                   Msg
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

     * put the FIPS utility (downloaded in TESTGET program) on
     *  the FTP server.
     c                   callp     ftp_binaryMode(sess: *on)
 B01 c                   if        ftp_put(sess: 'fips.exe': '/fips.exe')<0
     c                   eval      Msg = ftp_errorMsg(sess)
     c                   dsply                   Msg
 E01 c                   endif

     c                   callp     ftp_quit(sess)
     c                   eval      *inlr = *on
     c                   return
