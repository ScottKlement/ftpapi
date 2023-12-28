      *-                                                                            +
      * Copyright (c) 2001-2021 Scott C. Klement                                    +
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


      * This is a simple example of sending ("putting") a file from this
      *  AS/400 to a remote FTP server.
      *
      * Note that unlike the GET examples, I do not know of a public server
      * where I can PUT a file as an example.  So you'll need to fill in the
      * server, user and password below to somewhere you can upload...
      *
      *

      /if defined(*CRTBNDRPG)
     H DFTACTGRP(*NO) ACTGRP(*NEW)
      /endif
     H BNDDIR('FTPAPI')

 CPY  /COPY FTPAPI_H

     D Msg             S             52A
     D sess            S             10I 0

      * connect to FTP server.  If an error occurs,
      *  display an error message and exit.
     c                   eval      sess = ftp_conn('ftpserv.mydomain.com':
     c                                        'myname':
     c                                        'mypassword')
 B01 c                   if        sess < 0
     c                   eval      Msg = ftp_errorMsg(0)
     c                   dsply                   Msg
     c                   eval      *inlr = *on
     c                   return
 E01 c                   endif

      * put the FIPS utility (downloaded in TESTGET program) on
      *  the FTP server.
     c                   callp     ftp_binaryMode(sess: *on)
 B01 c                   if        ftp_put(sess: 'fips.exe': '/fips.exe')<0
     c                   eval      Msg = ftp_errorMsg(sess)
     c                   dsply                   Msg
 E01 c                   endif

     c                   callp     ftp_quit(sess)
     c                   eval      *inlr = *on
     c                   return
