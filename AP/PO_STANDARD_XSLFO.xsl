<?xml version="1.0" encoding="UTF-8"?>
<!-- +======================================================================+ -->
<!-- |    Copyright (c) 2005, 2016 Oracle and/or its affiliates.           | -->
<!-- |                         All rights reserved.                         | -->
<!-- |                           Version 12.0.0                             | -->
<!-- +======================================================================+ -->
 <!-- $Header: PO_STANDARD_XSLFO.xsl 120.29.12020000.7 2016/10/24 03:42:46 zhijfeng ship $ --> 
 <!-- dbdrv: exec java oracle/apps/xdo/oa/util XDOLoader.class java &phase=dat checkfile:~PROD:patch/115/publisher/templates:PO_STANDARD_XSLFO.xsl UPLOAD -DB_USERNAME &un_apps -DB_PASSWORD &pw_apps -JDBC_CONNECTION &jdbc_db_addr -LOB_TYPE TEMPLATE -APPS_SHORT_NAME PO -LOB_CODE PO_STANDARD_XSLFO -LANGUAGE en -XDO_FILE_TYPE XSL-FO -FILE_NAME &fullpath:~PROD:patch/115/publisher/templates:PO_STANDARD_XSLFO.xsl -->

<xsl:stylesheet version="1.0"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:fo="http://www.w3.org/1999/XSL/Format"  >


<!-- Attribute Set for table header labels with right align and space at end-->
	<xsl:attribute-set name="table_head">
		<xsl:attribute name="font-size">8pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-end">3pt</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table header labels with right align and space at start-->
	<xsl:attribute-set name="table_head1">
		<xsl:attribute name="font-size">8pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-start">3pt</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table header labels with right align and space at end and space before and after-->
	<xsl:attribute-set name="table_head2">
		<xsl:attribute name="font-size">8pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-end">5pt</xsl:attribute>
		<xsl:attribute name="space-before">1.2pt</xsl:attribute>
		<xsl:attribute name="space-after">1.2pt</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table cell with border, background and right align attributes-->
	<xsl:attribute-set name="table_cell_heading1">
		<xsl:attribute name=" background-color">#E7E7E7</xsl:attribute>
		<xsl:attribute name="text-align">right</xsl:attribute>
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table cell with border, background and left align attributes-->
	<xsl:attribute-set name="table_cell_heading2">
		<xsl:attribute name=" background-color">#E7E7E7</xsl:attribute>
		<xsl:attribute name="text-align">left</xsl:attribute>
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table cell with out border and right align attribute-->
	<xsl:attribute-set name="table_cell_heading3">
			<xsl:attribute name="text-align">right</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table cell same as table_cell_heading1 except top padding.-->
	<xsl:attribute-set name="table_cell_heading4">
		<xsl:attribute name=" background-color">#E7E7E7</xsl:attribute>
		<xsl:attribute name="text-align">right</xsl:attribute>
		<xsl:attribute name="padding-top">1.2pt</xsl:attribute>
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for table cell with border and center align attributes-->
	<xsl:attribute-set name="heading.center.align">
			<xsl:attribute name="font-weight">bold</xsl:attribute>	
			<xsl:attribute name="text-align">center</xsl:attribute>
			<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for cover page heading -->
	<xsl:attribute-set name="coverpage.label">
		<xsl:attribute name="font-style">italic</xsl:attribute>
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
	</xsl:attribute-set>


<!--Bug#4221678:Added three attributes to preserve the white spaces and line breaks -->
<!-- Attribute Set for field values with space at start-->
	<xsl:attribute-set name="form_data">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-start">3pt</xsl:attribute>
                <xsl:attribute name="white-space-treatment">preserve</xsl:attribute>
                <xsl:attribute name="white-space-collapse">false</xsl:attribute>
                <xsl:attribute name="linefeed-treatment">preserve</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with space at end-->
	<xsl:attribute-set name="form_data1">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-end">3pt</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with space at start, before and after-->
	<xsl:attribute-set name="form_data2">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-start">5pt</xsl:attribute>
		<xsl:attribute name="space-before">3pt</xsl:attribute>
		<xsl:attribute name="space-after">3pt</xsl:attribute> 
	</xsl:attribute-set>


<!-- Attribute Set for field values with out space -->
	<xsl:attribute-set name="form_data3">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for cover page text-->
	<xsl:attribute-set name="cover_page_text">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="space-start">3pt</xsl:attribute>
		<xsl:attribute name="linefeed-treatment">preserve</xsl:attribute>
	</xsl:attribute-set>


<!-- Attribute Set for field values with border-->
	<xsl:attribute-set name="table.cell">
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
		<xsl:attribute name="text-align">left</xsl:attribute>
	</xsl:attribute-set>


<!-- Attribute Set for field values with out border-->
	<xsl:attribute-set name="table.cell2">
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with border and right align-->
	<xsl:attribute-set name="table.cell3">
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
		<xsl:attribute name="text-align">right</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with border and right align-->
	<xsl:attribute-set name="table.cell4">
		<xsl:attribute name="text-align">center</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with right align-->
	<xsl:attribute-set name="table.cell5">
		<xsl:attribute name="text-align">right</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with left align-->
	<xsl:attribute-set name="table.cell6">
		<xsl:attribute name="text-align">left</xsl:attribute>
		<xsl:attribute name="height">0mm</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set for field values with border and no height-->
	<xsl:attribute-set name="table.cell7">
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
		<xsl:attribute name="height">4mm</xsl:attribute>
	</xsl:attribute-set>


<!-- Attribute Set for Legal entity details-->
	<xsl:attribute-set name="legal_details_style">
		<xsl:attribute name="font-size">12pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="text-align">left</xsl:attribute>
		<xsl:attribute name="font-weight">bold</xsl:attribute>
	</xsl:attribute-set>

<!-- Attribute Set same as Legal entity details with center align -->
	<xsl:attribute-set name="test_style">
		<xsl:attribute name="font-size">12pt</xsl:attribute>
		<xsl:attribute name="font-family">Times</xsl:attribute>
		<xsl:attribute name="text-align">center</xsl:attribute>
		<xsl:attribute name="font-weight">bold</xsl:attribute>
	</xsl:attribute-set>


<!-- Attribute for lines table with border width attribute -->
	<xsl:attribute-set name="lines.table.style">
		<xsl:attribute name="border-width">.5pt</xsl:attribute>
	</xsl:attribute-set>



<!-- Variable for holding the root tag object-->
<xsl:variable name="ROOT_OBJ" select="(/PO_DATA)"/>

<!-- Variable for holding boilerplate messages -->
<xsl:variable name="BOILER_PLATE_MESSAGES_OBJ" select="($ROOT_OBJ/MESSAGE/MESSAGE_ROW)"/>

<!-- Variable for holding the lines root object-->
<xsl:variable name="LINES_ROOT_OBJ" select="($ROOT_OBJ/LINES/LINES_ROW)"/>

<!-- Variable for holding the Price Modifiers root object-->
<xsl:variable name="PRICE_MODIFIERS_ROOT_OBJ" select="($LINES_ROOT_OBJ/PRICE_MODIFIERS/PRICE_MODIFIERS_ROW)"/>

<!-- Variable for holding the Blanket Price Modifiers root object-->
<xsl:variable name="ADD_PRICE_MODIFIERS_ROOT_OBJ" select="($LINES_ROOT_OBJ/ADD_PRICE_MODIFIERS/ADD_PRICE_MODIFIERS_ROW)"/>

<!-- Variable for holding the Blanket Price Modifiers root object-->
<xsl:variable name="ADD_PRICE_PONUM_ROOT_OBJ" select="($LINES_ROOT_OBJ/ADD_PRICE_PONUM/ADD_PRICE_PONUM_ROW)"/>

<!-- Variable for holding the shipments root object-->
<xsl:variable name="LINE_LOCATIONS_ROOT_OBJ" select="($LINES_ROOT_OBJ/LINE_LOCATIONS/LINE_LOCATIONS_ROW)"/>

<!-- Variable for holding the DISTRIBUTIONS root object-->
<xsl:variable name="DISTRIBUTIONS_ROOT_OBJ" select="($LINE_LOCATIONS_ROOT_OBJ/DISTRIBUTIONS/DISTRIBUTIONS_ROW)"/>


<!-- Variable for holding the line long attachments root object-->
<xsl:variable name="LINE_LONG_ATTACHMENTS_ROOT_OBJ" select="($ROOT_OBJ/LINE_ATTACHMENTS/ID)"/>

<!-- Variable for holding the header long attachments root object-->
<xsl:variable name="HEADER_LONG_ATTACHMENTS_ROOT_OBJ" select="($ROOT_OBJ/HEADER_ATTACHMENTS)"/>

<!-- Variable for holding the shipment long attachments root object-->
<!--Bug #4654094-->
<xsl:variable name="SHIPMENT_ATTACHMENTS_ROOT_OBJ" select="($ROOT_OBJ/SHIPMENT_ATTACHMENTS/LINE_LOCATION_ID)"/>



<!-- variable to control the display of boilerplate texts. The current value is true because 1 is equal to 1. -->
<xsl:variable name="DisplayBoilerPlate" select="1=1" />

<!-- variable which controls the display of Charge Account. Current value is false because 1 is not equal to 2 -->
<xsl:variable name="PSA" select="1=2"/>
	

<!-- Variable which contains the text that will be displayed in the header -->
<xsl:variable name="header_text">
	<xsl:text>  </xsl:text>
</xsl:variable>

<!-- Variable which contains the text that will be displayed in the footer -->
<xsl:variable name="footer_text">
	<xsl:text>  </xsl:text>
</xsl:variable>

<!-- variable to find the total amount -->
<xsl:variable name="total_amount">
	<xsl:text>0</xsl:text>
</xsl:variable>

<!-- variable that indicates whether SPO is a complex work PO or not -->
<xsl:variable name="IS_COMPLEX_WORK_PO" select="$ROOT_OBJ/IS_COMPLEX_WORK_PO='Y'"/>

<!-- variable to print multiple word or not at header level ship to -->

<xsl:variable name="print_multiple">
	<xsl:if test="$ROOT_OBJ/DIST_SHIPMENT_COUNT &gt; 1">
		<xsl:text>Y</xsl:text>
	</xsl:if>
</xsl:variable>

<!-- Variable to identify whether Contract Terms and Conditions exists for current PO -->
<xsl:variable name="CON_TERMS_EXIST_FLAG" select="$ROOT_OBJ/WITH_TERMS='Y'"/>

<!-- This key is used to find the distinct of requestor id's -->
<xsl:key name="distinct-person_id" match="/PO_DATA/LINES/LINES_ROW/LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/DELIVER_TO_PERSON_ID" use="."/>

<!-- bug 21658024 -->
<xsl:key name="distinct-location_code" match="/PO_DATA/LINES/LINES_ROW/LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/LOCATION_CODE" use="."/>

<!-- 
	The DRAFT word should appear in the following conditions:
	1.Document status is incomplete or requires re-approval
	2.Document status is pre-approved because of pending approval and 	
	'DRAFT' will not be displayed if the requires signature field is checked and acceptance required field is 'Document and Signature' 
	3.Document status is In process, because approval isn't complete
	Note: if document is pre-approved, the internal flag requires signature is checked, and acceptance required is document and signature (binding design), 
	the draft word doesn't apply. In this situation the document is pending signature and the supplier shouldn't see the word draft. 

	Bug#3612548: Draft is not printed when PO is REJECTED. Added the condition.
	Bug#3650429: Draft is not printed in PO if PO is in PRE-APPROVED and Acceptance flag is set to document and signature.
	(Removing the condition ACCEPTANCE_REQUIRED_FLAG != 'S' and modified PENDING_SIGNATURE_FLAG ='N' when document is in PRE-APPROVED status)
     
-->

<xsl:variable name="print_draft" select="$ROOT_OBJ/AUTHORIZATION_STATUS = 'N' or $ROOT_OBJ/AUTHORIZATION_STATUS = 'INCOMPLETE' or $ROOT_OBJ/AUTHORIZATION_STATUS = 'REJECTED' or $ROOT_OBJ/AUTHORIZATION_STATUS = 'REQUIRES REAPPROVAL' or $ROOT_OBJ/AUTHORIZATION_STATUS = 'IN PROCESS' or ($ROOT_OBJ/AUTHORIZATION_STATUS ='PRE-APPROVED' and $ROOT_OBJ/PENDING_SIGNATURE_FLAG !='Y' )"/>



<xsl:template match="/">

    <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:fox="http://xml.apache.org/fop/extensions">

<!--bug#3650689: Changed the margin-top of simple-page-master to 0.5,
			     margin-bottom of region-body to 1.0,
			     extent of region-after to 0.66 -->
<fo:layout-master-set>
	<fo:simple-page-master master-name="cover-page" margin-top="0.5in" margin-bottom="0.0in" margin-left="0.71in" margin-right="0.71in" page-width="8.5in" page-height="11in" >
               <fo:region-before region-name="xsl-region-header" extent="0.5in"/>
               <fo:region-body region-name="xsl-region-body" margin-top="0.5in" margin-bottom="1.0in"/>
               <fo:region-after region-name="xsl-region-footer" extent="0.66in"/>
        </fo:simple-page-master> 

	<fo:simple-page-master  margin-top="0.5in" margin-bottom="0.0in" margin-left="0.71in" margin-right="0.71in" page-width="8.5in" page-height="11in" master-name="details-first-page">
		<fo:region-body margin-top="0.5in"  margin-bottom="1.0in" />
		<fo:region-before region-name="first-page" extent="0.5in"/>
		<fo:region-after extent="0.66in"/>
	</fo:simple-page-master>

	<fo:simple-page-master  margin-top="0.5in"  margin-bottom="0.0in" margin-left="0.71in" margin-right="0.71in" page-width="8.5in" page-height="11in" master-name="details-remaining-page">
		<fo:region-body margin-top="0.5in"  margin-bottom="1.0in" />
		<fo:region-before region-name="remaining-page" extent="0.5in"/>
		<fo:region-after extent="0.66in"/>
	</fo:simple-page-master>

	<fo:page-sequence-master master-name="details-page" > 
		<fo:conditional-page-master-reference master-reference="details-first-page"    page-position="first" /> 
		<fo:repeatable-page-master-reference master-reference="details-remaining-page" page-position="rest" /> 
	</fo:page-sequence-master> 
</fo:layout-master-set>

<xsl:if test="$CON_TERMS_EXIST_FLAG">
<fo:page-sequence master-reference="cover-page">


<!-- Block for displaying footer details -->
	<fo:static-content flow-name="xsl-region-after">
		<fo:block xsl:use-attribute-sets="form_data">  
		<fo:table>
		<fo:table-column column-width="90mm"/> <fo:table-column column-width="90mm"/>
		<fo:table-body>
		<fo:table-row>
			<fo:table-cell>	<fo:block> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PROPRIETARY_INFORMATION'][1]/TEXT"/> </fo:block> </fo:table-cell>
			<!-- Note to developer:- The attribute reference id for fo:page-number-citation is same as contract stylesheet. 
			     If the Contracts stylesheet fo:page-number-citation ref-id changes then the same has to be changed here.
			     Otherwise  the total page numbers will not appear in the PDF document. -->
			<fo:table-cell xsl:use-attribute-sets="table.cell5">	<fo:block> <xsl:call-template name="pageNumber"/> </fo:block> </fo:table-cell>
		</fo:table-row>
		</fo:table-body>
		</fo:table>
		</fo:block>
	</fo:static-content>
	<fo:static-content flow-name="xsl-region-header">
		<!-- Table to display Draft and document type -->
		<fo:table>
			<fo:table-column column-width="60mm"/> <fo:table-column column-width="60mm"/> <fo:table-column column-width="60mm"/>
				<fo:table-body>
					<fo:table-row>
						<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data3"> <xsl:value-of select="$ROOT_OBJ/OU_NAME"/>	 </fo:block> </fo:table-cell>
						<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data">  
							<xsl:if test="$print_draft">
								<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DRAFT'][1]/TEXT"/>
							</xsl:if>
						</fo:block> </fo:table-cell>
						<fo:table-cell xsl:use-attribute-sets="table.cell5">	
							<fo:block xsl:use-attribute-sets="form_data" > 
								<xsl:value-of select="$ROOT_OBJ/STYLE_DISPLAY_NAME"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$ROOT_OBJ/SEGMENT1"/>, <fo:leader leader-pattern="space" leader-length="1.0pt"/>  <xsl:value-of select="$ROOT_OBJ/REVISION_NUM" />
							</fo:block> 
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>
	<!-- end of display -->
	</fo:static-content>

<fo:flow flow-name="xsl-region-body">
<fo:table>
	<fo:table-body>
	<fo:table-row>
	<fo:table-cell xsl:use-attribute-sets="heading.center.align">	
		<fo:block xsl:use-attribute-sets="form_data"> 
			<xsl:value-of select="$ROOT_OBJ/STYLE_DISPLAY_NAME"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$ROOT_OBJ/SEGMENT1"/>,   <xsl:value-of select="$ROOT_OBJ/REVISION_NUM" />
		</fo:block> 
	</fo:table-cell>
	</fo:table-row>
	</fo:table-body>
</fo:table>
	    
<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>
<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>
	       
<fo:block xsl:use-attribute-sets="coverpage.label">  <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CONTRACTOR'][1]/TEXT"/> </fo:block>	       

<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>

<fo:table>
<fo:table-column column-width="15mm"/> <fo:table-column column-width="160mm"/> 
<fo:table-body>
	<fo:table-row>
		<fo:table-cell xsl:use-attribute-sets="table_cell_heading3"> <fo:block xsl:use-attribute-sets="table_head2"> 
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_COMPANY'][1]/TEXT"/> 
			<fo:block xsl:use-attribute-sets="table_head2"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CONTACT_NAME'][1]/TEXT"/> 
			<fo:block xsl:use-attribute-sets="table_head2"/>  <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_ADDRESS'][1]/TEXT"/>
		</fo:block> 
		</fo:table-cell>
		<fo:table-cell xsl:use-attribute-sets="table.cell2">  
		<fo:block xsl:use-attribute-sets="form_data"> 
			<xsl:value-of select="$ROOT_OBJ/VENDOR_NAME" /> 
			<fo:block/><xsl:call-template name="NAME_TEMPLATE">
			<xsl:with-param name="FIRST_NAME" select="$ROOT_OBJ/VENDOR_CONTACT_FIRST_NAME"/>
			<xsl:with-param name="LAST_NAME" select="$ROOT_OBJ/VENDOR_CONTACT_LAST_NAME"/>
			<xsl:with-param name="TITLE" select="$ROOT_OBJ/VENDOR_CONTACT_TITLE"/>
			</xsl:call-template>
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/VENDOR_ADDRESS_LINE1" />
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/VENDOR_CITY"/>  <xsl:if test="$ROOT_OBJ/VENDOR_CITY!=''">, </xsl:if>  <xsl:value-of select="$ROOT_OBJ/VENDOR_STATE"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$ROOT_OBJ/VENDOR_POSTAL_CODE"/>
		</fo:block> 
		</fo:table-cell>
	</fo:table-row>
	
</fo:table-body>
</fo:table>

<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>

<fo:block xsl:use-attribute-sets="coverpage.label">  <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUBMIT_RESPONSE'][1]/TEXT"/>  </fo:block>	       

<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>

<fo:table>
<fo:table-column column-width="15mm"/> <fo:table-column column-width="160mm"/> 
<fo:table-body>
	<fo:table-row>
		<fo:table-cell xsl:use-attribute-sets="table_cell_heading3"> <fo:block xsl:use-attribute-sets="table_head2"> 
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_COMPANY'][1]/TEXT"/> 
			<fo:block xsl:use-attribute-sets="table_head2"/>  <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CONTACT_NAME'][1]/TEXT"/>
			<fo:block xsl:use-attribute-sets="table_head2"/>  <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_ADDRESS'][1]/TEXT"/>
			<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>
			<fo:block xsl:use-attribute-sets="table_head2"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TELEPHONE'][1]/TEXT"/> 
			<fo:block xsl:use-attribute-sets="table_head2"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_FAX'][1]/TEXT"/>
			<fo:block xsl:use-attribute-sets="table_head2"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_EMAIL'][1]/TEXT"/>
		</fo:block> </fo:table-cell>
		<fo:table-cell xsl:use-attribute-sets="table.cell2">  <fo:block xsl:use-attribute-sets="form_data"> 
			<xsl:value-of select="$ROOT_OBJ/OU_NAME" /> 
			<fo:block/> <xsl:call-template name="NAME_TEMPLATE">
			<xsl:with-param name="FIRST_NAME" select="$ROOT_OBJ/DOCUMENT_BUYER_FIRST_NAME"/>
			<xsl:with-param name="LAST_NAME" select="$ROOT_OBJ/DOCUMENT_BUYER_LAST_NAME"/>
			<xsl:with-param name="TITLE" select="$ROOT_OBJ/DOCUMENT_BUYER_TITLE"/>
			</xsl:call-template>
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/BUYER_ADDRESS_LINE1" />
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/BUYER_CITY_STATE_ZIP"/>
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/BUYER_CONTACT_PHONE" /> 
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/BUYER_CONTACT_FAX" />
			<fo:block/> <xsl:value-of select="$ROOT_OBJ/BUYER_CONTACT_EMAIL" />
		</fo:block> </fo:table-cell>
	</fo:table-row>
	
</fo:table-body>
</fo:table>

<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>

<fo:table>
<fo:table-column column-width="180mm"/> 
<fo:table-body>
	<fo:table-row>
		<fo:table-cell>  
		<fo:block xsl:use-attribute-sets="cover_page_text" > 
		<xsl:choose>
		<xsl:when  test="PO_DATA/REVISION_NUM &gt; 0 and PO_DATA/AMENDMENT_PROFILE ='Y' and PO_DATA/SIGNED='T' "> 
			<xsl:value-of select="PO_DATA/AMMENDMENT_MESSAGE"/>
		  </xsl:when>
		  <xsl:otherwise >
			<xsl:value-of select="PO_DATA/COVER_MESSAGE"/> 
		  </xsl:otherwise>
		  </xsl:choose>
		  
		</fo:block> </fo:table-cell>
	</fo:table-row>
</fo:table-body>
</fo:table>

</fo:flow>
</fo:page-sequence>
</xsl:if> 
    

