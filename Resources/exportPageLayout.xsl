<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" version="1.0"
    xmlns="http://www.artifacts.de/storytellingeditor"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 31, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b> mic</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    
    <xsl:template match="/">
        <Document xmlns="http://www.artifacts.de/storytellingeditor"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            name="PageLayout" externalId="" internalId="">
            <xsl:apply-templates/>
        </Document>
    </xsl:template>

    <xsl:template match="Stage">
        <xsl:element name="Stage">            
            <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
            <xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute>
            <xsl:attribute name="height"><xsl:value-of select="@height"/></xsl:attribute>
			<xsl:attribute name="pageWidth"><xsl:value-of select="@pageWidth"/></xsl:attribute>
			<xsl:attribute name="pageHeight"><xsl:value-of select="@pageHeight"/></xsl:attribute>
            <xsl:attribute name="externalId"><xsl:value-of select="@externalId"/></xsl:attribute>
            <xsl:attribute name="internalId"><xsl:value-of select="@internalId"/></xsl:attribute>
            <xsl:element name="Scenario">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="Scene">
        <Scene externalId="{@externalId}" internalId="{@id}">
            <xsl:apply-templates/>
        </Scene>
    </xsl:template>

    <xsl:template match="Asset">
        <!-- convert position and bounds to x, y, width and height -->
        <xsl:variable name="position" select="str:tokenize(KeyframeAnimation/Keyframe[1]/@position, '\{\}, ')" />
        <xsl:variable name="bounds" select="str:tokenize(KeyframeAnimation/Keyframe[1]/@bounds, '\{\}, ')" />
        <xsl:variable name="x" select="$position[1]" />
        <xsl:variable name="y" select="$position[2]" />
        <xsl:variable name="w" select="$bounds[3]" />
        <xsl:variable name="h" select="$bounds[4]" />

        <xsl:choose>
            <xsl:when test="@kind = 0">
                <Asset hidden="false" isButton="false" name="{@name}" x="{$x}" y="{$y}" width="{$w}"
                    height="{$h}" zIndex="{@viewPosition}" externalId="{@externalId}"
                    internalId="{@id}" kind="image">
                    <xsl:apply-templates/>
                </Asset>
            </xsl:when>
            <xsl:when test="@kind = 1">
                <Asset hidden="false" isButton="false" name="{@name}" x="{$x}" y="{$y}" width="{$w}"
                    height="{$h}" zIndex="{@viewPosition}" externalId="{@externalId}"
                    internalId="{@id}" kind="video">
                    <xsl:apply-templates/>
                </Asset>
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template match="ExternalData">
        <ExternalData externalURL="{@externalURL}" keyName="{@keyName}"
            viewPosition="{@viewPosition}" externalId="{@externalId}" internalId="{@id}">
        </ExternalData>
    </xsl:template>

    <!-- unfinished, not needed actually, because storytelling animations are exported via BIPStageXML
        xsl:template match="KeyframeAnimation">
        <KeyframeAnimation time="26" bounds="{@bounds}" easing="{@easing}" position="{@position}" rotation="0" opacity="1" backgroundColor="#ffffff00">
        </KeyframeAnimation>
    </xsl:template -->
    
</xsl:stylesheet>
