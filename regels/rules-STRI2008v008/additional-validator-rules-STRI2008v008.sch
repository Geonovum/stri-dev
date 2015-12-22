<?xml version="1.0" encoding="UTF-8"?>
<!--
/*******************************************************************************
 * File: additional-validator-rules-STRI2008v008.sch
 *
 * (C) CGI, 2013
 *
 *
 * Info:
 * Schematron Validation Document for STRI2008
 *
 * History:
 * 16-12-2008   RD  Initial version
 * 02-02-2009   RD  Bugfix: XPath expression for GeleideFormulier element
 *                  Check of all elements in Onderdelen element for 
 *                  corresponding signature Reference in a GeleideFormulier.
 *                  Check uniqueness of certificate.
 * 17-02-2009   RD  Check for documents of type Gebiedsbesluit
 *                  Checks AD4A, AD4B, AD4C and AD4D updated because of missing document types
 * 30-02-2009   RD  Bugfixes in AD7B, AD7C, AD7D and AD7E.
 *                  Check AD7D now only permits 1 X509Data element inside the KeyInfo element.
 *                  Error code AD8 renamed to AD8A because of extra check.
 *                  Security checks added: AD8B, AD8C.
 *                  Security checks added to prevent DOS attacks using Transforms: AD9A, AD9B, AD9C, AD9D.
 *                  Security checks added to prevent DOS attacks and security attacks: AD10A, AD10B, AD10C, AD10D, AD10E.
 * 27-04-2009   RD  Check for attribute overheidsCode also applicable for GeleideFormulier
 * 06-07-2009   RD  Rule AD0: Uniqueness test for plan Id in a manifest
 * 16-02-2009   RD  Rule AD6 adapted. Https is also a permitted choice.
 * 06-06-2013   MO  MO  Added validation for 'geldende stri norm voor manifest' RO standaarden 2012 per 1-7-2013
 ******************************************************************************/
-->
<iso:schema xmlns:iso="http://purl.oclc.org/dsdl/schematron"
			xml:lang="en">  <!-- ISO Schematron 1.6 namespace -->

	<!-- <iso:title>Schematron validaties voor PCP2008</iso:title>-->
	<!-- Titel weggehaald om geen output te hebben als er geen fout is -->
	<!-- De validator concludeert daaruit dat er geen fout en dus een valide bestand is -->

	<iso:ns prefix="gml" uri="http://www.opengis.net/gml"/>
	<iso:ns prefix="ds" uri="http://www.w3.org/2000/09/xmldsig#"/>
	<iso:ns prefix="stri" uri="http://www.geonovum.nl/stri/2008/1"/>

	<iso:ns prefix="regexp" uri="nl.vrom.roo.util.Regexp"/>
		
	<iso:let name="lowercaseChars" value="'abcdefghijklmnopqrstuvwxyz'"/>
	<iso:let name="uppercaseChars" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
	
	<!-- Definieer reguliere expressies om PlanIdn en bestandsnamen te valideren -->

	<iso:let name="ankerRegexp" value="'(#.*)?'"/>
	
	<iso:let name="idnCheckRegexp" value="'NL\.IMRO\.[0-9]{4}\.[A-Za-z0-9]{1,18}-[A-Za-z0-9]{4}'"/>

	<iso:let name="stri2008CheckRegexp" value="'((r|rb|t|tb|i|vb|pt|d|db|b|bb|g)_)?NL\.IMRO\.[0-9]{4}\.[A-Za-z0-9]{1,18}-[A-Za-z0-9]{4}(_[A-Za-z0-9\.]{1,20})?\.(html|htm|xhtml|xml|gml|pdf|png|jpg|jpeg)'"/>
	
	
	<iso:pattern name="unieke_identificatie">
		<!-- De planId moet uniek zijn binnen een manifest. -->
		<iso:rule context="/stri:Manifest/stri:Plan">
		
			<iso:let name="Id" value="@Id"/>
			
			<iso:assert test="not(following-sibling::stri:Plan/@Id=$Id)">