<fo:page-sequence master-reference="details-page">
	
	<!-- Block for displaying footer details -->
	<fo:static-content flow-name="xsl-region-after">
		<fo:block xsl:use-attribute-sets="form_data">  
		<fo:table>
		<fo:table-column column-width="90mm"/> <fo:table-column column-width="90mm"/>
		<fo:table-body>
		<fo:table-row>
			<fo:table-cell>	<fo:block> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PROPRIETARY_INFORMATION'][1]/TEXT"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell5">	<fo:block> 
			<!-- Logic to generate the page numbers: If the PO has Contract Terms then use fo:page-number-citation id as
			     in the contracts terms. Here we hard coded the id as "eod". If the name in contracts stylesheet
			     changes then same has to change here, otherwise the page numbers will not be generated.-->
			     <!-- bug#3836856: Removed the hard coded value and called the template which will take the printing of page numbers. -->
                             <xsl:call-template name="pageNumber"/>

			</fo:block> </fo:table-cell>
		</fo:table-row>
		</fo:table-body>
		</fo:table>
		</fo:block>
	</fo:static-content>

	<!-- Block for displaying header static content with Legal entity name-->
	<fo:static-content flow-name="first-page">
	 <fo:block xsl:use-attribute-sets="form_data">
	 <fo:table>
		<fo:table-column column-width="60mm"/> <fo:table-column column-width="60mm"/> <fo:table-column column-width="60mm"/>
			<fo:table-body>
				<fo:table-row>
					<fo:table-cell ><fo:block>
                                        <!-- Code for displaying the image at top left corner in the first page.
                                             For displaying the company logo, uncomment the fo:inline tag and
                                             specify the image location.
                                        -->
					<!-- <fo:inline>      
                                                <fo:external-graphic content-width="248pt" content-height="33pt" src="url('http://www.oracle.com/admin/header/ora_logo.gif')" />     
                                             </fo:inline> -->
                                        </fo:block> </fo:table-cell>
					<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data">  
						<xsl:if test="$print_draft">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DRAFT'][1]/TEXT"/>
						</xsl:if>
					</fo:block> </fo:table-cell>
					<fo:table-cell xsl:use-attribute-sets="table.cell5">	
						<fo:block xsl:use-attribute-sets="form_data" > 
							<xsl:value-of select="$ROOT_OBJ/STYLE_DISPLAY_NAME"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$ROOT_OBJ/SEGMENT1"/>, <fo:leader leader-pattern="space" leader-length="1.0pt"/>  <xsl:value-of select="$ROOT_OBJ/REVISION_NUM" />
						</fo:block> 
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
	</fo:table>
	</fo:block>
	<fo:block font-size="8pt"> <xsl:value-of select="$header_text"/> </fo:block>
       </fo:static-content>
	
	<fo:static-content flow-name="remaining-page">
	 <fo:block xsl:use-attribute-sets="form_data">
	 <fo:table>
		<fo:table-column column-width="60mm"/> <fo:table-column column-width="60mm"/> <fo:table-column column-width="60mm"/>
			<fo:table-body>
				<fo:table-row>
					<fo:table-cell xsl:use-attribute-sets="table.cell6"><fo:block xsl:use-attribute-sets="form_data3"><xsl:value-of select="$ROOT_OBJ/OU_NAME"/></fo:block> </fo:table-cell>
					<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data">  
						<xsl:if test="$print_draft">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DRAFT'][1]/TEXT"/>
						</xsl:if>
					</fo:block> </fo:table-cell>
					<fo:table-cell xsl:use-attribute-sets="table.cell5">	
						<fo:block xsl:use-attribute-sets="form_data" > 
							<xsl:value-of select="$ROOT_OBJ/STYLE_DISPLAY_NAME"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$ROOT_OBJ/SEGMENT1"/>, <fo:leader leader-pattern="space" leader-length="1.0pt"/>  <xsl:value-of select="$ROOT_OBJ/REVISION_NUM" />
						</fo:block> 
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
	</fo:table>
	</fo:block>
	<fo:block font-size="8pt"> <xsl:value-of select="$header_text"/> </fo:block>
       </fo:static-content>
                      
<fo:flow flow-name="xsl-region-body" >
	<xsl:apply-templates select="PO_DATA"/>
</fo:flow>
</fo:page-sequence>
</fo:root>
</xsl:template>

<xsl:template match="PO_DATA">


<!-- If the Test flag is Y display the boilerplate -->
<xsl:if test="TEST_FLAG ='Y'">
	<fo:block xsl:use-attribute-sets="test_style" > <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TEST'][1]/TEXT"/> </fo:block>
	<fo:block>  <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>
</xsl:if>

<fo:block id="page_ref"/>

<!-- table for displaying the Legal Entity and PA details -->
<fo:table table-layout="fixed" text-align="center">
<fo:table-column column-width="100mm"/> <fo:table-column column-width="80mm"/>
<fo:table-body>
<fo:table-row>
	<fo:table-cell>
		<fo:block xsl:use-attribute-sets="legal_details_style">
			<!-- <xsl:value-of select="LE_NAME"/> <fo:block/>
			<xsl:if test="LE_ADDR1 !='' "> <xsl:value-of select="LE_ADDR1"/> <fo:block/> </xsl:if> 
			<xsl:if test="LE_ADDR2 !='' "> <xsl:value-of select="LE_ADDR2"/> <fo:block/> </xsl:if>
			<xsl:if test="LE_ADDR3 !='' "> <xsl:value-of select="LE_ADDR3"/> <fo:block/> </xsl:if>
			<xsl:if test="LE_TOWN_CITY !=''"> <xsl:value-of select="LE_TOWN_CITY"/>,<fo:leader leader-pattern="space" leader-length="2.0pt"/> </xsl:if> <xsl:value-of select="LE_STAE_PROVINCEY"/><fo:leader leader-pattern="space" leader-length="3.0pt"/><xsl:value-of select="LE_POSTALCODE"/> <fo:block/>
			<xsl:value-of select="LE_COUNTRY"/> -->

			<xsl:value-of select="OU_NAME"/> <fo:block/>
			<xsl:if test="OU_ADDR1 !='' "> <xsl:value-of select="OU_ADDR1"/> <fo:block/> </xsl:if> 
			<xsl:if test="OU_ADDR2 !='' "> <xsl:value-of select="OU_ADDR2"/> <fo:block/> </xsl:if>
			<xsl:if test="OU_ADDR3 !='' "> <xsl:value-of select="OU_ADDR3"/> <fo:block/> </xsl:if>
			<xsl:if test="OU_TOWN_CITY !=''"> <xsl:value-of select="OU_TOWN_CITY"/>,<fo:leader leader-pattern="space" leader-length="2.0pt"/> </xsl:if> <xsl:value-of select="OU_REGION2"/><fo:leader leader-pattern="space" leader-length="3.0pt"/><xsl:value-of select="OU_POSTALCODE"/> <fo:block/>
			<xsl:value-of select="OU_COUNTRY"/>
		</fo:block>
	</fo:table-cell>

	<fo:table-cell>

		<fo:table table-layout="fixed" >
		<fo:table-column column-width="30mm"/> <fo:table-column column-width="50mm"/>
		<fo:table-body>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4"> <fo:block xsl:use-attribute-sets="table_head">
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TYPE'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="STYLE_DISPLAY_NAME"/> </fo:block> </fo:table-cell> 
		</fo:table-row>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4"> <fo:block xsl:use-attribute-sets="table_head"> 
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_ORDER'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell">  <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="SEGMENT1"/> </fo:block> </fo:table-cell> 
		</fo:table-row>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4"> <fo:block xsl:use-attribute-sets="table_head">
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REVISION'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell">  <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="REVISION_NUM"/> </fo:block> </fo:table-cell> 
		</fo:table-row>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4"> <fo:block xsl:use-attribute-sets="table_head">
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_ORDER_DATE'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell">  <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="substring(CREATION_DATE,1,11)"/> </fo:block> </fo:table-cell> 
		</fo:table-row>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4"> <fo:block xsl:use-attribute-sets="table_head"> 
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PREPARER'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell">  <fo:block xsl:use-attribute-sets="form_data"> 
			<xsl:if test="REVISION_NUM &gt; 0">
				<xsl:call-template name="NAME_TEMPLATE">
				<xsl:with-param name="FIRST_NAME" select="ARCHIVE_BUYER_FIRST_NAME"/>
				<xsl:with-param name="LAST_NAME" select="ARCHIVE_BUYER_LAST_NAME"/>
				<xsl:with-param name="TITLE" select="ARCHIVE_BUYER_TITLE"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="REVISION_NUM = 0">
				<xsl:call-template name="NAME_TEMPLATE">
				<xsl:with-param name="FIRST_NAME" select="DOCUMENT_BUYER_FIRST_NAME"/>
				<xsl:with-param name="LAST_NAME" select="DOCUMENT_BUYER_LAST_NAME"/>
				<xsl:with-param name="TITLE" select="DOCUMENT_BUYER_TITLE"/>
				</xsl:call-template>
			</xsl:if>
			</fo:block> </fo:table-cell> 
		</fo:table-row>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4" > <fo:block xsl:use-attribute-sets="table_head"> 
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REVISION_DATE'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell">  <fo:block xsl:use-attribute-sets="form_data"><xsl:value-of select="substring(REVISED_DATE,1,11)"/>  </fo:block> </fo:table-cell> 
		</fo:table-row>
		<fo:table-row>
			<fo:table-cell xsl:use-attribute-sets="table_cell_heading4"> <fo:block xsl:use-attribute-sets="table_head">  
				<xsl:if test="$DisplayBoilerPlate">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REVISED_BY'][1]/TEXT"/>
				</xsl:if>
			</fo:block> </fo:table-cell> 
			<fo:table-cell xsl:use-attribute-sets="table.cell">  <fo:block xsl:use-attribute-sets="form_data">
			<!--Bug16581873--> 
			<!--xsl:if test="REVISION_NUM &gt; 0"-->
				<xsl:call-template name="NAME_TEMPLATE">
				<xsl:with-param name="FIRST_NAME" select="DOCUMENT_BUYER_FIRST_NAME"/>
				<xsl:with-param name="LAST_NAME" select="DOCUMENT_BUYER_LAST_NAME"/>
				<xsl:with-param name="TITLE" select="DOCUMENT_BUYER_TITLE"/>
				</xsl:call-template>
			<!--/xsl:if-->
			</fo:block> </fo:table-cell> 
		</fo:table-row>
		</fo:table-body>
		</fo:table>
	</fo:table-cell>
</fo:table-row>
</fo:table-body>
</fo:table>
<fo:block/>
<!-- Table for displaying Supplier, Ship To and Bill To address -->
<fo:table table-layout="fixed" >
<!-- Bug 14612448 Start: make the column width auto adjusted based on the column size -->
<xsl:choose>
    <xsl:when test="$DisplayBoilerPlate">
        <xsl:variable name="length_of_po_fo_vendor" select="string-length($BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_VENDOR'][1]/TEXT)"/>
        <xsl:variable name="length_of_po_fo_ship_to" select="string-length($BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT)"/>
        <xsl:variable name="length_of_po_fo_bill_to" select="string-length($BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_BILL_TO'][1]/TEXT)"/>
        <!-- To decide which one of three is maximum, we use the maximum -->
        <xsl:variable name="vsb_max_length1">
        <xsl:choose>
            <xsl:when test="$length_of_po_fo_ship_to &gt; $length_of_po_fo_vendor">
            	<xsl:value-of select="$length_of_po_fo_ship_to"/>
            </xsl:when>
            <xsl:otherwise>
            	<xsl:value-of select="$length_of_po_fo_vendor"/>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vsb_max_length2">
        <xsl:choose>
            <xsl:when test="$length_of_po_fo_bill_to &gt; $vsb_max_length1">
            	<xsl:value-of select="$length_of_po_fo_bill_to"/>
            </xsl:when>
            <xsl:otherwise>
            	<xsl:value-of select="$vsb_max_length1"/>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vsb_max_length3">
        <xsl:choose>
                <!-- if longer than 60, just get 60 to keep remaining room for 3rd column -->
        		<xsl:when test="$vsb_max_length2 &gt; 60">
        			<xsl:value-of select="60"/>
        		</xsl:when>
        		<xsl:otherwise>
        			<xsl:value-of select="$vsb_max_length2"/>
        		</xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <!-- 1) Keep 15 as step 2) string-length('Supplier:') as standard length in language US 3) total width of three columns is 177mm -->
        <xsl:variable name="colwidth1" select="format-number(round($vsb_max_length3 * 15 div string-length('Supplier:')),'##0')"/>
        <xsl:variable name="colwidth3" select="160-$colwidth1"/>
        <fo:table-column><xsl:attribute name="column-width"><xsl:value-of select="$colwidth1"/>mm</xsl:attribute></fo:table-column>
        <fo:table-column column-width="2mm"/> 
        <fo:table-column><xsl:attribute name="column-width"><xsl:value-of select="$colwidth3"/>mm</xsl:attribute></fo:table-column>
    </xsl:when>
    <xsl:otherwise>
      <fo:table-column column-width="15mm"/><fo:table-column column-width="2mm"/><fo:table-column column-width="160mm"/>
    </xsl:otherwise>
</xsl:choose>
<!-- Bug 14612448 End -->
<fo:table-body>
<fo:table-row>
	<fo:table-cell xsl:use-attribute-sets="table.cell5"> 
	<fo:block xsl:use-attribute-sets="form_data"> 
		<xsl:if test="$DisplayBoilerPlate ">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_VENDOR'][1]/TEXT"/>
		</xsl:if>
	</fo:block> </fo:table-cell>

	<fo:table-cell> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>

	<fo:table-cell xsl:use-attribute-sets="table.cell2"> <fo:block xsl:use-attribute-sets="form_data">
		<xsl:value-of select="VENDOR_NAME"/>
		<fo:block/><xsl:value-of select="VENDOR_ADDRESS_LINE1"/>
		<xsl:if test="VENDOR_ADDRESS_LINE2 !=''"/> <fo:block/><xsl:value-of select="VENDOR_ADDRESS_LINE2"/>
		<xsl:if test="VENDOR_ADDRESS_LINE3 !=''"/> <fo:block/><xsl:value-of select="VENDOR_ADDRESS_LINE3"/>
		<fo:block/> <xsl:if test="VENDOR_CITY !=''"> <xsl:value-of select="VENDOR_CITY"/>,<fo:leader leader-pattern="space" leader-length="2.0pt"/></xsl:if><xsl:value-of select="VENDOR_STATE"/><fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="VENDOR_POSTAL_CODE"/> 
		<fo:block/> <xsl:value-of select="VENDOR_COUNTRY"/>
	</fo:block>
	</fo:table-cell>
</fo:table-row>

<fo:table-row> <fo:table-cell number-columns-spanned="3"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>

<fo:table-row>
	<fo:table-cell xsl:use-attribute-sets="table.cell5"> 
	<fo:block xsl:use-attribute-sets="form_data">
		<xsl:if test="$DisplayBoilerPlate ">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/>
		</xsl:if>
	</fo:block>
	</fo:table-cell>

	<fo:table-cell> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>

	<fo:table-cell xsl:use-attribute-sets="table.cell2"> <fo:block xsl:use-attribute-sets="form_data">

	<!-- Logic for displaying Ship To address at header level.

		1. If all shipment level ship to are same as each other and different from header ship to then
		replace header ship to with shipment level ship to address.
		2. If any of the shipment level ship to is different from header level ship to then print "Multiple"
		3. If all header ship to and shipment level ship to are same the print address at header level
		ship to.

	-->
		
		<xsl:choose>

		<xsl:when test="$ROOT_OBJ/DIST_SHIPMENT_COUNT = 1">
			
			<xsl:value-of select="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_LINE1[1]"/>
			<xsl:if test="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_LINE2[1] !=''"> <fo:block/><xsl:value-of select="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_LINE2[1]"/> </xsl:if>
			<xsl:if test="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_LINE3[1] !=''"> <fo:block/><xsl:value-of select="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_LINE3[1]"/>  </xsl:if>
			<xsl:if test="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_INFO[1] !=''"> <fo:block/> <xsl:value-of select="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_ADDRESS_INFO"/> </xsl:if>
			<xsl:if test="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_COUNTRY[1] !=''"> <fo:block/>  <xsl:value-of select="$LINE_LOCATIONS_ROOT_OBJ/SHIP_TO_COUNTRY"/>	</xsl:if>

			<!-- Bug 9855114
			Display the message to use address at shipment level if shipment has one time address
			-->
			<xsl:if test="$LINE_LOCATIONS_ROOT_OBJ/IS_SHIPMENT_ONE_TIME_LOC[1] = 'Y'">
			<fo:block />
			<xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS']/TEXT" />
			</xsl:if>
			<!-- Bug 9855114 changes-->
	
		</xsl:when>
		<xsl:when test="normalize-space($print_multiple) = 'Y' ">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_MULTIPLE'][1]/TEXT"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/>
			<xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/> </xsl:if>
			<xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/> </xsl:if>
			<xsl:if test="SHIP_TO_ADDRESS_INFO !=''"> <fo:block/> <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/> </xsl:if>
			<xsl:if test="SHIP_TO_COUNTRY !=''"> <fo:block/>  <xsl:value-of select="SHIP_TO_COUNTRY"/>	</xsl:if>
			
		</xsl:otherwise>
			

		

		</xsl:choose>
	</fo:block>
	</fo:table-cell>
</fo:table-row>

<fo:table-row> <fo:table-cell number-columns-spanned="3"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>

<fo:table-row>
	<fo:table-cell xsl:use-attribute-sets="table.cell5"> 
	<fo:block xsl:use-attribute-sets="form_data">
	<xsl:if test="$DisplayBoilerPlate ">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_BILL_TO'][1]/TEXT"/>
	</xsl:if>
	</fo:block> </fo:table-cell>

	<fo:table-cell> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>

	<fo:table-cell xsl:use-attribute-sets="table.cell2"> <fo:block xsl:use-attribute-sets="form_data">
		<!--<xsl:value-of select="BILL_TO_LOCATION_NAME"/> -->
		<xsl:value-of select="BILL_TO_ADDRESS_LINE1"/>
		<xsl:if test="BILL_TO_ADDRESS_LINE2 !=''"> <fo:block/><xsl:value-of select="BILL_TO_ADDRESS_LINE2"/> </xsl:if>
		<xsl:if test="BILL_TO_ADDRESS_LINE3 !=''"> <fo:block/><xsl:value-of select="BILL_TO_ADDRESS_LINE3"/> </xsl:if>
		<xsl:if test="BILL_TO_ADDRESS_INFO !=''">  <fo:block/> <xsl:value-of select="BILL_TO_ADDRESS_INFO"/> </xsl:if>
		<xsl:if test="BILL_TO_COUNTRY !=''">  <fo:block/> <xsl:value-of select="BILL_TO_COUNTRY"/> </xsl:if>
	</fo:block>
	</fo:table-cell>
</fo:table-row>

<fo:table-row> <fo:table-cell number-columns-spanned="3"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>

</fo:table-body>
</fo:table>



<fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>

<fo:table table-layout="fixed" >
<fo:table-column column-width="30mm"/>
<fo:table-column column-width="20mm"/>
<fo:table-column column-width="30mm"/>
<fo:table-column column-width="20mm"/>
<fo:table-column column-width="25mm"/>
<fo:table-column column-width="40mm"/>
<fo:table-column column-width="15mm"/>
<fo:table-body>
<fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CUSTOMER_ACCOUNT_NO'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>
    
    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_VENDOR_NO'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PAYMENT_TERMS'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>
    
    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_FREIGHT_TERMS'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_FOB'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TRANSPORTATION_ARRANGED'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_SHIP_VIA'][1]/TEXT"/>
	</xsl:if>
    </fo:block>
    </fo:table-cell>

  </fo:table-row>

<fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="CUSTOMER_NUM"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="VENDOR_NUM"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="PAYMENT_TERMS"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="FREIGHT_TERMS"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="FOB"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="SHIPPING_CONTROL"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="SHIP_VIA"/> </fo:block> </fo:table-cell>
  </fo:table-row>

</fo:table-body>
</fo:table>


<!-- Table for displaying Confirm To/Telephone and Deliver To/Requestor -->
<fo:table table-layout="fixed" >
<fo:table-column column-width="90mm"/>
<fo:table-column column-width="90mm"/>
<fo:table-body>

  <fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_CONFIRM_TO_TELE'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_REQUESTER_DELIVER'][1]/TEXT"/>
	</xsl:if>
        </fo:block>
     </fo:table-cell>
  </fo:table-row>

  <fo:table-row>
     <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> 
	
	<xsl:call-template name="NAME_TEMPLATE">
		<xsl:with-param name="FIRST_NAME" select="VENDOR_CONTACT_FIRST_NAME"/>
		<xsl:with-param name="LAST_NAME" select="VENDOR_CONTACT_LAST_NAME"/>
		<xsl:with-param name="TITLE" select="VENDOR_CONTACT_TITLE"/>
	</xsl:call-template>
	<!-- Bug# 5512086 - Enclosing area code in brackets and inserting space between area code and phone number--> 
	<fo:leader leader-pattern="space" leader-length="3.0pt"/>
		(<xsl:value-of select="VENDOR_CONTACT_AREA_CODE"/>) <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="VENDOR_CONTACT_PHONE"/>
        </fo:block>
   </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table.cell">   
	<fo:block xsl:use-attribute-sets="form_data"> 

	   <!-- Logic for displaying Requestor/Deliver To
		1. If multiple shipments display blank
		2. If multiple shipments and if all the requesters are same display the name 
		3. If the PO has single requestor, then display the user -->

	    <xsl:if test="count($DISTRIBUTIONS_ROOT_OBJ/DELIVER_TO_PERSON_ID[generate-id()=generate-id(key('distinct-person_id',.))] ) = 1">
            <xsl:if test="count($DISTRIBUTIONS_ROOT_OBJ/LOCATION_CODE[generate-id()=generate-id(key('distinct-location_code',.))] ) = 1">
		<xsl:call-template name="NAME_TEMPLATE">
			<xsl:with-param name="FIRST_NAME" select="$DISTRIBUTIONS_ROOT_OBJ/REQUESTER_DELIVER_FIRST_NAME[1]"/>
			<xsl:with-param name="LAST_NAME" select="$DISTRIBUTIONS_ROOT_OBJ/REQUESTER_DELIVER_LAST_NAME[1]"/>
                        <xsl:with-param name="LOCATION_CODE" select="$DISTRIBUTIONS_ROOT_OBJ/LOCATION_CODE"/>
			<xsl:with-param name="TITLE" select="$DISTRIBUTIONS_ROOT_OBJ/REQUESTER_DELIVER_TITLE[1]"/>
		</xsl:call-template>
            </xsl:if>
	    </xsl:if>
	</fo:block>
    </fo:table-cell>

  </fo:table-row>
