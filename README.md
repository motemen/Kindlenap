Kindlenap
=========

WHAT IS THIS
------------

kindlenap.pl converts URL/file to [kindlegen][kindlegen]-ready HTML file.

 * Extracts main content of website
 * Embeds title/author metadata
 * Includes embedded images

HOW TO USE
----------

	kindlenap.pl [--out-dir dir] [--title title] [--author author] [--verbose] [--autopagerize] url-or-file

If you omit <var>url-or-file</var>, kindlenap.pl reads content from STDIN.

DESCRIPTION
-----------

kindlenap.pl generates file <var>title</var> <var>suffix</var>.html in specified output directory (defaults to 'out').

After that, process the generated file by kindlegen.

### SPECIAL-HANDLED WEBSITES

 * Formats and exracts metadata of [pixiv 小説][pixiv-novel] pages properly.

[kindlegen]: http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000234621
[pixiv-novel]: http://www.pixiv.net/novel/