Foutcode AD0: PlanId "<iso:value-of select="$Id"/>" komt meerdere malen voor binnen het manifest.
De Id van een plan moet uniek zijn binnen een manifest.
			</iso:assert>
		</iso:rule>
	</iso:pattern>


	<iso:pattern name="ManifestAttributenCheck">

		<iso:rule context="/f | /stri:GeleideFormulier">
			
			<iso:let name="overheidsCode" value="@OverheidsCode"/>
			
			<iso:assert test="regexp:matches($overheidsCode,'[0-9]{4}')">
Foutcode AD1A: OverheidsCode (huidige waarde '<iso:value-of select="$overheidsCode"/>') moet uit 4 cijfers bestaan. 
			</iso:assert>
			
			<iso:let name="naamOverheid" value="@NaamOverheid"/>
			
			<iso:assert test="string-length($naamOverheid) &gt; 0">
Foutcode AD1B: NaamOverheid moet een naam zijn en geen lege string.
			</iso:assert>
		</iso:rule>
	</iso:pattern>


	<iso:pattern name="Checks_Per_Plan">

		<iso:rule context="//stri:Plan">

			<!--  Validatie van planId: Foutcode AD2 -->
			<iso:let name="detectedPlanId" value="@Id"/>

			<iso:assert test="regexp:matches($detectedPlanId,$idnCheckRegexp)">
Foutcode AD2: identificatie (huidige waarde "<iso:value-of select="$detectedPlanId"/>") 
voldoet niet aan de conventies van STRI2008 voor plan identificatie.
(PlanIdn regexp: '<iso:value-of select="$idnCheckRegexp"/>')
			</iso:assert>

			<!-- Validatie van plantypes: Foutcode AD4 -->
		
			<!-- detectedPlanId is nodig voor extra bestandsnaamvalidatie: planId moet in bestandsnaam voorkomen. -->

			<iso:let name="typePlan" value=".//stri:Type"/>
			
	
			<iso:let name="isBestemmingsplan" 
					value="contains('bestemmingsplan,
								inpassingsplan,
								rijksbestemmingsplan,
								wijzigingsplan,
								uitwerkingsplan'
								, $typePlan)"/>
			
			<iso:let name="isGebiedsgerichtBesluit"
					value="contains('aanwijzingsbesluit,
									beheersverordening,
									buiten toepassing verklaring beheersverordening,
									projectbesluit,
									reactieve aanwijzing,
									voorbereidingsbesluit,
									tijdelijke ontheffing buitenplans,
									amvb'
									,$typePlan)"/>

			<iso:let name="isStructuurvisie" value="$typePlan='structuurvisie'"/>
			
			<iso:let name="isProvincialeVerordening" value="$typePlan='provinciale verordening'"/>
			
			<!--
				In de volgende tests wordt de booleaanse logica !A + A*B = !A + B gebruikt.
				Ofwel: 
					Als het niet een plantype X (!A) is dan is alles OK.
					Als het wel een plantype X (A) is dan moet ook criterium B gelden.
			 -->

		
			<iso:let name="aantalRegels" value="count(.//stri:Regels)"/>
			<iso:let name="aantalRegelsBijlagen" value="count(.//stri:RegelsBijlage)"/>
			<iso:let name="aantalToelichtingen" value="count(.//stri:Toelichting)"/>
			<iso:let name="aantalToelichtingBijlagen" value="count(.//stri:ToelichtingBijlage)"/>
			<iso:let name="aantalBesluitDocumenten" value="count(.//stri:BesluitDocument)"/>
			<iso:let name="aantalBesluitDocumentBijlagen" value="count(.//stri:BesluitDocumentBijlage)"/>
			<iso:let name="aantalBeleidsTeksten" value="count(.//stri:BeleidsTekst)"/>
			<iso:let name="aantalBeleidsTekstBijlagen" value="count(.//stri:BeleidsTekstBijlage)"/>
			<iso:let name="aantalBeleidsDocumenten" value="count(.//stri:BeleidsDocument)"/>
			<iso:let name="aantalBeleidsDocumentBijlagen" value="count(.//stri:BeleidsDocumentBijlage)"/>
			<iso:let name="aantalVaststellingsBesluiten" value="count(.//stri:VaststellingsBesluit)"/>
			<iso:let name="aantalIllustraties" value="count(.//stri:Illustratie)"/>



			 
			 <!-- Bij bestemmingsplannen moeten Regel en Toelichting minstens 1x voorkomen,
			 	en mogen geen BesluitDocument, BesluitDocumentBijlage, 
			 					BeleidsTekst, BeleidsTekstBijlage voorkomen. 
			  -->
			<iso:assert test="not($isBestemmingsplan) 
								or 
								 (
									($aantalRegels &gt;= 1) and 
									($aantalToelichtingen &gt;= 1) and
								 	($aantalBesluitDocumenten=0) and
								 	($aantalBesluitDocumentBijlagen=0) and
								 	($aantalBeleidsTeksten=0) and
								 	($aantalBeleidsTekstBijlagen=0) and
								 	($aantalBeleidsDocumenten=0) and
								 	($aantalBeleidsDocumentBijlagen=0)
								 )">
