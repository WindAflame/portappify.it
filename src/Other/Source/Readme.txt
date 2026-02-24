Sonic 3 A.I.R. Portable
=======================

Sonic 3 Angel Island Revisited (A.I.R.) is a fan-remaster of Sonic 3 & Knuckles.
More information: https://sonic3air.org

This portable package is licensed under CC BY-NC-SA 4.0.
The game itself is created by Eukaryot and is freeware (non-OSI, non-commercial).

The base application's source code and details are available from:
https://sonic3air.org

LICENSE
=======

This package's launcher is the PortableApps.com Launcher, released under the GPL.
Full source and documentation available from:
https://portableapps.com/development

We request that developers using the PortableApps.com Launcher please leave this
directory intact and unchanged.

USER CONFIGURATION
==================

Some configuration in the PortableApps.com Launcher can be overridden by the
user in an INI file next to Sonic3AIRPortable.exe called Sonic3AIRPortable.ini.
If you are happy with the default options, it is not necessary, though.  There
is an example INI included with this package to get you started.  To use it,
copy Sonic3AIRPortable.ini from this directory next to Sonic3AIRPortable.exe.
The options in the INI file are as follows:

   AdditionalParameters=
   DisableSplashScreen=false
   RunLocally=false

(There is no need for an INI header in this file; if you have one, though, it
won't damage anything.)

The AdditionalParameters entry allows you to pass additional command-line
parameters to the application.

The DisableSplashScreen entry allows you to run the launcher without the splash
screen showing up.  The default is false.

The RunLocally entry allows you to run the portable application from a read-
only medium. This is known as Live mode. It copies what it needs to to a
temporary directory on the host computer, runs the application, and then
deletes it afterwards, leaving nothing behind. This can be useful for running
the application from a CD or if you work on a computer that may have spyware or
viruses and you'd like to keep your device set to read-only. As a consequence
of this technique, any changes you make during the Live mode session aren't
saved back to your device.  The default is false.
