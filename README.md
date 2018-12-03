

Named Parameters
---

Tcl procs are called with positional parameters.  Parameters may have default values, and don't need to be specified.

One problem with how they work is that if, for example, the second through fifth arguments to a function have default values, if the developer wants the default values for the second through fourth but to specify something different for the fifth, they are obliged to pass in values for the second through fourth arguments to get to the fifth.

Another is the general unwieldiness of functions that take a lot of positional parameters.

We draw inspiration from the behavior of Tcl intrinsics such as lsort and lsearch, Unix command line tools, and the Tk toolkit.

Our goal is to extend Tcl to support named parameters.  Some way that, in the prior example, we can pass the value of the fifth element without having to specify the ones we don't need or want to provide.

The implementation needs to be:
* fast
* not break existing stuff (at least nothing substantial)
* not require any special magic (weird character or whatnot) to invoke
* ideally still define these functions using "proc" rather than something different like "func"
* want the implementation to be minimally invasive on Tcl; changes are localized rather than sprawling
* follow the KISS principle; optimize for simplicity over features and see how small we can make it and still get what we are looking for
* still support "args"
* provide a way to be certain of not be tricked into thinking a value like -5 is a named variable, and a nonexistent one at that.


We recognized that the normal arguments to proc actually provide enough information for a named parameter.  That is, the variable name and, optionally, a default value.

It didn't, however, provide support for both named parameters and positional parameters and, of course, positional parameters must continue to work as they always have (and without slowdown) in support of the keeping the vast body of existing Tcl code running and not needing updating.

We chose to go with the familiar "-var value" style from Tk and Itcl and whatnot.

It was appealing to consider something like

```tcl
proc z {-a -b c d} {...}
```

In the above example, a and b will be named and c and d are positional (and required).

Looks pretty neat and zero or almost zero code ever written to declare a proc variable with a leading dash.

The problem comes in the implementation.  We want to leverage Tcl's existing C code as much as possible and this ends up with variables called -a and -b unless we do a lot of work.

To leverage Tcl more and make the required changes smaller, Shannon came up with specifying the variable names without the leading dash, and using a dash-dash separator

```tcl
proc z {a b -- c d} {...}
```

the above can be invoked as any of the following:

```tcl
z -a aval cval dval
z -b bval cval dval
z -a aval -b bval cval dval
z -b bval -a aval cval dval
```

The -- operator can be specified at runtime that, as with so many Tcl native commands, indicates an end of named parameters.

```tcl
z -a aval -b bval -- cval dval
```

For any variable for which there are default variables, the variable need not be specified, whether positional (as before) or named.

To specify a function that takes only named parameters, just don't put any variables to the right of the "--" specifier.

```tcl
proc z {a b c d --} {...}
```

A word about putting the named parameters first rather than last.  This is how Tcl core commands such as lsort, lsearch, and switch work.  And Unix command lines.  You wouldn't say `grep * -v pattern`.

A surprising and pleasant side-effect was how much more readable the code is when using named parameters, even when calling a function with only a couple arguments.

What's This
---

This is an implementation of Tcl named parameters, written entirely in native Tcl.

It should work the same as the C version (still a work in progress), but considerably more slowly for procs that use named parameters.

Currently we use np::proc when we want the functionality of named parameters, after a "package require np".  Eventually we expect the C implementation to just do it natively within "proc".  This package could replace the native proc with np::proc but so far we have not done that.  It's handy not to screw up proc like it would if some dev version of this stuff breaks, for instance, and when we have proc doing this in C we don't want to accidentally be bypassing that because this is plugged and still doing it in this slower and clumsier way.

If np::proc is invoked on a proc that doesn't declare any named parameters, normal proc is invoked without any rewriting so the proc will execute at its normal, full speed.


Usage
---

```tcl
package require np

np::proc z {{a defa} b -- c {d defd}} {puts "a '$a' b '$b' c '$c' d '$d'"}

np::proc zez {{a aval} {b bval} -- {c cval} {d dval}} {puts "a '$a' b '$b' c '$c' d '$d'"}

np::proc zezzy {{a aval} {b bval} -- {c cval} {d dval} args} {puts "a '$a' b '$b' c '$c' d '$d' args '$args'"}

```

Again... everything before the -- is named parameters; everything after is positional.


You aren't supporting booleans, switches that don't have a corresponding value?
---

This would be like you want to say "-debug" and have that turn on debugging instead of saying
"-debug 1".  Yeah we're not doing that.  The regularity, based on a lot of experience with key-value pairs, is a big plus. Also with non-value-specifying booleans, to be able to interpret what variables get set to what values requires the code to know which variables are booleans.  There are additional problems but that last one is pretty bad anyway.


