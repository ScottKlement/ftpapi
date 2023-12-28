      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')
      /COPY FTPAPI_H

     D ftp             S             10I 0
     D Msg             S             52A

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
