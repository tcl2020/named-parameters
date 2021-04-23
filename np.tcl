

#"proc name args body"

namespace eval ::np {
	#
	# proc_args_to_dict - given a proc name and declared
	#   proc arguments (variable names with optional
	#   default values and a -- and possible some more
	#   stuff, create and return a dict containing that
	#   info in a way that's convenient and quicker
	#   for us at runtime:
	#   * we store a list of positional parameters
	#   * we store a list of named parameters
	#   * we store a list of var-value defaults
	#   * we get a tricked-out error message in errmsg
	#
	::proc proc_args_to_dict {name procArgs} {
		set seenDashes 0
		dict set d defaults [list]
		dict set d positional [list]
		dict set d named [list]
		set errmsg "wrong # args: should be \"$name "

		foreach arg $procArgs {
			if {$arg eq "--"} {
				set seenDashes 1
				append errmsg "?--? "
				continue
			}

			set var [lindex $arg 0]
			dict lappend d [expr {$seenDashes ? "positional" : "named"}] $var

			if {[llength $arg] == 2} {
				dict lappend d defaults $var [lindex $arg 1]
				if {$seenDashes} {
					append errmsg "?$var? "
				} else {
					append errmsg "?-$var val? "
				}
			} elseif {$var eq "args"} {
				dict lappend d defaults $var [list]
				append errmsg "?arg ...? "
			} else {
				if {$seenDashes} {
					append errmsg "$var "
				} else {
					append errmsg "-$var val "
				}
			}
		}
		dict set d errmsg "[string range $errmsg 0 end-1]\""
		return $d
	}

	#
	# np_handler - look at an argument dict created by proc_args_to_dict
	#   and look at the real arguments to a function (args), and sort
	#   out the named and positional parameters to behave in the
	#   expected way.
	#
	::proc np_handler {argd realArgs} {
		set named [dict get $argd named]
		set positional [dict get $argd positional]

		# process named parameters
		while {[llength $realArgs] > 0} {
			set arg [lindex $realArgs 0]

			# if arg is --, flip to positional
			if {$arg eq "--"} {
				set realArgs [lrange $realArgs 1 end]
				break
			}

			# if "var" doesn't start with a dash or equal sign, flip to positional
			set start_character [string index $arg 0]
			if {$start_character ne "-" && $start_character ne "="} {
				#puts "possible var '$arg' doesn't start with a dash, flip to positional"
				break
			}

			# if "var" isn't known to us as a named parameter, flip to positional
			set var [string range $arg 1 end]
			if {[lsearch $named $var] < 0 && $start_character ne "="} {
				#puts "'var' '$arg' not recognized, flip to positional"
				break
			}

			# if there isn't at least one more element in the arg list,
			# we are missing a value for one of our named parameters
			if {[llength $realArgs] == 0} {
				#puts "realArgs is empty but i expect something for $var"
				error [dict get $argd errmsg] "" [list TCL WRONGARGS]
			}

			# we're good, set the named parameter into the variable sets
			#puts [list set vsets($var) [lindex $realArgs 1]]

			# but don't allow the same variable to be set twice
			if {[info exists vsets($var)]} {
				error [dict get $argd errmsg] "" [list TCL WRONGARGS]
			}

			set vsets($var) [lindex $realArgs 1]
			set realArgs [lrange $realArgs 2 end]
		}

		# fill in defaults for all the vars with defaults that
		# didn't get set to a value
		foreach "var value" [dict get $argd defaults] {
			if {![info exists vsets($var)]} {
				set vsets($var) $value
			}
		}

		foreach var $positional {
			if {$var eq "args"} {
				set vsets($var) $realArgs
				set realArgs [list]
				break
			}

			if {[llength $realArgs] > 0} {
				set vsets($var) [lindex $realArgs 0]
				set realArgs [lrange $realArgs 1 end]
			}

			# no arguments left.  if this var doesn't
			# have a default value, it's a wrong args error
			if {![info exists vsets($var)]} {
				error [dict get $argd errmsg] "" [list TCL WRONGARGS]
			}
		}

		# make sure all the named parameters have been set, either
		# by defaults or explicitly, any not set is an error
		foreach var $named {
			if {![info exists vsets($var)]} {
				#puts "required named parameter '-$var' is not set"
				error [dict get $argd errmsg] "" [list TCL WRONGARGS]
			}
		}

		# are there too many arguments?
		if {[llength $realArgs] > 0} {
			#puts "leftover arguments (too many) '$realArgs'"
			error [dict get $argd errmsg] "" [list TCL WRONGARGS]
		}

		# now iterate through the var-value pairs and set them into
		# the caller's frame
		foreach "var value" [array get vsets] {
			#puts "set '$var' '$value'"
			upvar $var myvar
			set myvar $value
		}
		return
	}

	#
	# np::proc - same as proc except if -- is in the argv
	#   then it will generate a proc that has extra code
	#   at the beginning to wrangle the named parameters
	#
	proc proc {name argv body} {
		# handle the case where there are no named parameters
		if {[lsearch $argv --] < 0} {
			uplevel [list ::proc $name $argv $body]
			return
		}

		if {[lsearch $argv --] == 0} {
			return -code error "-- cannot be the first argument for named parameters. Use positional parameters."
		}

		set d [proc_args_to_dict $name $argv]
		set newbody "::proc $name args {\n"
		append newbody "    ::np::np_handler [list $d] \$args\n"
		append newbody $body
		append newbody "\n}"
		#puts $newbody
		uplevel $newbody
	}
}

package provide np 1.1.0