Foutcode AD4A: Bij een bestemmingsplan (huidig type plan = '<iso:value-of select="$typePlan"/>', plan Id='<iso:value-of select="$detectedPlanId"/>') 
moet minstens 1 Regels (aantal=<iso:value-of select="$aantalRegels"/>) en 
minstens 1 Toelichting (aantal=<iso:value-of select="$aantalToelichtingen"/>) document aanwezig zijn.
BesluitDocument (aantal=<iso:value-of select="$aantalBesluitDocumenten"/>), 
BesluitDocumentBijlage (aantal=<iso:value-of select="$aantalBesluitDocumentBijlagen"/>), 
Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsTeksten"/>),
BeleidstekstBijlage (aantal=<iso:value-of select="$aantalBeleidsTekstBijlagen"/>),
BeleidsDocument (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>) en
BeleidsDocumentBijlage (aantal=<iso:value-of select="$aantalBeleidsDocumentBijlagen"/>) documenten zijn niet toegestaan. 
RegelsBijlage, ToelichtingBijlage, Illustratie, VaststellingsBesluit en PlanTeksten documenten zijn ook toegestaan. 
			</iso:assert>

			 <!-- Bij structuurvisies moeten Beleidsdocument en BeleidsTekst 1x voorkomen
			 	en mogen Besluitdocument, BeleidsDocumentBijlage, BeleidsTekstBijlage,
			 	Regel, RegelsBijlage ,Toelichting, ToelichtingBijlage niet voorkomen.
			  -->
			<iso:assert test="not($isStructuurvisie) or 
								(
									($aantalBeleidsDocumenten&gt;=1) and
									($aantalBeleidsTeksten&gt;=1) and
									($aantalBesluitDocumenten=0) and
									($aantalBesluitDocumentBijlagen=0) and
									($aantalBeleidsTekstBijlagen=0) and
									($aantalRegels=0) and
									($aantalRegelsBijlagen=0) and
									($aantalToelichtingen=0) and
									($aantalToelichtingBijlagen=0)
								)">
