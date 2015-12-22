<?xml version="1.0" encoding="UTF-8"?>
<!--
/*******************************************************************************
 * File: stri2012-rulesv003.sch
 *
 * (C) Logica, 2008
 *
 *
 * Info:
 * Schematron Validation Document for STRI2012
 *
 * History:
 *
 * 23-11-2011   RD  verwijzingen naar tekst naar documenten met prefix r_, t_, b_ 
 *                  zijn alleen toegestaan in het geval er geen sprake is van 
 *                  objectgerichte teksten en vice versa.
 * 31-01-2012   RD  Namespace definitie aanpassen a.g.v. nieuw XML schema:
 *                     http://www.geonovum.nl/stri/2012/1  ==> http://www.geonovum.nl/stri/2012/1.0
 *
 ******************************************************************************/
-->
<iso:schema xmlns:iso="http://purl.oclc.org/dsdl/schematron"
			xml:lang="en">  <!-- ISO Schematron 1.6 namespace -->

	<!-- <iso:title>Schematron validaties voor STRI2012</iso:title>-->
	<!-- Titel weggehaald om geen output te hebben als er geen fout is -->
	<!-- De validator concludeert daaruit dat er geen fout en dus een valide bestand is -->

	<iso:ns prefix="gml" uri="http://www.opengis.net/gml"/>
	<iso:ns prefix="ds" uri="http://www.w3.org/2000/09/xmldsig#"/>
	<iso:ns prefix="stri" uri="http://www.geonovum.nl/stri/2012/1.0"/>

	<iso:ns prefix="regexp" uri="nl.vrom.roo.util.Regexp"/>
		
	<iso:let name="lowercaseChars" value="'abcdefghijklmnopqrstuvwxyz'"/>
	<iso:let name="uppercaseChars" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
	
	<!-- Definieer reguliere expressies om PlanIdn en bestandsnamen te valideren -->

	<iso:let name="ankerRegexp" value="'(#.*)?'"/>
	
	<iso:let name="idnCheckRegexp" value="'NL\.IMRO\.[0-9]{4}\.[A-Za-z0-9]{1,18}-[A-Za-z0-9]{4}'"/>

	<iso:let name="stri2008CheckRegexp" value="'((r|rb|t|tb|i|vb|pt|d|db|b|bb|g)_)?NL\.IMRO\.[0-9]{4}\.[A-Za-z0-9]{1,18}-[A-Za-z0-9]{4}(_[A-Za-z0-9\.]{1,20})?\.(html|htm|xhtml|xml|gml|pdf|png|jpg|jpeg)'"/>
	
	
	<iso:pattern name="unieke_identificatie">
		<!-- De planId moet uniek zijn binnen een manifest. -->
		<iso:rule context="/stri:Manifest/stri:Dossier/stri:Plan">
		
			<iso:let name="Id" value="@Id"/>
			
			<iso:assert test="not(following-sibling::stri:Plan/@Id=$Id)">
Foutcode AD0A: PlanId "<iso:value-of select="$Id"/>" komt meerdere malen voor binnen het manifest.
De Id van een plan moet uniek zijn binnen een manifest.
			</iso:assert>
			
			<iso:let name="dossierId" value="ancestor::stri:Dossier/@Id"/>

			<iso:assert test="contains($Id,$dossierId)">
Foutcode AD0C: PlanId "<iso:value-of select="$Id"/>" moet beginnen met het dossierId "<iso:value-of select="$dossierId"/>"
			</iso:assert>

			
		</iso:rule>
		
		<!-- De planId moet uniek zijn binnen een manifest. -->
		<iso:rule context="/stri:Manifest/stri:Dossier">
		
			<iso:let name="Id" value="@Id"/>
			
			<iso:assert test="not(following-sibling::stri:Dossier/@Id=$Id)">
Foutcode AD0B: DossierId "<iso:value-of select="$Id"/>" komt meerdere malen voor binnen het manifest.
De Id van een dossier moet uniek zijn binnen een manifest.
			</iso:assert>
		</iso:rule>

	</iso:pattern>


	<iso:pattern name="eenmalige_checks_GeleideFormulier_en_manifest">

		<iso:rule abstract="true" id="check_overheidscode_en_naamOverheid">
			
			<iso:let name="overheidsCode" value="@OverheidsCode"/>
			
			<iso:assert test="regexp:matches($overheidsCode,'[0-9]{4}')">
Foutcode AD1A: OverheidsCode (huidige waarde '<iso:value-of select="$overheidsCode"/>') moet uit 4 cijfers bestaan. 
			</iso:assert>
			
			<iso:let name="naamOverheid" value="@NaamOverheid"/>
			
			<iso:assert test="string-length($naamOverheid) &gt; 0">
Foutcode AD1B: NaamOverheid moet een naam zijn en geen lege string.
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="/stri:Manifest">
			<iso:extends rule="check_overheidscode_en_naamOverheid"/>
		</iso:rule>
		

		<iso:rule context="/stri:GeleideFormulier">
			<iso:extends rule="check_overheidscode_en_naamOverheid"/>

			<iso:let name="aantalPlanTeksten" value="count(//stri:PlanTeksten)"/>
			<iso:let name="aantalRegels" value="count(//stri:Regels)"/>
			<iso:let name="aantalToelichtingen" value="count(//stri:Toelichting)"/>
			<iso:let name="aantalBeleidsOfBesluitDocumenten" value="count(//stri:BeleidsOfBesluitDocument)"/>
			
			<iso:let name="planTekstenAfwezig" value="($aantalPlanTeksten=0)"/>
			<iso:let name="regelsToelichtingBeleidDocsAfwezig" 
						value="($aantalRegels=0 and $aantalToelichtingen=0 and $aantalBeleidsOfBesluitDocumenten=0)"/>
			
			<iso:assert test="$planTekstenAfwezig or $regelsToelichtingBeleidDocsAfwezig">
