Development Notes
=================

XSLT Testing
------------


    for f in latest/*_.xhtml ; do xsltproc --encoding UTF8 --html --param htmlfilename "'$(basename $f)'" xslfiles/generic.xsl $f >$(basename $f).xml ; done
    for f in latest/*.xhtml ; do xsltproc --html --param htmlfilename "'$(basename $f)'" xslfiles/generic.xsl $f >$(basename $f).xml ; done

    xsltproc --param htmlfilename "'Sws.xhtml'" --html xslfiles/generic.xsl latest/Sws.xhtml

    xsltproc --html backend/fetcher/carrier105/xslfiles/generic.xsl tests/Miamichart.xhtml
    xsltproc --html backend/fetcher/carrier105/xslfiles/generic.xsl tests/Huenemechart.xhtml
    xsltproc --html backend/fetcher/carrier105/xslfiles/generic.xsl tests/NorthHuenemechart.xhtml