Foutcode AD4B: Bij een structuurvisie (huidig type plan = '<iso:value-of select="$typePlan"/>', plan Id='<iso:value-of select="$detectedPlanId"/>') 
moet minstens 1 BeleidsDocument (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>) en 
minstens 1 Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsTeksten"/>) document voorkomen 
en mogen er geen 
BesluitDocument (aantal=<iso:value-of select="$aantalBesluitDocumenten"/>), 
BesluitDocumentBijlage (aantal=<iso:value-of select="$aantalBesluitDocumentBijlagen"/>), 
BeleidsTekstBijlage (aantal=<iso:value-of select="$aantalBeleidsTekstBijlagen"/>), 
Regels (aantal=<iso:value-of select="$aantalRegels"/>), 
RegelsBijlage (aantal=<iso:value-of select="$aantalRegelsBijlagen"/>), 
Toelichting (aantal=<iso:value-of select="$aantalToelichtingen"/>) en
ToelichtingBijlage (aantal=<iso:value-of select="$aantalToelichtingBijlagen"/>) voorkomen. 
Illustratie, VaststellingsBesluit, BeleidsDocumentBijlage en PlanTeksten documenten zijn ook toegestaan. 
			</iso:assert>

			 <!-- 
			 	Bij provinciale verordeningen mogen geen Beleidstekst, Beleidstekstbijlage, BesluitDocument 
			 	en BesluitDocumentBijlage documenten voorkomen.
			  -->
			<iso:assert test="not($isProvincialeVerordening) or 
								(
									($aantalBeleidsTeksten=0) and
									($aantalBeleidsTekstBijlagen=0) and
									($aantalBeleidsDocumenten=0) and
									($aantalBeleidsDocumentBijlagen=0)
								)">
Foutcode AD4C: Bij een provinciale verordening (huidig type plan = '<iso:value-of select="$typePlan"/>', plan Id='<iso:value-of select="$detectedPlanId"/>') 
mogen geen 
Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsTeksten"/>), 
BeleidsTekstBijlage (aantal=<iso:value-of select="$aantalBeleidsTekstBijlagen"/>), 
BeleidsDocument (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>) en 
BeleidsDocumentBijlage (aantal=<iso:value-of select="$aantalBeleidsDocumentBijlagen"/>) documenten voorkomen.
BesluitDocument, BesluitDocumentBijlage, Regels, Regelsbijlagen, Toelichting, Toelichtingbijlagen, 
Illustratie, VaststellingsBesluit en PlanTeksten documenten zijn wel toegestaan. 
			</iso:assert>

			 <!-- 
			 	Bij gebieds gerichte besluiten mogen BeleidsDocument en BeleidsDocumentBijlage niet voorkomen.
			  -->
			<iso:assert test="not($isGebiedsgerichtBesluit) or 
								(
									($aantalBeleidsDocumenten=0) and
									($aantalBeleidsDocumentBijlagen=0)
							 	)">
Foutcode AD4D: Bij een gebiedsgericht besluit (huidig type plan = '<iso:value-of select="$typePlan"/>', plan Id='<iso:value-of select="$detectedPlanId"/>') 
mogen geen 
BeleidsDocumenten (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>) en
BeleidsDocumentBijlagen (aantal=<iso:value-of select="$aantalBeleidsDocumentBijlagen"/>) documenten voorkomen.
BesluitDocument, BesluitDocumentBijlage, BeleidsTekst, BeleidsTekstBijlage, 
Regels, Regelsbijlagen, Toelichting, Toelichtingbijlagen, 
Illustratie, VaststellingsBesluit en PlanTeksten documenten zijn wel toegestaan. 
			</iso:assert>

		</iso:rule>


			<!-- Checks voor bestandsnamen en prefixen: Foutcode AD5 -->

			<!--
				Planonderdeel				Prefix	extensies
				
				IMRO						geen	.gml
				Regels						r_		.html,.xhtml,.htm
				RegelsBijlage				rb_		.html,.xhtml,.htm,.pdf
				Toelichting					t_		.html,.xhtml,.htm,.pdf
				ToelichtingBijlage			tb_		.html,.xhtml,.htm,.pdf
				VaststellingsBesluit		vb_		.html,.xhtml,.htm,.pdf
				BesluitDocument				d_		.html,.xhtml,.htm,.pdf
				BesluitDocumentBijlage		db_		.html,.xhtml,.htm,.pdf
				BeleidsTekst				b_		.html,.xhtml,.htm,.pdf
				BeleidsTekstBijlage			bb_		.html,.xhtml,.htm,.pdf
				BeleidsDocument				d_		.html,.xhtml,.htm,.pdf
				BeleidsDocumentBijlage		db_		.html,.xhtml,.htm,.pdf
				Illustratie					i_		.jpg,.jpeg,.png,.pdf
				PlanTeksten					pt_		.xml
				GeleideFormulier			g_		.xml
			 -->
	
			<!-- onderdeel IMRO valideren -->
		<iso:rule context="//stri:IMRO">
			<iso:let name="detectedPlanId" value="ancestor::stri:Plan/@Id"/>
	
			<iso:assert test="text()=concat($detectedPlanId,'.gml')">
