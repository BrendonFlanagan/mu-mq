<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes="dp" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:anz="com.anz.services:0.1">
	<xsl:output method="xml"/>
	<!--#################################################################-->
	<!--Log a system log error message.-->
	<!--#################################################################-->
	<xsl:template match="/">
		<xsl:variable name="Uuid" select="dp:variable('var://context/CommonWeb/UUID')"/>
		<xsl:variable name="URL-Out" select="dp:variable('var://service/URL-out')"/>
		<xsl:variable name="Error-Headers" select="dp:variable('var://service/error-headers')"/>
		<xsl:variable name="Error-Message" select="dp:variable('var://service/error-message')"/>
		<xsl:variable name="EndpointTransport" select="dp:variable('var://context/CommonWeb/EndpointTransport')"/>
		<xsl:variable name="MQErrorAlreadyTriggered" select="dp:variable('var://context/CommonWeb/MQErrorAlreadyTriggered')"/>
		<xsl:variable name="TransRuleType" select="dp:variable('var://service/transaction-rule-type')"/>
		<xsl:choose>
			<xsl:when test="$TransRuleType != 'error'">
				<xsl:if test="$EndpointTransport = 'HTTP'">
					<xsl:variable name="backendRspCode" select="dp:http-response-header('x-dp-response-code')"/>
					<dp:set-variable name="'var://context/CommonWeb/BackendRspCode'" value="$backendRspCode"/>
					<xsl:variable name="httpStatusCode" select="substring($backendRspCode,1,3)"/>
					<xsl:if test="$httpStatusCode &gt;= '300'">
						<xsl:message dp:type="CommonWeb" dp:priority="error">
							<xsl:value-of select="concat('Error in CommonWeb: ', 'Uuid: ',$Uuid, ' URL-Out: ',$URL-Out, ' ErrorHeader: ',$httpStatusCode, ' ErrorMsg: ',$backendRspCode)"/>
						</xsl:message>
					</xsl:if>
				</xsl:if>
				<xsl:if test="$EndpointTransport = 'MQ'">
					<xsl:variable name="backendRspCode" select="dp:http-response-header('x-dp-response-code')"/>
					<xsl:variable name="Domain" select="dp:variable('var://service/domain-name')"/>
					<xsl:variable name="Type" select="concat($Domain,'-business-service-metadata')"/>
					<xsl:message dp:type="{$Type}" dp:priority="info">
								backendRspCode: <xsl:value-of select="$backendRspCode"/>
					</xsl:message>
					<xsl:if test="not($MQErrorAlreadyTriggered)">
						<xsl:if test="not(starts-with($backendRspCode, '2') and string-length($backendRspCode)=4)">
							<!--if present, parse the MQMD header and extract out what detail we can get of meaningful use based on MsgType scenario.-->
							<!--If MsgType was 8, aka Datagram only with no reply, then the MQMD details are that of the PUT message from Datapower.-->
							<!--If MsgType was 2, aka Request/Reply, and a Reply was expected, then the MQMD details are that of the PUT message from the downstream system.-->
							<!-- Get the MQMD headers -->
							<xsl:variable name="MQMD" select="dp:response-header('MQMD')"/>
							<!-- Parse the MQMD headers to XML format -->
							<xsl:variable name="parsedMQMD" select="dp:parse($MQMD)"/>
							<!--Shortened representation of the MQMD and to also override the MsgType for better understanding.-->
							<xsl:variable name="URLout" select="dp:variable('var://service/URL-out')"/>
							<xsl:variable name="modifiedMQMD">
								<xsl:choose>
									<xsl:when test="contains($URL-Out, 'ReplyQueue')">
						Desc=Provider MQPUT Info, MsgType=2, MsgId=<xsl:value-of select="$parsedMQMD/MQMD/MsgId"/>, CorrelId=<xsl:value-of select="$parsedMQMD/MQMD/CorrelId"/>, ReplyToQMgr=<xsl:value-of select="normalize-space($parsedMQMD/MQMD/ReplyToQMgr)"/>, PutDate=<xsl:value-of select="$parsedMQMD/MQMD/PutDate"/>, PutTime=<xsl:value-of select="$parsedMQMD/MQMD/PutTime"/>
									</xsl:when>
									<xsl:otherwise>
						Desc=Datapower MQPUT Info, MsgType=<xsl:value-of select="$parsedMQMD/MQMD/MsgType"/>, MsgId=<xsl:value-of select="$parsedMQMD/MQMD/MsgId"/>, PutDate=<xsl:value-of select="$parsedMQMD/MQMD/PutDate"/>, PutTime=<xsl:value-of select="$parsedMQMD/MQMD/PutTime"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="Domain" select="dp:variable('var://service/domain-name')"/>
							<xsl:variable name="Type" select="concat($Domain,'-business-service-metadata')"/>
							<xsl:message dp:type="{$Type}" dp:priority="info">
								<xsl:value-of select="$modifiedMQMD"/>
							</xsl:message>
						</xsl:if>
						<!--	 -->
						<xsl:if test="starts-with($backendRspCode, '2') and string-length($backendRspCode)=4">
							<dp:set-variable name="'var://context/CommonWeb/MQErrorAlreadyTriggered'" value="'Yes'"/>
							<xsl:message dp:type="CommonWeb" dp:priority="error">
								<xsl:value-of select="concat('Error in CommonWeb: ', 'Uuid: ',$Uuid, ' URL-Out: ',$URL-Out, ' ErrorHeader: ',$backendRspCode, ' ErrorMsg: ',$backendRspCode)"/>
							</xsl:message>
							<dp:set-variable name="'var://context/CommonWeb/BackendRspCode'" value="$backendRspCode"/>
							<dp:set-http-response-header name="'x-dp-response-code'" value="'200 OK'"/>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message dp:type="CommonWeb" dp:priority="error">
					<xsl:value-of select="concat('Error in CommonWeb: ', 'Uuid: ',$Uuid, ' URL-Out: ',$URL-Out, ' ErrorHeader: ',$Error-Headers, ' ErrorMsg: ',$Error-Message)"/>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