</fo:table-body>
</fo:table>

<fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>

<fo:table table-layout="fixed" >
<!-- Bug 14612448 Start: make the column width auto adjusted based on the column size -->
<xsl:choose>
    <xsl:when test="$DisplayBoilerPlate">
        <xsl:variable name="length_of_po_fo_notes" select="string-length($BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_NOTES'][1]/TEXT)"/>
        <xsl:variable name="notes_max_length">
            <xsl:choose>
                <!-- if longer than 40, just get 40 to keep remaining room for 3rd column -->
                <xsl:when test="$length_of_po_fo_notes &gt; 40">
                	<xsl:value-of select="40"/>
                </xsl:when>
                <xsl:otherwise>
                	<xsl:value-of select="$length_of_po_fo_notes"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- 1) Keep 8 as step and 7 as margin 2) string-length('Notes:') as standard length in language US 3) total width of three columns is 175mm -->
        <xsl:variable name="notes_colwidth2" select="format-number(round($notes_max_length * 8 div string-length('Notes:')) + 7,'##0')"/>
        <xsl:variable name="notes_colwidth3" select="150-$notes_colwidth2"/>
        <fo:table-column column-width="10mm"/>
        <fo:table-column><xsl:attribute name="column-width"><xsl:value-of select="$notes_colwidth2"/>mm</xsl:attribute></fo:table-column>
        <fo:table-column><xsl:attribute name="column-width"><xsl:value-of select="$notes_colwidth3"/>mm</xsl:attribute></fo:table-column>
    </xsl:when>
    <xsl:otherwise>
    	<fo:table-column column-width="10mm"/><fo:table-column column-width="15mm"/><fo:table-column column-width="150mm"/>
    </xsl:otherwise>
</xsl:choose>
<!-- Bug 14612448 End --> 
<fo:table-body>
<fo:table-row>
	
	<fo:table-cell > <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/>  </fo:block>	</fo:table-cell>
	<fo:table-cell xsl:use-attribute-sets="table.cell2"> <fo:block xsl:use-attribute-sets="coverpage.label"> 
		<xsl:if test="$DisplayBoilerPlate">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_NOTES'][1]/TEXT"/>
		</xsl:if>
	</fo:block>
	</fo:table-cell>
	
	<fo:table-cell > <fo:block xsl:use-attribute-sets="form_data">  

	<!-- Time zone text -->
	<fo:block> <xsl:value-of select="TIMEZONE"/> </fo:block>

	<!-- Header note to supplier -->
	<fo:block> <xsl:value-of select="NOTE_TO_VENDOR"/>  </fo:block>	

        <!-- Header short Text -->
	<xsl:for-each select="HEADER_SHORT_TEXT/HEADER_SHORT_TEXT_ROW">
	<fo:block> <xsl:value-of select="SHORT_TEXT"/> </fo:block>
	</xsl:for-each>

	<!-- Header long text -->
	<xsl:for-each select="HEADER_ATTACHMENTS/LONG_TEXT">
	<fo:block> <xsl:value-of select="."/> </fo:block>
	</xsl:for-each>

        <!-- PO Attachments support 11i.11: start-->
        <!--Table for displaying the header Web and File attachments -->
        <xsl:if test="count(HEADER_URL_ATTACHMENTS/HEADER_URL_ATTACHMENTS_ROW/WEB_PAGE) &gt; 0 or count(HEADER_FILE_ATTACHMENTS/HEADER_FILE_ATTACHMENTS_ROW) &gt; 0">
        <fo:table table-layout="fixed" >
                <fo:table-column column-width="35mm"/>
                <fo:table-column column-width="100mm"/>
                <fo:table-body>
                <fo:table-row> <fo:table-cell>  
                        <fo:block> 
                        <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/>
                        </xsl:if>
                </fo:block> </fo:table-cell>
                
                <fo:table-cell>  
                <fo:block xsl:use-attribute-sets="form_data"> 

                
                <!-- Header URL Attachments -->
                <xsl:for-each select="HEADER_URL_ATTACHMENTS/HEADER_URL_ATTACHMENTS_ROW">
                <fo:block> 
                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                  <xsl:attribute name="external-destination">
                        <xsl:call-template name="webUrl">
                                <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                        </xsl:call-template>
                  </xsl:attribute> 
                  <xsl:value-of select="WEB_PAGE"/>
                </fo:basic-link></fo:block>
                </xsl:for-each>

                <!-- Header FILE Attachments -->
                <xsl:for-each select="HEADER_FILE_ATTACHMENTS/HEADER_FILE_ATTACHMENTS_ROW">
                <fo:block> <xsl:value-of select="FILE_NAME"/> </fo:block>
                </xsl:for-each>
                </fo:block> </fo:table-cell>
                </fo:table-row>
                </fo:table-body>
        </fo:table>
        </xsl:if>
        <!-- PO Attachments support 11i.11: end-->

	<!-- PA cancelled text -->
	<xsl:if test="CANCEL_FLAG='Y' ">
		<fo:block> 
			<fo:table>
			<fo:table-column column-width="80mm"/>
			<fo:table-body><fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell7"> <fo:block xsl:use-attribute-sets="form_data2"> 
				<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PO_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="1.0pt"/>  <xsl:value-of select="CANCEL_DATE"/> 
			</fo:block> </fo:table-cell> 
			</fo:table-row></fo:table-body>
			</fo:table>
		</fo:block> 
	</xsl:if>


	<fo:block>
		<xsl:if test="CONFIRMING_ORDER_FLAG='Y'">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CONFIRM_NOT_DUPLICATE'][1]/TEXT"/>
		</xsl:if> 
	</fo:block> 

	<fo:block><xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PRICES_EXPRESSED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="CURRENCY_CODE"/> </fo:block> 
	
	<xsl:if test="ACCEPTANCE_DUE_DATE !=''">
		<fo:block><xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_FORMAL_ACCEPT'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="substring(ACCEPTANCE_DUE_DATE,1,11)"/> </fo:block> 
	</xsl:if>

	</fo:block>
	</fo:table-cell>
</fo:table-row>


</fo:table-body>
</fo:table>

<fo:block><fo:leader leader-pattern="space" leader-length="1pt"/>  </fo:block>

<!-- Table for displaying the line, shipment and distribution data -->

<xsl:if test="count(LINES/LINES_ROW/LINE_NUM) > 0">

<fo:table xsl:use-attribute-sets="lines.table.style">
<fo:table-column column-width="12.5mm"/> 
<fo:table-column column-width="44.5mm"/>
<fo:table-column column-width="40mm"/> 
<fo:table-column column-width="17.5mm"/> 
<fo:table-column column-width="15mm"/> 
<fo:table-column column-width="17.5mm"/>
<fo:table-column column-width="10.5mm"/>
<fo:table-column column-width="22.5mm"/> 
<fo:table-header>

<fo:table-row >
<fo:table-cell  xsl:use-attribute-sets="table_cell_heading2" ><fo:block xsl:use-attribute-sets="table_head1">
	<xsl:if test="$DisplayBoilerPlate ">
    <xsl:choose>
      <xsl:when test="$IS_COMPLEX_WORK_PO">
        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_LINE_PAYITEM_NUM'][1]/TEXT"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_LINE_NUMBER'][1]/TEXT"/>
      </xsl:otherwise>
    </xsl:choose>
	</xsl:if>
</fo:block></fo:table-cell>

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading2" ><fo:block xsl:use-attribute-sets="table_head1">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PART_NO_DESC'][1]/TEXT"/>
	</xsl:if>
</fo:block></fo:table-cell>

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading2" ><fo:block xsl:use-attribute-sets="table_head1">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_DATE_TIME'][1]/TEXT"/> 
      </xsl:if>
</fo:block></fo:table-cell>	

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading1" ><fo:block xsl:use-attribute-sets="table_head">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_QUANTITY'][1]/TEXT"/>
	</xsl:if>
</fo:block></fo:table-cell>

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading2" ><fo:block xsl:use-attribute-sets="table_head1">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_UOM'][1]/TEXT"/>
	</xsl:if>
</fo:block></fo:table-cell>

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading1" ><fo:block xsl:use-attribute-sets="table_head">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_UNIT_PRICE'][1]/TEXT"/> 
	</xsl:if>
	<fo:block/>(<xsl:value-of select="$ROOT_OBJ/CURRENCY_CODE"/>)
</fo:block></fo:table-cell>

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading2" ><fo:block xsl:use-attribute-sets="table_head1">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_TAX'][1]/TEXT"/>
	</xsl:if>
</fo:block></fo:table-cell>

<fo:table-cell  xsl:use-attribute-sets="table_cell_heading1" ><fo:block xsl:use-attribute-sets="table_head">
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_AMOUNT'][1]/TEXT"/> 
	</xsl:if>
	<fo:block/> (<xsl:value-of select="$ROOT_OBJ/CURRENCY_CODE"/>)
</fo:block></fo:table-cell>

</fo:table-row>

<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
</fo:table-header>
<!--  end of header part -->


<!-- start of displaying line, shipment and distribution details -->
<fo:table-body>
<xsl:for-each select="$LINES_ROOT_OBJ">

	<xsl:variable name="lineID" select="PO_LINE_ID"/>

	<xsl:variable name="shipment_count" select="count(LINE_LOCATIONS/LINE_LOCATIONS_ROW/SHIP_TO_LOCATION_ID)"/>

	<xsl:variable name="distribution_count" select="count(LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT)"/>

	<!-- Variable for to display charge account or not -->
	<xsl:variable name="charge_account" select="$PSA='Y'"/>

	<!-- Variable to find UN number is null or not -->
	<xsl:variable name="un_num" select="UN_NUMBER !=''"/>

	<!-- Variable to find hazard class is null or not -->
	<xsl:variable name="hz_class" select="HAZARD_CLASS !=''"/>

	<!-- Variable to find NOTE_TO_VENDOR is null or not -->
	<xsl:variable name="vendor_note" select="NOTE_TO_VENDOR !=''"/>

	<!-- Variable to find GLOBAL_AGREEMENT_FLAG  is null or not -->
	<xsl:variable name="ga_flag" select="GLOBAL_AGREEMENT_FLAG !=''"/>

	<!-- Variable to find CONTRACT_NUM  is null or not -->
	<xsl:variable name="con_num" select="CONTRACT_NUM !=''"/>
	
	<!-- Variable to find CONTRACT_NUM  is null or not -->
	<xsl:variable name="sup_quote_num" select="QUOTE_VENDOR_QUOTE_NUMBER !=''"/>

	<!-- Variable to find short attachments  are null or not -->
	<xsl:variable name="short_attachments" select="LINE_SHORT_TEXT/LINE_SHORT_TEXT_ROW/SHORT_TEXT !=''"/>

	<!-- Bug 5230892 Variable to find long attachments are null or not  -->
	<xsl:variable name="long_attachments" select="$LINE_LONG_ATTACHMENTS_ROOT_OBJ !=''"/>

        <!-- Variable to find File attachments  are null or not -->
	<xsl:variable name="file_attachments" select="LINE_FILE_ATTACHMENTS/LINE_FILE_ATTACHMENTS_ROW/FILE_NAME !=''"/>

        <!-- Variable to find URL attachments  are null or not -->
	<xsl:variable name="url_attachments" select="LINE_URL_ATTACHMENTS/LINE_URL_ATTACHMENTS_ROW/WEB_PAGE !=''"/>

  <!-- Variables to find out how many delivery shipments and distributions exist.
       This will deterine if we are dealing with a financing line for complex work POs -->
  <xsl:variable name="line_delivery_count" select="count(LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_LOCATION_ID)"/>
  <xsl:variable name="line_delivery_distribution_count" select="count(LINE_DELIVERY/LINE_DELIVERY_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT)"/>
		
	
	<xsl:if test = "LINE_TYPE = 'QUANTITY' and PURCHASE_BASIS = 'GOODS'">
		
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data3"> <xsl:value-of select="LINE_NUM"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
				<xsl:value-of select="ITEM_NUM"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/>  <xsl:value-of select="ITEM_REVISION"/> <fo:block/>

				<!-- Supplier Item number -->
				<xsl:if test="VENDOR_PRODUCT_NUM !=''">
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUPPLIER_ITEM'][1]/TEXT"/>
					</xsl:if> 
				<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="VENDOR_PRODUCT_NUM"/> <fo:block/> </xsl:if>

				<!-- display Configuration ID is it is not null -->
				<xsl:if test="SUPPLIER_REF_NUMBER !='' ">
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUPPLIER_CONFIGURATION'][1]/TEXT"/>
					</xsl:if>
					 <fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="SUPPLIER_REF_NUMBER"/> <fo:block/> 
				</xsl:if>
				
			</fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
        <xsl:choose>
          <xsl:when test="$line_delivery_count = 1">
            <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/PROMISED_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/PROMISED_DATE"/>
            </xsl:if>
            <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/NEED_BY_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/NEED_BY_DATE"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$shipment_count = 1">
            <xsl:if test="LINE_LOCATIONS/LINE_LOCATIONS_ROW/PROMISED_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/PROMISED_DATE"/>
            </xsl:if>
            <xsl:if test="LINE_LOCATIONS/LINE_LOCATIONS_ROW/NEED_BY_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/NEED_BY_DATE"/>
            </xsl:if>
          </xsl:when>
        </xsl:choose>

			</fo:block> </fo:table-cell>
			
			<fo:table-cell xsl:use-attribute-sets="table.cell5"> <fo:block xsl:use-attribute-sets="form_data1">
				<!-- BEGIN INVCONV -->
			        <!-- Added foblock in quantity line and added secondary quantity line -->
				<fo:block/> <xsl:value-of  select="QUANTITY"/>
				<fo:block/> <xsl:value-of  select="SECONDARY_QUANTITY"/>
				<!-- END INVCONV -->
			</fo:block> </fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
				<!-- BEGIN INVCONV -->
			        <!-- Added foblock in unit_meas_lookup_code line and added secondary uom line -->
				<fo:block/> <xsl:value-of  select="UNIT_MEAS_LOOKUP_CODE"/>
				<fo:block/> <xsl:value-of  select="SECONDARY_UNIT_OF_MEASURE"/>
				<!-- END INVCONV -->
			</fo:block> </fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell5">
				<fo:block xsl:use-attribute-sets="form_data1">
					<xsl:value-of  select="UNIT_PRICE"/>
				</fo:block>
			</fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
        <xsl:choose>
          <xsl:when test="$line_delivery_count = 1">
            <xsl:value-of  select="LINE_DELIVERY/LINE_DELIVERY_ROW/TAXABLE_FLAG"/>
          </xsl:when>
          <xsl:when test="$shipment_count = 1">
            <xsl:value-of  select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/TAXABLE_FLAG"/>
		  	   </xsl:when>
        </xsl:choose>
			</fo:block> </fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell5"> <fo:block xsl:use-attribute-sets="form_data1">
				<xsl:value-of  select="LINE_AMOUNT"/>
			</fo:block> </fo:table-cell>

		</fo:table-row>
		<!-- Bug3670603: Item description should display in the same row if it spans more than one column. -->
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> <fo:block xsl:use-attribute-sets="form_data">
				<xsl:value-of select="ITEM_DESCRIPTION"/>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<!-- end of Bug3670603 -->	

<!-- Enhanced Pricing Start -->
<xsl:variable name="modifier_count" select="count(PRICE_MODIFIERS/PRICE_MODIFIERS_ROW)"/>
<xsl:if test="$modifier_count &gt; 0">
<fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>

<fo:table>
<fo:table-column column-width="30mm"/>
<fo:table-column column-width="40mm"/>
<fo:table-column column-width="20mm"/>
<fo:table-column column-width="30mm"/>
<fo:table-column column-width="30mm"/>
<fo:table-body>
<fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1">  
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MODIFIER_TYPE'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>
     <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1">  
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MODIFIER_DESC'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RATE'][1]/TEXT"/>
	</xsl:if>
        </fo:block>
     </fo:table-cell>
	  <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1">  
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RATE_APP_METHOD'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>
  </fo:table-row>
  <xsl:variable name="price_modifier_count" select="count(PRICE_MODIFIERS/PRICE_MODIFIERS_ROW)" />
  
<xsl:for-each select="PRICE_MODIFIERS/PRICE_MODIFIERS_ROW">
  <!--xsl:if test="$price_modifier_count &gt; 0"-->
<fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="MODIFIER_LINE_TYPE"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="MODIFIER_DESC"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell3"> <fo:block xsl:use-attribute-sets="form_data1"> <xsl:value-of select="OPERAND"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="ARITHMETIC_OPERATOR"/> </fo:block> </fo:table-cell>
 </fo:table-row>
  <xsl:variable name="price_modifier_count" select="$price_modifier_count - 1" />
  	<!--/xsl:if-->
</xsl:for-each>
</fo:table-body>

</fo:table>
<fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>
</xsl:if>

<xsl:variable name="add_modifier_count" select="count(ADD_PRICE_MODIFIERS/ADD_PRICE_MODIFIERS_ROW)"/>
<xsl:if test="$add_modifier_count &gt; 0">
<fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>
<fo:table>
<xsl:for-each select="ADD_PRICE_PONUM/ADD_PRICE_PONUM_ROW">
	<fo:table-cell xsl:use-attribute-sets="table.cell2"> <fo:block xsl:use-attribute-sets="coverpage.label"> 
		<xsl:if test="$DisplayBoilerPlate">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_BLANKET'][1]/TEXT"/>
			<fo:leader leader-pattern="space" leader-length="1.0pt"/>
			<xsl:value-of select="PONUM"/>
			<fo:leader leader-pattern="space" leader-length="1.0pt"/>
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_BLANKET_PRICE_STRUCT'][1]/TEXT"/>
		</xsl:if>
	</fo:block>
	</fo:table-cell>
	</xsl:for-each>
</fo:table>
<fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>
<fo:table>
<fo:table-column column-width="30mm"/>
<fo:table-column column-width="40mm"/>
<fo:table-column column-width="20mm"/>
<fo:table-column column-width="30mm"/>
<fo:table-column column-width="30mm"/>
<fo:table-body>
<fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1">  
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MODIFIER_TYPE'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>
     <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1">  
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MODIFIER_DESC'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>

    <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1"> 
	<xsl:if test="$DisplayBoilerPlate ">
		<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RATE'][1]/TEXT"/>
	</xsl:if>
        </fo:block>
     </fo:table-cell>
	  <fo:table-cell xsl:use-attribute-sets="table_cell_heading2"> <fo:block xsl:use-attribute-sets="table_head1">  
    <xsl:if test="$DisplayBoilerPlate ">
	<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RATE_APP_METHOD'][1]/TEXT"/>
    </xsl:if>
   </fo:block>
   </fo:table-cell>
  </fo:table-row>
  <xsl:variable name="price_modifier_count" select="count(ADD_PRICE_MODIFIERS/ADD_PRICE_MODIFIERS_ROW)" />
  
  
<xsl:for-each select="ADD_PRICE_MODIFIERS/ADD_PRICE_MODIFIERS_ROW">
  <!--xsl:if test="$price_modifier_count &gt; 0"-->
<fo:table-row>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="MODIFIER_LINE_TYPE"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="MODIFIER_DESC"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell3"> <fo:block xsl:use-attribute-sets="form_data1"> <xsl:value-of select="OPERAND"/> </fo:block> </fo:table-cell>
    <fo:table-cell xsl:use-attribute-sets="table.cell"> <fo:block xsl:use-attribute-sets="form_data"> <xsl:value-of select="ARITHMETIC_OPERATOR"/> </fo:block> </fo:table-cell>
 </fo:table-row>
  <xsl:variable name="price_modifier_count" select="$price_modifier_count - 1" />
  	<!--/xsl:if-->
