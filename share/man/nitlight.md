% NITLIGHT(1)

# NAME

nitlight - generates HTML of highlighted code from Nit source files.

# SYNOPSIS

nitlight [*options*] FILE...

# DESCRIPTION

Unlike generic lexical or syntactic highlighter, nitlight use semantic information on programs to improve the rendered result.

# OPTIONS

Common options of the Nit tools are understood.
Here, only the specific one are indicated.

`-f`, `--fragment`
:   Omit document header and footer.

    By default, a complete autonomous HTML document is generated.
    If `-f` is given, only the inside of the body part is generated such that it could be integrated
    into a HTML document.

`--first-line`
:   Start the source file at this line (default: 1).

    The generated HTML will only contains lines bellow the specified one.

`--last-line`
:   End the source file at this line (default: to the end)

    The generated HTML will only contains lines ebove the specified one.

`-d`, `--dir`
:   Output html files in a specific directory (required if more than one module).

    By default the generated HTML is outputted on the screen.
    If this option is used, then HTML files are generated in the specified directory.

    A basic `index.heml` and a `style.css` file are also generated in the directory.

`--full`
:   Process also imported modules.

    By default, only the modules indicated on the command line are highlighted.

    With the `--full` option, all imported modules (even those in standard) are also precessed.

# SEE ALSO

The Nit language documentation and the source code of its tools and libraries may be downloaded from <http://nitlanguage.org>
