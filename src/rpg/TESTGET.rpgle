      *-                                                                            +
      * Copyright (c) 2001-2024 Scott C. Klement                                    +
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
 B01 c                   if        ftp_chdir(ftp: 'pub/FreeBSD') < 0
     c                   eval      Msg = ftp_errorMsg(ftp)
     c                   dsply                   Msg
     c                   callp     ftp_quit(ftp)
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif


      * Get the README.TXT file and 
      *   save it to the /tmp directory, locally.
     c                   callp     ftp_binaryMode(ftp: *on)
 B01 c                   if        ftp_get( ftp
     c                                    : 'README.TXT'
     c                                    : '/tmp/README.TXT') < 0
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
