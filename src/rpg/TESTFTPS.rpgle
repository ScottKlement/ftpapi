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
      */                                                                            +


      * This is a simple example of sending ("putting") a file from this
      *  IBM i system to a remote FTP server.
      *
      * Note that unlike the GET examples, I do not know of a public server
      * where I can PUT a file as an example.  So you'll need to fill in the
      * server, user and password below to somewhere you can upload...
      *
      *

      /if defined(*CRTBNDRPG)
        ctl-opt dftactgrp(*no);
      /endif
        ctl-opt BNDDIR('FTPAPI');

      /copy FTPAPI_H

        dcl-s msg char(52);
        dcl-s sess int(10);

        // connect to FTP server. Setting FTPS_TLS will 
        // require the use of TLS (formerly known as "SSL")
        // to encrypt the connection

        sess = FTP_open( 'localhost'
                       : -1
                       : 15
                       : FTPS_TLS
                       : FTPS_PRIVATE
                       : FTPS_PRIVATE );
        if sess = -1;
          msg = ftp_errorMsg(0);
          dsply msg;
          *inlr = *on;
          return;
        endif;

        if FTP_login(sess: 'your userid': 'your password') = -1;
          msg = ftp_errorMsg(0);
          dsply msg;
          FTP_quit(sess);
          *inlr = *on;
          return;
        endif;
         

        FTP_binaryMode(sess: *on);
        FTP_passiveMode(sess: *on);

        if FTP_put( sess
                  : 'README.TXT'
                  : '/tmp/README.TXT') = -1;
          msg = ftp_errorMsg(0);
          dsply msg;
        endif;

        FTP_quit(sess);
        *inlr = *on;