Foutcode AD5A: planonderdeel IMRO (huidige waarde "<iso:value-of select="text()"/>") 
dient gelijk te zijn aan [planId].gml (<iso:value-of select="$detectedPlanId"/>.gml). 
			</iso:assert>
		</iso:rule>
		
			<!-- onderdeel Regels valideren -->
		<iso:rule context="//stri:Regels">
			<iso:let name="bestandsprefixenRegexp" value="'r_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel RegelsBijlage valideren -->
		<iso:rule context="//stri:RegelsBijlage">
			<iso:let name="bestandsprefixenRegexp" value="'rb_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
			
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel Toelichting valideren -->		
		<iso:rule context="//stri:Toelichting">
			<iso:let name="bestandsprefixenRegexp" value="'t_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel ToelichtingBijlage valideren -->
		<iso:rule context="//stri:ToelichtingBijlage">
		
			<iso:let name="bestandsprefixenRegexp" value="'tb_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel VaststellingsBesluit valideren -->
		<iso:rule context="//stri:VaststellingsBesluit">
			<iso:let name="bestandsprefixenRegexp" value="'vb_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel BesluitDocument valideren -->
		<iso:rule context="//stri:BesluitDocument">
			<iso:let name="bestandsprefixenRegexp" value="'d_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel BesluitDocumentBijlage valideren -->
		<iso:rule context="//stri:BesluitDocumentBijlage">
			<iso:let name="bestandsprefixenRegexp" value="'db_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel BeleidsDocument valideren -->
		<iso:rule context="//stri:BeleidsDocument">
			<iso:let name="bestandsprefixenRegexp" value="'d_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		
		</iso:rule>
		
			<!-- onderdeel BeleidsDocumentBijlage valideren -->
		<iso:rule context="//stri:BeleidsDocumentBijlage">
			<iso:let name="bestandsprefixenRegexp" value="'db_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel BeleidsTekst valideren -->
		<iso:rule context="//stri:BeleidsTekst">
			<iso:let name="bestandsprefixenRegexp" value="'b_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel BeleidsTekstBijlage valideren -->
		<iso:rule context="//stri:BeleidsTekstBijlage">

			<iso:let name="bestandsprefixenRegexp" value="'bb_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel Illustratie valideren -->
		<iso:rule context="//stri:Illustratie">

			<iso:let name="bestandsprefixenRegexp" value="'i_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.jpg|\.jpeg|\.png|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel PlanTeksten valideren -->
		<iso:rule context="//stri:PlanTeksten">

			<iso:let name="bestandsprefixenRegexp" value="'pt_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.xml'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel GeleideFormulier valideren.
			Dit moet met een speciale XPath expressie gebeuren omdat anders 
			het Root element bij een geleideformulier wordt geselecteerd. -->
		<iso:rule context="/stri:*//stri:GeleideFormulier">
		
			<iso:let name="bestandsprefixenRegexp" value="'g_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.xml'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>		
		</iso:rule>
		

		<!-- 
			Abstracte regel die 14x gebruikt wordt.
			Verondersteld wordt dat variabel bestandsprefixenRegexp, extensionCheckRegexp 
			bekend is gemaakt met een iso:let instructie
		-->
		<iso:rule abstract="true" id="bestandsnaamRegexpAndPlanIdCheck">

			<iso:let name="detectedPlanId" value="ancestor::stri:Plan/@Id"/>

			<iso:let name="prefix" value="concat(substring-before(text(),'_'),'_')"/>
			
			<iso:let name="bestandsnaamHeeftJuistePrefix" value="$prefix=$bestandsprefixenRegexp"/>
			
 			<iso:assert test="$bestandsnaamHeeftJuistePrefix">