</xsl:for-each>
</fo:table-body>
</fo:table>
</xsl:if>
<!-- Enhanced Pricing End -->

        <!-- PO Attachments support 11i.11: Added the condition to check whether file or web attachments are not null -->
		<!-- Bug 5230892 Added the condition to check whether long attachments are null or not -->                 
		<xsl:if test="$PSA or $un_num or $hz_class or $vendor_note or $ga_flag or $con_num or $sup_quote_num or $short_attachments or $long_attachments or $file_attachments or $url_attachments or $IS_COMPLEX_WORK_PO">
		<fo:table-row> <fo:table-cell number-columns-spanned="7"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>
		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6"> 
			<fo:block xsl:use-attribute-sets="form_data">

				<!-- to display the charge Account -->
				<xsl:if test="$charge_account">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CHARGE_ACCOUNT'][1]/TEXT"/>
					</xsl:if>
					<xsl:choose>
					<xsl:when test="$distribution_count =1">
					        <!-- bug# 6074720:  given the complete path (instead of $distributions_root_obj/charge_account), to select correct charge account for each distribution -->
						<xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT"/> <fo:block/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_MULTIPLE'][1]/TEXT"/> <fo:block/>
					</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- end of charge account -->
				
				<!-- Un number row -->
				<xsl:if test="$un_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_UN_NUMBER'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="UN_NUMBER"/> <fo:block/>
				</xsl:if>
				<!-- end of Un number row -->

				<!-- Hazard class -->
				<xsl:if test="$hz_class">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_HAZARD_CLASS'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="HAZARD_CLASS"/> <fo:block/>
				</xsl:if>
				<!-- end of Hazard class -->

        <!-- Complex Work Line Info -->
        <xsl:if test="$IS_COMPLEX_WORK_PO">
          <xsl:if test="ADVANCE_AMOUNT!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ADVANCE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="ADVANCE_AMOUNT"/> 
          </xsl:if>
          <xsl:if test="RECOUPMENT_RATE!=''">                    
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RECOUPMENT_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="RECOUPMENT_RATE"/> 
          </xsl:if>
          <xsl:if test="PROGRESS_PAYMENT_RATE!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PROGRESS_PAYMENT_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="PROGRESS_PAYMENT_RATE"/> 
          </xsl:if>
          <!--Bug 5278399 - Added Max Retainage Amount -->
          <xsl:if test="MAX_RETAINAGE_AMOUNT!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MAX_RETAINAGE_AMOUNT'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="MAX_RETAINAGE_AMOUNT"/> 
          </xsl:if>
          <xsl:if test="RETAINAGE_RATE!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RETAINAGE_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="RETAINAGE_RATE"/> 
          </xsl:if>
          <fo:block/>
        </xsl:if>
        <!-- end of Complex Work Line Info -->


				<!-- Vendor Notes -->
				<xsl:if test="$vendor_note">
					<xsl:value-of select="NOTE_TO_VENDOR"/> <fo:block/>
				</xsl:if>
				<!-- end of note to vendor -->

				<!-- for lines short text -->
				<xsl:for-each select="LINE_SHORT_TEXT/LINE_SHORT_TEXT_ROW">	
					<xsl:value-of select ="SHORT_TEXT"/> <fo:block/>
				</xsl:for-each>

				<!-- for long text -->
				<xsl:for-each select="$LINE_LONG_ATTACHMENTS_ROOT_OBJ">
					<xsl:if test="$lineID = .">
						<xsl:variable name="line" select="position()" />
						<xsl:value-of select="../TEXT[$line]"/>	<fo:block/> 	
					</xsl:if>
				</xsl:for-each>
                                
                                <!-- PO Attachments support 11i.11: start-->
                                <!-- Table for displaying the line Web and File attachments -->
                                <xsl:if test="$file_attachments or $url_attachments">
                                <fo:table table-layout="fixed" >
                                        <fo:table-column column-width="35mm"/>
                                        <fo:table-column column-width="100mm"/>
                                        <fo:table-body>
                                        <fo:table-row> <fo:table-cell>  
                                                <fo:block> 
                                                <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                        <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                                </xsl:if>
                                        </fo:block> </fo:table-cell>
                                        
                                        <fo:table-cell>  
                                                <fo:block> 

                                                <!-- for lines URL attachments -->
                                                <xsl:for-each select="LINE_URL_ATTACHMENTS/LINE_URL_ATTACHMENTS_ROW">	
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                                </xsl:for-each>

                                                <!-- for lines FILE attachments -->
                                                <xsl:for-each select="LINE_FILE_ATTACHMENTS/LINE_FILE_ATTACHMENTS_ROW">	
                                                        <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                                </xsl:for-each>
                                                </fo:block> </fo:table-cell>
		                        </fo:table-row> </fo:table-body> 
                                </fo:table>
                                </xsl:if>
                                <!-- PO Attachments support 11i.11: end-->

				<!-- Global agreement value -->
				<xsl:if test="$ga_flag">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_BPA'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="SEGMENT1"/> <fo:block/>
				</xsl:if>
				<!-- end of global agreement flag -->

				<!-- Contract agreement  -->
				<xsl:if test="$con_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_CONTRACT'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="CONTRACT_NUM"/> <fo:block/>
				</xsl:if>
				<!-- end of contract num -->

				<!-- Supplier quotation number-->
				<xsl:if test="$sup_quote_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_SUPPLIER_QUOTATION'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="QUOTE_VENDOR_QUOTE_NUMBER"/> <fo:block/>
				</xsl:if>
				<!-- end of Supplier quotation number -->
			 				
			</fo:block> 
			</fo:table-cell>
		</fo:table-row>
		</xsl:if>


  <!-- Print line delivery details (for complex work financing case) -->
  <xsl:if test="$line_delivery_count = 1">
    <fo:table-row>
       <fo:table-cell >
         <fo:block >
           <fo:leader leader-pattern="space" leader-length="1.0pt"/>
         </fo:block>
       </fo:table-cell>
       <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">
         <fo:block xsl:use-attribute-sets="form_data">
           <xsl:if test="$DisplayBoilerPlate ">
             <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> 
             <fo:block/>
           </xsl:if>
           <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE1"/>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE2 !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE2"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE3 !=''"> 
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE3"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_INFO !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_INFO"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_COUNTRY !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_COUNTRY"/>
           </xsl:if>
         </fo:block>
       </fo:table-cell>
    </fo:table-row>
  </xsl:if>

  <!-- Print line delivery distribution information (for complex work financing case) -->
  <xsl:if test="$line_delivery_distribution_count &gt; 0">
    <xsl:for-each select="LINE_DELIVERY/LINE_DELIVERY_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW">
      <xsl:if test="REQUESTER_DELIVER_FIRST_NAME !='' ">
        <fo:table-row>
          <fo:table-cell > <fo:block /> </fo:table-cell>
           <fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">
             <fo:block xsl:use-attribute-sets="form_data"> 
               <xsl:if test="DELIVER_TO_PERSON_ID !=''">				
                 <xsl:if test="$DisplayBoilerPlate ">
                   <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
                 </xsl:if> 
                 <xsl:call-template name="NAME_TEMPLATE">
                   <xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
                   <xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
                   <xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
                 </xsl:call-template>
                 <xsl:if test="QUANTITY_ORDERED !=''"> 
                   <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                   (<xsl:value-of select="QUANTITY_ORDERED"/>)
                 </xsl:if>
                 <xsl:if test="AMOUNT_ORDERED !=''"> 
                   <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                   (<xsl:value-of select="AMOUNT_ORDERED"/>)
                 </xsl:if>
						     <fo:block/>
                 <xsl:value-of select="EMAIL_ADDRESS"/>
                 <fo:block/>
               </xsl:if>
             </fo:block>
           </fo:table-cell>
        </fo:table-row>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>



		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block >  </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="70mm"/>
				<fo:table-body> <fo:table-row> <fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
                                <!-- Bug 5464925 START-->
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_QTY_ORDERED'][1]/TEXT"/>
                                <fo:leader leader-pattern="space" leader-length="2.0pt"/>
                                <xsl:variable name="line_locations_quantity_sum" select="sum(LINE_LOCATIONS/LINE_LOCATIONS_ROW/QUANTITY)" />
                                <xsl:variable name="line_locations_count" select="count(LINE_LOCATIONS/LINE_LOCATIONS_ROW)" />
                                <xsl:choose>
                                        <xsl:when test="$IS_COMPLEX_WORK_PO"><xsl:value-of select="$line_locations_quantity_sum div $line_locations_count"/></xsl:when>
                                        <xsl:otherwise><xsl:value-of select="$line_locations_quantity_sum"/></xsl:otherwise>
                                </xsl:choose>
                                <fo:block/>
				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_QUANTITY_CANCELED'][1]/TEXT"/><fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                                <xsl:choose>
                                        <xsl:when test="$IS_COMPLEX_WORK_PO"><xsl:value-of select="$line_locations_quantity_sum div $line_locations_count"/></xsl:when>
                                        <xsl:otherwise><xsl:value-of select="sum(LINE_LOCATIONS/LINE_LOCATIONS_ROW/QUANTITY_CANCELLED)"/></xsl:otherwise>
                                </xsl:choose>                                
                                <fo:block/>
                                <!-- Bug 5464925 END-->
				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<!-- start of shipment details -->
                <xsl:if test="$shipment_count &gt; 0"> <!-- bug#3823799:condition to check whether there are any shipments -->
		<xsl:for-each select="LINE_LOCATIONS/LINE_LOCATIONS_ROW">

      <xsl:variable name="use_line_ship_to" select="SHIPMENT_TYPE='PREPAYMENT' and ../../LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_LOCATION_ID=SHIP_TO_LOCATION_ID" />

		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block font-size="8pt"> <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row> 
		<fo:table-row  >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> 
        <fo:block xsl:use-attribute-sets="form_data3">
             <!-- bug#13359008 : Removed condition to display shipment num only in case of complex PO. -->
            <xsl:value-of select="../../LINE_NUM"/>-<xsl:value-of select="SHIPMENT_NUM"/>
        </fo:block> 
      </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data">
        <xsl:choose>
          <xsl:when test="$IS_COMPLEX_WORK_PO">
            <xsl:value-of select="DESCRIPTION"/>
           </xsl:when>
           <xsl:otherwise>
             <fo:table>
               <fo:table-column column-width="3.5mm"/> <fo:table-column column-width="34.5mm"/>
        			 <fo:table-body>
               <fo:table-row >
                 <fo:table-cell > <fo:block>  </fo:block> </fo:table-cell>
                 <fo:table-cell > <fo:block>  
                   <xsl:if test="$DisplayBoilerPlate ">
             		     <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> <fo:block/>
              	   </xsl:if>
                   <!-- bug#3594831: added drop_ship ship to details -->
                   <!-- Bug3670603: Address details should be displayed before Promised and Need by date -->
                   <xsl:if test="DROP_SHIP_FLAG='Y'">
              				<xsl:if test="SHIP_CUST_NAME !=''"> <xsl:value-of select="SHIP_CUST_NAME"/>  </xsl:if>
              				<xsl:if test="SHIP_CONT_NAME !=''"> <fo:block/> <xsl:value-of select="SHIP_CONT_NAME"/>  </xsl:if>
               				<xsl:if test="SHIP_CONT_EMAIL !=''"> <fo:block/><xsl:value-of select="SHIP_CONT_EMAIL"/> </xsl:if>
               				<xsl:if test="SHIP_CONT_PHONE !=''">
              					<xsl:if test="$DisplayBoilerPlate ">
            						 <fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TELEPHONE'][1]/TEXT"/>:
              					</xsl:if>
              					<fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="SHIP_CONT_PHONE"/> 
              				</xsl:if>
              				<xsl:if test="SHIP_TO_CONTACT_FAX !=''"> 
              					<xsl:if test="$DisplayBoilerPlate ">
          	   					 <fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_FAX'][1]/TEXT"/>:
              					</xsl:if>
              					 <fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="SHIP_TO_CONTACT_FAX"/> 
              				</xsl:if>
            			 </xsl:if>
              		 <!-- end of bug#3594831-->
             			<xsl:choose>
							<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
							<!-- Bug6762503 Added SHIP_TO_LOCATION_NAME in case there are multiple shipments-->
             				<xsl:when test="$print_multiple ='Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
							<xsl:value-of select="SHIP_TO_LOCATION_NAME"/>
							<xsl:if test="SHIP_TO_ADDRESS_LINE1 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/> </xsl:if>
          		  			<xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/> </xsl:if>
          			  		<xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/> </xsl:if>
           				  	<xsl:if test="SHIP_TO_ADDRESS_INFO !=''"> <fo:block/> <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/> </xsl:if>
           					  <xsl:if test="SHIP_TO_COUNTRY !=''"> <fo:block/><xsl:value-of select="SHIP_TO_COUNTRY"/>	</xsl:if>
            				</xsl:when>
							<!-- start of bug#4568471/6829381 For one time shipments print the one time address-->					
							<xsl:when test="IS_SHIPMENT_ONE_TIME_LOC = 'Y'">
								<xsl:if test="ONE_TIME_ADDRESS_DETAILS !=''"> <fo:block/><xsl:value-of select="ONE_TIME_ADDRESS_DETAILS"/> </xsl:if>
							</xsl:when>
							<!-- end of bug#4568471/6829381 -->
            				<xsl:otherwise>
            					<xsl:if test="$shipment_count &gt; 1">
            					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
            					</xsl:if>
            				</xsl:otherwise>
            			</xsl:choose> 
            			</fo:block> </fo:table-cell>
          			</fo:table-row>
         			</fo:table-body>
    			  </fo:table>
			      <!-- end of bug#3594831-->           
          </xsl:otherwise>
        </xsl:choose>
			</fo:block> </fo:table-cell>

			<xsl:if test="$IS_COMPLEX_WORK_PO or ($shipment_count &gt; 1)">
				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<!-- Bug3670603: As per the bug Promised and need by date are added. -->
					<xsl:if test="PROMISED_DATE!=''">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
					<fo:block/> <xsl:value-of select="PROMISED_DATE"/>
					</xsl:if>
					<xsl:if test="NEED_BY_DATE!=''">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
					<fo:block/> <xsl:value-of select="NEED_BY_DATE"/>
					</xsl:if>
				</fo:block> </fo:table-cell>

				<fo:table-cell xsl:use-attribute-sets="table.cell5"> <fo:block xsl:use-attribute-sets="form_data1">
					<!-- BEGIN INVCONV -->
					<!-- Added foblock in quantity line and added secondary quantity line -->
					<fo:block/> <xsl:value-of select="QUANTITY"/> 
					<fo:block/> <xsl:value-of select="SECONDARY_QUANTITY"/>
					<!-- END INVCONV -->
				</fo:block> </fo:table-cell>

				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<!-- BEGIN INVCONV -->
					<!-- Added foblock in unit_meas_lookup_code line and added secondary uom line -->
					<fo:block/> <xsl:value-of select="UNIT_MEAS_LOOKUP_CODE"/> 
					<fo:block/> <xsl:value-of select="SECONDARY_UNIT_OF_MEASURE"/>
					<!-- END INVCONV -->
				</fo:block> </fo:table-cell>

        <fo:table-cell xsl:use-attribute-sets="table.cell5"> <fo:block xsl:use-attribute-sets="form_data1">
          <xsl:if test="$IS_COMPLEX_WORK_PO">
            <xsl:value-of  select="PRICE_OVERRIDE"/>
          </xsl:if>
        </fo:block> </fo:table-cell>

				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<xsl:value-of select="TAXABLE_FLAG"/> 
				</fo:block> </fo:table-cell>


        <fo:table-cell xsl:use-attribute-sets="table.cell5"> <fo:block xsl:use-attribute-sets="form_data1">
          <xsl:if test="$IS_COMPLEX_WORK_PO">
            <xsl:value-of  select="AMOUNT"/>
          </xsl:if>
        </fo:block> </fo:table-cell>

			</xsl:if>
		</fo:table-row>

		<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
		<xsl:if test="$print_multiple != 'Y' and $shipment_count = 1 and not($IS_COMPLEX_WORK_PO) and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:if>

   <!-- Print complex work payitem ship-to information -->
   <xsl:if test="$IS_COMPLEX_WORK_PO">
     <fo:table-row>
       <fo:table-cell >
         <fo:block >
           <fo:leader leader-pattern="space" leader-length="1.0pt"/>
         </fo:block>
       </fo:table-cell>
       <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">
         <fo:block xsl:use-attribute-sets="form_data">
           <xsl:if test="$DisplayBoilerPlate ">
             <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> 
             <fo:block/>
           </xsl:if>
           <xsl:choose>
			<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
             <xsl:when test="$print_multiple != 'Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
               <fo:block/>
                 <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> 
                 <fo:leader leader-pattern="space" leader-length="2.0pt"/>
                 <fo:page-number-citation ref-id="page_ref" />
             </xsl:when>
             <xsl:when test="$use_line_ship_to">
               <fo:block/>
                 <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_LINE_SHIP_TO'][1]/TEXT"/> 
                 <fo:leader leader-pattern="space" leader-length="2.0pt"/>
                 <xsl:value-of select="../../LINE_NUM"/>
             </xsl:when>
             <xsl:otherwise>
               <fo:block/>
               <xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/>
               <xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''">
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/>
               </xsl:if>
               <xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> 
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/>
               </xsl:if>
               <xsl:if test="SHIP_TO_ADDRESS_INFO !=''">
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/>
               </xsl:if>
               <xsl:if test="SHIP_TO_COUNTRY !=''">
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_COUNTRY"/>
               </xsl:if>
             </xsl:otherwise>
           </xsl:choose>
         </fo:block>
       </fo:table-cell>
     </fo:table-row>
   </xsl:if>


                <!-- for lines short text -->
		<xsl:for-each select="LINE_LOC_SHORT_TEXT/LINE_LOC_SHORT_TEXT_ROW">
		<fo:table-row >
			<fo:table-cell > <fo:block > </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
		                <!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                			<xsl:with-param name="ATTACHMENT_TEXT" select="SHORT_TEXT"/>
				</xsl:call-template>
                                
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:for-each>

		<!-- for long text -->
                <!--Bug #4654094-->
                <xsl:variable name="lineLocationID" select="LINE_LOCATION_ID"/>
		<xsl:for-each select="$SHIPMENT_ATTACHMENTS_ROOT_OBJ">
			<xsl:if test="$lineLocationID = .">
				<xsl:variable name="line" select="position()" />
				<fo:table-row >
				<fo:table-cell > <fo:block > </fo:block> </fo:table-cell>
				<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
                                        <!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                         <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                                <xsl:with-param name="ATTACHMENT_TEXT" select="../LONG_TEXT[$line]"/>
                                         </xsl:call-template>
				</fo:block> </fo:table-cell>
                		</fo:table-row>
			</xsl:if>
		</xsl:for-each>
                
                <!-- PO Attachments support 11i.11: start-->
                <!-- Table for displaying the shipments Web and File attachments -->
                <xsl:if test="count(LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW/WEB_PAGE) &gt; 0 or count(LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW/FILE_NAME) &gt; 0">
                <fo:table-row >
                        <fo:table-cell > <fo:block > </fo:block> </fo:table-cell>
                        <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> 
                        <fo:block xsl:use-attribute-sets="form_data"> 
                        <fo:table table-layout="fixed" >
                                <fo:table-column column-width="38mm"/>
                                <fo:table-column column-width="100mm"/>
                                <fo:table-body>
                                <fo:table-row> <fo:table-cell>  
                                        <fo:block> 
                                        <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                        </xsl:if>
                                </fo:block> </fo:table-cell>
                                
                                <fo:table-cell>  <fo:block> 
                                        <!-- for lines URL attachments -->
                                        <xsl:for-each select="LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW">
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                        </xsl:for-each>

                                        <!-- for lines FILE attachments -->
                                        <xsl:for-each select="LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW">	
                                                <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                        </xsl:for-each>
                                </fo:block> </fo:table-cell>
                                </fo:table-row>
                                </fo:table-body>
                        </fo:table>
                        </fo:block> </fo:table-cell>
                </fo:table-row>
                </xsl:if>
                <!-- PO Attachments support 11i.11: end-->

		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row keep-together.within-page="always" >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  
      <fo:block> 
        <xsl:choose>
          <xsl:when test="$IS_COMPLEX_WORK_PO">
            <fo:table>
              <fo:table-column column-width="78mm"/>
              <fo:table-body> <fo:table-row>
                <fo:table-cell xsl:use-attribute-sets="table.cell7">
                  <fo:block xsl:use-attribute-sets="form_data2" >
                    <fo:leader leader-pattern="space" leader-length="10.0pt"/> 
                    <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_CANCELED'][1]/TEXT"/>
                    <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                    <xsl:value-of select="substring(CANCEL_DATE,1,11)"/>
                    <fo:block/>
                    <fo:leader leader-pattern="space" leader-length="10.0pt"/> 
                    <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_PAYITEM_QTY'][1]/TEXT"/>
                    <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                    <xsl:value-of select="QUANTITY"/>
                    <fo:block/>
                    <fo:leader leader-pattern="space" leader-length="31.0pt"/> <!--Bug 5464968 Aligned the prompts -->
                    <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_QTY_CANCELED'][1]/TEXT"/> 
                    <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                    <xsl:value-of select="QUANTITY_CANCELLED"/>
                    <fo:block/>
                  </fo:block>
                </fo:table-cell>
              </fo:table-row></fo:table-body>
            </fo:table>
          </xsl:when>
          <xsl:otherwise>
    				<fo:table>
    				<fo:table-column column-width="5mm"/> <fo:table-column column-width="78mm"/>
    				<fo:table-body> <fo:table-row> 
    				<fo:table-cell> <fo:block> </fo:block> </fo:table-cell>
    				<fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2" >
    				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPMENT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
    				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_QTY_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="QUANTITY"/> <fo:block/>
    				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_QUANTITY_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="QUANTITY_CANCELLED"/> <fo:block/>
    				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
    				</fo:table>
          </xsl:otherwise>
        </xsl:choose>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="8"  font-size="8pt"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<fo:table-row> <fo:table-cell number-columns-spanned="8" font-size="4pt"> <fo:block> <fo:leader leader-pattern="space" leader-length="0.0pt"/>  </fo:block></fo:table-cell> </fo:table-row>
		
		<!-- display deliver to details -->
		<xsl:for-each select="DISTRIBUTIONS/DISTRIBUTIONS_ROW">
		<xsl:if test="../../DROP_SHIP_FLAG !='' or REQUESTER_DELIVER_FIRST_NAME !='' ">
			<fo:table-row>
			<fo:table-cell > <fo:block> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
			<fo:table>
			<fo:table-column column-width="4mm"/><fo:table-column column-width="20mm"/> <fo:table-column column-width="150mm"/>
			<fo:table-body> 
				<fo:table-row> 
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell > <fo:block>
					<xsl:if test="DELIVER_TO_PERSON_ID !=''"> <!-- bug#3594831: Deliver To message will not displayed if id is null-->
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
					</xsl:if> 
					</xsl:if>  <!-- bug#3594831: -->
				</fo:block> </fo:table-cell>
			
				<fo:table-cell>  <fo:block>
					<!-- start of displaying deliver to details -->
						<xsl:if test="LOCATION_CODE !=''"> 
							<fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="LOCATION_CODE"/>
						</xsl:if>
						<fo:block/>
					<!-- end of deliver details -->

					<!-- start of drop ship -->
					<xsl:if test="../../DROP_SHIP_FLAG ='Y'">
						<!--shipping method -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_METHOD'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="../../SHIPPING_METHOD"/> <fo:block/>	
						<!-- shipping instructions -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPPING_INSTRUCTION'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/>  <xsl:value-of select="../../SHIPPING_INSTRUCTIONS"/> <fo:block/>
						<!-- packing instructions -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PACKING_INSTRUCTION'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="../../PACKING_INSTRUCTIONS"/> <fo:block/>
						
						<!-- customer po number, shipment number and line number -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CUST_PO_NUMBER'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="../../CUSTOMER_PO_NUM"/>
						<fo:leader leader-pattern="space" leader-length="2.0pt"/>
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_NUMBER'][1]/TEXT"/>
						</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="../../CUSTOMER_PO_LINE_NUM"/>
						<fo:leader leader-pattern="space" leader-length="2.0pt"/>
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_NUMBER'][1]/TEXT"/>
						</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="../../CUSTOMER_PO_SHIPMENT_NUM"/> <fo:block/>

						<!-- customer product instructions -->

						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CUST_ITEM_DESC'][1]/TEXT"/>
						</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="../../CUSTOMER_PRODUCT_DESC"/>

					</xsl:if>

					<!-- end of drop ship -->
				</fo:block> </fo:table-cell>
				</fo:table-row>
			</fo:table-body></fo:table>
			</fo:block> </fo:table-cell>
			</fo:table-row>
		</xsl:if>
		</xsl:for-each> 	<!-- end of distributions if-->
		
	</xsl:for-each> <!-- end of shipment if -->
        </xsl:if> <!-- end of if for shipment count -->
	<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
	</xsl:if> <!-- end of Goods line type -->

	<!-- amount based line -->
	<xsl:if test = "LINE_TYPE = 'AMOUNT'">
		
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data3"> <xsl:value-of select="LINE_NUM"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" > <fo:block xsl:use-attribute-sets="form_data">
				<!-- Supplier Item number -->
				<xsl:if test="VENDOR_PRODUCT_NUM !=''">
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUPPLIER_ITEM'][1]/TEXT"/>
					</xsl:if> 
				<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="VENDOR_PRODUCT_NUM"/> <fo:block/> </xsl:if>
				
			</fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="4"> <fo:block xsl:use-attribute-sets="form_data">
			<xsl:if test="$shipment_count = 1">
				<!-- Bug3670603: As per the bug Promised and need by date are added. -->
				<xsl:if test="LINE_LOCATIONS/LINE_LOCATIONS_ROW/PROMISED_DATE!=''">
				<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
				<fo:block/> <xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/PROMISED_DATE"/>
				</xsl:if>
				<xsl:if test="LINE_LOCATIONS/LINE_LOCATIONS_ROW/NEED_BY_DATE!=''">
				<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
				<fo:block/> <xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/NEED_BY_DATE"/>
				</xsl:if>
			</xsl:if>
			</fo:block> </fo:table-cell>
						
			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
			<xsl:if test="$shipment_count = 1">
                                <!-- bug#3836856: retrieved the taxable flag value from shipments -->
				<xsl:value-of  select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/TAXABLE_FLAG"/>
			</xsl:if>
			</fo:block> </fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell5"> <fo:block xsl:use-attribute-sets="form_data1">
				<xsl:value-of  select="LINE_AMOUNT"/>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<!-- Bug 11892229: Displaying Item description new row. -->
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> <fo:block xsl:use-attribute-sets="form_data">
				<xsl:value-of select="ITEM_DESCRIPTION"/>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<!-- end of Bug 11892229 -->

                <!-- PO Attachments support 11i.11: Added the condition to check whether file or web attachments are not null -->
                <!-- Bug 5254839 Added the condition to check whether short attachments are null or not -->
                <!-- Bug 5230892 Added the condition to check whether long attachments are null or not -->
		<xsl:if test="$PSA or $un_num or $hz_class or $vendor_note or $ga_flag or $con_num or $sup_quote_num or $short_attachments or $long_attachments or $file_attachments or $url_attachments">

		<fo:table-row> <fo:table-cell number-columns-spanned="7"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>

		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6"> 
			<fo:block xsl:use-attribute-sets="form_data">

				<!-- to display the charge Account -->
				<xsl:if test="$charge_account">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CHARGE_ACCOUNT'][1]/TEXT"/>
					</xsl:if>
					<xsl:choose>
					<xsl:when test="$distribution_count =1">
						<!-- bug# 6074720:  given the complete path (instead of $distributions_root_obj/charge_account), to select correct charge account for each distribution -->
						<xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT"/> <fo:block/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_MULTIPLE'][1]/TEXT"/> <fo:block/>
					</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- end of charge account -->
				
				<!-- Un number row -->
				<xsl:if test="$un_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_UN_NUMBER'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="UN_NUMBER"/> <fo:block/>
				</xsl:if>
				<!-- end of Un number row -->

				<!-- Hazard class -->
				<xsl:if test="$hz_class">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_HAZARD_CLASS'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="HAZARD_CLASS"/> <fo:block/>
				</xsl:if>
				<!-- end of Hazard class -->

				<!-- Vendor Notes -->
				<xsl:if test="$vendor_note">
					<xsl:value-of select="NOTE_TO_VENDOR"/> <fo:block/>
				</xsl:if>
				<!-- end of note to vendor -->

				<!-- for lines short text -->
				<xsl:for-each select="LINE_SHORT_TEXT/LINE_SHORT_TEXT_ROW">	
					<xsl:value-of select ="SHORT_TEXT"/> <fo:block/>
				</xsl:for-each>

				<!-- for long text -->
				<xsl:for-each select="$LINE_LONG_ATTACHMENTS_ROOT_OBJ">
					<xsl:if test="$lineID = .">
						<xsl:variable name="line" select="position()" />
						<xsl:value-of select="../TEXT[$line]"/>	<fo:block/> 	
					</xsl:if>
				</xsl:for-each>
                                
                                <!-- PO Attachments support 11i.11: start-->
                                <!-- Table for displaying the line Web and File attachments -->
                                <xsl:if test="$file_attachments or $url_attachments">
                                <fo:table table-layout="fixed" >
                                        <fo:table-column column-width="35mm"/>
                                        <fo:table-column column-width="100mm"/>
                                        <fo:table-body>
                                        <fo:table-row> <fo:table-cell>  
                                                <fo:block> 
                                                <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                        <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                                </xsl:if>
                                        </fo:block> </fo:table-cell>
                                        
                                        <fo:table-cell>  
                                                <fo:block> 

                                                <!-- for lines URL attachments -->
                                                <xsl:for-each select="LINE_URL_ATTACHMENTS/LINE_URL_ATTACHMENTS_ROW">	
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                                </xsl:for-each>

                                                <!-- for lines FILE attachments -->
                                                <xsl:for-each select="LINE_FILE_ATTACHMENTS/LINE_FILE_ATTACHMENTS_ROW">	
                                                        <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                                </xsl:for-each>
                                                </fo:block> </fo:table-cell>
		                        </fo:table-row> </fo:table-body> 
                                </fo:table>
                                </xsl:if>
                                <!-- PO Attachments support 11i.11: end-->

				<!-- Global agreement value -->
				<xsl:if test="$ga_flag">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_BPA'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="SEGMENT1"/> <fo:block/>
				</xsl:if>
				<!-- end of global agreement flag -->

				<!-- Contract agreement  -->
				<xsl:if test="$con_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_CONTRACT'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="CONTRACT_NUM"/> <fo:block/>
				</xsl:if>
				<!-- end of contract num -->

				<!-- Supplier quotation number-->
				<xsl:if test="$sup_quote_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_SUPPLIER_QUOTATION'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="QUOTE_VENDOR_QUOTE_NUMBER"/> <fo:block/>
				</xsl:if>
				<!-- end of Supplier quotation number -->
			 				
			</fo:block> 
			</fo:table-cell>
		</fo:table-row>
		</xsl:if>
		
		<!-- display canceled details -->

		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="70mm"/>
				<fo:table-body> <fo:table-row> <fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_QTY_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="sum(LINE_LOCATIONS/LINE_LOCATIONS_ROW/QUANTITY)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_QUANTITY_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="sum(LINE_LOCATIONS/LINE_LOCATIONS_ROW/QUANTITY_CANCELLED)"/> <fo:block/>
                                </fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<xsl:for-each select="LINE_LOCATIONS/LINE_LOCATIONS_ROW">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block font-size="8pt"> <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row> 
		<fo:table-row  >
			<fo:table-cell > <fo:block >  </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
			<fo:table>
			<fo:table-column column-width="3.5mm"/> <fo:table-column column-width="34.5mm"/>
			<fo:table-body>
			<fo:table-row >
			<fo:table-cell > <fo:block>  </fo:block> </fo:table-cell>
			<fo:table-cell > <fo:block>  
			<xsl:if test="$DisplayBoilerPlate ">
				<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> <fo:block/>
			</xsl:if>
			<!-- bug#3594831: added drop_ship ship to details -->
			<!-- Bug3670603: Address details should be displayed before Promised and Need by date -->
			<xsl:if test="DROP_SHIP_FLAG='Y'">
				<xsl:if test="SHIP_CUST_NAME !=''"> <xsl:value-of select="SHIP_CUST_NAME"/>  </xsl:if>
				<xsl:if test="SHIP_CONT_NAME !=''"> <fo:block/> <xsl:value-of select="SHIP_CONT_NAME"/>  </xsl:if>
				<xsl:if test="SHIP_CONT_EMAIL !=''"> <fo:block/><xsl:value-of select="SHIP_CONT_EMAIL"/> </xsl:if>
				<xsl:if test="SHIP_CONT_PHONE !=''">
					<xsl:if test="$DisplayBoilerPlate ">
						 <fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TELEPHONE'][1]/TEXT"/>:
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="SHIP_CONT_PHONE"/> 
				</xsl:if>
				<xsl:if test="SHIP_TO_CONTACT_FAX !=''"> 
					<xsl:if test="$DisplayBoilerPlate ">
						 <fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_FAX'][1]/TEXT"/>:
					</xsl:if>
					 <fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="SHIP_TO_CONTACT_FAX"/> 
				</xsl:if>
			</xsl:if>
			<!-- end of bug#3594831-->
			<xsl:choose>
				<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
				<!-- Bug6762503 Added SHIP_TO_LOCATION_NAME in case there are multiple shipments-->
				<xsl:when test="$print_multiple ='Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
					<fo:block/> <xsl:value-of select="SHIP_TO_LOCATION_NAME"/>
					<xsl:if test="SHIP_TO_ADDRESS_LINE1 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_INFO !=''"> <fo:block/> <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/> </xsl:if>
					<xsl:if test="SHIP_TO_COUNTRY !=''"> <fo:block/><xsl:value-of select="SHIP_TO_COUNTRY"/>	</xsl:if>
				</xsl:when>
				<!-- start of bug#4568471/6829381 For one time shipments print the one time address-->					
				<xsl:when test="IS_SHIPMENT_ONE_TIME_LOC = 'Y'">
					<xsl:if test="ONE_TIME_ADDRESS_DETAILS !=''"> <fo:block/><xsl:value-of select="ONE_TIME_ADDRESS_DETAILS"/> </xsl:if>
				</xsl:when>
				<!-- end of bug#4568471/6829381 -->
				<xsl:otherwise>
					<xsl:if test="$shipment_count &gt; 1">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose> 
			</fo:block> </fo:table-cell>
			</fo:table-row>
			</fo:table-body>
			</fo:table>
			<!-- end of bug#3594831-->
			</fo:block> </fo:table-cell>

			<xsl:if test="$shipment_count &gt; 1">
				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<!-- Bug3670603: As per the bug Promised and need by date are added. -->
					<xsl:if test="PROMISED_DATE!=''">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
					<fo:block/> <xsl:value-of select="PROMISED_DATE"/>
					</xsl:if>
					<xsl:if test="NEED_BY_DATE!=''">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
					<fo:block/> <xsl:value-of select="NEED_BY_DATE"/>
					</xsl:if>
				</fo:block> </fo:table-cell>

				<fo:table-cell text-align="center"> <fo:block > </fo:block>	</fo:table-cell>

				<fo:table-cell text-align="center"> <fo:block > </fo:block>	</fo:table-cell>

				<fo:table-cell text-align="center"> <fo:block > </fo:block>	</fo:table-cell>

				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<xsl:value-of select="TAXABLE_FLAG"/> 
				</fo:block> </fo:table-cell>

				<fo:table-cell xsl:use-attribute-sets="table.cell5">  <fo:block xsl:use-attribute-sets="form_data1"> 
				<xsl:value-of select="AMOUNT"/> 
				</fo:block> </fo:table-cell>
			</xsl:if>
		</fo:table-row>
		
		<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
		<xsl:if test="$print_multiple != 'Y' and $shipment_count = 1 and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:if>

		<!-- for lines short text -->
		<xsl:for-each select="LINE_LOC_SHORT_TEXT/LINE_LOC_SHORT_TEXT_ROW">
		<fo:table-row >
			<fo:table-cell > <fo:block >  </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
				<!-- Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment  --> 
				- <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
				  <xsl:with-param name="ATTACHMENT_TEXT" select="SHORT_TEXT" /> 
				  </xsl:call-template>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:for-each>

		<!-- for long text -->
                <!--Bug #4654094-->
                <xsl:variable name="lineLocationID" select="LINE_LOCATION_ID"/>
		<xsl:for-each select="$SHIPMENT_ATTACHMENTS_ROOT_OBJ">
			<xsl:if test="$lineLocationID = .">
				<xsl:variable name="line" select="position()" />
				<fo:table-row >
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
					<!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                         <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                                <xsl:with-param name="ATTACHMENT_TEXT" select="../LONG_TEXT[$line]"/>
                                         </xsl:call-template>					
				</fo:block> </fo:table-cell>
		</fo:table-row>
			</xsl:if>
		</xsl:for-each>
		
                <!-- PO Attachments support 11i.11: start-->
                <!-- Table for displaying the shipments Web and File attachments -->
                <xsl:if test="count(LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW/WEB_PAGE) &gt; 0 or count(LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW/FILE_NAME) &gt; 0">
                <fo:table-row >
                        <fo:table-cell > <fo:block > </fo:block> </fo:table-cell>
                        <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> 
                        <fo:block xsl:use-attribute-sets="form_data"> 
                        <fo:table table-layout="fixed" >
                                <fo:table-column column-width="38mm"/>
                                <fo:table-column column-width="100mm"/>
                                <fo:table-body>
                                <fo:table-row> <fo:table-cell>  
                                        <fo:block> 
                                        <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                        </xsl:if>
                                </fo:block> </fo:table-cell>
                                
                                <fo:table-cell>  <fo:block> 
                                        <!-- for lines URL attachments -->
                                        <xsl:for-each select="LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW">
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                        </xsl:for-each>

                                        <!-- for lines FILE attachments -->
                                        <xsl:for-each select="LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW">	
                                                <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                        </xsl:for-each>
                                </fo:block> </fo:table-cell>
                                </fo:table-row>
                                </fo:table-body>
                        </fo:table>
                        </fo:block> </fo:table-cell>
                </fo:table-row>
                </xsl:if>
                <!-- PO Attachments support 11i.11: end-->


		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="5mm"/> <fo:table-column column-width="78mm"/>
				<fo:table-body> <fo:table-row> 
				<fo:table-cell> <fo:block> </fo:block> </fo:table-cell>
				<fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPMENT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="20.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_SHIPMENT_QTY'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="QUANTITY"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="40.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_QUANTITY_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="QUANTITY_CANCELLED"/> <fo:block/>
				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="8"  font-size="8pt"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<fo:table-row> <fo:table-cell number-columns-spanned="8" font-size="4pt"> <fo:block> <fo:leader leader-pattern="space" leader-length="0.0pt"/>  </fo:block></fo:table-cell> </fo:table-row>

		<!-- display deliver to details -->
		<xsl:for-each select="DISTRIBUTIONS/DISTRIBUTIONS_ROW">
		<xsl:if test="../../DROP_SHIP_FLAG !='' or REQUESTER_DELIVER_FIRST_NAME !='' ">
			<fo:table-row>
			<fo:table-cell > <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
			<fo:table>
			<fo:table-column column-width="4mm"/><fo:table-column column-width="20mm"/> <fo:table-column column-width="150mm"/>
			<fo:table-body> 
				<fo:table-row> 
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell > <fo:block>
					<xsl:if test="DELIVER_TO_PERSON_ID !=''"> <!-- bug#3594831: Deliver To message will not displayed if id is null-->
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
					</xsl:if> 
					</xsl:if> <!-- bug#3594831: end-->
				</fo:block> </fo:table-cell>
			
				<fo:table-cell>  <fo:block>
					<!-- start of displaying deliver to details -->
					<xsl:if test="DELIVER_TO_PERSON_ID !=''"> <!-- bug#3594831: Deliver To message will not displayed if id is null-->
						<xsl:call-template name="NAME_TEMPLATE">
						<xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
						<xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
						<xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
						</xsl:call-template>
						<xsl:if test="QUANTITY_ORDERED !=''"> 
							<fo:leader leader-pattern="space" leader-length="2.0pt"/> (<xsl:value-of select="QUANTITY_ORDERED"/>)
						</xsl:if>
						<fo:block/> <xsl:value-of select="EMAIL_ADDRESS"/> <fo:block/>
					<!-- end of deliver details -->
					</xsl:if>  <!-- bug#3594831: end-->

					<!-- start of drop ship -->
					<xsl:if test="../../DROP_SHIP_FLAG ='Y'">
						<!--shipping method -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_METHOD'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="../../SHIPPING_METHOD"/> <fo:block/>	
						<!-- shipping instructions -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPPING_INSTRUCTION'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/>  <xsl:value-of select="../../SHIPPING_INSTRUCTIONS"/> <fo:block/>
						<!-- packing instructions -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PACKING_INSTRUCTION'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="../../PACKING_INSTRUCTIONS"/> <fo:block/>
						
						<!-- customer po number, shipment number and line number -->
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CUST_PO_NUMBER'][1]/TEXT"/>
						</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="../../CUSTOMER_PO_NUM"/>
						<fo:leader leader-pattern="space" leader-length="2.0pt"/>
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_NUMBER'][1]/TEXT"/>
						</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="../../CUSTOMER_PO_LINE_NUM"/>
						<fo:leader leader-pattern="space" leader-length="2.0pt"/>
						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_NUMBER'][1]/TEXT"/>
						</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="../../CUSTOMER_PO_SHIPMENT_NUM"/> <fo:block/>

						<!-- customer product instructions -->

						<xsl:if test="$DisplayBoilerPlate ">
							<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CUST_ITEM_DESC'][1]/TEXT"/>
						</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/><xsl:value-of select="../../CUSTOMER_PRODUCT_DESC"/>

					</xsl:if>

					<!-- end of drop ship -->
				</fo:block> </fo:table-cell>
				</fo:table-row>
			</fo:table-body></fo:table>
			</fo:block> </fo:table-cell>
			</fo:table-row>
		</xsl:if>
		</xsl:for-each> 	<!-- end of distributions if-->
		
		</xsl:for-each> <!-- end of shipment if -->
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
	</xsl:if> <!-- end of amount line type -->


	
	<!-- xsl for displaying the Rate Based Temp Labor Details -->
	<xsl:if test = "LINE_TYPE = 'RATE' and PURCHASE_BASIS = 'TEMP LABOR'">		
		
		<fo:table-row  >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data3"> <xsl:value-of select="LINE_NUM"/> </fo:block> </fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
				<!-- Supplier Item number -->
				<xsl:if test="VENDOR_PRODUCT_NUM !=''">
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUPPLIER_ITEM'][1]/TEXT"/>
					</xsl:if> 
				<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="VENDOR_PRODUCT_NUM"/> <fo:block/> </xsl:if>
				<xsl:if test="JOB_NAME !=''">
					<xsl:value-of select="JOB_NAME"/> <fo:block/>
				</xsl:if>
				
			</fo:block> </fo:table-cell>
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
				<xsl:value-of select="UNIT_MEAS_LOOKUP_CODE"/>
			</fo:block> </fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell5">  <fo:block xsl:use-attribute-sets="form_data1"> 
				<xsl:value-of select="UNIT_PRICE"/>
			</fo:block> </fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
                                <!-- bug#3836856: retrieved the taxable flag value from shipments -->
				<xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/TAXABLE_FLAG"/>
			</fo:block> </fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell5">  <fo:block xsl:use-attribute-sets="form_data1"> 
				<xsl:value-of select="LINE_AMOUNT"/>
			</fo:block> </fo:table-cell>

		</fo:table-row>
