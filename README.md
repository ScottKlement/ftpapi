This is the FTPAPI service program...  It is part of my efforts to
give back to the AS/400 community, which has done so much for me.

Please read the license info at the top of the source members, they
explain your rights with this product, as well as mine.

At the moment, this project is still "ALPHA".  It needs a lot more
work, including documentation, features and testing.

To compile/install it:  (instead of LIBFTP, use whatever you like:)

1) If you haven't already, restore the source file.  If you have a
     previous installation, destroy it now:
     DLTLIB LIBFTP

2) Restore the library from the savefile:
     RSTOBJ SAVLIB(LIBFTP) DEV(*SAVF) SAVF(FTPAPI)

3) Create the installation program:
     CRTCLPGM LIBFTP/INSTALL SRCFILE(LIBFTP/QCLSRC)

4) If you want to try the "TESTPUT" example program, you'll need to
     find an FTP server that will allow you to upload files.
     Change the server name, userid and password in the TESTPUT member.
     As appropriate.
     STRSEU LIBFTP/QRPGLESRC TESTPUT

     Do the same for the "TESTAPP" example program:
     STRSEU LIBFTP/QRPGLESRC TESTAPP

5) Use the INSTALL program to build everything:
     CALL LIBFTP/INSTALL (LIBFTP)


Testing it out:

1) You'll want LIBFTP in your library list
     ADDLIBLE LIBFTP

2) Run this program:
     CALL LIBFTP/TESTGET

3) Check it out.. you should now have fips.exe in your root directory
     in the IFS.  Do:  WRKLNK '/*'

4) Try sending this (if you did step #4 in installing, above)
     CALL LIBFTP/TESTPUT

5)  Your FTP server should now have fips.exe

6) Try the APPEND capability (also if you did step #4 in installing)
     CALL LIBFTP/TESTAPP

7) Your FTP server should now have 'testput.rpg4', and it should
     contain the text from both the TESTPUT and TESTAPP members
     of this source file.

8) Make a directory, and download a group of files into it:
     MKDIR '/incoming'
     CALL LIBFTP/TESTMGET

9) Check the results:
     WRKLNK '/incoming/*'


also.. most of the example (TESTxxx) programs will log the FTP
commands that they run into your job log.   DSPJOBLOG is useful
to see what happened during the FTP session.

Good luck!

If you get stuck, see:    http://www.scottklement.com/ftpapi/
  (Your best bet would be to sign up for the mailing list)

Please keep in mind that this program is free.  I'll help you if
I can, but jobs that I'm getting paid for will always take priority. :)

For a list of changes made from version to version, see the CHANGELOG
member of this source file.
