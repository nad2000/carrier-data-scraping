<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:str="http://exslt.org/strings" extension-element-prefixes="str">
    <xsl:import href="../../../processor/exslt/str/str.xsl"/>
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements=" "/>

    <xsl:param name="htmlfilename" select="notset"/>

	<!-- Port name trnaslations: -->
	<xsl:variable name="ports-en">
		<port name="***ORIGINAL***">*** English Name ***</port>
		<port name="大阪">Osaka; JP</port>
		<port name="神戸">Kobe; JP</port>
		<port name="名古屋">Nagoya, Aichi; JP</port>
		<port name="清水">Shimizu; JP</port>
		<port name="東京">Tokyo; JP</port>
		<port name="横浜">Yokohama; JP</port>
		<port name="青島">Qingdao; CN</port>
		<port name="上海">Shanghai; CN</port>
	</xsl:variable>

	<!-- Header line: -->
	<xsl:variable name="hl" select="//tr[@class='ttu']" />

	<!-- Source file base name: -->
    <xsl:variable name="basename" select="normalize-space(substring-before($htmlfilename, '.'))"/>

	<!-- Route name: -->
    <xsl:variable name="route">
        <xsl:choose>
            <xsl:when test="$basename = 'schedulef'">Kansai Line</xsl:when>
            <xsl:when test="$basename = 'schedulef2'">Kanto Line</xsl:when>
            <xsl:when test="$basename = 'schedulef3'">Chubu Line</xsl:when>
			<xsl:when test="$basename = 'schedulefq'">Qingdao Line</xsl:when>
            <xsl:otherwise><xsl:value-of select="$basename" /></xsl:otherwise>
        </xsl:choose>
	</xsl:variable>

    <xsl:template match="/">
        <schedules>
			<!-- xsl:copy-of select="$ports" / -->
			<schedule>
				<route><xsl:value-of select="$route" /></route>
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

        <xsl:if test="$vname!=''">

            <vessel name="{$vname}">

                <xsl:attribute name="voyage">
                    <xsl:call-template name="fixvoyagestring">
                        <xsl:with-param name="vstr" select="td[$xp+1]" />
                    </xsl:call-template>
                </xsl:attribute>

				<xsl:choose>
					<xsl:when test="starts-with($basename,'schedulefq')">

						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="$hl/td[3]" />
							<xsl:with-param name="eta" select="td[$xp+2]" />
						</xsl:call-template>
						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="concat($hl/td[4],$hl/td[5])" />
							<xsl:with-param name="eta" select="td[$xp+3]" />
						</xsl:call-template>
						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="concat($hl/td[6],$hl/td[7])" />
							<xsl:with-param name="eta" select="td[$xp+5]" />
						</xsl:call-template>
						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="$hl/td[8]" />
							<xsl:with-param name="eta" select="td[$xp+7]" />
						</xsl:call-template>
						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="concat($hl/td[9],$hl/td[10])" />
							<xsl:with-param name="eta" select="td[$xp+9]" />
						</xsl:call-template>
						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="concat($hl/td[11],$hl/td[12])" />
							<xsl:with-param name="eta" select="td[$xp+11]" />
						</xsl:call-template>
						<xsl:call-template name="porttagq">
							<xsl:with-param name="pname" select="$hl/td[13]" />
							<xsl:with-param name="eta" select="td[$xp+13]" />
						</xsl:call-template>

					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="td[$xp+2]" mode="ports">
							<xsl:with-param name="xp" select="number($xp+2)" />
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
            </vessel>
        </xsl:if>
	</xsl:template>

	<xsl:template name="porttagq" >
		<xsl:param name="pname" />
		<xsl:param name="eta" />
		<xsl:if test="not(translate($eta,' -','')='')">
			<port>
				<xsl:attribute name="name">
					<xsl:call-template name="fixportname">
						<xsl:with-param name="pname" select="$pname" />
					</xsl:call-template>
				</xsl:attribute>
				<xsl:call-template name="fixdatestring">
					<xsl:with-param name="dstr" select="$eta" />
				</xsl:call-template>
			</port>
		</xsl:if>
	</xsl:template>

    <xsl:template match="td" mode="ports">
        <xsl:param name="xp">0</xsl:param>

        <xsl:variable name="pname">
            <xsl:choose>
				<!-- @class ~ 'tur1[0-9]{a|d}' -->
				<xsl:when test="translate(../../tr[1]/td[$xp]/@class,'adtul0123456789','YY')='Y'">
                    <xsl:value-of select="normalize-space(concat(
							../../tr[1]/td[$xp],
							../../tr[1]/td[$xp+1]
							))" />
				</xsl:when>
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
            <xsl:when test="$hl/td[$xp]/@colspan">
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

		<xsl:if test="$pname != ''">
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
        </xsl:if>
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
        <xsl:variable name="pname2" select="translate($pname1,' ','')" />
		<xsl:variable name="port-en" select="document('')//xsl:variable[@name='ports-en']/*[@name=$pname2]" />
		<xsl:choose>
			<xsl:when test="$port-en"><xsl:value-of select="$port-en" /></xsl:when>
			<xsl:otherwise><xsl:value-of select="$pname2" /></xsl:otherwise>
		</xsl:choose>
    </xsl:template>

    <xsl:template name="fixdatestring">
        <xsl:param name="dstr">Blank</xsl:param>
        <xsl:variable name="dstr1" select="str:concat((str:split($dstr, ''))[contains('0123456789-/', .)])" />
        <xsl:value-of select="$dstr1" />
    </xsl:template>

</xsl:stylesheet>
