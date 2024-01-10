**free

/if defined(FTPTCP_H)
/eof
/endif
/define FTPTCP_H

//
// FTPTCP_H: Header for FTPTCP.  These are intended to be network
//           routines for FTPAPI to move them out of the main source
//

// Copyright (c) 2001-2024 Scott C. Klement                                    +
// All rights reserved.                                                        +
//                                                                             +
// Redistribution and use in source and binary forms, with or without          +
// modification, are permitted provided that the following conditions          +
// are met:                                                                    +
// 1. Redistributions of source code must retain the above copyright           +
//    notice, this list of conditions and the following disclaimer.            +
// 2. Redistributions in binary form must reproduce the above copyright        +
//    notice, this list of conditions and the following disclaimer in the      +
//    documentation and/or other materials provided with the distribution.     +
//                                                                             +
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ''AS IS'' AND      +
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE       +
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  +
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE     +
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL  +
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS     +
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)       +
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT  +
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY   +
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      +
// SUCH DAMAGE.                                                                +

/// =======================================================================
//   ftptcp_socket
//    Create a new TCP channel 
//
//   @param (input) number of seconds (with fraction) to wait for
//                  a network event before timing out
//   @param (input) size of the TCP send/receive buffers. If -1, the
//                  default size of 128k is used.
//
//   @return a new handle to a TCP channel or -1 upon failure
/// =======================================================================

dcl-pr ftptcp_socket int(10);
  timeout packed(9: 3) value;
  bufsize int(10)      value;
end-pr;


/// =======================================================================
//  ftptcp_connect
//   connect a TCP channel to a listening server port
//
//    @param = (input) handle to TCP socket
//    @param = (input) host name or IP address to connect to
//    @param = (input) port number to connect to
//
//    @return 0 if successfully connected, -1 upon failure
/// =======================================================================

dcl-pr ftptcp_connect int(10);
  handle int(10) value;
  host   pointer value options(*string);
  port   int(10) value;
end-pr;


/// =======================================================================
//  ftptcp_listenTo
//   Listen for connections on a given port number
//
//   @param = (input) handle to TCP socket
//   @param = (input) port number to listen on
//
//   @return 0 if successful, -1 upon failure
/// =======================================================================

dcl-pr ftptcp_listenTo int(10);
  handle  int(10) value;
  port    uns(5)  value;
  backlog int(10) value;
  refSsn  int(10) value;
  rtnAddr varchar(16) options(*omit);
  rtnPort uns(5)      options(*omit);
end-pr;


/// =======================================================================
//  ftptcp_accept
//   Accept a new connection on a listening socket
//
//   @param = (input) handle to TCP socket
//   @param = (output) dotted IPv4 address of peer
//   @param = (output) remote port number of peer
//
//   @return connected fd of peer socket, or -1 upon failure
/// =======================================================================

dcl-pr ftptcp_accept int(10);
  handle  int(10) value;
  rtnAddr varchar(16) options(*omit);
  rtnPort uns(5)      options(*omit);
end-pr;


/// =======================================================================
//   ftptcp_upgrade 
//    Updates a TCP channel from plain text to TLS. Once this has run
//    everything written/read will be encrypted over the wire until the
//    ftptcp_downgrade routine is called.
//
//    @param = (input) handle to TCP socket
//    @param = (input) role (GSK_SESSION_TYPE).  
//                     - FTPTCP_SERVER_SESSION (or 508=GSK_SERVER_SESSION)
//                     - FTPTCP_CLIENT_SESSION (or 507=GSK_CLIENT_SESSION)
//    @param = (input) application id to locate settings in the digital
//                     certificate manager.
//    @param = (input) path to keyring (aka 'cert store') file on disk
//                     to use. This will take precedence over the app id.
//    @param = (input) password for keyring file (or '' if no pw needed)
//    @param = (input) label within keyring file (or '' for default label)
//
//    @return 0 for success or -1 for failure
/// =======================================================================

dcl-pr ftptcp_upgrade int(10);
  handle         int(10) value;
  role           int(10) value;
  dcm_app_id     varchar(128) const options(*omit);
  keyring_path   varchar(256) const options(*omit);
  keyring_pass   varchar(128) const options(*omit);
  keyring_label  varchar(128) const options(*omit);
end-pr;

dcl-c FTPTCP_CLIENT_SESSION 507;
dcl-c FTPTCP_SERVER_SESSION 508;


/// =======================================================================
//   ftptcp_downgrade 
//    Disable TLS on this TCP channel.  If TLS is not enabled on the socket
//    this routine is a no-op.
//
//    @param = (input) handle to TCP socket
//
//    @return 0 for success, -1 otherwise
/// =======================================================================

dcl-pr ftptcp_downgrade int(10);
  handle int(10) value;
end-pr;


/// =======================================================================
//   ftptcp_close
//    Disconnect and free-up the memory used by a TCP channel
//
//    @param = (input) handle to TCP socket
//
//    @return 0 for success, -1 otherwise
/// =======================================================================

dcl-pr ftptcp_close int(10);
  handle int(10) value;
end-pr;


/// =======================================================================
//   ftptcp_read
//    Read whatever data is currently available on the TCP channel
//
//    @param = (input) handle to TCP socket
//    @param = (output) buffer to read data into
//    @param = (input) size of buffer to read data into
//
//    @return length of the data read or -1 upon failure
/// =======================================================================

dcl-pr ftptcp_read int(20);
  handle int(10) value;
  buffer pointer value;
  bufsiz uns(20) value;
end-pr;


/// =======================================================================
//   ftptcp_write
//    Write data to a TCP channel
//
//    @param = (input) handle to TCP socket
//    @param = (input) buffer to write data from
//    @param = (input) length of data to write from buffer
//
//    @return length of the data written or -1 upon error
/// =======================================================================

dcl-pr ftptcp_write int(20);
  handle int(10) value;
  buffer pointer value;
  buflen uns(20) value;
end-pr;


/// =======================================================================
//   ftptcp_readln
//    Read a CRLF delimited line of text from a TCP channel.
//
//    @param = (input) handle to TCP socket
//    @param = (output) buffer to read data into
//    @param = (input) size of buffer to read data into
//
//    @return length of the line read or -1 upon failure
/// =======================================================================

dcl-pr ftptcp_readln int(20);
  handle int(10) value;
  buffer pointer value;
  bufsiz uns(20) value;
  lfchar char(1) const;
end-pr;


/// =======================================================================
//   ftptcp_getPeerAddr
//    Retrieve the dotted IP address of the peer on a connected socket
//
//    @param = (input) handle to TCP socket
//
//    @return dotted peer addr, or '' upon failure
/// =======================================================================

dcl-pr ftptcp_getPeerAddr varchar(256);
  handle int(10) value;
end-pr;
