Website:

The XSLT broke because the format of the HTML tables in the web pages has changed.

Download:

Our system periodically runs /backend/fetcher/carrierXXX/dlscript.sh to download the HTML pages. This is working OK now, so no changes required here.

Convert:

After downloading the HTML pages, the system runs /backend/processFile.sh which calls HTMLTidy to clean-up and convert the original HTML to XHTML then calls the XSLT /xslfiles/generic.xsl to converts the XHTML to our XML format. For this job, all I need to see are the XML files generated from the modified XSLT to check that they are correct, before accepting the modified and fixed generic.xsl file.

References:

Under /current/ you will find the last downloaded HTML pages which processed correctly.

Under /latest/ you will find latest downloaded HTML pages, but their processing by XSLT has failed. The file chkports.err (if present) shows the reason, because the data is not in the same columns as previously; it's reading dates where port names used to be. This is what needs fixing.

Under /results/ you will find the data gathered from the latest run.
