<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:str="http://exslt.org/strings" extension-element-prefixes="str">
    <xsl:import href="../../../processor/exslt/str/str.xsl"/>
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements=" "/>

    <xsl:param name="htmlfilename" select="notset"/>

    <xsl:template match="/">
        <schedules>
            <xsl:apply-templates select="/html" />
        </schedules>
    </xsl:template>

    <xsl:template match="/html">
        <schedule>
            <route>
                <xsl:attribute name="code">
                    <xsl:value-of select="substring-before($htmlfilename, '.')" />
                </xsl:attribute>
                <xsl:value-of select="normalize-space(head/title)" />
            </route>
            <xsl:apply-templates select="//table[@class='ep_table']/thead/tr/th" />
        </schedule>
    </xsl:template>

    <xsl:template match="th">
        <xsl:variable name="xp" select="count(preceding-sibling::th)+1" />
        <xsl:variable name="vesname" select="normalize-space(.//span)" />
        <xsl:if test="$vesname != 'TBN'">
            <vessel>
                <xsl:attribute name="name">
                    <xsl:call-template name="fixvesselname">
                        <xsl:with-param name="name" select="$vesname" />
                    </xsl:call-template>
                </xsl:attribute>

                <xsl:attribute name="voyage">
                    <xsl:call-template name="fixvoyagestring">
                        <xsl:with-param name="vstr" select="normalize-space(./a[2])"/>
                    </xsl:call-template>
                </xsl:attribute>
                
                <xsl:apply-templates select="../../following-sibling::tr" mode="port">
                    <xsl:with-param name="xp" select="$xp"/>
                </xsl:apply-templates>
            </vessel>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tr" mode="port">
        <xsl:param name="xp">0</xsl:param>

		<!-- xsl:variable name="pdate" select="normalize-space(td[$xp+1]/span/span[1])" /-->
		<xsl:variable name="pname">
			<xsl:call-template name="fixportname">
				<xsl:with-param name="pname" select="th[@scope='row']"/>
			</xsl:call-template>
		</xsl:variable>


		<xsl:for-each select="td[$xp+1]/span/span" >
			<xsl:variable name="pdate" select="normalize-space(.)" />
            <xsl:if test="$pdate != '' and $pname != ''">
                <port name="{$pname}"><xsl:value-of select="$pdate" /></port>
            </xsl:if>
		</xsl:for-each>

    </xsl:template>

    <xsl:template name="fixvesselname">
        <xsl:param name="name">TBA</xsl:param>
        <xsl:variable name="nm1" select="normalize-space(str:replace($name,'&#160;',' '))"/>
        <xsl:value-of select="$nm1"/>
    </xsl:template>

    <xsl:template name="fixvoyagestring">
        <xsl:param name="vstr">Blank</xsl:param>
        <xsl:variable name="vstr1" select="normalize-space(str:replace($vstr,'&#160;',' '))"/>
        <xsl:value-of select="$vstr1"/>
    </xsl:template>

    <xsl:template name="fixportname">
        <xsl:param name="pname">Blank</xsl:param>
        <xsl:variable name="pname1" select="normalize-space(str:replace($pname,'&#160;',' '))"/>
        <xsl:choose>
            <xsl:when test="$pname1='Portland'">Portland; OR; US</xsl:when>
            <xsl:when test="$pname1='Alexandria'">Alexandria; EG</xsl:when>
            <xsl:when test="$pname1='Bremerhaven'">Bremerhaven; DE</xsl:when>
            <xsl:when test="$pname1='Xingang'">Tianjinxingang; CN</xsl:when>
            <xsl:when test="$pname1='Balboa'">Balboa; PA</xsl:when>
            <xsl:when test="$pname1='Manzanillo/Panama'">Manzanillo International Terminal; PA</xsl:when>
            <xsl:when test="$pname1='Moin Bay (Puerto Limon)'">Moin Bay; CR</xsl:when>
            <xsl:when test="$pname1='Malta(Marsaxl.)'">Marsaxlokk; MT</xsl:when>
            <xsl:when test="$pname1='Baltimore'">Baltimore; US</xsl:when>
            <xsl:when test="$pname1='Cartagena'">Cartagena; CO</xsl:when>
            <xsl:when test="$pname1='San Antonio'">San Antonio; CL</xsl:when>
            <xsl:when test="$pname1='Arica'">Arica; CL</xsl:when>
            <xsl:when test="$pname1='Dublin'">Dublin; IE</xsl:when>
            <xsl:when test="$pname1='Kingston'">Kingston; JM</xsl:when>
            <xsl:when test="$pname1='Rio Grande'">Rio Grande; BR</xsl:when>
            <xsl:when test="$pname1='Rotterdam'">Rotterdam; NL</xsl:when>
            <xsl:when test="$pname1='Sydney'">Sydney; AU</xsl:when>
            <xsl:when test="$pname1='Vancouver'">Vancouver; US</xsl:when>
            <xsl:when test="$pname1='Genua'">Genoa; IT</xsl:when>
            <xsl:when test="$pname1='Singapur'">Singapore; SG</xsl:when>
            <xsl:when test="$pname1='Savannah'">Savannah; GA; US</xsl:when>
            <xsl:when test="$pname1='Charleston'">Charleston; SC; US</xsl:when>
            <xsl:when test="$pname1='Manzanillo/Mexico'">Manzanillo; MX</xsl:when>
            <xsl:when test="$pname1='Puerto Limón'">Puerto Limon; CR</xsl:when>
            <xsl:when test="$pname1='Havana'">La Habana; CU</xsl:when>
            <xsl:when test="$pname1='Nagoya'">Nagoya, Aichi; JP</xsl:when>
            <xsl:when test="$pname1='Port Elizabeth'">Port Elizabeth; ZA</xsl:when>
            <xsl:when test="$pname1='St. Petersburg'">Saint Petersburg; RU</xsl:when>
            <xsl:when test="$pname1='São Petersburgo'">Saint Petersburg; RU</xsl:when>
            <xsl:when test="$pname1='Nelson'">Nelson; NZ</xsl:when>
            <xsl:when test="$pname1='Las Palmas'">Las Palmas; ES</xsl:when>
            <xsl:when test="$pname1='Piräus'">Piraeus; GR</xsl:when>
            <xsl:when test="$pname1='San Juan'">San Juan; PR</xsl:when>
            <xsl:when test="$pname1='Porto Madryn'">Puerto Madryn; AR</xsl:when>
            <xsl:when test="$pname1='Hamburgo'">Hamburg; DE</xsl:when>
            <xsl:when test="$pname1='Helsinque'">Helsinki (Helsingfors); FI</xsl:when>
            <xsl:when test="$pname1='Zárate'">Zarate; AR</xsl:when>
            <xsl:when test="$pname1='Lázaro Cárdenas'">Lazaro Cardenas; MX</xsl:when>
            <xsl:when test="$pname1='Navegantes'">Navegantes; BR</xsl:when>
            <xsl:when test="$pname1='Istanbul / Kumport'">Kumport; TR</xsl:when>
            <xsl:when test="$pname1='Gebze - Evyap'">Gebze; TR</xsl:when>
            <xsl:when test="$pname1='Barcelona'">Barcelona; ES</xsl:when>
            <xsl:otherwise><xsl:value-of select="$pname1" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="fixdatestring">
        <xsl:param name="dstr">Blank</xsl:param>
        <xsl:variable name="dstr1" select="normalize-space(str:replace($dstr,'&#160;',' '))"/>
        <xsl:variable name="dstr2" select="substring-after($dstr1, ' ')"/> <!-- strip day name -->
        <xsl:variable name="dstr3" select="str:replace($dstr2,'-',' ')"/>
        <xsl:variable name="dstr4" select="str:replace($dstr3,'Mai','May')"/>
        <xsl:variable name="dstr5" select="str:replace($dstr4,'Okt','Oct')"/>
        <xsl:variable name="dstr6" select="str:replace($dstr5,'Dez','Dec')"/>
        <xsl:variable name="dstr7" select="str:replace($dstr6,'Mr','Mar')"/>
        <xsl:variable name="dstr8" select="str:replace($dstr7,'Mär','Mar')"/>
        <xsl:value-of select="$dstr8"/>
    </xsl:template>

</xsl:stylesheet>