<!-- Bug 11892229: Displaying Item description new row. -->
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> <fo:block xsl:use-attribute-sets="form_data">
				<xsl:value-of select="ITEM_DESCRIPTION"/>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<!-- end of Bug 11892229 -->	


		<!-- PO Attachments support 11i.11: Added the condition to check whether short or file or web attachments are not null -->
		<!-- Bug 5230892 Added the condition to check whether long attachments are null or not -->
		<xsl:if test="$PSA or $vendor_note or $ga_flag or $short_attachments or $long_attachments or $file_attachments or $url_attachments">

		<fo:table-row> <fo:table-cell number-columns-spanned="7"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>
		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6"> 
			<fo:block xsl:use-attribute-sets="form_data">

				<!-- to display the charge Account -->
				<xsl:if test="$charge_account">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CHARGE_ACCOUNT'][1]/TEXT"/>
					</xsl:if>
					<xsl:choose>
					<xsl:when test="$distribution_count =1">
					        <!-- bug# 6074720:  given the complete path (instead of $distributions_root_obj/charge_account), to select correct charge account for each distribution -->
						<xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT"/> <fo:block/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_MULTIPLE'][1]/TEXT"/> <fo:block/>
					</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- end of charge account -->
				
				
				<!-- Vendor Notes -->
				<xsl:if test="$vendor_note">
					<xsl:value-of select="NOTE_TO_VENDOR"/> <fo:block/>
				</xsl:if>
				<!-- end of note to vendor -->

				<!-- for lines short text -->
				<xsl:for-each select="LINE_SHORT_TEXT/LINE_SHORT_TEXT_ROW">	
					<xsl:value-of select ="SHORT_TEXT"/> <fo:block/>
				</xsl:for-each>

				<!-- for long text -->
				<xsl:for-each select="$LINE_LONG_ATTACHMENTS_ROOT_OBJ">
					<xsl:if test="$lineID = .">
						<xsl:variable name="line" select="position()" />
						<xsl:value-of select="../TEXT[$line]"/>	<fo:block/> 	
					</xsl:if>
				</xsl:for-each>
                                
                                <!-- PO Attachments support 11i.11: start-->
                                <!-- Table for displaying the line Web and File attachments -->
                                <xsl:if test="$file_attachments or $url_attachments">
                                <fo:table table-layout="fixed" >
                                        <fo:table-column column-width="35mm"/>
                                        <fo:table-column column-width="100mm"/>
                                        <fo:table-body>
                                        <fo:table-row> <fo:table-cell>  
                                                <fo:block> 
                                                <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                        <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                                </xsl:if>
                                        </fo:block> </fo:table-cell>
                                        
                                        <fo:table-cell>  
                                                <fo:block> 

                                                <!-- for lines URL attachments -->
                                                <xsl:for-each select="LINE_URL_ATTACHMENTS/LINE_URL_ATTACHMENTS_ROW">	
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                                </xsl:for-each>

                                                <!-- for lines FILE attachments -->
                                                <xsl:for-each select="LINE_FILE_ATTACHMENTS/LINE_FILE_ATTACHMENTS_ROW">	
                                                        <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                                </xsl:for-each>
                                                </fo:block> </fo:table-cell>
		                        </fo:table-row> </fo:table-body> 
                                </fo:table>
                                </xsl:if>
                                <!-- PO Attachments support 11i.11: end-->


				<!-- Global agreement value -->
				<xsl:if test="$ga_flag">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_BPA'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="SEGMENT1"/> <fo:block/>
				</xsl:if>
				<!-- end of global agreement flag -->

			</fo:block> 
			</fo:table-cell>
		</fo:table-row>
		</xsl:if>
				
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row >
			<fo:table-cell > <fo:block >  </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
				<xsl:if test="CONTRACTOR_LAST_NAME != '' or CONTRACTOR_FIRST_NAME !=''">
				<xsl:if test="$DisplayBoilerPlate ">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CONTRACTOR_NAME'][1]/TEXT"/>
				</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/>
				<xsl:call-template name="NAME_TEMPLATE">
				<xsl:with-param name="FIRST_NAME" select="CONTRACTOR_FIRST_NAME"/>
				<xsl:with-param name="LAST_NAME" select="CONTRACTOR_LAST_NAME"/>
				<xsl:with-param name="TITLE" select="CONTRACTOR_TITLE"/>
				</xsl:call-template> <fo:block/>
				</xsl:if>
				
				<!-- Start Date -->
				<fo:leader leader-pattern="space" leader-length="29.0pt"/>
				<xsl:if test="$DisplayBoilerPlate ">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_START_DATE'][1]/TEXT"/>
				</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/>
				<xsl:value-of select="substring(START_DATE,1,11)"/> <fo:block/>

				<!-- end date -->
				<xsl:if test="EXPIRATION_DATE !=''">
				<fo:leader leader-pattern="space" leader-length="32.0pt"/>
				<xsl:if test="$DisplayBoilerPlate ">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_END_DATE'][1]/TEXT"/>
				</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/>
				<xsl:value-of select="substring(EXPIRATION_DATE,1,11)"/> <fo:block/>
				</xsl:if>

				<!-- Price differentials block -->		
				<xsl:if test="count(PRICE_DIFF/PRICE_DIFF_ROW/PRICE_TYPE) &gt; 0">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/>
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PRICE_DIFFERENTIALS'][1]/TEXT"/>
					</xsl:if> <fo:block/>
				<xsl:for-each select="PRICE_DIFF/PRICE_DIFF_ROW">
					<fo:leader leader-pattern="space" leader-length="10.0pt"/>
					<xsl:value-of select="PRICE_TYPE"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="MULTIPLIER"/> <fo:block/>
				</xsl:for-each>

				</xsl:if>

			</fo:block>
			</fo:table-cell>
		</fo:table-row>
		

		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="70mm"/>
				<fo:table-body> <fo:table-row> <fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_AMOUNT_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="TOTAL_LINE_AMOUNT"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_AMOUNT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="CANCELED_AMOUNT"/> <fo:block/>
				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		
		<!-- start of shipment details -->
		<xsl:for-each select="LINE_LOCATIONS/LINE_LOCATIONS_ROW">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="7"> <fo:block> </fo:block> </fo:table-cell> </fo:table-row>
		<fo:table-row  >
			<fo:table-cell > <fo:block > </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
			<xsl:if test="$DisplayBoilerPlate ">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> <fo:block/>
			</xsl:if><fo:block/>

			<xsl:choose>
				<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
				<!-- Bug6762503 Added SHIP_TO_LOCATION_NAME in case there are multiple shipments-->
				<xsl:when test="$print_multiple ='Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
					<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_LOCATION_NAME"/>
					<xsl:if test="SHIP_TO_ADDRESS_LINE1 !=''"> <fo:block/><fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''"> <fo:block/><fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> <fo:block/> <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_INFO !=''"> <fo:block/> <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/> </xsl:if>
					<xsl:if test="SHIP_TO_COUNTRY !=''"> <fo:block/> <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_COUNTRY"/>	</xsl:if>
				</xsl:when>
				<!-- start of bug#4568471/6829381 For one time shipments print the one time address-->					
				<xsl:when test="IS_SHIPMENT_ONE_TIME_LOC = 'Y'">
					<xsl:if test="ONE_TIME_ADDRESS_DETAILS !=''"> <fo:block/><xsl:value-of select="ONE_TIME_ADDRESS_DETAILS"/> </xsl:if>
				</xsl:when>
				<!-- end of bug#4568471/6829381 -->
				<xsl:otherwise>
					<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
				</xsl:otherwise>
			</xsl:choose> <fo:block/>
			<!-- for lines short text -->
			<xsl:for-each select="LINE_LOC_SHORT_TEXT/LINE_LOC_SHORT_TEXT_ROW">
				<!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                        <xsl:with-param name="ATTACHMENT_TEXT" select="SHORT_TEXT"/>
                                </xsl:call-template>				
			</xsl:for-each>

			<!-- for long text -->
                        <!--Bug #4654094-->
			<xsl:variable name="lineLocationID" select="LINE_LOCATION_ID"/>
			<xsl:for-each select="$SHIPMENT_ATTACHMENTS_ROOT_OBJ">
				<xsl:if test="$lineLocationID = .">
					<xsl:variable name="line" select="position()" />
					 <!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                         <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                                <xsl:with-param name="ATTACHMENT_TEXT" select="../LONG_TEXT[$line]"/>
                                         </xsl:call-template>		
				</xsl:if>
			</xsl:for-each>
                        
                        <!-- PO Attachments support 11i.11: start-->
                        <!-- Table for displaying the shipments Web and File attachments -->
                        <xsl:if test="count(LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW/WEB_PAGE) &gt; 0 or count(LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW/FILE_NAME) &gt; 0">
                        <fo:table table-layout="fixed" >
                                <fo:table-column column-width="38mm"/>
                                <fo:table-column column-width="100mm"/>
                                <fo:table-body>
                                <fo:table-row> <fo:table-cell>  
                                        <fo:block> 
                                        <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                        </xsl:if>
                                </fo:block> </fo:table-cell>
                                
                                <fo:table-cell>  <fo:block> 
                                        <!-- for lines URL attachments -->
                                        <xsl:for-each select="LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW">
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                       <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                        </xsl:for-each>

                                        <!-- for lines FILE attachments -->
                                        <xsl:for-each select="LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW">	
                                               <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                        </xsl:for-each>
                                </fo:block> </fo:table-cell>
                                </fo:table-row>
                                </fo:table-body>
                        </fo:table>
                </xsl:if>
                <!-- PO Attachments support 11i.11: end-->


			</fo:block> </fo:table-cell>
		</fo:table-row>
		
		
		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="5mm"/> <fo:table-column column-width="78mm"/>
				<fo:table-body> <fo:table-row> 
				<fo:table-cell> <fo:block> </fo:block> </fo:table-cell>
				<fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPMENT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_AMOUNT_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="TOTAL_SHIPMENT_AMOUNT"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="6.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_AMOUNT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="AMOUNT_CANCELLED"/> <fo:block/>
				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="8"  font-size="8pt"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<fo:table-row> <fo:table-cell number-columns-spanned="8" font-size="4pt"> <fo:block> <fo:leader leader-pattern="space" leader-length="0.0pt"/>  </fo:block></fo:table-cell> </fo:table-row>
		<!-- display deliver to details -->
		<xsl:for-each select="DISTRIBUTIONS/DISTRIBUTIONS_ROW">
		<xsl:if test="REQUESTER_DELIVER_FIRST_NAME !='' ">
			<fo:table-row>
			<fo:table-cell > <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
			<fo:table>
			<fo:table-column column-width="4mm"/><fo:table-column column-width="20mm"/> <fo:table-column column-width="100mm"/>
			<fo:table-body> 
				<fo:table-row> 
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell > <fo:block>
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
					</xsl:if> 
				</fo:block> </fo:table-cell>
			
				<fo:table-cell>  <fo:block>
					<!-- start of displaying deliver to details -->
					<xsl:call-template name="NAME_TEMPLATE">
					<xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
					<xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
					<xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
					</xsl:call-template>
			
					<fo:leader leader-pattern="space" leader-length="2.0pt"/> 
					<fo:block/> <xsl:value-of select="EMAIL_ADDRESS"/>
					<!-- end of deliver details -->
					
				</fo:block> </fo:table-cell>
				</fo:table-row>
			</fo:table-body></fo:table>
			</fo:block> </fo:table-cell>
			</fo:table-row>
		</xsl:if>
		</xsl:for-each> 	<!-- end of distributions if-->
		
		</xsl:for-each> <!-- end of shipment if -->
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
	</xsl:if>


	<!-- Displays Fixed Price Labor Line -->
	<xsl:if test = "LINE_TYPE = 'FIXED PRICE' and PURCHASE_BASIS = 'TEMP LABOR'">		
				
		<fo:table-row  >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data3"> <xsl:value-of select="LINE_NUM"/> </fo:block> </fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
				<!-- Supplier Item number -->
				<xsl:if test="VENDOR_PRODUCT_NUM !=''">
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUPPLIER_ITEM'][1]/TEXT"/>
					</xsl:if> 
				<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="VENDOR_PRODUCT_NUM"/> <fo:block/> </xsl:if>
				<xsl:value-of select="JOB_NAME"/> <fo:block/>
				
			</fo:block> </fo:table-cell>
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
        <xsl:choose>
          <xsl:when test="$line_delivery_count = 1">
            <xsl:value-of  select="LINE_DELIVERY/LINE_DELIVERY_ROW/TAXABLE_FLAG"/>
          </xsl:when>
          <xsl:when test="$shipment_count = 1">
            <xsl:value-of  select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/TAXABLE_FLAG"/>
		  	   </xsl:when>
        </xsl:choose>
			</fo:block> </fo:table-cell>

			<fo:table-cell  xsl:use-attribute-sets="table.cell5">  <fo:block xsl:use-attribute-sets="form_data1"> 
				<xsl:value-of select="LINE_AMOUNT"/>
			</fo:block> </fo:table-cell>

		</fo:table-row>
