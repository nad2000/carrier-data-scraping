Development Notes
=================

XSLT Testing
------------


	for f in latest/*.html ; do tidy -asxhtml -config tidy.config $f > ${f/.html/.xhtml} ; done
    for f in latest/*.xhtml ; do xsltproc --html --encoding UTF8  --param htmlfilename "'$(basename $f)'" xslfiles/generic.xsl $f >${f/.xhtml/.xml} ; done

    xsltproc --param htmlfilename "'Sws.xhtml'" --html xslfiles/generic.xsl latest/Sws.xhtml

    xsltproc --html backend/fetcher/carrier105/xslfiles/generic.xsl tests/Miamichart.xhtml
    xsltproc --html backend/fetcher/carrier105/xslfiles/generic.xsl tests/Huenemechart.xhtml
    xsltproc --html backend/fetcher/carrier105/xslfiles/generic.xsl tests/NorthHuenemechart.xhtml