Foutcode AD20: Planteksten (aantal: <iso:value-of select="$aantalPlanTeksten"/>) mogen niet aanwezig zijn als er documenten
			van het type Regels (aantal: <iso:value-of select="$aantalRegels"/>), 
			Toelichting (aantal: <iso:value-of select="$aantalToelichtingen"/>) of 
			BeleidOfBesluitDocument (aantal: <iso:value-of select="$aantalBeleidsOfBesluitDocumenten"/>) aanwezig zijn 
			en vice versa.
			</iso:assert>
		</iso:rule>
	</iso:pattern>
	
	

	<iso:pattern name="Checks_Per_Plan">

		<iso:rule context="//stri:Plan">

			<!--  Validatie van planId: Foutcode AD2 -->
			<iso:let name="detectedPlanId" value="@Id"/>

			<iso:assert test="regexp:matches($detectedPlanId,$idnCheckRegexp)">
Foutcode AD2: identificatie (huidige waarde "<iso:value-of select="$detectedPlanId"/>") 
voldoet niet aan de conventies van STRI2012 voor plan identificatie.
(PlanIdn regexp: '<iso:value-of select="$idnCheckRegexp"/>')
			</iso:assert>

		</iso:rule>


			<!-- Checks voor bestandsnamen en prefixen: Foutcode AD5 -->

			<!--
				Planonderdeel				Prefix	extensies
				
				IMRO						geen	.gml
				Regels						r_		.html,.xhtml,.htm
				Bijlage						b_		.html,.xhtml,.htm,.pdf
				Toelichting					t_		.html,.xhtml,.htm,.pdf
				VaststellingsBesluit		vb_		.html,.xhtml,.htm,.pdf
				BeleidsOfBesluitDocument	d_		.html,.xhtml,.htm,.pdf
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
		
			<!-- onderdeel Toelichting valideren -->		
		<iso:rule context="//stri:Toelichting">
			<iso:let name="bestandsprefixenRegexp" value="'t_'"/>
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
		<iso:rule context="//stri:BeleidsOfBesluitDocument">
			<iso:let name="bestandsprefixenRegexp" value="'d_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
			<!-- onderdeel RegelsBijlage valideren -->
		<iso:rule context="//stri:Bijlage">
			<iso:let name="bestandsprefixenRegexp" value="'b_'"/>
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
		<iso:rule context="/stri:GeleideFormulier//stri:GeleideFormulier">
		
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
die niet voldoet aan de bestandsnaamconventies van STRI2012. 
De prefix had moeten zijn: '<iso:value-of select="$bestandsprefixenRegexp"/>'.
			</iso:assert>

			<iso:let name="bestandsnaamNaPrefix" value="substring-after(text(),'_')"/>
			<iso:let name="bestandsnaamNaPrefixBegintMetPlanId" 
				value="starts-with($bestandsnaamNaPrefix, $detectedPlanId)"/>

  			<iso:assert test="$bestandsnaamNaPrefixBegintMetPlanId">
Foutcode AD5C: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2012. 
De planId (<iso:value-of select="$detectedPlanId"/>) volgt niet onmiddelijk na de prefix. 
			</iso:assert>

			<iso:let name="bestandsnaamHeeftJuisteExtensie" value="regexp:matches(text(),concat('.*',$extensionCheckRegexp))"/>
							
			<iso:let name="toegestaneExtensies" value="translate($extensionCheckRegexp,'(\.|)','  ., ')"/>
			
			<iso:assert test="$bestandsnaamHeeftJuisteExtensie">
Foutcode AD5D: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2012. 
De bestandsextensie moet een van de volgende extensies zijn: <iso:value-of select="$toegestaneExtensies"/>.
			</iso:assert>
		</iso:rule>
	</iso:pattern>
	
	<iso:pattern name="Supplementen_basisURL_Check">

		<iso:rule context="//stri:StartPagina | //stri:CSS">

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

			<!-- onderdeel GeleideFormulier valideren binnen een manifest. Dit moet een URL bevatten -->
		<iso:rule context="/stri:Manifest//stri:GeleideFormulier">
	
			<iso:assert test="starts-with(text(),'http://') or starts-with(text(),'https://') ">
Foutcode AD6C: De waarde van het veld GeleideFormulier ('<iso:value-of select="text()"/>') in een manifest moet een URL zijn beginnend met http://
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

		<iso:rule context="/stri:GeleideFormulier/ds:Signature/ds:SignedInfo/ds:Reference[(@URI) and (@URI!='')]">
		
			<iso:let name="bestandsnaam" value="@URI"/>

			<iso:assert test="(/stri:GeleideFormulier//stri:Onderdelen/stri:*[local-name()!='GeleideFormulier'][text() = $bestandsnaam])">
Foutcode AD8B: Reference met URI="<iso:value-of select="$bestandsnaam"/>" heeft geen corresponderend Planonderdeel.
			</iso:assert>
		</iso:rule>
		
		<iso:rule context="/stri:Manifest//ds:Reference[@URI]">
			
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


</iso:schema>