Foutcode AD5B: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2008. 
De prefix had moeten zijn: '<iso:value-of select="$bestandsprefixenRegexp"/>'.
			</iso:assert>

			<iso:let name="bestandsnaamNaPrefix" value="substring-after(text(),'_')"/>
			<iso:let name="bestandsnaamNaPrefixBegintMetPlanId" 
				value="starts-with($bestandsnaamNaPrefix, $detectedPlanId)"/>

  			<iso:assert test="$bestandsnaamNaPrefixBegintMetPlanId">
Foutcode AD5C: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2008. 
De planId (<iso:value-of select="$detectedPlanId"/>) volgt niet onmiddelijk na de prefix. 
			</iso:assert>

			<iso:let name="bestandsnaamHeeftJuisteExtensie" value="regexp:matches(text(),concat('.*',$extensionCheckRegexp))"/>
							
			<iso:let name="toegestaneExtensies" value="translate($extensionCheckRegexp,'(\.|)','  ., ')"/>
			
			<iso:assert test="$bestandsnaamHeeftJuisteExtensie">
Foutcode AD5D: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2008. 
De bestandsextensie moet een van de volgende extensies zijn: <iso:value-of select="$toegestaneExtensies"/>.
			</iso:assert>
		</iso:rule>
	</iso:pattern>
	
	<iso:pattern name="Supplementen_basisURL_Check">

		<iso:rule context="//stri:StartPagina | //stri:CSS | //stri:SLD | //stri:WMS">

			<iso:let name="detectedPlanId" value="ancestor::stri:Plan/@Id"/>
			
			<!-- Check voor basisURL: Foutcode AD6 -->

			<iso:let name="BasisURL" value="parent::*/@BasisURL"/>
			<iso:let name="supplementIsFullURL" value="(text()!='') and 
													(starts-with(text(),'http://')
													or
													starts-with(text(),'https://'))"/>
			
			<!-- 
				In deze assert statements is gebruik gemaakt van de booleaanse logica
				!A + A * !B = !A + !B
				(waaruit tevens volgt: A + !A * B = A + B )
			-->
 			
			<!-- Als er geen basisURL is dan hoeft deze assert niet te worden uitgevoerd,
				en als er wel een basisURL is dan mag de supplement URL geen http bevatten. 
			-->
			<iso:assert test="not($BasisURL) or not($supplementIsFullURL)">
Foutcode AD6A: Als de basisURL (huidige waarde '<iso:value-of select="$BasisURL"/>') van element Supplementen bestaat
dan mag het supplement onderdeel <iso:value-of select="name()"/> (huidige waarde '<iso:value-of select="text()"/>') niet met http:// beginnen. 
Huidig plan Id='<iso:value-of select="$detectedPlanId"/>'.
			</iso:assert>

			<!-- Als er een basisURL is dan hoeft deze assert niet te worden uitgevoerd,
				en als er geen basisURL is dan moet de supplement URL http bevatten. 
			-->
			<iso:assert test="($BasisURL) or ($supplementIsFullURL)">
Foutcode AD6B: Als de basisURL van element Supplementen niet bestaat
dan moet het supplement onderdeel <iso:value-of select="name()"/> (huidige waarde '<iso:value-of select="text()"/>') met http:// beginnen. 
Huidig plan Id='<iso:value-of select="$detectedPlanId"/>'.
			</iso:assert>
		</iso:rule>
	
	</iso:pattern>
	

	<iso:pattern name="SignatureChecks">

		<iso:rule context="//ds:Reference">
			<iso:assert test="(@URI)">
