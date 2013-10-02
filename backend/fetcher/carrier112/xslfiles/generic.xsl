<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:str="http://exslt.org/strings" extension-element-prefixes="str">
    <xsl:import href="../../../processor/exslt/str/str.xsl"/>
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements=" "/>

    <xsl:param name="htmlfilename" select="notset"/>

	<!-- Port name trnaslations: -->
	<xsl:variable name="ports-en">
		<port name="***ORIGINAL***">*** English Name ***</port>
		<port name="大 阪">Osaka; JP</port>
		<port name="神 戸">Kobe; JP</port>
		<port name="名 古 屋">Nagoya, Aichi; JP</port>
		<port name="清 水">Shimizu; JP</port>
		<port name="東 京">Tokyo; JP</port>
		<port name="横 浜">Yokohama; JP</port>
		<port name="青 島">Qingdao; CN</port>
		<port name="上 海">Shanghai; CN</port>
	</xsl:variable>

    <xsl:template match="/">
        <schedules>
			<schedule>
				<route>
					<xsl:call-template name="fixroutename">
						<xsl:with-param name="name" select="$htmlfilename" />
					</xsl:call-template>
				</route>
				<xsl:apply-templates select="(//table[1]/tr/td[contains(., 'VESSEL')])[1]" mode="vessels" />
		</schedule>
        </schedules>
    </xsl:template>

    <xsl:template match="td" mode="vessels">
        <xsl:variable name="xp" select="count(preceding-sibling::td)+1" />

        <xsl:apply-templates select="../following-sibling::tr" mode="vessel">
            <xsl:with-param name="xp" select="$xp" />
        </xsl:apply-templates>
    </xsl:template>

	<xsl:template match="tr" mode="vessel">
        <xsl:param name="xp">0</xsl:param>

        <xsl:variable name="vname">
            <xsl:call-template name="fixvesselname">
                <xsl:with-param name="name" select="td[$xp]" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$vname != ''">
            <vessel>
                <xsl:attribute name="name">
                    <xsl:value-of select="$vname" />
                </xsl:attribute>

                <xsl:attribute name="voyage">
                    <xsl:call-template name="fixvoyagestring">
                        <xsl:with-param name="vstr" select="td[$xp+1]" />
                    </xsl:call-template>
                </xsl:attribute>

                <xsl:apply-templates select="td[$xp+2]" mode="ports">
                    <xsl:with-param name="xp" select="number($xp+2)" />
                </xsl:apply-templates>
            </vessel>
        </xsl:if>
	</xsl:template>

    <xsl:template match="td" mode="ports">
        <xsl:param name="xp">0</xsl:param>

        <xsl:variable name="pname">
            <xsl:choose>
                <xsl:when test="../../tr[1]/td[$xp]/br">
                    <xsl:value-of select="normalize-space(../../tr[1]/td[$xp]/node()[not(preceding-sibling::br)])" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="../../tr[1]/td[$xp]" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- deal with various date variants - either single date, or two dates, or date interval (which can reside in single cell or in two adjacent cells -->
        <xsl:choose>
            <xsl:when test="../../tr[1]/td[$xp]/@colspan">
                <xsl:variable name="pdate1">
                    <xsl:call-template name="fixdatestring">
                        <xsl:with-param name="dstr" select="." />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="pdate2">
                    <xsl:call-template name="fixdatestring">
                        <xsl:with-param name="dstr" select="following-sibling::td[1]" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:call-template name="porttag">
                    <xsl:with-param name="pname" select="$pname" />
                    <xsl:with-param name="pdate" select="normalize-space(concat($pdate1, ' ', $pdate2))" />
                </xsl:call-template>

                <xsl:apply-templates select="following-sibling::td[2]" mode="ports">
                    <xsl:with-param name="xp" select="$xp+1" />
                </xsl:apply-templates>
            </xsl:when>

            <xsl:otherwise>
                <xsl:call-template name="porttag">
                    <xsl:with-param name="pname" select="$pname" />
                    <xsl:with-param name="pdate">
                        <xsl:call-template name="fixdatestring">
                            <xsl:with-param name="dstr" select="." />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>

                <xsl:apply-templates select="following-sibling::td[1]" mode="ports">
                    <xsl:with-param name="xp" select="$xp+1" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="porttag">
        <xsl:param name="pname">TBA</xsl:param>
        <xsl:param name="pdate">Blank</xsl:param>

        <xsl:variable name="pdate1" select="substring($pdate, 1, 5)" />
        <xsl:variable name="pdate2" select="normalize-space(substring($pdate, 6))" />

        <port>
            <xsl:attribute name="name">
                <xsl:call-template name="fixportname">
                    <xsl:with-param name="pname" select="$pname" />
                </xsl:call-template>
            </xsl:attribute>
            
            <xsl:value-of select="$pdate1" />
        </port>

        <xsl:choose>
            <xsl:when test="starts-with($pdate2, '-')">
                <xsl:variable name="fmon" select="number(substring-before($pdate1, '/'))" />
                <xsl:variable name="fday" select="number(substring-after($pdate1, '/'))" />
                <xsl:variable name="sday" select="normalize-space(substring-after($pdate2, '-'))" />

                <port>
                    <xsl:attribute name="name">
                        <xsl:call-template name="fixportname">
                            <xsl:with-param name="pname" select="$pname" />
                        </xsl:call-template>
                    </xsl:attribute>
                    
                    <xsl:choose>
                        <xsl:when test="number($sday) &gt;= $fday">
                            <xsl:choose>
                                <xsl:when test="$fmon &lt; 10"><xsl:value-of select="concat('0', $fmon, '/', $sday)" /></xsl:when>
                                <xsl:otherwise><xsl:value-of select="concat($fmon, '/', $sday)" /></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$fmon &lt; 9"><xsl:value-of select="concat('0', ($fmon + 1), '/', $sday)" /></xsl:when>
                                <xsl:when test="$fmon &lt; 12"><xsl:value-of select="concat(($fmon + 1), '/', $sday)" /></xsl:when>
                                <xsl:otherwise><xsl:value-of select="concat('01/', $sday)" /></xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </port>
            </xsl:when>

            <xsl:when test="contains($pdate2, '/')">
                <port>
                    <xsl:attribute name="name">
                        <xsl:call-template name="fixportname">
                            <xsl:with-param name="pname" select="$pname" />
                        </xsl:call-template>
                    </xsl:attribute>
                    
                    <xsl:value-of select="$pdate2" />
                </port>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="fixroutename">
        <xsl:param name="name">TBA</xsl:param>
        <xsl:variable name="nm1" select="normalize-space(substring-before($name, '.'))"/>
        <xsl:choose>
            <xsl:when test="$nm1 = 'schedulef'">Kansai Line</xsl:when>
            <xsl:when test="$nm1 = 'schedulef2'">Kanto Line</xsl:when>
            <xsl:when test="$nm1 = 'schedulef3'">Chubu Line</xsl:when>
			<xsl:when test="$nm1 = 'schedulefq'">Qingdao Line</xsl:when>

            <xsl:otherwise><xsl:value-of select="$nm1" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="fixvesselname">
        <xsl:param name="name">TBA</xsl:param>
        <xsl:variable name="nm1" select="normalize-space(translate($name,'&#160;&#12288;','  '))"/>
		<xsl:value-of select="$nm1" />
    </xsl:template>

    <xsl:template name="fixvoyagestring">
        <xsl:param name="vstr">Blank</xsl:param>
        <xsl:variable name="vstr1" select="normalize-space(str:replace(translate($vstr,'&#160;&#12288;',' '), 'E/W', ''))"/>
        <xsl:value-of select="$vstr1"/>
    </xsl:template>

    <xsl:template name="fixportname">
        <xsl:param name="pname">Blank</xsl:param>
        <xsl:variable name="pname1" select="normalize-space(translate($pname,'&#160;&#12288;','  '))" />
        <xsl:variable name="pname2" select="normalize-space(translate($pname,'　',''))" />
		<xsl:variable name="port-en" select="document('')//xsl:variable[@name='ports-en']/*[@name=$pname1]" />
        <xsl:if test="$port-en"><xsl:value-of select="$port-en" /> / </xsl:if>
        <xsl:value-of select="$pname1" />
    </xsl:template>

    <xsl:template name="fixdatestring">
        <xsl:param name="dstr">Blank</xsl:param>
        <xsl:variable name="dstr1" select="str:concat((str:split($dstr, ''))[contains('0123456789-/', .)])" />
        <xsl:value-of select="$dstr1" />
    </xsl:template>

</xsl:stylesheet>
