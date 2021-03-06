dnl ===================================================================
dnl   Licensed to the Apache Software Foundation (ASF) under one
dnl   or more contributor license agreements.  See the NOTICE file
dnl   distributed with this work for additional information
dnl   regarding copyright ownership.  The ASF licenses this file
dnl   to you under the Apache License, Version 2.0 (the
dnl   "License"); you may not use this file except in compliance
dnl   with the License.  You may obtain a copy of the License at
dnl
dnl     http://www.apache.org/licenses/LICENSE-2.0
dnl
dnl   Unless required by applicable law or agreed to in writing,
dnl   software distributed under the License is distributed on an
dnl   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
dnl   KIND, either express or implied.  See the License for the
dnl   specific language governing permissions and limitations
dnl   under the License.
dnl ===================================================================
dnl
dnl  Mac OS X specific checks

dnl SVN_LIB_MACHO_ITERATE
dnl Check for _dyld_image_name and _dyld_image_header availability
AC_DEFUN(SVN_LIB_MACHO_ITERATE,
[
  AC_MSG_CHECKING([for Mach-O dynamic module iteration functions])
  AC_RUN_IFELSE([AC_LANG_PROGRAM([[
    #include <mach-o/dyld.h>
    #include <mach-o/loader.h>
  ]],[[
    const struct mach_header *header = _dyld_get_image_header(0);
    const char *name = _dyld_get_image_name(0);
    if (name && header) return 0;
    return 1;
  ]])],[
    AC_DEFINE([SVN_HAVE_MACHO_ITERATE], [1],
              [Is Mach-O low-level _dyld API available?])
    AC_MSG_RESULT([yes])
  ],[
    AC_MSG_RESULT([no])
  ])
])

dnl SVN_LIB_MACOS_PLIST
dnl Assign variables for Mac OS property list support
AC_DEFUN(SVN_LIB_MACOS_PLIST,
[
  AC_MSG_CHECKING([for Mac OS property list utilities])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
    #include <AvailabilityMacros.h>
    #if !defined(MAC_OS_X_VERSION_MAX_ALLOWED) \
     || !defined(MAC_OS_X_VERSION_10_0) \
     || (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_0)
    #error ProperyList API unavailable.
    #endif
  ]],[[]])],[
    dnl ### Hack.  We should only need to pass the -framework options when
    dnl linking libsvn_subr, since it is the only library that uses Keychain.
    dnl
    dnl Unfortunately, libtool 1.5.x doesn't track transitive dependencies for
    dnl OS X frameworks like it does for normal libraries, so we need to
    dnl explicitly pass the option to all the users of libsvn_subr to allow
    dnl static builds to link successfully.
    dnl
    dnl This does mean that all executables we link will be linked directly
    dnl to these frameworks - even when building shared libraries - but that
    dnl shouldn't cause any problems.

    LIBS="$LIBS -framework CoreFoundation"
    AC_DEFINE([SVN_HAVE_MACOS_PLIST], [1],
              [Is Mac OS property list API available?])
    AC_MSG_RESULT([yes])
  ],[
    AC_MSG_RESULT([no])
  ])
])

dnl SVN_LIB_MACOS_KEYCHAIN
dnl Check configure options and assign variables related to Keychain support

AC_DEFUN(SVN_LIB_MACOS_KEYCHAIN,
[
  AC_ARG_ENABLE(keychain,
    AS_HELP_STRING([--disable-keychain],
    [Disable use of Mac OS KeyChain for auth credentials]),
    [enable_keychain=$enableval],[enable_keychain=yes])

  AC_MSG_CHECKING([for Mac OS KeyChain Services])

  if test "$enable_keychain" = "yes"; then
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
      #include <AvailabilityMacros.h>
      #if !defined(MAC_OS_X_VERSION_MAX_ALLOWED) \
       || !defined(MAC_OS_X_VERSION_10_2) \
       || (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_2)
      #error KeyChain API unavailable.
      #endif
    ]],[[]])],[
      dnl ### Hack, see SVN_LIB_MACOS_PLIST
      LIBS="$LIBS -framework Security"
      LIBS="$LIBS -framework CoreServices"
      AC_DEFINE([SVN_HAVE_KEYCHAIN_SERVICES], [1], [Is Mac OS KeyChain support enabled?])
      AC_MSG_RESULT([yes])
    ],[
      enable_keychain=no
      AC_MSG_RESULT([no])
    ])
  fi
])