Foutcode AD7A: Een signature Reference moet altijd een URI attribuut hebben. 
			</iso:assert>
		</iso:rule>

		<!-- SignedInfo is een verplicht element binnen Signature. -->	
		<iso:rule context="//ds:SignedInfo">
		
			<iso:assert test="count(.//ds:Reference[@URI=''])=1">
Foutcode AD7B: Er moet 1 Reference zijn waarbij attribuut URI="". Er moet namelijk een handtekening bestaan van het huidige document.
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="//ds:Signature">
			<iso:assert test="count(.//ds:KeyInfo)=1">
Foutcode AD7C: Er moet 1 KeyInfo element aanwezig zijn.
			</iso:assert>
		</iso:rule>

		<iso:rule context="//ds:KeyInfo">
			<iso:assert test="count(.//ds:X509Data)=1">
Foutcode AD7D: Binnen een KeyInfo element moet 1 X509Data element aanwezig zijn.
			</iso:assert>
		</iso:rule>

		<iso:rule context="//ds:X509Data">
			<iso:assert test="count(.//ds:X509Certificate) &gt; 0">
Foutcode AD7E: Binnen een X509Data element moet minstens 1 X509Certificate element aanwezig zijn.
			</iso:assert>
		</iso:rule>

		<iso:rule context="//ds:X509Certificate">
			<iso:let name="certificate" value="text()" />
			<iso:assert test="not(following-sibling::ds:X509Certificate[text()=$certificate])">
Foutcode AD7F: Een certificaat mag slechts 1x voorkomen in een certificatenlijst.
			</iso:assert>
		</iso:rule>

	</iso:pattern>


	<iso:pattern name="GeleideFormulier_Onderdelen_Signature_match">
	
		<iso:rule context="/stri:GeleideFormulier//stri:Onderdelen/stri:*[local-name()!='GeleideFormulier']">
		
			<iso:let name="bestandsnaam" value="text()"/>

			<iso:assert test="(/stri:GeleideFormulier//ds:Reference[@URI = $bestandsnaam])">
Foutcode AD8A: Planonderdeel '<iso:value-of select="name()"/>' (huidige waarde '<iso:value-of select="$bestandsnaam"/>') heeft geen Reference met 
een corresponderende URI binnen het SignedInfo element.	
			</iso:assert>
		</iso:rule>

		<iso:rule context="/stri:GeleideFormulier/ds:Signature/ds:SignedInfo/ds:Reference[@URI!='']">
		
			<iso:let name="bestandsnaam" value="@URI"/>

			<iso:assert test="(/stri:GeleideFormulier//stri:Onderdelen/stri:*[local-name()!='GeleideFormulier'][text() = $bestandsnaam])">
Foutcode AD8B: Reference met URI="<iso:value-of select="$bestandsnaam"/>" heeft geen corresponderend Planonderdeel.
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="/stri:Manifest//ds:Reference">
			
			<iso:assert test="(@URI='')">
Foutcode AD8C: Binnen een manifest is een Reference met een URI anders dan "" niet toegestaan. Huidige waarde URI="<iso:value-of select="@URI"/>".
			</iso:assert>
		</iso:rule>

	</iso:pattern>
	
	<iso:pattern name="VeiligheidsChecks">
	
	<!-- Veiligheids checks om DOS aanvallen te voorkomen. -->
	
		<iso:rule context="//ds:Reference/ds:Transforms">
			<iso:let name="aantalTransform" value="count(./ds:Transform)"/>
		
			<iso:assert test="$aantalTransform=1">
Foutcode AD9A: Binnen een Transforms element (binnen een Reference element) mag slechts 1 (huidig aantal=<iso:value-of select="$aantalTransform"/>) Transform element aanwezig zijn (veiligheidsredenen).
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="//ds:Reference//ds:Transform">

			<iso:let name="uri" value="ancestor::ds:Reference/@URI"/>

			<iso:assert test="($uri='') or not(@Algorithm = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature')">