<!-- Bug 11892229: Displaying Item description new row.  -->
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> <fo:block xsl:use-attribute-sets="form_data">
				<xsl:value-of select="ITEM_DESCRIPTION"/>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<!-- end of Bug 11892229 -->	


		<!-- PO Attachments support 11i.11: Added the condition to check whether short or file or web attachments are not null -->
		<!-- Bug 5230892 Added the condition to check whether long attachments are null or not -->
                <xsl:if test="$PSA or $vendor_note or $ga_flag or $short_attachments or $long_attachments or $file_attachments or $url_attachments or $IS_COMPLEX_WORK_PO">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>

		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6"> 
			<fo:block xsl:use-attribute-sets="form_data">

				<!-- to display the charge Account -->
				<xsl:if test="$charge_account">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CHARGE_ACCOUNT'][1]/TEXT"/>
					</xsl:if>
					<xsl:choose>
					<xsl:when test="$distribution_count =1">
					        <!-- bug# 6074720:  given the complete path (instead of $distributions_root_obj/charge_account), to select correct charge account for each distribution -->
						<xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT"/> <fo:block/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_MULTIPLE'][1]/TEXT"/> <fo:block/>
					</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- end of charge account -->

        <!-- Complex Work Line Info -->
        <xsl:if test="$IS_COMPLEX_WORK_PO">
          <xsl:if test="ADVANCE_AMOUNT!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ADVANCE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="ADVANCE_AMOUNT"/> 
          </xsl:if>
          <xsl:if test="RECOUPMENT_RATE!=''">                    
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RECOUPMENT_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="RECOUPMENT_RATE"/> 
          </xsl:if>
          <xsl:if test="PROGRESS_PAYMENT_RATE!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PROGRESS_PAYMENT_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="PROGRESS_PAYMENT_RATE"/> 
          </xsl:if>
          <!--Bug 5278399 - Added Max Retainage Amount -->
          <xsl:if test="MAX_RETAINAGE_AMOUNT!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MAX_RETAINAGE_AMOUNT'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="MAX_RETAINAGE_AMOUNT"/> 
          </xsl:if>
          <xsl:if test="RETAINAGE_RATE!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RETAINAGE_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="RETAINAGE_RATE"/> 
          </xsl:if>
          <fo:block/>
        </xsl:if>
        <!-- end of Complex Work Line Info -->
				
				
				<!-- Vendor Notes -->
				<xsl:if test="$vendor_note">
					<xsl:value-of select="NOTE_TO_VENDOR"/> <fo:block/>
				</xsl:if>
				<!-- end of note to vendor -->

				<!-- for lines short text -->
				<xsl:for-each select="LINE_SHORT_TEXT/LINE_SHORT_TEXT_ROW">	
					<xsl:value-of select ="SHORT_TEXT"/> <fo:block/>
				</xsl:for-each>

				<!-- for long text -->
				<xsl:for-each select="$LINE_LONG_ATTACHMENTS_ROOT_OBJ">
					<xsl:if test="$lineID = .">
						<xsl:variable name="line" select="position()" />
						<xsl:value-of select="../TEXT[$line]"/>	<fo:block/> 	
					</xsl:if>
				</xsl:for-each>
                                
                                <!-- PO Attachments support 11i.11: start-->
                                <!-- Table for displaying the line Web and File attachments -->
                                <xsl:if test="$file_attachments or $url_attachments">
                                <fo:table table-layout="fixed" >
                                        <fo:table-column column-width="35mm"/>
                                        <fo:table-column column-width="100mm"/>
                                        <fo:table-body>
                                        <fo:table-row> <fo:table-cell>  
                                                <fo:block> 
                                                <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                        <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                                </xsl:if>
                                        </fo:block> </fo:table-cell>
                                        
                                        <fo:table-cell>  
                                                <fo:block> 

                                                <!-- for lines URL attachments -->
                                                <xsl:for-each select="LINE_URL_ATTACHMENTS/LINE_URL_ATTACHMENTS_ROW">	
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                                </xsl:for-each>

                                                <!-- for lines FILE attachments -->
                                                <xsl:for-each select="LINE_FILE_ATTACHMENTS/LINE_FILE_ATTACHMENTS_ROW">	
                                                        <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                                </xsl:for-each>
                                                </fo:block> </fo:table-cell>
		                        </fo:table-row> </fo:table-body> 
                                </fo:table>
                                </xsl:if>
                                <!-- PO Attachments support 11i.11: end-->


				<!-- Global agreement value -->
				<xsl:if test="$ga_flag">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_BPA'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="SEGMENT1"/> <fo:block/>
				</xsl:if>
				<!-- end of global agreement flag -->

			</fo:block> 
			</fo:table-cell>
		</fo:table-row>
		</xsl:if>

  <!-- Print line delivery details (for complex work financing case) -->
  <xsl:if test="$line_delivery_count = 1">
    <fo:table-row>
       <fo:table-cell >
         <fo:block >
           <fo:leader leader-pattern="space" leader-length="1.0pt"/>
         </fo:block>
       </fo:table-cell>
       <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">
         <fo:block xsl:use-attribute-sets="form_data">
           <xsl:if test="$DisplayBoilerPlate ">
             <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> 
             <fo:block/>
           </xsl:if>
           <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE1"/>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE2 !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE2"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE3 !=''"> 
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE3"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_INFO !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_INFO"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_COUNTRY !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_COUNTRY"/>
           </xsl:if>
         </fo:block>
       </fo:table-cell>
    </fo:table-row>
  </xsl:if>

  <!-- Print line delivery distribution information (for complex work financing case) -->
  <xsl:if test="$line_delivery_distribution_count &gt; 0">
    <xsl:for-each select="LINE_DELIVERY/LINE_DELIVERY_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW">
      <xsl:if test="REQUESTER_DELIVER_FIRST_NAME !='' ">
        <fo:table-row>
          <fo:table-cell > <fo:block /> </fo:table-cell>
           <fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">
             <fo:block xsl:use-attribute-sets="form_data"> 
               <xsl:if test="DELIVER_TO_PERSON_ID !=''">				
                 <xsl:if test="$DisplayBoilerPlate ">
                   <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
                 </xsl:if> 
                 <xsl:call-template name="NAME_TEMPLATE">
                   <xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
                   <xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
                   <xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
                 </xsl:call-template>
                 <xsl:if test="QUANTITY_ORDERED !=''"> 
                   <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                   (<xsl:value-of select="QUANTITY_ORDERED"/>)
                 </xsl:if>
                 <xsl:if test="AMOUNT_ORDERED !=''"> 
                   <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                   (<xsl:value-of select="AMOUNT_ORDERED"/>)
                 </xsl:if>
						     <fo:block/>
                 <xsl:value-of select="EMAIL_ADDRESS"/>
                 <fo:block/>
               </xsl:if>
             </fo:block>
           </fo:table-cell>
        </fo:table-row>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>

		
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>
		<fo:table-row >
			<fo:table-cell > <fo:block >  </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
				<xsl:if test="CONTRACTOR_LAST_NAME != '' or CONTRACTOR_FIRST_NAME !=''">
				<xsl:if test="$DisplayBoilerPlate ">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CONTRACTOR_NAME'][1]/TEXT"/>
				</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/>
				<xsl:call-template name="NAME_TEMPLATE">
				<xsl:with-param name="FIRST_NAME" select="CONTRACTOR_FIRST_NAME"/>
				<xsl:with-param name="LAST_NAME" select="CONTRACTOR_LAST_NAME"/>
				<xsl:with-param name="TITLE" select="CONTRACTOR_TITLE"/>
				</xsl:call-template> <fo:block/>
				</xsl:if>
				
				<!-- Start Date -->
				<fo:leader leader-pattern="space" leader-length="29.0pt"/>
				<xsl:if test="$DisplayBoilerPlate ">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_START_DATE'][1]/TEXT"/>
				</xsl:if> <fo:leader leader-pattern="space" leader-length="2.0pt"/>
				<xsl:value-of select="substring(START_DATE,1,11)"/> <fo:block/>

				<!-- end date -->
				<xsl:if test="EXPIRATION_DATE !=''">
				<fo:leader leader-pattern="space" leader-length="32.0pt"/>
				<xsl:if test="$DisplayBoilerPlate ">
					<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_END_DATE'][1]/TEXT"/>
				</xsl:if><fo:leader leader-pattern="space" leader-length="2.0pt"/>
				<xsl:value-of select="substring(EXPIRATION_DATE,1,11)"/>
				</xsl:if>
			</fo:block> </fo:table-cell>
		</fo:table-row>
			
		
		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="70mm"/>
				<fo:table-body> <fo:table-row> <fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_AMOUNT_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="TOTAL_LINE_AMOUNT"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_AMOUNT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="CANCELED_AMOUNT"/> <fo:block/>
				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:if>

		<!-- end of canceled details -->

		<!-- start of shipment details -->
		<xsl:for-each select="LINE_LOCATIONS/LINE_LOCATIONS_ROW">

      <xsl:variable name="use_line_ship_to" select="SHIPMENT_TYPE='PREPAYMENT' and ../../LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_LOCATION_ID=SHIP_TO_LOCATION_ID" />

    <!-- If complex work PO, we need to show all payitem information -->
    <xsl:choose>
      <xsl:when test="$IS_COMPLEX_WORK_PO">
        <fo:table-row  >
          <fo:table-cell xsl:use-attribute-sets="table.cell4"> 
            <fo:block xsl:use-attribute-sets="form_data3">
            <xsl:value-of select="../../LINE_NUM"/>-<xsl:value-of select="SHIPMENT_NUM"/>
            </fo:block>
          </fo:table-cell>
          <fo:table-cell xsl:use-attribute-sets="table.cell6">
            <fo:block xsl:use-attribute-sets="form_data"> 
              <xsl:value-of select="DESCRIPTION"/>
            </fo:block>
          </fo:table-cell>
          <fo:table-cell xsl:use-attribute-sets="table.cell6">
            <fo:block xsl:use-attribute-sets="form_data"> 
              <xsl:if test="PROMISED_DATE!=''">
                <fo:block/>
                  <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
                <fo:block/>
                <xsl:value-of select="PROMISED_DATE"/>
              </xsl:if>
              <xsl:if test="NEED_BY_DATE!=''">
                <fo:block/>
                <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
                <fo:block/>
                <xsl:value-of select="NEED_BY_DATE"/>
              </xsl:if> 
            </fo:block>
          </fo:table-cell>

          <fo:table-cell xsl:use-attribute-sets="table.cell5">
            <fo:block xsl:use-attribute-sets="form_data1">
              <xsl:if test="VALUE_BASIS='QUANTITY'">
                <xsl:value-of  select="QUANTITY"/>
              </xsl:if>
            </fo:block>
          </fo:table-cell>

          <fo:table-cell xsl:use-attribute-sets="table.cell6">
            <fo:block xsl:use-attribute-sets="form_data">
              <xsl:if test="VALUE_BASIS='QUANTITY'">
                <xsl:value-of  select="UNIT_MEAS_LOOKUP_CODE"/>
              </xsl:if>
            </fo:block>
          </fo:table-cell>

          <fo:table-cell xsl:use-attribute-sets="table.cell5">
            <fo:block xsl:use-attribute-sets="form_data1">
              <xsl:if test="$IS_COMPLEX_WORK_PO">
                <xsl:choose>
                  <xsl:when test="VALUE_BASIS = 'FIXED PRICE'">
                    <xsl:value-of select="AMOUNT"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="PRICE_OVERRIDE"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>           
            </fo:block>
          </fo:table-cell>
 
          <fo:table-cell xsl:use-attribute-sets="table.cell6">
            <fo:block xsl:use-attribute-sets="form_data"> 
              <xsl:value-of select="TAXABLE_FLAG"/> 
            </fo:block>
          </fo:table-cell>

          <fo:table-cell xsl:use-attribute-sets="table.cell5">
            <fo:block xsl:use-attribute-sets="form_data1"> 
              <xsl:value-of select="AMOUNT"/> 
            </fo:block>
          </fo:table-cell>

        </fo:table-row>
      </xsl:when>
      <xsl:otherwise>
        <fo:table-row>
          <fo:table-cell number-columns-spanned="8">
            <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/>
            </fo:block> 
          </fo:table-cell> 
        </fo:table-row>
      </xsl:otherwise>
    </xsl:choose>

		
		<fo:table-row  >
			<fo:table-cell > <fo:block >  </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
			<xsl:if test="$DisplayBoilerPlate ">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> <fo:block/>
			</xsl:if> <fo:block/>
			<xsl:choose>
        <xsl:when test="$use_line_ship_to">
          <fo:block/>
          <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_LINE_SHIP_TO'][1]/TEXT"/> 
          <fo:leader leader-pattern="space" leader-length="2.0pt"/>
          <xsl:value-of select="../../LINE_NUM"/>
        </xsl:when>
			<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
			<!-- Bug6762503 Added SHIP_TO_LOCATION_NAME in case there are multiple shipments-->
				<xsl:when test="$print_multiple ='Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
					<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_LOCATION_NAME"/>
					<xsl:if test="SHIP_TO_ADDRESS_LINE1 !=''"> <fo:block/><fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''"> <fo:block/><fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> <fo:block/> <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/> </xsl:if>
					<xsl:if test="SHIP_TO_ADDRESS_INFO !=''"> <fo:block/> <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/> </xsl:if>
					<xsl:if test="SHIP_TO_COUNTRY !=''"> <fo:block/> <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of select="SHIP_TO_COUNTRY"/>	</xsl:if>
				</xsl:when>
				<!-- start of bug#4568471/6829381 For one time shipments print the one time address-->					
				<xsl:when test="IS_SHIPMENT_ONE_TIME_LOC = 'Y'">
					<xsl:if test="ONE_TIME_ADDRESS_DETAILS !=''"> <fo:block/><xsl:value-of select="ONE_TIME_ADDRESS_DETAILS"/> </xsl:if>
				</xsl:when>
				<!-- end of bug#4568471/6829381 -->
				<xsl:otherwise>
					<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
				</xsl:otherwise> 
			</xsl:choose><fo:block/>
			<!-- for lines short text -->
			<xsl:for-each select="LINE_LOC_SHORT_TEXT/LINE_LOC_SHORT_TEXT_ROW">
				<!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                 <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                        <xsl:with-param name="ATTACHMENT_TEXT" select="SHORT_TEXT"/>
                                 </xsl:call-template>
			</xsl:for-each>

			<!-- for long text -->
                        <!--Bug #4654094-->
                        <xsl:variable name="lineLocationID" select="LINE_LOCATION_ID"/>
			<xsl:for-each select="$SHIPMENT_ATTACHMENTS_ROOT_OBJ">
				<xsl:if test="$lineLocationID = .">
					<xsl:variable name="line" select="position()" />
					 <!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                         <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                                <xsl:with-param name="ATTACHMENT_TEXT" select="../LONG_TEXT[$line]"/>
                                         </xsl:call-template>		
				</xsl:if>
			</xsl:for-each>
                        
                        <!-- PO Attachments support 11i.11: start-->
                        <!-- Table for displaying shipment Web and File attachments-->
                        <xsl:if test="count(LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW/WEB_PAGE) &gt; 0 or count(LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW/FILE_NAME) &gt; 0">
                        <fo:table table-layout="fixed" >
                                <fo:table-column column-width="38mm"/>
                                <fo:table-column column-width="100mm"/>
                                <fo:table-body>
                                <fo:table-row> <fo:table-cell>  
                                        <fo:block> 
                                        <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                        </xsl:if>
                                </fo:block> </fo:table-cell>
                                
                                <fo:table-cell>  <fo:block> 
                                        <!-- for lines URL attachments -->
                                        <xsl:for-each select="LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW">
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                        </xsl:for-each>

                                        <!-- for lines FILE attachments -->
                                        <xsl:for-each select="LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW">	
                                                <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                        </xsl:for-each>
                                </fo:block> </fo:table-cell>
                                </fo:table-row>
                                </fo:table-body>
                        </fo:table>
                        </xsl:if>
                        <!-- PO Attachments support 11i.11: end-->

			</fo:block> </fo:table-cell>
			
		</fo:table-row>

		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  
      <fo:block> 
        <xsl:choose>
          <xsl:when test="$IS_COMPLEX_WORK_PO">
            <fo:table>
              <fo:table-column column-width="78mm"/>
              <fo:table-body> <fo:table-row>
                <fo:table-cell xsl:use-attribute-sets="table.cell7">
                  <fo:block xsl:use-attribute-sets="form_data2" >
                    <fo:leader leader-pattern="space" leader-length="10.0pt"/> 
                    <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_CANCELED'][1]/TEXT"/>
                    <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                    <xsl:value-of select="substring(CANCEL_DATE,1,11)"/>
                    <fo:block/>
                    <!--Bug 5464968 Start: Matching basis may or may not be quantity -->
                    <fo:leader leader-pattern="space" leader-length="10.0pt"/>
                    <xsl:choose> 
                      <xsl:when test="MATCHING_BASIS = 'QUANTITY'">
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_PAYITEM_QTY'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="QUANTITY"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_PAYITEM_AMT'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="TOTAL_SHIPMENT_AMOUNT"/><!--Bug 5464968 Total Shipment Amount contains the original amount ordered -->
                      </xsl:otherwise>
                    </xsl:choose>
                    <fo:block/>
                    <fo:leader leader-pattern="space" leader-length="21.0pt"/>
                    <xsl:choose> 
                      <xsl:when test="MATCHING_BASIS = 'QUANTITY'">
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_QTY_CANCELED'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="QUANTITY_CANCELLED"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_AMT_CANCELED'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="AMOUNT_CANCELLED"/>
                      </xsl:otherwise>
                    </xsl:choose>
                    <!--Bug 5464968 End: Matching basis may or may not be quantity -->
                    <fo:block/>
                  </fo:block>
                </fo:table-cell>
              </fo:table-row></fo:table-body>
            </fo:table>
          </xsl:when>
          <xsl:otherwise>
    				<fo:table>
    				<fo:table-column column-width="5mm"/> <fo:table-column column-width="78mm"/>
    				<fo:table-body> <fo:table-row> 
    				<fo:table-cell> <fo:block> </fo:block> </fo:table-cell>
    				<fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2" >
    				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPMENT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
    				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_QTY_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="QUANTITY"/> <fo:block/>
    				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_QUANTITY_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="QUANTITY_CANCELLED"/> <fo:block/>
    				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
    				</fo:table>
          </xsl:otherwise>
      </xsl:choose>

			</fo:block> </fo:table-cell>
		</fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="8"  font-size="8pt"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<fo:table-row> <fo:table-cell number-columns-spanned="8" font-size="4pt"> <fo:block> <fo:leader leader-pattern="space" leader-length="0.0pt"/>  </fo:block></fo:table-cell> </fo:table-row>
		<!-- display deliver to details -->
		<xsl:for-each select="DISTRIBUTIONS/DISTRIBUTIONS_ROW">
		<xsl:if test="REQUESTER_DELIVER_FIRST_NAME !='' ">
			<fo:table-row>
			<fo:table-cell > <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
			<fo:table>
			<fo:table-column column-width="4mm"/><fo:table-column column-width="20mm"/> <fo:table-column column-width="100mm"/>
			<fo:table-body> 
				<fo:table-row> 
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell > <fo:block>
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
					</xsl:if> 
				</fo:block> </fo:table-cell>
			
				<fo:table-cell>  <fo:block>
					<!-- start of displaying deliver to details -->
					<xsl:call-template name="NAME_TEMPLATE">
					<xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
					<xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
					<xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
					</xsl:call-template>
					<xsl:if test="QUANTITY_ORDERED !=''"> 
						<fo:leader leader-pattern="space" leader-length="2.0pt"/> (<xsl:value-of select="QUANTITY_ORDERED"/>)
					</xsl:if>
					<xsl:if test="AMOUNT_ORDERED !=''"> 
						<fo:leader leader-pattern="space" leader-length="2.0pt"/> (<xsl:value-of select="AMOUNT_ORDERED"/>)
					</xsl:if>
					<fo:block/> <xsl:value-of select="EMAIL_ADDRESS"/>
					<!-- end of deliver details -->
					
				</fo:block> </fo:table-cell>
				</fo:table-row>
			</fo:table-body></fo:table>
			</fo:block> </fo:table-cell>
			</fo:table-row>
		</xsl:if>
		</xsl:for-each> 	<!-- end of distributions if-->
		</xsl:for-each> <!-- end of shipment if -->
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
	</xsl:if>




	<!-- For displaying Fixed price Lines -->
	<xsl:if test = "LINE_TYPE = 'FIXED PRICE' and PURCHASE_BASIS = 'SERVICES'">

		<fo:table-row  >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block xsl:use-attribute-sets="form_data3"> <xsl:value-of select="LINE_NUM"/> </fo:block> </fo:table-cell>
			<fo:table-cell  xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
				<!-- Supplier Item number -->
				<xsl:if test="VENDOR_PRODUCT_NUM !=''">
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SUPPLIER_ITEM'][1]/TEXT"/>
					</xsl:if> 
				<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="VENDOR_PRODUCT_NUM"/> <fo:block/> </xsl:if>
				
			</fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
        <xsl:choose>
          <xsl:when test="$line_delivery_count = 1">
            <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/PROMISED_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/PROMISED_DATE"/>
            </xsl:if>
            <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/NEED_BY_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/NEED_BY_DATE"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$shipment_count = 1">
            <xsl:if test="LINE_LOCATIONS/LINE_LOCATIONS_ROW/PROMISED_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/PROMISED_DATE"/>
            </xsl:if>
            <xsl:if test="LINE_LOCATIONS/LINE_LOCATIONS_ROW/NEED_BY_DATE!=''">
              <fo:block/>
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
              <fo:block/>
              <xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/NEED_BY_DATE"/>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
			</fo:block> </fo:table-cell>
			<fo:table-cell text-align="right"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell text-align="right"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>
			<fo:table-cell text-align="right"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell>

			<fo:table-cell xsl:use-attribute-sets="table.cell6"> <fo:block xsl:use-attribute-sets="form_data">
        <xsl:choose>
          <xsl:when test="$line_delivery_count = 1">
            <xsl:value-of  select="LINE_DELIVERY/LINE_DELIVERY_ROW/TAXABLE_FLAG"/>
          </xsl:when>
          <xsl:when test="$shipment_count = 1">
            <xsl:value-of  select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/TAXABLE_FLAG"/>
		  	   </xsl:when>
        </xsl:choose>
			</fo:block> </fo:table-cell>

			<fo:table-cell  xsl:use-attribute-sets="table.cell5">  <fo:block xsl:use-attribute-sets="form_data1"> 
				<xsl:value-of select="LINE_AMOUNT"/>
			</fo:block> </fo:table-cell>

		</fo:table-row>
