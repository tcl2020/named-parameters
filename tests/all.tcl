# all.tcl --
#
# This file contains a top-level script to run all of the Tcl
# tests.  Execute it by invoking "source all.test" when running tcltest
# in this directory.
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# Copyright (c) 2000 by Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package prefer latest
package require Tcl 8.6-
package require tcltest 2.3
namespace import ::tcltest::*


# Hook to determine if any of the tests failed. Then we can exit with
# proper exit code: 0=all passed, 1=one or more failed
proc tcltest::cleanupTestsHook {} {
        variable numTests
        set ::exitCode [expr {$numTests(Failed) > 0}]
}

# Allow command line arguments to be passed to the configure command
# This supports only running a single test or a single test file
::tcltest::configure {*}$argv

::tcltest::runAllTests

if {$exitCode == 1} {
        puts "====== FAIL ====="
        exit $exitCode
} else {
        puts "====== SUCCESS ====="
}
