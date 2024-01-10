**free

//
// FTPTCP. These are intended to be network routines for FTPAPI
//         to move them out of the main source
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

ctl-opt nomain option(*srcstmt:*nodebugio);

/copy FTPTCP_H
/copy SOCKET_H
/copy GSKSSL_H
/copy ERRNO_H
/copy FTPAPI_H

dcl-pr memchr pointer extproc(*cwiden:'memchr');
  buf pointer value;
  chr int(10) value;
  len uns(10) value;
end-pr;

dcl-pr memcpy pointer extproc(*cwiden:'memcpy');
  dst pointer value;
  src pointer value;
  len uns(10) value;
end-pr;


dcl-c BUFFER_SIZE 131072;

dcl-pr setError;
  errnum int(10) value;
  errmsg char(60) const;
end-pr;

dcl-ds vanillaSsn qualified;
  TlsSoc  pointer inz(*null);
  fd      int(10) inz(-1);
  ipaddr  uns(10) inz(INADDR_NONE);
  port    int(10) inz(0);
  timeout packed(9: 3);
  host    varchar(256);
  bufSize uns(10) inz(0);
  bufLen  uns(10) inz(0);
  bufCurr pointer inz(*null);
  bufPtr  pointer inz(*null); 
end-ds;

dcl-s ssnptr pointer dim(1000);
dcl-s p_ssn pointer;
dcl-ds ssn likeds(vanillaSsn) based(p_ssn);
dcl-s tlsEnv pointer inz(*null);

dcl-pr system_errno pointer extproc('__errno');
end-pr;

/// =======================================================================
//   selectSsn 
//   INTERNAL: This chooses which TCP session is currently active in
//             the global static memory of this module.
//
//    @param = (input) handle to TCP socket
//
//    @return no return value, but p_ssn will point to the session, 
//            or will point to *NULL if there's an error.
/// =======================================================================

dcl-proc selectSsn;

  dcl-pi *n;
    handle int(10) value;
  end-pi;

  if handle >= 0 and handle < %elem(ssnptr);
    if ssnptr(handle + 1) = *null;
      ssnptr(handle + 1) = %alloc(%size(ssn));
    endif;
    p_ssn = ssnptr(handle + 1);
  else;
    p_ssn = *NULL;
  endif;

end-proc;


/// =======================================================================
//   setGskError
//   INTERNAL: This looks up the GSKit error message and calls 
//             setError() with the message.
//
//   @param = (input) FTPAPI error code to set
//   @param = (input) String identifying the area of the code where 
//                    the error occurred.
//   @param = (input) the GSKit return code that identifies the error
//
//   @return 0 if there was no error in the gskrc, 
//       or -1 if there was an error
/// =======================================================================

dcl-proc setGskError;

  dcl-pi *n int(10);
    code   int(10)      value;
    action varchar(126) const;
    gskrc  int(10)      value;
  end-pi;

  dcl-s  err  int(10) based(p_err);
  dcl-s  msg  varchar(254);

  select;
  when gskrc = GSK_OK;
    return 0;
  when gskrc = GSK_ERROR_IO;
    p_err = system_errno();
    msg = action
        + ': GSK_ERROR_IO: '
        + %str(strerror(err));
    setError(code : msg);
    return -1;
  other;
    msg = action
        + ': '
        + %str(gsk_strerror(gskrc));
    setError(code : msg);
    return -1;
  endsl;

end-proc;


/// =======================================================================
//  gskit_cleanup
//  INTERNAL: This cleans up the active GSKit environment. It is meant to
//            be called internally by GskEnvironmentCleanup(), or to be
//            called by CEE4RAGE if the activation group ends unexpectedly.
// 
//    @param = (input) the activation group that's ending
//    @param = (input) the reason the activation group is ending
//    @param = (output) result of cleanup action. We set this to 0 for
//                      successful cleanup, or 20 if there's an error.
//    @param = (output) user return code 
/// =======================================================================

dcl-proc gskit_cleanup;

  dcl-pi *n;
    ActGrpMark  uns(10);
    Reason      uns(10);
    Result      uns(10);
    UserRC      uns(10);
  end-pi;

  dcl-s rc int(10);

  if TlsEnv <> *NULL;

    rc = gsk_environment_close(TlsEnv);
    if rc = GSK_OK;
      TlsEnv = *NULL;
      result = 0;
    else;
      result = 20;
    endif;

  endif;
  
end-proc;


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

