XSLT Creation - Task Description
================================

General Description
-------------------

We need various freight carrier schedules retrieved from their web sites
and the data reformatted, cleaned up, and put into our standard format.
This will entail developing a XSLT stylesheet to transform the HTML
based data into a standardized XML format. If the schedule data is in a
XLS file, it first is run through a simple script to turn into into a
HTML table. HTMLTidy is used to transform the raw HTML (from a web site
or the converted XLS file) into properly formatted XHTML before the XSLT
step.

Materials Needed
----------------

We will provide you with the following:

-   The PHP based script that transforms XLS files into HTML tables

-   The PHP script that transforms the HTML into XML (using the XSLT
    stylesheet you develop)

-   An example XSLT stylesheet

-   The specification of the XML file and an example XML file

-   A HTMLTidy configuration file

The copy of HTMLTidy to use (specific to your OS) should be downloaded
from [http://tidy.sourceforge.net/](http://tidy.sourceforge.net/). You
are responsible for any compilation needed.

Deliverables
------------

Upon task completion, you should provide us with the following:

\1) The source HTML file(s) from the website or the XLS file(s) used

\2) The XSLT stylesheet

Issues to Deal With
-------------------

The main problems encountered are wrestling with character set issues,
dealing with differences between the HTML data and the reference data in
our database (e.g. misspellings of port names), and a wide variation in
how data is formatted (and what's presented) in the HTML or XLS files.

Our project will be for many carriers but we are starting with just 2 or
3 to verify the ability of the provider.

Some carriers put several itineraries on one page (e.g. the northbound
voyage and the southbound voyage) - the XSLT stylesheet would split this
into two schedules/itineraries (the XML format can handle multiple
schedules in one file).

Another issue is that sometimes the data should be split into two
schedules/itineraries even though it doesn't look like it - the
definition of an itinerary is 'a path stopping at several ports, all of
them only once'. So if a ship goes from A to B to C to D, that is one
itinerary/schedule. If the carrier's schedule data / table indicates the
ship then goes from D to C and back to A, that is a second
itinerary/schedule and should be specified as such in the XML file.

The Specific Procedure
----------------------

-   Find the schedule data on the website

-   Download all of it

-   If in XLS files, run the files through the xls2html script to
    generate a HTML file

-   Use HTMLTidy on the HTML files to create XHTML files - this will
    strip out Microsoft related stuff and makes the HTML more uniform

-   It also detects some basic issues, like a strange character set that
    would throw the subsequent scripts off.

-   Develop a XSLT stylesheet to transform the XHTML file into a XML
    file

Sometimes it is easy because the XHTML is cleanly formatted and
sometimes it isn't, so you have to use XSLT functions to do various
things such as skip this row, process a date to strip out extraneous
characters like asterisks.. etc. Sometimes port names are wrong, port
names are misspelled, the country isn't specified, etc - see the example
XSLT stylesheet for a template that handles this task. There may be
several XSLT stylesheets associated with one carrier - if their schedule
pages all have different formats, then each is a stylesheet.

\

