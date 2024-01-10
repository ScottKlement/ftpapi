# FTPAPI -- programmatic FTP client software for ILE RPG -- README

This is the FTPAPI service program...  It is part of my efforts to
give back to the IBM i community, which has done so much for me. This
project began back in 2001.

Please read the LICENSE files that accompany this product, it will
explain your rights as well as my rights to this software.

## To compile/install it (You may replace LIBFTP with a different library
name as needed.)

1) If you haven't already, restore the source file.  If you have a
     previous installation, destroy it now:
     ```DLTLIB LIBFTP```

2) Restore the library from the savefile:
     ```RSTOBJ SAVLIB(LIBFTP) DEV(*SAVF) SAVF(FTPAPI)```

3) Create the installation program:
     ```CRTCLPGM LIBFTP/INSTALL SRCFILE(LIBFTP/QCLSRC)```

4) If you want to try the "TESTPUT" example program, you'll need to
     find an FTP server that will allow you to upload files.
     Change the server name, userid and password in the TESTPUT member.
     As appropriate.
     ```STRSEU LIBFTP/QRPGLESRC TESTPUT```

     Do the same for the "TESTAPP" example program:
     ```STRSEU LIBFTP/QRPGLESRC TESTAPP```

5) Use the INSTALL program to build everything:
     ```CALL LIBFTP/INSTALL (LIBFTP)```


## Testing it out:

1) You'll want LIBFTP in your library list
     ```ADDLIBLE LIBFTP```

2) Run this program:
     ```CALL LIBFTP/TESTGET```

3) Check it out.. you should now have fips.exe in your root directory
     in the IFS.  Do:  `WRKLNK '/*'`

4) Try sending this (if you did step #4 in installing, above)
     ```CALL LIBFTP/TESTPUT```

5)  Your FTP server should now have fips.exe

6) Try the APPEND capability (also if you did step #4 in installing)
     ```CALL LIBFTP/TESTAPP```

7) Your FTP server should now have 'testput.rpg4', and it should
     contain the text from both the TESTPUT and TESTAPP members
     of this source file.

8) Make a directory, and download a group of files into it:
     ```MKDIR '/incoming'```
     ```CALL LIBFTP/TESTMGET```

9) Check the results:
     ```WRKLNK '/incoming/*'```

also.. most of the example (TESTxxx) programs will log the FTP
commands that they run into your job log.   DSPJOBLOG is useful
to see what happened during the FTP session.

Good luck!

If you get stuck, please ask for help on the public forums:
   https://www.scottklement.com/forums/

For a list of changes made from version to version, see the CHANGELOG
file.