Foutcode AD9B: Een Transform element met Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" is alleen toegestaan binnen een Reference met URI="" (huidige waarde URI= "<iso:value-of select="$uri"/>").
			</iso:assert>

		</iso:rule>

		<iso:rule context="//ds:KeyInfo/*">
			<iso:assert test="local-name()='X509Data'">
Foutcode AD10A: Binnen een KeyInfo element zijn geen <iso:name/> elementen toegestaan. Alleen X509Data elementen kunnen worden verwerkt (veiligheidsredenen).
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="//ds:X509Data/*">
			<iso:assert test="local-name()='X509Certificate'">
Foutcode AD10B: Binnen een X509Data element zijn geen <iso:name/> elementen toegestaan. Alleen X509Certificate elementen kunnen worden verwerkt (veiligheidsredenen).
			</iso:assert>
		</iso:rule>

		<iso:rule context="//ds:CanonicalizationMethod | //ds:Transform">
			<iso:assert test="not(contains(@Algorithm,'#WithComments') or
									contains(@Algorithm,'-xslt-') or
									contains(@Algorithm,'-xptr-') or
									contains(@Algorithm,'-filter') or
									contains(@Algorithm,'-xpath-'))">
Foutcode AD10C: Binnen een <iso:name/> element is het volgende Algorithm attribuut niet toegestaan: <iso:value-of select="@Algorithm"/>.
XSLT, XPATH, XPOINTER en commentaar verwerkende algoritmes zijn niet toegestaan (veiligheidsredenen).
			</iso:assert>

 			<iso:extends rule="geenChildElementsEnTekstToegestaan"/>
		</iso:rule>

		<iso:rule abstract="true" id="geenChildElementsEnTekstToegestaan">
			<iso:assert test="not(child::*) and not(text())">
Foutcode AD10D: Binnen een <iso:name/> element zijn geen child elements of tekst toegestaan (veiligheidsredenen).
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="//ds:SignatureMethod | //ds:DigestMethod">
			<iso:assert test="not(contains(@Algorithm,'md5'))">
Foutcode AD10E: Binnen een <iso:name/> element is het volgende Algorithm attribuut niet toegestaan: <iso:value-of select="@Algorithm"/>.
Gebruik als hashing algoritme geen MD5 omdat dit reeds gekraakt is of zeer spoedig zal worden (veiligheidsredenen).
			</iso:assert>

			<iso:extends rule="geenChildElementsEnTekstToegestaan"/>
		</iso:rule>
		
	</iso:pattern>
	
	<iso:pattern name="STRI2008ManifestMoetVanVoor30Juni2013Zijn">
	<iso:rule context="/stri:Manifest">

		<!-- Eigenlijk is dit niet nodig aangezien dit validatie-schema enkel uitgevoerd kan worden op STRI2008 -->
		<iso:let name="isCorrectxmlns" value="namespace-uri() = 'http://www.geonovum.nl/stri/2008/1'"/>
		
		<iso:let name="datum" value="@Datum"/>

		<iso:let name="year" value="substring($datum,1,4)"/>
		<iso:let name="month" value="substring($datum,6,2)"/>
		<iso:let name="day" value="substring($datum,9,2)"/>

		<iso:let name="is2014Plus" value="$year &gt; 2013"/>
		<iso:let name="is2013" value="$year = 2013"/>
		<iso:let name="isJulyPlus" value="$month &gt; 6"/>
		<iso:let name="isJune" value="$month = 6"/>
		<iso:let name="is30Plus" value="$day &gt; 29"/>

		<iso:let name="isAfter29June2013" value="$is2014Plus or ($is2013 and $isJulyPlus) or ($is2013 and $isJune and $is30Plus)"/>
		
		<iso:assert test="not($isAfter29June2013 and $isCorrectxmlns)" diagnostics="Error">
		Foutcode AD26B: Het manifest is gecodeerd conform STRI2008, maar dit is niet meer de geldende norm.
		</iso:assert>

    </iso:rule>
</iso:pattern>


</iso:schema>