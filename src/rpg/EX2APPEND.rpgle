      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')
      /COPY FTPAPI_H

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

     * Place the TESTPUT source member onto the FTP server
     c                   callp     ftp_binaryMode(sess: *off)
 B01 c                   if        ftp_put(sess: 'testput.rpg4':
     c                              '/qsys.lib/libftp.lib/qrpglesrc.file/' +
     c                              'testput.mbr') < 0
     c                   eval      Msg = ftp_errorMsg(sess)
     c                   dsply                   Msg
 E01 c                   endif

     * Append the TESTAPP member onto the end of the TESTPUT member
 B01 c                   if        ftp_append(sess: 'testput.rpg4':
     c                              '/qsys.lib/libftp.lib/qrpglesrc.file/' +
     c                              'testapp.mbr') < 0
     c                   eval      Msg = ftp_errorMsg(sess)
     c                   dsply                   Msg
 E01 c                   endif

     c                   callp     ftp_quit(sess)
     c                   eval      *inlr = *on
     c                   return