<!-- Bug 11892229: Displaying Item description new row.  -->
		<fo:table-row >
			<fo:table-cell xsl:use-attribute-sets="table.cell4"> <fo:block> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> <fo:block xsl:use-attribute-sets="form_data">
				<xsl:value-of select="ITEM_DESCRIPTION"/>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<!-- end of Bug 11892229 -->	

		<!-- PO Attachments support 11i.11: Added the condition to check whether short or file or web attachments are not null -->
		<!-- Bug 5230892 Added the condition to check whether long attachments are null or not -->
                <xsl:if test="$PSA or $un_num or $hz_class or $vendor_note or $ga_flag or $short_attachments or $long_attachments or $file_attachments or $url_attachments or $IS_COMPLEX_WORK_PO">

                <fo:table-row> <fo:table-cell number-columns-spanned="7"> <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell> </fo:table-row>

		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6"> 
			<fo:block xsl:use-attribute-sets="form_data">

				<!-- to display the charge Account -->
				<xsl:if test="$charge_account">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_CHARGE_ACCOUNT'][1]/TEXT"/>
					</xsl:if>
					<xsl:choose>
					<xsl:when test="$distribution_count =1">
					        <!-- bug# 6074720:  given the complete path (instead of $distributions_root_obj/charge_account), to select correct charge account for each distribution -->
						<xsl:value-of select="LINE_LOCATIONS/LINE_LOCATIONS_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW/CHARGE_ACCOUNT"/> <fo:block/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_MULTIPLE'][1]/TEXT"/> <fo:block/>
					</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- end of charge account -->
				
				<!-- Un number row -->
				<xsl:if test="$un_num">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_UN_NUMBER'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="UN_NUMBER"/> <fo:block/>
				</xsl:if>
				<!-- end of Un number row -->

				<!-- Hazard class -->
				<xsl:if test="$hz_class">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_HAZARD_CLASS'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="HAZARD_CLASS"/> <fo:block/>
				</xsl:if>
				<!-- end of Hazard class -->

        <!-- Complex Work Line Info -->
        <xsl:if test="$IS_COMPLEX_WORK_PO">
          <xsl:if test="ADVANCE_AMOUNT!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ADVANCE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="ADVANCE_AMOUNT"/> 
          </xsl:if>
          <xsl:if test="RECOUPMENT_RATE!=''">                    
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RECOUPMENT_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="RECOUPMENT_RATE"/> 
          </xsl:if>
          <xsl:if test="PROGRESS_PAYMENT_RATE!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PROGRESS_PAYMENT_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="PROGRESS_PAYMENT_RATE"/> 
          </xsl:if>
          <!--Bug 5278399 - Added Max Retainage Amount -->
          <xsl:if test="MAX_RETAINAGE_AMOUNT!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_MAX_RETAINAGE_AMOUNT'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="MAX_RETAINAGE_AMOUNT"/> 
          </xsl:if>
          <xsl:if test="RETAINAGE_RATE!=''">
            <fo:block/>
            <xsl:if test="$DisplayBoilerPlate">
              <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_RETAINAGE_RATE'][1]/TEXT"/>
            </xsl:if>
            <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
            <xsl:value-of select="RETAINAGE_RATE"/> 
          </xsl:if>
          <fo:block/>
        </xsl:if>
        <!-- end of Complex Work Line Info -->


				<!-- Vendor Notes -->
				<xsl:if test="$vendor_note">
					<xsl:value-of select="NOTE_TO_VENDOR"/> <fo:block/>
				</xsl:if>
				<!-- end of note to vendor -->

				<!-- for lines short text -->
				<xsl:for-each select="LINE_SHORT_TEXT/LINE_SHORT_TEXT_ROW">	
					<xsl:value-of select ="SHORT_TEXT"/> <fo:block/>
				</xsl:for-each>

				<!-- for long text -->
				<xsl:for-each select="$LINE_LONG_ATTACHMENTS_ROOT_OBJ">
					<xsl:if test="$lineID = .">
						<xsl:variable name="line" select="position()" />
						<xsl:value-of select="../TEXT[$line]"/>	<fo:block/> 	
					</xsl:if>
				</xsl:for-each>
                                
                                <!-- PO Attachments support 11i.11: start-->
                                <!-- Table for displaying the line Web and File attachments -->
                                <xsl:if test="$file_attachments or $url_attachments">
                                <fo:table table-layout="fixed" >
                                        <fo:table-column column-width="35mm"/>
                                        <fo:table-column column-width="100mm"/>
                                        <fo:table-body>
                                        <fo:table-row> <fo:table-cell>  
                                                <fo:block> 
                                                <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                        <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                                </xsl:if>
                                        </fo:block> </fo:table-cell>
                                        
                                        <fo:table-cell>  
                                                <fo:block> 

                                                <!-- for lines URL attachments -->
                                                <xsl:for-each select="LINE_URL_ATTACHMENTS/LINE_URL_ATTACHMENTS_ROW">	
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/> <!-- Bug 5516488 -->
                                                </fo:basic-link>
                                                </xsl:for-each>

                                                <!-- for lines FILE attachments -->
                                                <xsl:for-each select="LINE_FILE_ATTACHMENTS/LINE_FILE_ATTACHMENTS_ROW">	
                                                        <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                                </xsl:for-each>
                                                </fo:block> </fo:table-cell>
		                        </fo:table-row> </fo:table-body> 
                                </fo:table>
                                </xsl:if>
                                <!-- PO Attachments support 11i.11: end-->


				<!-- Global agreement value -->
				<xsl:if test="$ga_flag">
					<xsl:if test="$DisplayBoilerPlate">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_REF_BPA'][1]/TEXT"/>
					</xsl:if>
					<fo:leader leader-pattern="space" leader-length="1.0pt"/> <xsl:value-of select="SEGMENT1"/> <fo:block/>
				</xsl:if>
				<!-- end of global agreement flag -->
					
			</fo:block> 
			</fo:table-cell>
		</fo:table-row>
		</xsl:if>

  <!-- Print line delivery details (for complex work financing case) -->
  <xsl:if test="$line_delivery_count = 1">
    <fo:table-row>
       <fo:table-cell >
         <fo:block >
           <fo:leader leader-pattern="space" leader-length="1.0pt"/>
         </fo:block>
       </fo:table-cell>
       <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">
         <fo:block xsl:use-attribute-sets="form_data">
           <xsl:if test="$DisplayBoilerPlate ">
             <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> 
             <fo:block/>
           </xsl:if>
           <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE1"/>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE2 !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE2"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE3 !=''"> 
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_LINE3"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_INFO !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_ADDRESS_INFO"/>
           </xsl:if>
           <xsl:if test="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_COUNTRY !=''">
             <fo:block/>
             <xsl:value-of select="LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_COUNTRY"/>
           </xsl:if>
         </fo:block>
       </fo:table-cell>
    </fo:table-row>
  </xsl:if>

  <!-- Print line delivery distribution information (for complex work financing case) -->
  <xsl:if test="$line_delivery_distribution_count &gt; 0">
    <xsl:for-each select="LINE_DELIVERY/LINE_DELIVERY_ROW/DISTRIBUTIONS/DISTRIBUTIONS_ROW">
      <xsl:if test="REQUESTER_DELIVER_FIRST_NAME !='' ">
        <fo:table-row>
          <fo:table-cell > <fo:block /> </fo:table-cell>
           <fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">
             <fo:block xsl:use-attribute-sets="form_data"> 
               <xsl:if test="DELIVER_TO_PERSON_ID !=''">				
                 <xsl:if test="$DisplayBoilerPlate ">
                   <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
                 </xsl:if> 
                 <xsl:call-template name="NAME_TEMPLATE">
                   <xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
                   <xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
                   <xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
                 </xsl:call-template>
                 <xsl:if test="QUANTITY_ORDERED !=''"> 
                   <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                   (<xsl:value-of select="QUANTITY_ORDERED"/>)
                 </xsl:if>
                 <xsl:if test="AMOUNT_ORDERED !=''"> 
                   <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                   (<xsl:value-of select="AMOUNT_ORDERED"/>)
                 </xsl:if>
						     <fo:block/>
                 <xsl:value-of select="EMAIL_ADDRESS"/>
                 <fo:block/>
               </xsl:if>
             </fo:block>
           </fo:table-cell>
        </fo:table-row>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>


		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  <fo:block> 
				<fo:table>
				<fo:table-column column-width="70mm"/>
				<fo:table-body> <fo:table-row> <fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_LINE_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_AMOUNT_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="TOTAL_LINE_AMOUNT"/> <fo:block/>
				<fo:leader leader-pattern="space" leader-length="24.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_AMOUNT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="CANCELED_AMOUNT"/> <fo:block/>
				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
				</fo:table>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="8"  font-size="8pt"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<fo:table-row> <fo:table-cell number-columns-spanned="8" font-size="4pt"> <fo:block> <fo:leader leader-pattern="space" leader-length="0.0pt"/>  </fo:block></fo:table-cell> </fo:table-row>

		<!-- start of shipment details -->
		<xsl:for-each select="LINE_LOCATIONS/LINE_LOCATIONS_ROW">

      <xsl:variable name="use_line_ship_to" select="SHIPMENT_TYPE='PREPAYMENT' and ../../LINE_DELIVERY/LINE_DELIVERY_ROW/SHIP_TO_LOCATION_ID=SHIP_TO_LOCATION_ID" />

		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block font-size="8pt"> <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row> 
		<fo:table-row  >
      <fo:table-cell xsl:use-attribute-sets="table.cell4"> 
        <fo:block xsl:use-attribute-sets="form_data3">
          <!-- bug#13359008 : Removed condition to display shipment num only in case of complex PO. -->
            <xsl:value-of select="../../LINE_NUM"/>-<xsl:value-of select="SHIPMENT_NUM"/>
        </fo:block> 
      </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
        <xsl:choose>
          <xsl:when test="$IS_COMPLEX_WORK_PO">
            <xsl:value-of select="DESCRIPTION"/>
           </xsl:when>
           <xsl:otherwise>
             <fo:table>
               <fo:table-column column-width="3.5mm"/> <fo:table-column column-width="34.5mm"/>
        			 <fo:table-body>
               <fo:table-row >
                 <fo:table-cell > <fo:block>  </fo:block> </fo:table-cell>
                 <fo:table-cell > <fo:block>  
                   <xsl:if test="$DisplayBoilerPlate ">
             		     <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> <fo:block/>
              	   </xsl:if>
                   <!-- bug#3594831: added drop_ship ship to details -->
                   <!-- Bug3670603: Address details should be displayed before Promised and Need by date -->
                   <xsl:if test="DROP_SHIP_FLAG='Y'">
              				<xsl:if test="SHIP_CUST_NAME !=''"> <xsl:value-of select="SHIP_CUST_NAME"/>  </xsl:if>
              				<xsl:if test="SHIP_CONT_NAME !=''"> <fo:block/> <xsl:value-of select="SHIP_CONT_NAME"/>  </xsl:if>
               				<xsl:if test="SHIP_CONT_EMAIL !=''"> <fo:block/><xsl:value-of select="SHIP_CONT_EMAIL"/> </xsl:if>
               				<xsl:if test="SHIP_CONT_PHONE !=''">
              					<xsl:if test="$DisplayBoilerPlate ">
            						 <fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TELEPHONE'][1]/TEXT"/>:
              					</xsl:if>
              					<fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="SHIP_CONT_PHONE"/> 
              				</xsl:if>
              				<xsl:if test="SHIP_TO_CONTACT_FAX !=''"> 
              					<xsl:if test="$DisplayBoilerPlate ">
          	   					 <fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_FAX'][1]/TEXT"/>:
              					</xsl:if>
              					 <fo:leader leader-pattern="space" leader-length="3.0pt"/> <xsl:value-of select="SHIP_TO_CONTACT_FAX"/> 
              				</xsl:if>
            			 </xsl:if>
              		 <!-- end of bug#3594831-->
             			<xsl:choose>
						<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
						<!-- Bug6762503 Added SHIP_TO_LOCATION_NAME in case there are multiple shipments-->
             				<xsl:when test="$print_multiple ='Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
							<fo:block/> <xsl:value-of select="SHIP_TO_LOCATION_NAME"/>
							<xsl:if test="SHIP_TO_ADDRESS_LINE1 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/> </xsl:if>
          		  			<xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/> </xsl:if>
          			  		<xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> <fo:block/><xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/> </xsl:if>
           				  	<xsl:if test="SHIP_TO_ADDRESS_INFO !=''"> <fo:block/> <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/> </xsl:if>
           					  <xsl:if test="SHIP_TO_COUNTRY !=''"> <fo:block/><xsl:value-of select="SHIP_TO_COUNTRY"/>	</xsl:if>
            				</xsl:when>
							<!-- start of bug#4568471/6829381 For one time shipments print the one time address-->					
							<xsl:when test="IS_SHIPMENT_ONE_TIME_LOC = 'Y'">
								<xsl:if test="ONE_TIME_ADDRESS_DETAILS !=''"> <fo:block/><xsl:value-of select="ONE_TIME_ADDRESS_DETAILS"/> </xsl:if>
							</xsl:when>
							<!-- end of bug#4568471/6829381 -->
            				<xsl:otherwise>
            					<xsl:if test="$shipment_count &gt; 1">
            					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
            					</xsl:if>
            				</xsl:otherwise>
            			</xsl:choose> 
            			</fo:block> </fo:table-cell>
          			</fo:table-row>
         			</fo:table-body>
    			  </fo:table>
			      <!-- end of bug#3594831-->           
          </xsl:otherwise>
        </xsl:choose>
			</fo:block> </fo:table-cell>

			<xsl:if test="$IS_COMPLEX_WORK_PO or ($shipment_count &gt; 1)">
				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<!-- Bug3670603: As per the bug Promised and need by date are added. -->
					<xsl:if test="PROMISED_DATE!=''">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_PROMISED_DATE'][1]/TEXT"/>
					<fo:block/> <xsl:value-of select="PROMISED_DATE"/>
					</xsl:if>
					<xsl:if test="NEED_BY_DATE!=''">
					<fo:block/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_WF_NOTIF_NEEDBY_DATE'][1]/TEXT"/>
					<fo:block/> <xsl:value-of select="NEED_BY_DATE"/>
					</xsl:if> 
				</fo:block> </fo:table-cell>

       <fo:table-cell xsl:use-attribute-sets="table.cell5">
         <fo:block xsl:use-attribute-sets="form_data1">
           <xsl:if test="VALUE_BASIS='QUANTITY'">
             <xsl:value-of  select="QUANTITY"/>
           </xsl:if>
         </fo:block>
       </fo:table-cell>

       <fo:table-cell xsl:use-attribute-sets="table.cell6">
         <fo:block xsl:use-attribute-sets="form_data">
           <xsl:if test="VALUE_BASIS='QUANTITY'">
             <xsl:value-of  select="UNIT_MEAS_LOOKUP_CODE"/>
           </xsl:if>
         </fo:block>
       </fo:table-cell>

       <fo:table-cell xsl:use-attribute-sets="table.cell5">
         <fo:block xsl:use-attribute-sets="form_data1">
           <xsl:if test="$IS_COMPLEX_WORK_PO">
             <xsl:choose>
               <xsl:when test="VALUE_BASIS = 'FIXED PRICE'">
                 <xsl:value-of select="AMOUNT"/>
               </xsl:when>
               <xsl:otherwise>
                 <xsl:value-of select="PRICE_OVERRIDE"/>
               </xsl:otherwise>
             </xsl:choose>
           </xsl:if>           
         </fo:block>
       </fo:table-cell>


				<fo:table-cell xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
					<xsl:value-of select="TAXABLE_FLAG"/> 
				</fo:block> </fo:table-cell>

				<fo:table-cell xsl:use-attribute-sets="table.cell5">  <fo:block xsl:use-attribute-sets="form_data1"> 
				<xsl:value-of select="AMOUNT"/> 
				</fo:block> </fo:table-cell>

			</xsl:if>
		</fo:table-row>
	
	<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->                
   <!-- Bug#3823799: to display Ship to address at top of page which spans more than one column-->
   <xsl:if test="$print_multiple != 'Y' and $shipment_count = 1 and not($IS_COMPLEX_WORK_PO) and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
		 <fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <fo:page-number-citation ref-id="page_ref" />
			</fo:block> </fo:table-cell>
		 </fo:table-row>
   </xsl:if>

   <!-- Print complex work payitem ship-to information -->
   <xsl:if test="$IS_COMPLEX_WORK_PO">
     <fo:table-row>
       <fo:table-cell >
         <fo:block >
           <fo:leader leader-pattern="space" leader-length="1.0pt"/>
         </fo:block>
       </fo:table-cell>
       <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">
         <fo:block xsl:use-attribute-sets="form_data">
           <xsl:if test="$DisplayBoilerPlate ">
             <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIP_TO'][1]/TEXT"/> 
             <fo:block/>
           </xsl:if>
           <xsl:choose>
			<!-- bug#4568471/6829381Add extra check so that the shipments which have one time address as ship-to will not be considered-->
             <xsl:when test="$print_multiple != 'Y' and IS_SHIPMENT_ONE_TIME_LOC != 'Y'">
               <fo:block/>
                 <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_SHIP_ADDRESS_TOP'][1]/TEXT"/> 
                 <fo:leader leader-pattern="space" leader-length="2.0pt"/>
                 <fo:page-number-citation ref-id="page_ref" />
             </xsl:when>
             <xsl:when test="$use_line_ship_to">
               <fo:block/>
                 <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_USE_LINE_SHIP_TO'][1]/TEXT"/> 
                 <fo:leader leader-pattern="space" leader-length="2.0pt"/>
                 <xsl:value-of select="../../LINE_NUM"/>
             </xsl:when>
             <xsl:otherwise>
               <fo:block/>
               <xsl:value-of select="SHIP_TO_ADDRESS_LINE1"/>
               <xsl:if test="SHIP_TO_ADDRESS_LINE2 !=''">
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_ADDRESS_LINE2"/>
               </xsl:if>
               <xsl:if test="SHIP_TO_ADDRESS_LINE3 !=''"> 
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_ADDRESS_LINE3"/>
               </xsl:if>
               <xsl:if test="SHIP_TO_ADDRESS_INFO !=''">
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_ADDRESS_INFO"/>
               </xsl:if>
               <xsl:if test="SHIP_TO_COUNTRY !=''">
                 <fo:block/>
                 <xsl:value-of select="SHIP_TO_COUNTRY"/>
               </xsl:if>
             </xsl:otherwise>
           </xsl:choose>
         </fo:block>
       </fo:table-cell>
     </fo:table-row>
   </xsl:if>

		<!-- for lines short text -->
		<xsl:for-each select="LINE_LOC_SHORT_TEXT/LINE_LOC_SHORT_TEXT_ROW">
		<fo:table-row >
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
                                <!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                 <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                        <xsl:with-param name="ATTACHMENT_TEXT" select="SHORT_TEXT"/>
                                 </xsl:call-template>
			</fo:block> </fo:table-cell>
		</fo:table-row>
		</xsl:for-each>

		<!-- for long text -->
                <!--Bug #4654094-->
                <xsl:variable name="lineLocationID" select="LINE_LOCATION_ID"/>
		<xsl:for-each select="$SHIPMENT_ATTACHMENTS_ROOT_OBJ">
			<xsl:if test="$lineLocationID = .">
				<xsl:variable name="line" select="position()" />
				<fo:table-row >
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7">  <fo:block xsl:use-attribute-sets="form_data"> 
					<!--Bug#4221678: Call LINE_LOCATION_ATTACHMENT_TEMP template to display the attachment -->
                                         <xsl:call-template name="LINE_LOCATION_ATTACHMENT_TEMP">
                                                <xsl:with-param name="ATTACHMENT_TEXT" select="../LONG_TEXT[$line]"/>
                                         </xsl:call-template>
				</fo:block> </fo:table-cell>
		</fo:table-row>
			</xsl:if>
		</xsl:for-each>
                
                <!-- PO Attachments support 11i.11: start-->
                <!-- Table for displaying the shipments Web and File attachments -->
                <xsl:if test="count(LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW/WEB_PAGE) &gt; 0 or count(LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW/FILE_NAME) &gt; 0">
                <fo:table-row >
                        <fo:table-cell > <fo:block > </fo:block> </fo:table-cell>
                        <fo:table-cell xsl:use-attribute-sets="table.cell6" number-columns-spanned="7"> 
                        <fo:block xsl:use-attribute-sets="form_data"> 
                        <fo:table table-layout="fixed" >
                                <fo:table-column column-width="36mm"/>
                                <fo:table-column column-width="100mm"/>
                                <fo:table-body>
                                <fo:table-row> <fo:table-cell>  
                                        <fo:block> 
                                        <xsl:if test="$DisplayBoilerPlate = 'Y' ">
                                                <fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_REFERENCE_DOCUMENTS'][1]/TEXT"/> 
                                        </xsl:if>
                                </fo:block> </fo:table-cell>
                                
                                <fo:table-cell>  <fo:block> 
                                        <!-- for lines URL attachments -->
                                        <xsl:for-each select="LINE_LOC_URL_ATTACHMENTS/LINE_LOC_URL_ATTACHMENTS_ROW">
                                                <fo:basic-link show-destination="new" color="#0000ff" text-decoration="underline">
                                                        <xsl:attribute name="external-destination">
                                                                <xsl:call-template name="webUrl">
                                                                        <xsl:with-param name="URL_LOCATION" select="WEB_PAGE"/>
                                                                </xsl:call-template>
                                                        </xsl:attribute> 
                                                        <xsl:value-of select="WEB_PAGE"/> <fo:block/>
                                                </fo:basic-link>
                                        </xsl:for-each>

                                        <!-- for lines FILE attachments -->
                                        <xsl:for-each select="LINE_LOC_FILE_ATTACHMENTS/LINE_LOC_FILE_ATTACHMENTS_ROW">	
                                                <xsl:value-of select ="FILE_NAME"/>  <fo:block/>
                                        </xsl:for-each>
                                </fo:block> </fo:table-cell>
                                </fo:table-row>
                                </fo:table-body>
                        </fo:table>
                        </fo:block> </fo:table-cell>
                </fo:table-row>
                </xsl:if>
                <!-- PO Attachments support 11i.11: end-->
		
		<!-- display canceled details -->
		<xsl:if test="CANCEL_FLAG='Y'">
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		<fo:table-row  keep-together.within-page="always">
			<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7">  
      <fo:block> 
        <xsl:choose>
          <xsl:when test="$IS_COMPLEX_WORK_PO">
            <fo:table>
              <fo:table-column column-width="78mm"/>
              <fo:table-body> <fo:table-row>
                <fo:table-cell xsl:use-attribute-sets="table.cell7">
                  <fo:block xsl:use-attribute-sets="form_data2" >
                    <fo:leader leader-pattern="space" leader-length="10.0pt"/> 
                    <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_CANCELED'][1]/TEXT"/>                    <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                    <xsl:value-of select="substring(CANCEL_DATE,1,11)"/>
                    <!--Bug 5464968 Start: Matching basis may or may not be quantity -->
                    <fo:leader leader-pattern="space" leader-length="10.0pt"/>
                    <xsl:choose> 
                      <xsl:when test="MATCHING_BASIS = 'QUANTITY'">
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_PAYITEM_QTY'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="QUANTITY"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_PAYITEM_AMT'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="TOTAL_SHIPMENT_AMOUNT"/><!--Bug 5464968 Total Shipment Amount contains the original amount ordered -->
                      </xsl:otherwise>
                    </xsl:choose>
                    <fo:block/>
                    <fo:leader leader-pattern="space" leader-length="21.0pt"/>
                    <xsl:choose> 
                      <xsl:when test="MATCHING_BASIS = 'QUANTITY'">
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_QTY_CANCELED'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="QUANTITY_CANCELLED"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAYITEM_AMT_CANCELED'][1]/TEXT"/>
                        <fo:leader leader-pattern="space" leader-length="2.0pt"/> 
                        <xsl:value-of select="AMOUNT_CANCELLED"/>
                      </xsl:otherwise>
                    </xsl:choose>
                    <!--Bug 5464968 End: Matching basis may or may not be quantity -->
                    <fo:block/>
                  </fo:block>
                </fo:table-cell>
              </fo:table-row></fo:table-body>
            </fo:table>
          </xsl:when>
          <xsl:otherwise>
	     			<fo:table>
     				<fo:table-column column-width="5mm"/> <fo:table-column column-width="78mm"/>
			     	<fo:table-body> <fo:table-row> 
     				<fo:table-cell> <fo:block> </fo:block> </fo:table-cell>
     				<fo:table-cell xsl:use-attribute-sets="table.cell7">  <fo:block xsl:use-attribute-sets="form_data2">
    				<fo:leader leader-pattern="space" leader-length="10.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_SHIPMENT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="substring(CANCEL_DATE,1,11)"/> <fo:block/>
    				<fo:leader leader-pattern="space" leader-length="20.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_ORIGINAL_AMOUNT_ORDERED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="TOTAL_SHIPMENT_AMOUNT"/> <fo:block/>
     				<fo:leader leader-pattern="space" leader-length="40.0pt"/> <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_AMOUNT_CANCELED'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="AMOUNT_CANCELLED"/> <fo:block/>
    				</fo:block> </fo:table-cell> </fo:table-row> </fo:table-body>
     				</fo:table>
         </xsl:otherwise>
      </xsl:choose>

			</fo:block> </fo:table-cell>
		</fo:table-row>
		<fo:table-row> <fo:table-cell number-columns-spanned="8"  font-size="8pt"> <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
		</xsl:if>
		<!-- end of canceled details -->

		<fo:table-row> <fo:table-cell number-columns-spanned="8" font-size="4pt"> <fo:block> <fo:leader leader-pattern="space" leader-length="0.0pt"/>  </fo:block></fo:table-cell> </fo:table-row>

		<!-- display deliver to details -->
		<xsl:for-each select="DISTRIBUTIONS/DISTRIBUTIONS_ROW">
		<xsl:if test="REQUESTER_DELIVER_FIRST_NAME !='' ">
			<fo:table-row>
			<fo:table-cell > <fo:block> <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
			<fo:table-cell number-columns-spanned="7" xsl:use-attribute-sets="table.cell6">  <fo:block xsl:use-attribute-sets="form_data"> 
			<fo:table>
			<fo:table-column column-width="4mm"/><fo:table-column column-width="20mm"/> <fo:table-column column-width="100mm"/>
			<fo:table-body> 
				<fo:table-row> 
				<fo:table-cell > <fo:block > <fo:leader leader-pattern="space" leader-length="1.0pt"/> </fo:block> </fo:table-cell>
				<fo:table-cell > <fo:block>
					<xsl:if test="$DisplayBoilerPlate ">
						<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_DELIVER_TO_LOCATION'][1]/TEXT"/>
					</xsl:if> 
				</fo:block> </fo:table-cell>
			
				<fo:table-cell>  <fo:block>
					<!-- start of displaying deliver to details -->
					<xsl:call-template name="NAME_TEMPLATE">
					<xsl:with-param name="FIRST_NAME" select="REQUESTER_DELIVER_FIRST_NAME"/>
					<xsl:with-param name="LAST_NAME" select="REQUESTER_DELIVER_LAST_NAME"/>
					<xsl:with-param name="TITLE" select="REQUESTER_DELIVER_TITLE"/>
					</xsl:call-template>
					<xsl:if test="QUANTITY_ORDERED !=''"> 
					<fo:leader leader-pattern="space" leader-length="2.0pt"/> (<xsl:value-of select="QUANTITY_ORDERED"/>)
					</xsl:if>
					<xsl:if test="AMOUNT_ORDERED !=''"> 
					<fo:leader leader-pattern="space" leader-length="2.0pt"/> (<xsl:value-of select="AMOUNT_ORDERED"/>)
					</xsl:if>
					<fo:block/> <xsl:value-of select="EMAIL_ADDRESS"/>
					<!-- end of deliver details -->
					
				</fo:block> </fo:table-cell>
				</fo:table-row>
			</fo:table-body></fo:table>
			</fo:block> </fo:table-cell>
			</fo:table-row>
		</xsl:if>
		</xsl:for-each> 	<!-- end of distributions if-->
		</xsl:for-each> <!-- end of shipment if -->
		<fo:table-row> <fo:table-cell number-columns-spanned="8"> <fo:block > <fo:leader leader-pattern="space" leader-length="2.0pt"/> </fo:block>	</fo:table-cell> </fo:table-row>
	</xsl:if>

