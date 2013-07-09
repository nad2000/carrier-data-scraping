<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:str="http://exslt.org/strings" extension-element-prefixes="str">
    <xsl:import href="../../../processor/exslt/str/str.xsl"/>
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements=" "/>

    <xsl:param name="htmlfilename" select="notset"/>

    <xsl:template match="/">
        <schedules>
            <xsl:apply-templates select="//tr[td[1] = 'VESSEL']" mode="schedule" />
        </schedules>
    </xsl:template>

    <xsl:template match="tr" mode="schedule">
        <xsl:variable name="xp" select="count(preceding-sibling::tr)-1" />
		<!-- Route: -->
		<xsl:variable name="route0">
			<xsl:choose>
				<xsl:when test="/html/body/p[2]/@class = 'c2'">
					<xsl:value-of select="/html/body/p[2]/span/." />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/html/body/p[2]/span/." /><xsl:value-of select="/html/body/p[3]/span/." />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
        <xsl:variable name="route" select="normalize-space($route0)" />

        <schedule>
            <route><xsl:value-of select="$route" /></route>
            <xsl:apply-templates select="following-sibling::tr[1]" mode="vessel">
                <xsl:with-param name="route" select="$route" />
                <xsl:with-param name="xp" select="$xp" />
            </xsl:apply-templates>
        </schedule>
    </xsl:template>

    <xsl:template match="tr" mode="vessel">
        <xsl:param name="xp">0</xsl:param>
        <xsl:param name="route">TBA</xsl:param>

        <xsl:if test="normalize-space(td[1]) != ''">
			<xsl:if test="normalize-space(td[2]) != ''">
				<vessel>
					<xsl:attribute name="name">
						<xsl:call-template name="fixvesselname">
							<xsl:with-param name="name" select="td[1]" />
						</xsl:call-template>
					</xsl:attribute>
					<xsl:choose>
						<xsl:when test="../tr[$xp]/td[2]/@colspan = 2">
							<xsl:attribute name="voyage">
								<xsl:call-template name="fixvoyagestring">
									<xsl:with-param name="vstr" select="concat(td[2], td[3])" />
								</xsl:call-template>
							</xsl:attribute>

							<xsl:apply-templates select="td[position() &gt; 3]">
								<xsl:with-param name="xp" select="$xp" />
								<xsl:with-param name="route" select="$route" />
							</xsl:apply-templates>
						</xsl:when>

						<xsl:otherwise>
							<xsl:attribute name="voyage">
								<xsl:call-template name="fixvoyagestring">
									<xsl:with-param name="vstr" select="td[2]" />
								</xsl:call-template>
							</xsl:attribute>

							<xsl:apply-templates select="td[position() &gt; 2]">
								<xsl:with-param name="xp" select="$xp" />
								<xsl:with-param name="route" select="$route" />
							</xsl:apply-templates>
						</xsl:otherwise>
					</xsl:choose>
				</vessel>
			</xsl:if>

            <xsl:apply-templates select="following-sibling::tr[1]" mode="vessel">
                <xsl:with-param name="route" select="$route" />
                <xsl:with-param name="xp" select="$xp" />
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="td">
        <xsl:param name="xp">0</xsl:param>
        <xsl:param name="route">TBA</xsl:param>

        <xsl:variable name="mxp" select="position()" /> <!-- 1-based number to take care of rowspanned cells at header line -->
        <xsl:variable name="pdate" select="normalize-space(.)" />
        <xsl:variable name="pname0">
            <xsl:choose>
                <!-- first element when first port name is missed - get departing port name from route -->
                <xsl:when test="../../tr[$xp]/td[3]/@rowspan = 2 and $mxp = 1">
                    <xsl:variable name="fromp" select="substring-before($route, ' to')" />
                    <xsl:variable name="topp" select ="substring-after($route, ' to')" />
                    <xsl:choose>
                      <xsl:when test="string-length($fromp) &lt;= string-length($topp)">
                        <xsl:value-of select="$fromp" />
                      </xsl:when>
                      <xsl:when test="string-length($fromp) &gt; string-length($topp)">
                        <xsl:value-of select="$topp" />
                      </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <!-- not first element when first port name is missed - fix up for rowspan -->
                <xsl:when test="../../tr[$xp]/td[3]/@rowspan = 2 and $mxp != 1">
					<xsl:value-of select="../../tr[$xp+1]/td[$mxp - 1]" />
				</xsl:when>
                <xsl:otherwise>
					<xsl:value-of select="concat(../../tr[$xp+1]/td[$mxp+1],'; ', ../../tr[$xp+2]/td[$mxp+2])" />
				</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="pname" select="normalize-space($pname0)" />

        <xsl:if test="$pname != '' and $pdate != '-'">
            <port>
                <xsl:attribute name="name">
                    <xsl:call-template name="fixportname">
                        <xsl:with-param name="pname" select="$pname" />
                    </xsl:call-template>
                </xsl:attribute>

                <xsl:call-template name="fixdatestring">
                    <xsl:with-param name="dstr" select="." />
                </xsl:call-template>
            </port>
        </xsl:if>
    </xsl:template>

    <xsl:template name="fixvesselname">
        <xsl:param name="name">TBA</xsl:param>
        <xsl:variable name="nm1" select="normalize-space(str:replace($name,'&#160;',' '))"/>
        <xsl:value-of select="$nm1" />
    </xsl:template>

    <xsl:template name="fixvoyagestring">
        <xsl:param name="vstr">Blank</xsl:param>
        <xsl:variable name="vstr1" select="normalize-space(str:replace($vstr,'&#160;',' '))"/>
        <xsl:value-of select="$vstr1"/>
    </xsl:template>

    <xsl:template name="fixportname">
        <xsl:param name="pname">Blank</xsl:param>
        <xsl:variable name="pname1" select="normalize-space(str:replace(translate($pname,'.,*',';;'),'&#160;',' '))" />
        <xsl:variable name="pname2"><xsl:choose>
            <xsl:when test="starts-with($pname1, 'Pt ') or starts-with($pname1, 'PT ')"><xsl:value-of select="concat('Puerto ', substring($pname1, 4))" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$pname1" /></xsl:otherwise>
        </xsl:choose></xsl:variable>
        <xsl:choose>
            <xsl:when test="$pname2 = 'Amirante'">Almirante; PA</xsl:when>
            <xsl:when test="$pname2 = 'Amirante; PA'">Almirante; PA</xsl:when>
            <xsl:when test="$pname2 = 'Almirante; PN'">Almirante; PA</xsl:when>
            <xsl:when test="$pname2 = 'ALMIRANTE; PANAMA'">Almirante; PA</xsl:when>
            <xsl:when test="$pname2 = 'CALDERA; COSTA RICA'">Caldera; CR</xsl:when>
            <xsl:when test="$pname2 = 'Freeport; TX'">Freeport; TX; US</xsl:when>
            <xsl:when test="$pname2 = 'FREEPORT; TX'">Freeport; TX; US</xsl:when>
            <xsl:when test="$pname2 = 'GUAYAQUIL; ECUADOR'">Guayaquil; EC</xsl:when>
            <xsl:when test="$pname2 = 'Gulfport; MS'">Gulfport; MS; US</xsl:when>
            <xsl:when test="$pname2 = 'GULFPORT; MS'">Gulfport; MS; US</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Hueneme; CA'">Port Hueneme; CA; US</xsl:when>
            <xsl:when test="$pname2 = 'Hueneme; CALIFORNIA'">Port Hueneme; CA; US</xsl:when>
            <xsl:when test="$pname2 = 'HUENEME; CALIFORNIA'">Port Hueneme; CA; US</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Almirante; PN'">Almirante; PA</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Barrios; GU'">Puerto Barrios; GT</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Barrios; HN'">Puerto Barrios; GT</xsl:when>
            <xsl:when test="$pname2 = 'Puerto BARRIOS; GUATEMALA'">Puerto Barrios; GT</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Cortes; CR'">Puerto Cortes; HN</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Cortez; HN'">Puerto Cortes; HN</xsl:when>
            <xsl:when test="$pname2 = 'Puerto CORTES; HONDURAS'">Puerto Cortes; HN</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Everglades; FL'">Port Everglades; FL; US</xsl:when>
            <xsl:when test="$pname2 = 'Miami (Pt Everglades; FL)'">Port Everglades; FL; US</xsl:when>
            <xsl:when test="$pname2 = 'SOUTH; FL'">Port Everglades; FL; US</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Limon'">Puerto Limon; CR</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Limon; HN'">Puerto Limon; CR</xsl:when>
            <xsl:when test="$pname2 = 'Puerto LIMON; COSTA RICA'">Puerto Limon; CR</xsl:when>
            <xsl:when test="$pname2 = 'Puerto Quetzal; GU'">Puerto Quetzal; GT</xsl:when>
            <xsl:when test="$pname2 = 'Puerto QUETZAL; GUATEMALA'">Puerto Quetzal; GT</xsl:when>
            <xsl:when test="$pname2 = 'Wilmington; DE'">Wilmington; DE; US</xsl:when>
            <xsl:when test="$pname2 = 'WILMINGTON; DE'">Wilmington; DE; US</xsl:when>
            <xsl:when test="$pname2 = 'Bremerhaven'">Bremerhaven; DE</xsl:when>
            <xsl:when test="$pname2 = 'Vado'">Vado Ligure; IT</xsl:when>

            <xsl:otherwise><xsl:value-of select="$pname2" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="fixdatestring">
        <xsl:param name="dstr">Blank</xsl:param>
        <xsl:variable name="dstr1" select="normalize-space(str:replace($dstr,'&#160;',' '))" />
        <xsl:variable name="dstr2" select="normalize-space(str:replace($dstr1,'/',' '))" />
        <xsl:variable name="dstr3" select="normalize-space(str:replace($dstr2,'Skip',''))" />
        <xsl:value-of select="$dstr3" />
    </xsl:template>

</xsl:stylesheet>
