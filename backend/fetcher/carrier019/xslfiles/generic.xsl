<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:str="http://exslt.org/strings" xmlns:php="http://php.net/xsl" extension-element-prefixes="str php">

  <xsl:import href="../../../processor/exslt/str/str.xsl" />
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements=" "/>
  <xsl:param name="htmlfilename" select="notset"/>

  <xsl:template match="/">
    <schedules>
      <xsl:apply-templates select="//table//tr[starts-with(translate(., '&#160; ', ''), 'Vessel')]" mode="vnames"/>
    </schedules>
  </xsl:template>

  <xsl:template match="tr" mode="vnames">
    <xsl:variable name="pcolumn">
      <xsl:for-each select="./td">
        <xsl:if test="starts-with(normalize-space(.),'Vessel')">
          <xsl:value-of select="position()"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <schedule>
      <route>
        <xsl:call-template name="fixroutename">
          <xsl:with-param name="fname" select="$htmlfilename" />
        </xsl:call-template>
      </route>
      <xsl:apply-templates select="./following-sibling::tr[contains(td[number($pcolumn)],'Voyage')]" mode="voyrow">
        <xsl:with-param name="pcolo" select="number($pcolumn)" />
      </xsl:apply-templates>
    </schedule>
  </xsl:template>

  <xsl:template name="fixroutename">
    <xsl:param name="fname">Blank</xsl:param>
    <xsl:variable name="rname" select="(preceding-sibling::tr[td[@colspan &gt; 7] and count(td[string-length(normalize-space(.)) &gt; 3]) = 1 and string-length(translate(., '&#160; ', '')) &gt; 10])[last()]" />
    <xsl:variable name="rname1" select="normalize-space(str:replace($rname,'&#160;',' '))" />
    <xsl:value-of select="$rname1" />
  </xsl:template>

  <xsl:template match="tr" mode="voyrow">
    <xsl:param name="pcolo">0</xsl:param>
    <xsl:apply-templates select="./td" mode="vname">
      <xsl:with-param name="pcol" select="$pcolo" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="td" mode='vname'>
    <xsl:param name="pcol">0</xsl:param> 
    <xsl:variable name="xp" select="position()"/> 
    <xsl:if test="normalize-space(.) != '' and not(contains(.,'Voyage'))">
      <xsl:variable name="vessname" select="./../preceding-sibling::tr[contains(td[$pcol],'Vessel')]/td[$xp]"/>
      <xsl:if test="normalize-space($vessname) != '' and not(contains($vessname,'?'))">
        <xsl:variable name="stop-at" select="generate-id(./../following-sibling::tr[contains(td[$pcol],'Voyage') or (not(contains(td[$pcol],'Ports')) and count(.//td[position() &gt; $pcol and normalize-space(.) != ''])=0)])" />
        <!-- <val><xsl:value-of select="$stop-at" /></val>  -->

        <xsl:variable name="alldates">
          <xsl:for-each select="./../following-sibling::tr[$stop-at = '' or following-sibling::tr[generate-id() = $stop-at]]">
            <xsl:call-template name="fixdatestring">
              <xsl:with-param name="dstr" select="td[$xp]" />
            </xsl:call-template>
          </xsl:for-each>
        </xsl:variable>
        <xsl:if test="normalize-space($alldates) != ''">
          <vessel>
            <xsl:attribute name="name">
              <xsl:call-template name="fixvesselname">
                <xsl:with-param name="name1" select="$vessname"/>
              </xsl:call-template>
            </xsl:attribute>

            <xsl:attribute name="voyage">
              <xsl:call-template name="fixvoyagestring">
                <xsl:with-param name="vstr" select="." />  
              </xsl:call-template>
            </xsl:attribute>

            <xsl:for-each select="./../following-sibling::tr">
              <xsl:variable name="pdate0">
                  <xsl:call-template name="fixdatestring">
                    <xsl:with-param name="dstr" select="td[$xp]" />
                  </xsl:call-template>
              </xsl:variable>

              <xsl:variable name="pdate" select="normalize-space($pdate0)" />
              <xsl:if test="($stop-at = '' or following-sibling::tr[generate-id() = $stop-at]) and not(contains(./td[$pcol],'Ports')) and not(normalize-space(./td[$pcol]) = '.') and not(contains(./td[$pcol],'**')) and $pdate != ''">
                <port>
                  <xsl:attribute name="name">
                    <xsl:call-template name="fixportname">
                      <xsl:with-param name="pname">
                        <xsl:choose>
                          <xsl:when test="contains($pdate, ' ')"><xsl:value-of select="substring-before($pdate, ' ')" /></xsl:when>
                          <xsl:otherwise><xsl:value-of select="td[$pcol]" /></xsl:otherwise>
                        </xsl:choose>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:attribute>

                  <xsl:choose>
                    <xsl:when test="contains($pdate, ' ')"><xsl:value-of select="substring-after($pdate, ' ')" /></xsl:when>
                    <xsl:otherwise><xsl:value-of select="$pdate" /></xsl:otherwise>
                  </xsl:choose>
                </port>
              </xsl:if>
            </xsl:for-each>
          </vessel>
        </xsl:if>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="fixvesselname">
    <xsl:param name="name1">Blank</xsl:param>
    <xsl:variable name="nm1" select="normalize-space(str:replace($name1,'&#160;',' '))" />
    <xsl:value-of select="normalize-space($nm1)"/>
  </xsl:template>
  
  <xsl:template name="fixvoyagestring">
    <xsl:param name="vstr">Blank</xsl:param> 
    <xsl:variable name="vstr1" select="normalize-space(str:replace($vstr,'&#160;',' '))" />
    <xsl:value-of select="$vstr1" />
  </xsl:template>

  <xsl:template name="fixportname">
    <xsl:param name="pname">Blank</xsl:param>
    <xsl:variable name="pname1" select="normalize-space(str:replace($pname,'&#160;',' '))" />
    <xsl:variable name="pname2" select="normalize-space(str:replace($pname1,'*',''))" />
    <xsl:variable name="pname3" select="translate($pname2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')" />
    <xsl:choose>
      <xsl:when test="$pname3 = 'xingang'">Tianjinxingang; CN</xsl:when>
      <xsl:when test="$pname3 = 'navegantes'">Navegantes; BR</xsl:when>
      <xsl:when test="$pname3 = 'doula'">Douala; CM</xsl:when>
      <xsl:when test="$pname3 = 'shangai'">Shanghai; CN</xsl:when>
      <xsl:when test="$pname3 = 'lagos'">Lagos; NG</xsl:when>
      <xsl:when test="$pname3 = 'capetown'">Cape Town; ZA</xsl:when>
      <xsl:otherwise><xsl:value-of select="$pname3" /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="fixdatestring">
    <xsl:param name="dstr">Blank</xsl:param> 
    <xsl:variable name="dstr0" select="normalize-space(str:replace($dstr,'&#160;',' '))" />
    <xsl:variable name="dstr1">
      <xsl:choose>
        <xsl:when test="starts-with($dstr0, '[')"><xsl:value-of select="substring-after($dstr0, ']')" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="$dstr0" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ds" select="normalize-space(translate($dstr1, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'))" />
    <xsl:variable name="dst" select="normalize-space(str:replace($ds,'bo',''))" />
    <xsl:choose>
      <xsl:when test="$dst = 'omit'"></xsl:when>
      <xsl:when test="$dst = 'omits'"></xsl:when>
      <xsl:when test="$dst = 'sailed'"></xsl:when>
      <xsl:when test="$dst = 'on berth'"></xsl:when>
      <xsl:when test="$dst = 'in port'"></xsl:when>
      <xsl:when test="$dst = 'n/a'"></xsl:when>
      <xsl:when test="$dst = 'tba'"></xsl:when>
      <xsl:otherwise><xsl:value-of select="$dst" /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