</xsl:for-each> <!-- end of Line, shipments and distributions details -->

<fo:table-row> 
	<fo:table-cell  number-columns-spanned="8" xsl:use-attribute-sets="table_cell_heading1" ><fo:block xsl:use-attribute-sets="form_data">
		<xsl:if test="$DisplayBoilerPlate ">
			<xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_TOTAL'][1]/TEXT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/>
		</xsl:if>
		
		<fo:inline xsl:use-attribute-sets="legal_details_style">
			 <xsl:value-of select="TOTAL_AMOUNT"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> (<xsl:value-of select="CURRENCY_CODE"/>)
		</fo:inline>
	</fo:block> </fo:table-cell> 
</fo:table-row>

</fo:table-body>
</fo:table>

	
</xsl:if>

<!-- Display text file data in new page -->

<xsl:if test="TEXT_FILE !='' ">
<fo:block xsl:use-attribute-sets="form_data"> 
	<xsl:value-of select="TEXT_FILE"/>
</fo:block>
</xsl:if>
<fo:block id="last-page" >
	
</fo:block>

</xsl:template>


<xsl:template name="NAME_TEMPLATE">
	<xsl:param name="FIRST_NAME"/>
	<xsl:param name="LAST_NAME"/>
        <xsl:param name="LOCATION_CODE"/>
	<xsl:param name="TITLE"/>
	<xsl:if test="$LAST_NAME != ''"> <xsl:value-of select="$LAST_NAME"/>,</xsl:if>  <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$TITLE"/> <fo:leader leader-pattern="space" leader-length="2.0pt"/> <xsl:value-of select="$FIRST_NAME"/> 
        <xsl:if test="$LOCATION_CODE != ''"> <fo:leader leader-pattern="space" leader-length="2.0pt"/> / <xsl:value-of select="$LOCATION_CODE"/> </xsl:if>
</xsl:template>

<!-- Template for displaying the page numbers -->
<!-- bug#3836856: Template for displaying the page numbers at right bottom of the page -->
<xsl:template name="pageNumber">
	<xsl:variable name="po_page">
	   <xsl:value-of  select="$BOILER_PLATE_MESSAGES_OBJ[MESSAGE='PO_FO_PAGE'][1]/TEXT"/>
	</xsl:variable>
	<!-- Get the String before the PAGE_NUM token -->
	<xsl:variable name="string_before_page_num">
	    <xsl:value-of select="substring-before($po_page,'&amp;PAGE_NUM')"/>
	</xsl:variable>
	<!-- Get the String after the PAGE_NUM token -->
	<xsl:variable name="string_after_page_num">
	    <xsl:value-of select="substring-after($po_page,'&amp;PAGE_NUM')"/>
	</xsl:variable>
	<!-- If the String after PAGE_NUM token contains the token END_PAGE -->
	<xsl:if test="contains($string_after_page_num,'&amp;END_PAGE')">
	    <xsl:variable name="string_before_end_page">
		<xsl:value-of select="substring-before($string_after_page_num,'&amp;END_PAGE')"/>
	    </xsl:variable>
	    <xsl:variable name="string_after_end_page">
		<xsl:value-of select="substring-after($string_after_page_num,'&amp;END_PAGE')"/>
	    </xsl:variable>
	    <xsl:value-of select="$string_before_page_num"/><fo:page-number/>
	    <xsl:value-of select="$string_before_end_page"/>
	    <xsl:choose>
		<xsl:when test="$ROOT_OBJ/WITH_TERMS='N' or $ROOT_OBJ/IS_ATTACHED_DOC='Y'">
		    <fo:page-number-citation ref-id="last-page"/> 
		</xsl:when>
		<xsl:otherwise>
		    <fo:page-number-citation ref-id="eod"/> 
		</xsl:otherwise>
	    </xsl:choose>
	    <xsl:value-of select="$string_after_end_page"/>
	</xsl:if>
	<!-- If the String before PAGE_NUM token contains the token END_PAGE -->
	<xsl:if test="contains($string_before_page_num,'&amp;END_PAGE')">
	    <xsl:variable name="string_before_end_page">
		<xsl:value-of select="substring-before($string_before_page_num,'&amp;END_PAGE')"/>
	    </xsl:variable>
	    <xsl:variable name="string_after_end_page">
		<xsl:value-of select="substring-after($string_before_page_num,'&amp;END_PAGE')"/>
	    </xsl:variable>
	    <xsl:value-of select="$string_before_end_page"/>
	    <xsl:choose>
		<xsl:when test="$CON_TERMS_EXIST_FLAG='N' or $ROOT_OBJ/IS_ATTACHED_DOC='Y'">
		    <fo:page-number-citation ref-id="last-page"/> 
		</xsl:when>
		<xsl:otherwise>
		    <fo:page-number-citation ref-id="eod"/> 
		</xsl:otherwise>
	    </xsl:choose>
	    <xsl:value-of select="$string_after_end_page"/>
	    <fo:page-number/><xsl:value-of select="$string_after_page_num"/>
        </xsl:if> 
  </xsl:template>

<xsl:template name="webUrl">
        <xsl:param name="URL_LOCATION"/>
        <xsl:choose>
        <xsl:when test="starts-with($URL_LOCATION,'http')">
                <xsl:value-of select="$URL_LOCATION"/>
        </xsl:when>
        <xsl:otherwise>
                http://<xsl:value-of select="$URL_LOCATION"/>
        </xsl:otherwise>
        </xsl:choose>
</xsl:template>

<!--Bug#4221678: The wrapped attachment line is not aligned to start of the line. 
                 Created the template to display the attachment in new table -->
<xsl:template name="LINE_LOCATION_ATTACHMENT_TEMP">
        <xsl:param name="ATTACHMENT_TEXT"/>
        <fo:table>
        <fo:table-column column-width="3.5mm"/> <fo:table-column column-width="163.5mm"/>
        <fo:table-body>
        <fo:table-row >
        <fo:table-cell > <fo:block>  </fo:block> </fo:table-cell>
        <fo:table-cell > <fo:block> <xsl:value-of select ="$ATTACHMENT_TEXT"/> 
        </fo:block> </fo:table-cell>
        </fo:table-row>
        </fo:table-body>
        </fo:table> 
</xsl:template>
</xsl:stylesheet>