dcl-proc ftptcp_socket export;

  dcl-pi *n int(10);
    timeout packed(9: 3) value;
    bufsize int(10)      value;
  end-pi;

  dcl-s s int(10);

  s = socket(AF_INET: SOCK_STREAM: IPPROTO_IP);
  if s = -1;
    setError(FTP_ERRSKT: 'Unable to create socket');
    return -1;
  endif;

  selectSsn(s);
  eval-corr ssn = vanillaSsn;
  ssn.fd = s;

  if bufsize >= 0;
    ssn.bufSize = bufsize;
  else;
    ssn.bufSize = BUFFER_SIZE;
  endif;

  if timeout = 0;
    ssn.timeout = 180.000;
  else;
    ssn.timeout = timeout;
  endif;

  ssn.bufPtr  = %alloc(ssn.bufSize);
  ssn.bufCurr = ssn.bufPtr;

  setsockopt( ssn.fd
            : SOL_SOCKET
            : SO_RCVBUF
            : %addr(ssn.bufSize)
            : %size(ssn.bufSize));

  setsockopt( ssn.fd
            : SOL_SOCKET
            : SO_SNDBUF
            : %addr(ssn.bufSize)
            : %size(ssn.bufSize));

  return s;

end-proc;


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

dcl-proc ftptcp_connect export;

  dcl-pi *n int(10);
    handle int(10) value;
    host   pointer value options(*string);
    port   int(10) value;
  end-pi;

  dcl-ds addr        likeds(sockaddr_in);
  dcl-ds pfd         likeds(pollfd_t) dim(1);
  dcl-s  err         int(10) based(p_err);
  dcl-s  binAddr     uns(10);
  dcl-s  connErr     int(10);
  dcl-s  connErrSize int(10)  inz(%size(connErr));
  dcl-s  errNum      int(10);
  dcl-s  flags       uns(10);
  dcl-s  rc          int(10);

  binAddr = inet_addr(host);
  if binAddr = INADDR_NONE;
    p_hostent = gethostbyname(host);
    if p_hostent <> *NULL;
      binAddr = h_addr;
    endif;
  endif;

  if binAddr = INADDR_NONE;
    setError(FTP_BADIP: 'Host not found!');
    return -1;
  endif;
      
  addr = *ALLx'00';
  addr.sin_family = AF_INET;
  addr.sin_port   = port;
  addr.sin_addr   = binAddr;

  selectSsn(handle);

  flags = fcntl(ssn.fd: F_GETFL);
  flags = %bitor(flags: O_NONBLOCK);
  fcntl(ssn.fd: F_SETFL: flags);

  if connect(ssn.fd: %addr(addr): %size(addr)) = -1;
     p_err = system_errno();
     if err <> EINPROGRESS;
       setError(FTP_BADCNN: 'connect: '
                          + %str(strerror(err)));
       return -1;
     endif;
  endif;

  ssn.port = port;
  ssn.host = %str(host);
  ssn.ipaddr = binAddr;

  pfd(1) = *allx'00';
  pfd(1).fd = ssn.fd;
  pfd(1).events = POLLOUT;

  rc = poll( pfd: 1: ssn.timeout * 1000);

  select;
  when rc = 0;
    rc = close(ssn.fd);
    setError(FTP_CONNTO: 'connect: No connection made, +
                          connection timed out.');
    return -1;
  when rc = -1;
    p_err = system_errno();
    errnum = err;
    rc = close(ssn.fd);
    setError(FTP_BADCNN: 'poll: '
                       + %str(strerror(err)));
    return -1;
  endsl;
  
  if %bitand( pfd(1).revents: POLLOUT) = 0;
    rc = close(ssn.fd);
    setError(FTP_CONNTO: 'connect poll: No connection made, +
                          connection timed out.');
    return -1;
  endif;

  getsockopt(ssn.fd: SOL_SOCKET: SO_ERROR: %addr(connErr): connErrSize);
  if connErr <> 0;
    rc = close(ssn.fd);
    setError(FTP_BADCNN: 'connect: '
                       + %str(strerror(connErr)));
    return -1;
  endif;

  return 0;
end-proc;


/// =======================================================================
//  ftptcp_listenTo
//   Listen for connections on a given port number
//
//   @param = (input) handle to TCP socket
//   @param = (input) port number to listen on
//
//   @return 0 if successful, -1 upon failure
/// =======================================================================

dcl-proc ftptcp_listenTo export;

  dcl-pi *n int(10);
    handle  int(10) value;
    port    uns(5)  value;
    backlog int(10) value;
    refSsn  int(10) value;
    rtnAddr varchar(16) options(*omit);
    rtnPort uns(5)      options(*omit);
  end-pi;

  dcl-ds addr    likeds(sockaddr_in);
  dcl-ds refaddr likeds(sockaddr_in);
  dcl-s  addrLen int(10);
  dcl-s  err     int(10) based(p_err);
  dcl-s  rc      int(10);

  addr    = *ALLx'00';
  refAddr = *ALLx'00';
  addrLen = %size(refAddr);

  // 
  // Get the address that was used on the reference socket
  // (i.e. the control connection) -- we should listen to 
  // the same interface.
  //

  if refSsn >= 0;
    selectSsn(refSsn);
    if getsockname(ssn.fd: refaddr: addrLen) = -1;
      setError(FTP_GETSNM: 'Unable to get control address');
      return -1;
    endif;
    if addrLen < %size(addr.sin_family)
               + %size(addr.sin_port)
               + %size(addr.sin_addr);
      setError(FTP_GETSNM: 'Unable to get control address');
      return -1;
    endif;      
    addr.sin_addr = refAddr.sin_addr;
    if %addr(rtnAddr) <> *null;
      rtnAddr = %str(inet_ntoa(refAddr.sin_addr));
    endif;
  endif;


  // 
  // Bind to the address and port.
  //

  selectSsn(handle);
      
  addr = *ALLx'00';
  addr.sin_family = AF_INET;
  addr.sin_port   = port;

  rc = bind(ssn.fd: %addr(addr): %size(addr));
  if rc = -1;
    p_err = system_errno();
    setError( FTP_ERRBND: 'bind: '
            + %str(strerror(err)));
  endif;


  // 
  // listen to it
  //

  rc = listen(ssn.fd: backlog);
  if rc = -1;
    p_err = system_errno();
    setError( FTP_LSTERR: 'listen: '
            + %str(strerror(err)));
  endif;


  // 
  // if the return port was given, find out which port
  // was selected and return it.
  //
  
  if %addr(rtnAddr) <> *null
     or %addr(rtnPort) <> *null;
    if getsockname(ssn.fd: addr: addrLen) = -1;
      setError(FTP_GETPRT: 'Unable to get local port');
      return -1;
    endif;
    if addrLen < %size(addr.sin_family)
               + %size(addr.sin_port);
      setError(FTP_GETPRT: 'Unable to get local port');
      return -1;
    endif;      
    if %addr(rtnAddr) <> *null and addr.sin_addr <> 0;
      rtnAddr = %str(inet_ntoa(addr.sin_addr));
    endif;
    if %addr(rtnPort) <> *null;
      rtnPort = addr.sin_port;
    endif;
  endif;

  return 0;
end-proc;


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

dcl-proc ftptcp_accept export;

  dcl-pi *n int(10);
    handle  int(10) value;
    rtnAddr varchar(16) options(*omit);
    rtnPort uns(5)      options(*omit);
  end-pi;

  dcl-ds addr       likeds(sockaddr_in);
  dcl-s  addrLen    int(10);
  dcl-s  fd         int(10) inz(-1);
  dcl-s  err        int(10) based(p_err);
  dcl-ds pfd        likeds(pollfd_t) dim(1);
  dcl-s  accErr     int(10);
  dcl-s  accErrSize int(10)  inz(%size(accErr));
  dcl-s  bufsize    uns(10);
  dcl-s  timeout    packed(9: 3);
  dcl-s  rc         int(10);
  dcl-s  flags      uns(10);
  dcl-s  blocking   uns(10);

  addr = *ALLx'00';
  addrLen = 0;
  blocking = O_NONBLOCK;
  blocking = %bitnot(blocking);

  selectSsn(handle);

  // ---------------------------------------------
  //   Wait for a connection (POLLIN indicates 
  //   that there will be a connection to accept)
  // ---------------------------------------------

  pfd(1) = *allx'00';
  pfd(1).fd = ssn.fd;
  pfd(1).events = POLLIN;

  rc = poll( pfd: 1: ssn.timeout * 1000);

  if rc < 1;
    setError( FTP_TIMOUT
            : 'Timed out waiting for data connection');
    return -1;
  endif;

  // ---------------------------------------------
  //   accept the connection
  // ---------------------------------------------

  fd = accept( ssn.fd: %addr(addr): addrLen );
  if fd = -1;
    p_err = system_errno();
    setError(FTP_DTAACC: 'accept: '
            + %str(strerror(err)));
    return -1;
  endif;


  // ---------------------------------------------
  //   Check for an error
  // ---------------------------------------------

  getsockopt(fd: SOL_SOCKET: SO_ERROR: %addr(accErr): accErrSize);
  if accErr <> 0;
    rc = close(fd);
    setError(FTP_DTAACC: 'accept: '
                       + %str(strerror(accErr)));
    return -1;
  endif;


  // ---------------------------------------------
  //   Set up the session data for the newly
  //   accepted descriptor
  // ---------------------------------------------

  bufsize = ssn.bufSize;
  timeout = ssn.timeout;

  selectSsn(fd);
  eval-corr ssn = vanillaSsn;
  
  ssn.fd = fd;
  ssn.bufSize = bufsize;
  ssn.timeout = timeout;
  ssn.bufPtr  = %alloc(ssn.bufSize);
  ssn.bufCurr = ssn.bufPtr;
  ssn.ipaddr  = addr.sin_addr;
  ssn.port    = addr.sin_port;

  setsockopt( ssn.fd
            : SOL_SOCKET
            : SO_RCVBUF
            : %addr(ssn.bufSize)
            : %size(ssn.bufSize));

  setsockopt( ssn.fd
            : SOL_SOCKET
            : SO_SNDBUF
            : %addr(ssn.bufSize)
            : %size(ssn.bufSize));

  if %addr(rtnAddr) <> *null;
    rtnAddr = %str(inet_ntoa(ssn.ipaddr));
  endif;
  if %addr(rtnPort) <> *null;
    rtnPort = ssn.port;
  endif;

  return fd;
end-proc;


/// =======================================================================
//   GskEnvironmentSetup
//   INTERNAL: This sets up a TLS environment in the static memory of this
//             module that can be used to create TLS encrypted sockets
//
//    @param = (input) handle to TCP socket
//    @param = (input) application id to locate settings in the digital
//                     certificate manager.
//    @param = (input) path to keyring (aka 'cert store') file on disk
//                     to use. This will take precedence over the app id.
//    @param = (input) password for keyring file (or '' if no pw needed)
//    @param = (input) label within keyring file (or '' for default label)
//
//    NOTE: If none of the application id or keyring options are set, 
//          the default *SYSTEM cert store will be assumed.
//
//    @return 0 for success or -1 upon failure
/// =======================================================================

dcl-proc GskEnvironmentSetup;
  
  dcl-pi *n int(10);
    handle int(10) value;
    dcm_app_id     varchar(128) const options(*omit:*nopass);
    keyring_path   varchar(256) const options(*omit:*nopass);
    keyring_pass   varchar(128) const options(*omit:*nopass);
    keyring_label  varchar(128) const options(*omit:*nopass);
  end-pi;

  dcl-s rc int(10);

  dcl-ds fdbk qualified;
    sev   uns(5)  inz(0);
    msgno uns(5)  inz(0);
    flags char(1) inz(x'00');
    facid char(3) inz(x'000000');
    isi   uns(10) inz(0);
  end-ds;

  dcl-pr CEE4RAGE;
    callback pointer(*proc) const;
    feedback likeds(fdbk) options(*omit);
  end-pr;

  dcl-ds keyring qualified;
    path   varchar(254) inz('');
    app_id varchar(126) inz('');
    pass   varchar(126) inz('');
    label  varchar(126) inz('');
  end-ds;


  // --------------------------------------------
  // All of the keyring parameters are optional.
  // fill-in the keyring data structure with the
  // values passed.
  // --------------------------------------------

  if %parms >= 2 and %addr(dcm_app_id)<>*null;
    keyring.app_id = %trim(dcm_app_id);
  endif;
  if %parms >= 3 and %addr(keyring_path)<>*null;
    keyring.path = %trim(keyring_path);
  endif;
  if %parms >= 4 and %addr(keyring_pass)<>*null;
    keyring.pass = %trim(keyring_pass);
  endif;
  if %parms >= 5 and %addr(keyring_label)<>*null;
    keyring.label = %trim(keyring_label);
  endif;


  // --------------------------------------------
  // IF none of the keyring parameters were given
  // use the default (*SYSTEM cert store) setting
  // --------------------------------------------

  if keyring.app_id    = ''
     and keyring.path  = ''
     and keyring.pass  = ''
     and keyring.label = '';
     keyring.path = '*SYSTEM';
  endif;


  // --------------------------------------------
  // If the environment is already open because
  // settings were previously set -- then 
  // wipe it out to start fresh
  // --------------------------------------------

  if tlsEnv <> *NULL;
    GskEnvironmentCleanup();
    tlsEnv = *NULL;
  endif;


  // --------------------------------------------
  //  Create a new environment handle.
  //  set the various settings within it.
  // --------------------------------------------

  rc = gsk_environment_open(tlsEnv);
  if rc <> GSK_OK;
    setGskError(FTP_GSKENV: 'gsk_environment_open': rc);
    tlsEnv = *NULL;
    return -1;
  endif;

  // --------------------------------------------
  //  In case the activation group ends, 
  //  clean up the GSKit environment
  // --------------------------------------------
  CEE4RAGE(%paddr(gskit_cleanup): fdbk);


  // --------------------------------------------
  //  Keyring (cert store) parameters
  // --------------------------------------------

  if keyring.path <> '';
    rc = gsk_attribute_set_buffer( tlsEnv
                                 : GSK_KEYRING_FILE
                                 : keyring.path
                                 : %len(keyring.path) );
    if rc <> GSK_OK;
      setGskError(FTP_GSKENV: 'GSK_KEYRING_FILE': rc);
      GskEnvironmentCleanup();
      return -1;
    endif;
  endif;
  
  if keyring.pass <> '';
    rc = gsk_attribute_set_buffer( tlsEnv
                                 : GSK_KEYRING_PW
                                 : keyring.pass
                                 : %len(keyring.pass) );
    if rc <> GSK_OK;
      setGskError(FTP_GSKENV: 'GSK_KEYRING_PW': rc);
      GskEnvironmentCleanup();
      return -1;
    endif;
  endif;
  
  if keyring.label <> '';
    rc = gsk_attribute_set_buffer( tlsEnv
                                 : GSK_KEYRING_LABEL
                                 : keyring.label
                                 : %len(keyring.label) );
    if rc <> GSK_OK;
      setGskError(FTP_GSKENV: 'GSK_KEYRING_LABEL': rc);
      GskEnvironmentCleanup();
      return -1;
    endif;
  endif;


  // --------------------------------------------
  //  If there's no keystore parameters, but an
  //  application id was given, use that.
  // --------------------------------------------
   
  if keyring.path       = ''
    and keyring.pass    = ''
    and keyring.label   = ''
    and keyring.app_id <> '';
    rc = gsk_attribute_set_buffer( tlsEnv
                                 : GSK_IBMI_APPLICATION_ID
                                 : keyring.app_id
                                 : %len(keyring.app_id));
    if rc <> GSK_OK;
      setGskError(FTP_GSKENV: 'GSK_IBMI_APPLICATION_ID': rc);
      GskEnvironmentCleanup();
      return -1;
    endif;
  endif;


  // --------------------------------------------
  //  Default this environment to client sessions
  //  (but this may be overridden at the socket
  //  level)
  // --------------------------------------------

  gsk_attribute_set_enum( TlsEnv
                        : GSK_SESSION_TYPE
                        : GSK_CLIENT_SESSION );


  // --------------------------------------------
  //  Put authentication in passthru mode
  // --------------------------------------------

  gsk_attribute_set_enum( TlsEnv
                        : GSK_SERVER_AUTH_TYPE
                        : GSK_SERVER_AUTH_PASSTHRU );
  gsk_attribute_set_enum( TlsEnv
                        : GSK_CLIENT_AUTH_TYPE
                        : GSK_CLIENT_AUTH_PASSTHRU );

  // --------------------------------------------
  //  Activate all of the options set above
  // --------------------------------------------

  rc = gsk_environment_init( tlsEnv );
  if rc <> GSK_OK;
    setGskError(FTP_ENVINI: 'gsk_environment_init': rc);
    GskEnvironmentCleanup();
    return -1;
  endif;

  return 0;
end-proc;


/// =======================================================================
//  GskEnvironmentCleanup
//    INTERNAL:
//    Cleans up the environment. Greta Thunberg would be so proud!
//    Cleans up the GSKit environment currently in memory.
//
//  @return 0 for success, -1 upon failure
/// =======================================================================

dcl-proc GskEnvironmentCleanup;

  dcl-pi *n int(10);
  end-pi;

  dcl-s ActGrpMark uns(10);
  dcl-s Reason     uns(10);
  dcl-s Result     uns(10);
  dcl-s UserRC     uns(10);

  gskit_cleanup( ActGrpMark
               : Reason
               : Result
               : UserRC );

  if reason = 0;
    return 0;
  else;
    return -1;
  endif;               

end-proc;


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

dcl-proc ftptcp_upgrade export;

  dcl-pi *n int(10);
    handle         int(10) value;
    role           int(10) value;
    dcm_app_id     varchar(128) const options(*omit);
    keyring_path   varchar(256) const options(*omit);
    keyring_pass   varchar(128) const options(*omit);
    keyring_label  varchar(128) const options(*omit);
  end-pi;

  dcl-s flags uns(10);
  dcl-s rc    int(10);

  if TlsEnv = *NULL 
    and GskEnvironmentSetup( handle
                           : dcm_app_id
                           : keyring_path
                           : keyring_pass
                           : keyring_label ) = -1;
    return -1;
  endif;

  selectSsn(handle);

  rc = gsk_secure_soc_open( TlsEnv: ssn.TlsSoc );
  if rc <> GSK_OK;
    setGskError(FTP_GSKSOC: 'gsk_secure_soc_open': rc);
    return -1;
  endif;

  rc = gsk_attribute_set_numeric_value( ssn.TlsSoc
                                      : GSK_HANDSHAKE_TIMEOUT
                                      : ssn.timeout );
  if rc <> GSK_OK;
    setGskError(FTP_GSKSOC: 'GSK_HANDSHAKE_TIMEOUT': rc);
    gsk_secure_soc_close( ssn.TlsSoc );
    ssn.TlsSoc = *NULL;
    return -1;
  endif;

  rc = gsk_attribute_set_numeric_value( ssn.TlsSoc
                                      : GSK_IBMI_READ_TIMEOUT
                                      : ssn.timeout * 1000 );
  if rc <> GSK_OK;
    setGskError(FTP_GSKSOC: 'GSK_HANDSHAKE_TIMEOUT': rc);
    gsk_secure_soc_close( ssn.TlsSoc );
    ssn.TlsSoc = *NULL;
    return -1;
  endif;

  flags = fcntl(ssn.fd: F_GETFL);
  flags = %bitand(flags: %bitnot(O_NONBLOCK));
  fcntl(ssn.fd: F_SETFL);

  rc = gsk_attribute_set_numeric_value( ssn.TlsSoc
                                      : GSK_FD
                                      : ssn.fd );
  if rc <> GSK_OK;
    setGskError(FTP_GSKSOC: 'GSK_FD': rc);
    gsk_secure_soc_close( ssn.TlsSoc );
    ssn.TlsSoc = *NULL;
    return -1;
  endif;

  rc = gsk_attribute_set_buffer( ssn.TlsSoc
                               : GSK_SSL_EXTN_SERVERNAME_REQUEST
                               : ssn.host
                               : %len(ssn.host));
  // Ignore errors with Server Name Indication                               
  // if rc <> GSK_OK;
  //   setGskError(FTP_GSKSOC: 'GSK_SSL_EXTN_SERVERNAME_REQUEST': rc);
  //   return -1;
  // endif;

  // --------------------------------------------
  //  determine whether this is a client or server
  //  socket
  // --------------------------------------------

  rc = gsk_attribute_set_enum( TlsEnv
                             : GSK_SESSION_TYPE
                             : role );
  if rc <> GSK_OK;
    setGskError(FTP_GSKSOC: 'GSK_SESSION_TYPE': rc);
    gsk_secure_soc_close( ssn.TlsSoc );
    ssn.TlsSoc = *NULL;
    return -1;
  endif;


  // --------------------------------------------
  //  Put authentication in passthru mode
  // --------------------------------------------

  gsk_attribute_set_enum( ssn.TlsSoc
                        : GSK_SERVER_AUTH_TYPE
                        : GSK_SERVER_AUTH_PASSTHRU );

  gsk_attribute_set_enum( ssn.TlsSoc
                        : GSK_CLIENT_AUTH_TYPE
                        : GSK_CLIENT_AUTH_PASSTHRU );


  // --------------------------------------------
  //  Activate settings.
  //
  //   This is where the SSL/TLS handshake
  //   takes place!  It is also where we are most
  //   likely to receive TLS errors.
  // --------------------------------------------

  rc = gsk_secure_soc_init( ssn.TlsSoc );
  if rc <> GSK_OK;
    setGskError(FTP_SOCINIT: 'gsk_secure_soc_init': rc);
    gsk_secure_soc_close( ssn.TlsSoc );
    ssn.TlsSoc = *NULL;
    return -1;
  endif;

  return 0;

end-proc;


/// =======================================================================
//   ftptcp_downgrade 
//    Disable TLS on this TCP channel.  If TLS is not enabled on the socket
//    this routine is a no-op.
//
//    @param = (input) handle to TCP socket
//
//    @return 0 for success, -1 otherwise
/// =======================================================================

dcl-proc ftptcp_downgrade export;

  dcl-pi *n int(10);
    handle int(10) value;
  end-pi;

  selectSsn(handle);

  if ssn.TlsSoc <> *NULL;
    gsk_secure_soc_close( ssn.TlsSoc );
    ssn.TlsSoc = *NULL;
  endif;

  return 0;
end-proc;


/// =======================================================================
//   ftptcp_close
//    Disconnect and free-up the memory used by a TCP channel
//
//    @param = (input) handle to TCP socket
//
//    @return 0 for success, -1 otherwise
/// =======================================================================

dcl-proc ftptcp_close export;

  dcl-pi *n int(10);
    handle int(10) value;
  end-pi;

  dcl-s rc  int(10);
  dcl-s err int(10) based(p_err);
  dcl-s handle_plus_one int(10);

  ftptcp_downgrade(handle);
  selectSsn(handle);

  if ssn.fd <> -1;

    rc = close(ssn.fd);
    if rc = -1;
      p_err = system_errno();
      setError(FTP_CLSERR
              :'close: ' + %str(strerror(err)));
      return -1;
    endif;

    ssn.fd = -1;

  endif;

  if ssn.bufptr <> *null;
    dealloc ssn.bufptr;
    ssn.bufptr = *NULL;
    ssn.bufcurr = *NULL;
    ssn.bufSize = 0;
    ssn.buflen = 0;
  endif;

  handle_plus_one = handle + 1;
  dealloc ssnptr(handle_plus_one);
  ssnptr(handle_plus_one) = *NULL;
  p_ssn = *NULL;
  return 0;

end-proc;


/// =======================================================================
//  tcpread
//
//  INTERNAL: This is a wrapper around recv() (or read()) that handles
//            non-blocking and timeouts correctly.
//
//  @param (input) socket descriptor to read from
//  @param (output) pointer to buffer to read data into
//  @param (input)  size of the buffer to read into
//  @param (input)  number of seconds (possibly with fraction) to wait
//                  for data before timing out.  0=return immediately.
//
//  @return the length of the data read or -1 upon failure
/// =======================================================================

dcl-proc tcpread;

  dcl-pi *n int(10);
    fd      int(10)      value;
    buf     pointer      value;
    bufsiz  uns(10)      value;
    timeout packed(9: 3) value;
  end-pi;

  dcl-s  err int(10) based(p_err);
  dcl-s  len int(10) inz(0);
  dcl-s  rc  int(10) inz(0);
  dcl-ds pfd likeds(pollfd_t) dim(1);

  dou len > 0;

    len = recv(fd: buf: bufsiz: 0);

    if len = 0;

      setError( FTP_DISCON
              : 'Connection dropped while reading data.');
      return -1;              
  
    elseif len = -1;

      p_err = system_errno();
      if err <> EAGAIN;
        setError( FTP_DISCON: %str(strerror(err)));
        return -1;
      endif;

      pfd(1) = *allx'00';
      pfd(1).fd = fd;
      pfd(1).events = POLLIN;

      rc = poll( pfd: 1: timeout * 1000);
      if rc = -1;
        setError( FTP_POLERR
                : 'poll: ' + %str(strerror(err)));
        return -1;
      elseif rc = 0;
        setError( FTP_TIMOUT
                : 'Timed out while reading data from network.');
        return -1;
      endif;

    endif;
  
  enddo;

  return len;

end-proc;



/// =======================================================================
//  tcpwrite
//
//  INTERNAL: This is a wrapper around send() (or write()) that handles
//            non-blocking and timeouts correctly.
//
//  @param (input)  socket descriptor to write to
//  @param (output) pointer to buffer to write data from
//  @param (input)  length of the data in the buffer to wite
//  @param (input)  number of seconds (possibly with fraction) to wait
//                  for data before timing out.  0=return immediately.
//
//  @return the length of the data written or -1 upon failure
/// =======================================================================

dcl-proc tcpwrite;

  dcl-pi *n int(10);
    fd      int(10)      value;
    buf     pointer      value;
    buflen  uns(10)      value;
    timeout packed(9: 3) value;
  end-pi;

  dcl-s  err int(10) based(p_err);
  dcl-s  len int(10) inz(0);
  dcl-s  rc  int(10) inz(0);
  dcl-ds pfd likeds(pollfd_t) dim(1);
  dcl-s  total int(10) inz(0);

  dou buflen <= 0;

    len = send(fd: buf: buflen: 0);

    if len < buflen;

      p_err = system_errno();
      if err <> EAGAIN;
        setError( FTP_WRTNET
                : 'send: ' + %str(strerror(err)));
        return -1;
      endif;

      pfd(1) = *allx'00';
      pfd(1).fd = fd;
      pfd(1).events = POLLOUT;

      rc = poll( pfd: 1: timeout * 1000);
      if rc = -1;
        setError( FTP_POLERR
                : 'poll: ' + %str(strerror(err)));
        return -1;
      elseif rc = 0;
        setError( FTP_TIMOUT
                : 'Timed out while writing data to network.');
        return -1;
      else;
        len = 0;
      endif;

    endif;

    if len > 0;
      total += len;
      buflen -= len;
      if buflen > 0;
        buf += len;
      endif;
    endif;

  enddo;

  return len;

end-proc;


/// =======================================================================
//   refill
//   INTERNAL: Makes sure there is data in the session read buffer (by 
//             waiting for it and loading it if neccesary.)
//
//   @return the number of bytes currently in the read buffer
//           or -1 upon failure
/// =======================================================================

dcl-proc refill;
  
  dcl-pi *n int(10);
  end-pi;

  dcl-s len int(10);
  dcl-s rc  int(10);

  if ssn.bufLen > 0;
    return ssn.bufLen;
  endif;

  ssn.bufCurr = ssn.bufPtr;

  dou len > 0;

    if ssn.tlsSoc = *NULL;

      len = tcpread(ssn.fd: ssn.bufCurr: ssn.bufSize: ssn.timeout);
      if len = -1;
        return len;
      endif;

    else;

      rc = gsk_secure_soc_read( ssn.tlsSoc: ssn.bufCurr: ssn.bufSize: len );
      if rc <> GSK_OK;

        if len = 0;
          setError( FTP_DISCON
                  : 'Connection dropped while reading data.');
          return -1;
        elseif rc = GSK_IBMI_ERROR_TIMED_OUT;
          setError( FTP_TIMOUT
                  : 'Timed out while reading data from network.');
          return -1;
        else;
          return setGskError( FTP_DISCON
                            : 'gsk_secure_soc_read'
                            : rc );
        endif;

      endif;

    endif;

  enddo;

  ssn.bufLen += len;
  return ssn.bufLen;

end-proc;


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

dcl-proc ftptcp_read export;

  dcl-pi *n int(20);
    handle int(10) value;
    buffer pointer value;
    bufsiz uns(20) value;
  end-pi;

  dcl-s len uns(10);

  selectSsn(handle);

  if refill() = -1;
    return -1;
  endif;

  len = bufsiz;
  if len > ssn.bufLen;
    len = ssn.bufLen;
  endif;

  if len > 0;
    memcpy(buffer: ssn.bufCurr: len);
    ssn.bufLen -= len;
    if ssn.bufLen > 0;
      ssn.bufCurr += len;
    endif;
  endif;

  return len;
end-proc;


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

dcl-proc ftptcp_write export;

  dcl-pi *n int(20);
    handle int(10) value;
    buffer pointer value;
    buflen uns(20) value;
  end-pi;

  dcl-s len int(10);
  dcl-s rc  int(10);

  selectSsn(handle);

  if ssn.tlsSoc = *null;

    rc = tcpwrite(ssn.fd: buffer: buflen: ssn.timeout);
    if rc = -1;
      return -1;
    else;
      len = rc;
    endif;

  else;

    rc = gsk_secure_soc_write(ssn.tlsSoc: buffer: buflen: len);
    if rc <> GSK_OK;
      setGskError( FTP_WRTNET
                 : 'gsk_secure_soc_write'
                 : rc );
      return -1;
    endif;

  endif;

  return len;
end-proc;


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

dcl-proc ftptcp_readln export;

  dcl-pi *n int(20);
    handle int(10) value;
    buffer pointer value;
    bufsiz uns(20) value;
    lfchar char(1) const;
  end-pi;

  dcl-s total  uns(20) inz(0);
  dcl-s len    int(10);
  dcl-s left   uns(20);
  dcl-s bufpos pointer;
  dcl-s pos    pointer;

  dcl-ds val qualified;
    ch    char(1);
    chnum uns(3) overlay(ch);
  end-ds;
    
  val.ch = lfchar;

  selectSsn(handle);

  len    = 0;
  left   = bufsiz;
  bufpos = buffer;

  dow left > 0;

    // ---------------------------------------------
    //  Step 1: make sure there's data in the buffer
    // ---------------------------------------------

    if refill() = -1;
      return -1;
    endif;


    // ---------------------------------------------
    //  Step 2: Restrict search area to the size of
    //          the data in the buffer, or the data
    //          we have space for.
    // ---------------------------------------------

    len = ssn.bufLen;
    if len > left;
      len = left;
    endif;


    // ---------------------------------------------
    //  Step 3a: Find a linefeed character. If found
    //           copy up to that character into
    //           the output buffer.
    // ---------------------------------------------

    pos = memchr(ssn.bufCurr: val.chnum: len);
    if pos <> *null;
      len = (pos - ssn.bufCurr) + 1;
      memcpy(bufpos: ssn.bufCurr: len);
      ssn.bufLen -= len;
      left -= len;
      if ssn.bufLen > 0;
        ssn.bufCurr += len;
      endif;
      leave;
    endif;


    // ---------------------------------------------
    //  Step 3b: If there is no linefeed, copy 
    //           whatever is available, then get
    //           more data.
    // ---------------------------------------------

    memcpy(bufpos: ssn.bufCurr: len);
    ssn.bufLen -= len;
    left -= len;
    if left > 0;
      bufpos += len;
    endif;
    if ssn.bufLen > 0;
      ssn.bufCurr += len;
    endif;

  enddo;

  total = bufsiz - left;
  return total;
end-proc;


/// =======================================================================
//   ftptcp_getPeerAddr
//    Retrieve the dotted IP address of the peer on a connected socket
//
//    @param = (input) handle to TCP socket
//
//    @return dotted peer addr, or '' upon failure
/// =======================================================================

dcl-proc ftptcp_getPeerAddr export;

  dcl-pi *n varchar(256);
    handle int(10) value;
  end-pi;

  dcl-ds addr    likeds(sockaddr_in);
  dcl-s  addrLen int(10) inz(%size(addr));
  dcl-s  dotted  varchar(256);

  selectSsn(handle);

  if getpeername(ssn.fd: addr: addrLen) = -1;
    return '';
  endif;

  if addrLen < %size(sin_Family) 
             + %size(sin_port)
             + %size(sin_addr);
    return '';
  endif;

  dotted = %str(inet_ntoa(addr.sin_addr));
  return dotted;

end-proc;
