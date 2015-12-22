<?xml version="1.0" encoding="UTF-8"?>
<!--
/*******************************************************************************
 * File: additional-validator-rules-STRI2006v004.sch
 *
 * (C) Logica, 2011
 *
 *
 * Info:
 * Schematron Validation Document for STRI2006
 *
 * History:
 * 16-12-2008   RD  Initial version
 * 06-07-2009   RD  Rule AD0: Uniqueness test for plan Id in a manifest
 * 08-06-2009   RD  Check AD3A and AD3B: Messages adapted because of misunderstandings.
 * 16-02-2009   RD  Rule AD6 adapted. Https is also a permitted choice.
 * 30-11-2011   RD  Added new PCP2008 plan types
 * 12-06-2011   RD  New STRI2006 version v1.2b.1
 ******************************************************************************/

Opmerkingen / hints:

-->
<iso:schema xmlns:iso="http://purl.oclc.org/dsdl/schematron"
			xml:lang="en">  <!-- ISO Schematron 1.6 namespace -->

	<!-- <iso:title>Schematron validaties voor PCP2008</iso:title>-->
	<!-- Titel weggehaald om geen output te hebben als er geen fout is -->
	<!-- De validator concludeert daaruit dat er geen fout en dus een valide bestand is -->

	<iso:ns prefix="gml" uri="http://www.opengis.net/gml"/>
	<iso:ns prefix="ds" uri="http://www.w3.org/2000/09/xmldsig#"/>
	<iso:ns prefix="stri" uri="http://www.geonovum.nl/stri/2006/1"/>

	<iso:ns prefix="regexp" uri="nl.vrom.roo.util.Regexp"/>
		
	<iso:let name="lowercaseChars" value="'abcdefghijklmnopqrstuvwxyz'"/>
	<iso:let name="uppercaseChars" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
	
	<!-- Vrijwel identiek aan schematron validaties voor IMRO2006 -->	
	
	<!-- Definieer reguliere expressies om PlanIdn en bestandsnamen te valideren -->
	<iso:let name="idnCheckRegexp" value="'NL\.IMRO\.[0-9]{8}[A-Za-z0-9_\-\.]{1,15}-([A-Za-z0-9_\-\.]{1,32})?'"/>



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
		<iso:rule context="/stri:Manifest">
			
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


		<!--
			In de volgende tests wordt de booleaanse logica !A + A*B = !A + B gebruikt.
			Ofwel: 
				Als het niet een plantype X (!A) is dan is alles OK.
				Als het wel een plantype X (A) is dan moet ook criterium B gelden.
		 -->

		<iso:rule context="//stri:Plan">

			<!-- Check planId: Foutcode AD2 -->
			<iso:let name="identificatie" value="@Id"/>

			<iso:assert test="regexp:matches($identificatie,$idnCheckRegexp)">
Foutcode AD2: identificatie (huidige waarde "<iso:value-of select="$identificatie"/>") 
voldoet niet aan de conventies van STRI2006 voor plan identificatie.
(PlanIdn regexp: '<iso:value-of select="$idnCheckRegexp"/>')
			</iso:assert>

			<!-- Validatie van planType in combinatie met Contour: Foutcode AD3 -->

			<!-- detectedPlanId is nodig voor extra bestandsnaamvalidatie: planId moet in bestandsnaam voorkomen. -->
			<iso:let name="detectedPlanId" value="@Id"/>
			<iso:let name="typePlan" value=".//stri:Type"/>
			<iso:let name="planStatus" value=".//stri:Status"/>

			<!-- PCP2008 plantype:
				gemeentelijk plan; bestemmingsplan artikel 10
				gemeentelijk plan; uitwerkingsplan artikel 11
				gemeentelijk plan; wijzigingsplan artikel 11
				gemeentelijk plan; voorbereidingsbesluit
				gemeentelijk plan; overig
				provinciaal plan; overig
				rijksplan; overig
				gemeentelijke visie; overig
				provinciale visie; overig
				rijksvisie; overig
				gemeentelijk besluit; overig
				provinciaal besluit; overig
				rijksbesluit; overig
			 -->
			<iso:let name="planTypeIsPCP2008Bestemmingsplan" 
					value="contains('gemeentelijk plan; bestemmingsplan artikel 10,
									gemeentelijk plan; uitwerkingsplan artikel 11,
									gemeentelijk plan; wijzigingsplan artikel 11'
									, $typePlan)"/>

			<iso:let name="planTypeIsPCP2008Beleidsplan" 
					value="contains('gemeentelijk plan; voorbereidingsbesluit,
									gemeentelijk plan; overig,
									provinciaal plan; overig,
									rijksplan; overig,
									gemeentelijke visie; overig,
									provinciale visie; overig,
									rijksvisie; overig,
									gemeentelijk besluit; overig,
									provinciaal besluit; overig,
									rijksbesluit; overig'
									, $typePlan)"/> />

			<iso:let name="planTypeIsPCP2008PlanType" value="$planTypeIsPCP2008Bestemmingsplan or $planTypeIsPCP2008Beleidsplan"/>

			
			<!-- Planstatussen die overeenkomen tussen PCP2008 en IMRO2006 -->
			<iso:let name="planStatusIsPCP2008orIMRO2006PlanStatus" 
					value="contains('concept,
									voorontwerp,
									ontwerp,
									vastgesteld'
									,$planStatus)"/>

			<!-- Planstatussen die niet overeenkomen tussen PCP2008 en IMRO2006 -->
			<iso:let name="planStatusIsPCP2008PlanStatusOnherroepelijk" 
					value="($planStatus='onherroepelijk')"/>

			<!-- Hier weten we in elk geval dat de planstatus bij een PCP2008 plan past. -->
			<iso:let name="planStatusIsPCP2008PlanStatus" 
					value="($planStatusIsPCP2008orIMRO2006PlanStatus) or ($planStatusIsPCP2008PlanStatusOnherroepelijk)"/>

			<!-- Valideer planContour planType planStatus -->
			<iso:let name="contour" value="@Contour"/>
			<iso:let name="isContour" value="$contour='true'"/>

			<!-- Mismatches tussen planType, planStatus en Contour worden ook door additionele referentievalidatie gedetecteerd. -->
			<iso:assert test="(not($isContour) and not($planTypeIsPCP2008Beleidsplan))
								or 
								($isContour and $planTypeIsPCP2008PlanType)">
Foutcode AD3A: De waarde van Type '<iso:value-of select="$typePlan"/>' stemt niet
overeen met de waarde van attribuut Contour '<iso:value-of select="$contour"/>', 
of het attribuut Contour="true" ontbreekt bij gebruik van PCP2008 plantype 'gemeentelijk plan'. 
Huidig plan Id='<iso:value-of select="$detectedPlanId"/>'
			</iso:assert>
			
			<iso:assert test="(not($isContour) and not($planStatusIsPCP2008PlanStatusOnherroepelijk))
								or 
								($isContour and $planStatusIsPCP2008PlanStatus)">
Foutcode AD3B: De waarde van Status '<iso:value-of select="$planStatus"/>' stemt niet
overeen met de waarde van attribuut Contour '<iso:value-of select="$contour"/>',
of het attribuut Contour="true" ontbreekt bij gebruik van PCP2008 planstatus 'onherroepelijk'.
Huidig plan Id='<iso:value-of select="$detectedPlanId"/>'
			</iso:assert>


			<!-- Validatie van planType met planonderdelen: Foutcode AD4 -->


			<!-- Bestemmingsplannen plantype: 
				gemeentelijk plan; bestemmingsplan artikel 10,
				gemeentelijk plan; structuurplan,					Niet toegestaan
				gemeentelijk plan; structuurschets,					Niet toegestaan
				gemeentelijk plan; structuurvisie,					Niet toegestaan
				gemeentelijk plan; uitwerkingsplan artikel 11,
				gemeentelijk plan; wijzigingsplan artikel 11,
				gemeentelijk plan; artikel 19 plan					Niet toegestaan
			 -->
			<iso:let name="isBestemmingsplan" 
					value="not($isContour) and
							not($typePlan='gemeentelijk plan') and 
							contains('gemeentelijk plan; bestemmingsplan artikel 10,
									gemeentelijk plan; uitwerkingsplan artikel 11,
									gemeentelijk plan; wijzigingsplan artikel 11'
								, $typePlan)"/>
			 


			<!-- Beleidsplannen plantype:
				gemeentelijk plan,									Structuurvisie
				Euregionaal plan,										Niet toegestaan
				Europees plan,											Niet toegestaan
				nationaal plan,										Nationale plannen worden verenigd onder deze variant
				nationaal plan; nota,									
				nationaal plan; PKB,
				nationaal plan; structuurschema/schets,					
				nationaal plan; uitwerking nationaal plan,				
				provinciaal plan,									Provinciale plannen worden verenigd onder deze variant
				provinciaal plan; omgevingsplan,						
				provinciaal plan; sectorplan,							
				provinciaal plan; streekplan,							
				provinciaal plan; uitwerking provinciaal plan,			
				regionaal plan,											Niet toegestaan
				regionaal plan; omgevingsplan,							Niet toegestaan
				regionaal plan; sectorplan,								Niet toegestaan
				regionaal plan; structuurplan/schets/visie,				Niet toegestaan
				regionaal plan; uitwerking regionaal plan,				Niet toegestaan
			 -->
			<iso:let name="isBeleidsplan" 
					value="contains('gemeentelijk plan,
									nationaal plan,
									nationaal plan; nota,
									nationaal plan; PKB,
									nationaal plan; structuurschema/schets,
									nationaal plan; uitwerking nationaal plan,
									provinciaal plan,
									provinciaal plan; omgevingsplan,
									provinciaal plan; sectorplan,
									provinciaal plan; streekplan,
									provinciaal plan; uitwerking provinciaal plan'
								, $typePlan)"/>


<!-- 
	Besluiten worden binnen IMRO2006 in de praktijk niet gebruikt. 
	Binnen PCP2008 bestaat een voorbereidingsbesluit en binnen IMRO2008 zijn er wel besluitgebieden. 
-->
			<!-- Gebiedsbesluit plantype:
				artikel 19 besluit,					Niet ondersteund door STRI2006
				besluit aanwijzing,					Niet ondersteund door STRI2006
				goedkeuringsbesluit,				Niet ondersteund door STRI2006
				uitspraak ABRS,						Niet ondersteund door STRI2006
				uitspraak rechtbank,				Niet ondersteund door STRI2006
				voorbereidingsbesluit,				Niet ondersteund door STRI2006
				vrijstellingsbesluit				Niet ondersteund door STRI2006
			 -->
<!-- 
			<iso:let name="isBesluit"
					value="contains('artikel 19 besluit,
									besluit aanwijzing,
									goedkeuringsbesluit,
									uitspraak ABRS,
									uitspraak rechtbank,
									voorbereidingsbesluit,
									vrijstellingsbesluit'
									,$typePlan)"/>
-->
		
			<iso:let name="aantalVoorschriften" value="count(.//stri:Voorschriften)"/>
			<iso:let name="aantalVoorschriftenBijlagen" value="count(.//stri:VoorschriftenBijlage)"/>
			<iso:let name="aantalToelichtingen" value="count(.//stri:Toelichting)"/>
			<iso:let name="aantalToelichtingBijlagen" value="count(.//stri:ToelichtingBijlage)"/>
			<iso:let name="aantalBesluitDocumenten" value="count(.//stri:BesluitDocument)"/>
			<iso:let name="aantalBeleidsDocumenten" value="count(.//stri:BeleidsDocument)"/>
			<iso:let name="aantalBeleidsDocumentBijlagen" value="count(.//stri:BeleidsDocumentBijlage)"/>
			<iso:let name="aantalBeleidsteksten" value="count(.//stri:BeleidsTekst)"/>
		 	<iso:let name="aantalPlankaarten" value="count(.//stri:PlanKaart)"/>

			<!--
				Documenten waarop getest kan worden:
					Voorschriften 
					VoorschriftenBijlage
					Toelichting
					ToelichtingBijlage
					BesluitDocument
					BeleidsDocument
					BeleidsDocumentBijlage
					BeleidsTekst
					Plankaart
				
				Te gebruiken variabelen:
				
					aantalVoorschriften
					aantalVoorschriftenBijlagen
					aantalToelichtingen
					aantalToelichtingBijlagen
					aantalBesluitDocumenten
					aantalBeleidsDocumenten
					aantalBeleidsDocumentBijlagen
					aantalBeleidsteksten
					aantalPlankaarten
			 -->


			 <!--
			 	Bij PCP2008 bestemmingsplannen mogen alleen Plankaart, Voorschriften, Toelichting, Bijlage bij de voorschriften, Bijlagen bij de toelichting, Besluitdocument documenten,
			 	worden meegeleverd. De overige documenten zijn niet toegestaan.
			  -->
			<iso:assert test="not($isContour and $planTypeIsPCP2008Bestemmingsplan) or 
								(
									($aantalBeleidsDocumenten=0) and
								 	($aantalBeleidsDocumentBijlagen=0) and
								 	($aantalBeleidsteksten=0) 
								)">
Foutcode AD4A: Bij een PCP2008 bestemmingsplan (huidig type plan = '<iso:value-of select="$typePlan"/>', Id='<iso:value-of select="$detectedPlanId"/>') 
mogen alleen Plankaart, Voorschriften, Toelichting, Bijlage bij de voorschriften, Bijlagen bij de toelichting, Besluitdocument, IMRO en GeleideFormulier documenten voorkomen.
BeleidsDocument (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>),
BeleidsDocumentBijlage (aantal=<iso:value-of select="$aantalBeleidsDocumentBijlagen"/>),
Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsteksten"/>) documenten zijn niet toegestaan.
			</iso:assert>

			 
			 <!--
			 	Bij PCP2008 voorbereidingsbesluit mogen alleen Plankaart, Beleidsdocument, Bijlage bij beleidsdocument en BesluitDocument documenten
			 	worden meegeleverd. De overige documenten zijn niet toegestaan.
			  -->
			<iso:assert test="not($isContour and $planTypeIsPCP2008Beleidsplan) or 
								(
									($aantalVoorschriften=0) and 
									($aantalVoorschriftenBijlagen=0) and 
									($aantalToelichtingen=0) and  
								 	($aantalToelichtingBijlagen=0) and
								 	($aantalBeleidsteksten=0)
								)">
Foutcode AD4B: Bij een PCP2008 voorbereidingsbesluit (huidig type plan = '<iso:value-of select="$typePlan"/>', Id='<iso:value-of select="$detectedPlanId"/>') 
mogen alleen Plankaart, Beleidsdocument, Bijlage bij beleidsdocument, BesluitDocument, IMRO en GeleideFormulier documenten voorkomen.
Voorschriften (aantal=<iso:value-of select="$aantalVoorschriften"/>), 
VoorschriftenBijlage (aantal=<iso:value-of select="$aantalVoorschriftenBijlagen"/>), 
Toelichting (aantal=<iso:value-of select="$aantalToelichtingen"/>),
ToelichtingBijlage (aantal=<iso:value-of select="$aantalToelichtingBijlagen"/>), 
Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsteksten"/>) documenten zijn niet toegestaan.
			</iso:assert>
			 
			 <!-- Bij bestemmingsplannen mogen alleen Voorschriften, VoorschriftenBijlage, Toelichting,
			 ToelichtingBijlage worden gebruikt.
			 De varianten BesluitDocument, BeleidsDocument, BeleidsDocumentBijlage, BeleidsTekst 
			 mogen niet voorkomen.
			  -->
			<iso:assert test="not($isBestemmingsplan) 
								or 
								 (
								 	($aantalBesluitDocumenten=0) and
								 	($aantalBeleidsDocumenten=0) and
								 	($aantalBeleidsDocumentBijlagen=0) and
								 	($aantalBeleidsteksten=0) and
								 	($aantalPlankaarten=0)
								 )">
Foutcode AD4C: Bij een bestemmingsplan (huidig type plan = '<iso:value-of select="$typePlan"/>', Id='<iso:value-of select="$detectedPlanId"/>') 
mogen alleen Voorschriften, VoorschriftenBijlage, Toelichting, ToelichtingBijlage, IMRO en GeleideFormulier documenten voorkomen.
BesluitDocument (aantal=<iso:value-of select="$aantalBesluitDocumenten"/>),
BeleidsDocument (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>),
BeleidsDocumentBijlage (aantal=<iso:value-of select="$aantalBeleidsDocumentBijlagen"/>),
Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsteksten"/>) en
Plankaart (aantal=<iso:value-of select="$aantalPlankaarten"/>) documenten zijn niet toegestaan.
			</iso:assert>


			 <!-- Bij Beleidsplangebieds mogen alleen BeleidsDocument, BeleidsDocumentBijlage en
				Beleidstekst documenten voorkomen.
				Voorschriften, VoorschriftenBijlage, Toelichting, ToelichtingBijlage en BesluitDocument 
				documenten zijn niet toegestaan. 
			  -->
			<iso:assert test="not($isBeleidsplan) or 
								(
									($aantalVoorschriften=0) and 
									($aantalVoorschriftenBijlagen=0) and 
									($aantalToelichtingen=0) and  
								 	($aantalToelichtingBijlagen=0) and
								 	($aantalBesluitDocumenten=0) and
								 	($aantalPlankaarten=0)
							 	)">
Foutcode AD4D: Bij een beleidsplan (huidig type plan = '<iso:value-of select="$typePlan"/>', Id='<iso:value-of select="$detectedPlanId"/>') 
mogen alleen BeleidsDocument, BeleidsDocumentBijlage, Beleidstekst, IMRO en GeleideFormulier documenten voorkomen.  
Voorschriften (aantal=<iso:value-of select="$aantalVoorschriften"/>), 
VoorschriftenBijlage (aantal=<iso:value-of select="$aantalVoorschriftenBijlagen"/>), 
Toelichting (aantal=<iso:value-of select="$aantalToelichtingen"/>),
ToelichtingBijlage (aantal=<iso:value-of select="$aantalToelichtingBijlagen"/>), 
BesluitDocument (aantal=<iso:value-of select="$aantalBesluitDocumenten"/>) en
Plankaart (aantal=<iso:value-of select="$aantalPlankaarten"/>) documenten zijn niet toegestaan.
			</iso:assert>

<!-- 
	Besluiten worden binnen IMRO2006 in de praktijk niet gebruikt. 
	Binnen PCP2008 bestaat een voorbereidingsbesluit en binnen IMRO2008 zijn er wel besluitgebieden. 
-->
			 <!-- Bij besluiten mag alleen een BesluitDocument voorkomen.
				Voorschriften, VoorschriftenBijlage, Toelichting, ToelichtingBijlage, 
				BeleidsDocument, BeleidsDocumentBijlage, BeleidsTekst mogen niet voorkomen.
			  -->
<!-- 			  
			<iso:assert test="not($isBesluit) or 
								(
									($aantalVoorschriften=0) and 
									($aantalVoorschriftenBijlagen=0) and 
									($aantalToelichtingen=0) and  
								 	($aantalToelichtingBijlagen=0) and
								 	($aantalBeleidsDocumenten=0) and
								 	($aantalBeleidsDocumentBijlagen=0) and
								 	($aantalBeleidsteksten=0) and
								 	($aantalPlankaarten=0)
								)">
Foutcode AD4E: Bij een besluit (huidig type plan = '<iso:value-of select="$typePlan"/>', Id='<iso:value-of select="$detectedPlanId"/>') 
mogen alleen BesluitDocument, IMRO en GeleideFormulier documenten voorkomen.
Voorschriften (aantal=<iso:value-of select="$aantalVoorschriften"/>), 
VoorschriftenBijlage (aantal=<iso:value-of select="$aantalVoorschriftenBijlagen"/>), 
Toelichting (aantal=<iso:value-of select="$aantalToelichtingen"/>),
ToelichtingBijlage (aantal=<iso:value-of select="$aantalToelichtingBijlagen"/>), 
BeleidsDocument (aantal=<iso:value-of select="$aantalBeleidsDocumenten"/>),
BeleidsDocumentBijlage (aantal=<iso:value-of select="$aantalBeleidsDocumentBijlagen"/>), 
Beleidstekst (aantal=<iso:value-of select="$aantalBeleidsteksten"/>) en
Plankaart (aantal=<iso:value-of select="$aantalPlankaarten"/>) documenten zijn niet toegestaan.
			</iso:assert>
-->
		</iso:rule>


			<!-- Checks voor bestandsnamen en prefixen: Foutcode AD5 -->

			<!--
				Planonderdeel			Prefix	extensies
				
				IMRO 					geen	.gml
				Voorschriften			v_  	.html,.htm,.xhtml
				VoorschriftenBijlage	vb_		.pdf
				Toelichting				t_		.pdf
				ToelichtingBijlage		tb_		.pdf
				BesluitDocument			bd_		.html,.htm,.xhtml,.pdf
				BeleidsDocument			d_		.pdf
				BeleidsDocumentBijlage	db_		.pdf
				BeleidsTekst			b_		.html,.htm,.xhtml,.pdf
				PlanKaart				p_		.pdf	(voor PCP2008)
				GeleideFormulier		g_		.xml, .pdf
			 -->

			<!-- onderdeel IMRO valideren -->
		<iso:rule context="//stri:IMRO">
			<iso:let name="detectedPlanId" value="ancestor::stri:Plan/@Id"/>
	
			<iso:assert test="text()=concat($detectedPlanId,'.gml')">
Foutcode AD5A: planonderdeel IMRO (huidige waarde "<iso:value-of select="text()"/>") 
dient gelijk te zijn aan [planId].gml (<iso:value-of select="$detectedPlanId"/>.gml). 
			</iso:assert>
		</iso:rule>

			<!-- onderdeel Voorschriften valideren -->
		<iso:rule context="//stri:Voorschriften[not(ancestor::stri:Plan/@Contour)]">
	
			<iso:let name="bestandsprefixenRegexp" value="'v_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml)'"/>
					
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:Voorschriften[ancestor::stri:Plan/@Contour='true']">
	
			<iso:let name="bestandsprefixenRegexp" value="'v_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.pdf)'"/>
					
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>


		<iso:rule context="//stri:VoorschriftenBijlage">
			<!-- onderdeel VoorschriftenBijlage valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'vb_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.pdf'"/>
					
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>

		<iso:rule context="//stri:Toelichting">
			<!-- onderdeel Toelichting valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'t_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.pdf'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:ToelichtingBijlage">
			<!-- onderdeel ToelichtingBijlage valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'tb_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.pdf'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:BesluitDocument">
			<!-- onderdeel BesluitDocument valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'bd_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:BeleidsDocument">
			<!-- onderdeel BeleidsDocument valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'d_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.pdf'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:BeleidsDocumentBijlage">
			<!-- onderdeel BeleidsDocumentBijlage valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'db_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.pdf'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>

		<iso:rule context="//stri:BeleidsTekst">
			<!-- onderdeel BeleidsTekst valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'b_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.html|\.htm|\.xhtml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:PlanKaart">
			<!-- onderdeel PlanKaart valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'p_'"/>
			<iso:let name="extensionCheckRegexp" value="'\.pdf'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		</iso:rule>
		
		<iso:rule context="//stri:GeleideFormulier">
			<!-- onderdeel GeleideFormulier valideren -->

			<iso:let name="bestandsprefixenRegexp" value="'g_'"/>
			<iso:let name="extensionCheckRegexp" value="'(\.xml|\.pdf)'"/>
		
			<iso:extends rule="bestandsnaamRegexpAndPlanIdCheck"/>
		
		</iso:rule>


		<!-- 
			Abstracte regel die 10x gebruikt wordt.
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
die niet voldoet aan de bestandsnaamconventies van STRI2006. 
De prefix had moeten zijn: '<iso:value-of select="$bestandsprefixenRegexp"/>'.
			</iso:assert>

			<iso:let name="bestandsnaamNaPrefix" value="substring-after(text(),'_')"/>
			<iso:let name="bestandsnaamNaPrefixBegintMetPlanId" 
				value="starts-with($bestandsnaamNaPrefix, $detectedPlanId)"/>

  			<iso:assert test="$bestandsnaamNaPrefixBegintMetPlanId">
Foutcode AD5C: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2006. 
De planId (<iso:value-of select="$detectedPlanId"/>) volgt niet onmiddelijk na de prefix. 
			</iso:assert>

			<iso:let name="bestandsnaamHeeftJuisteExtensie" value="regexp:matches(text(),concat('.*',$extensionCheckRegexp))"/>
							
			<iso:let name="toegestaneExtensies" value="translate($extensionCheckRegexp,'(\.|)','  ., ')"/>
			
			<iso:assert test="$bestandsnaamHeeftJuisteExtensie">
Foutcode AD5D: planonderdeel <iso:value-of select="name()"/> van plan (Id='<iso:value-of select="$detectedPlanId"/>') 
bevat een bestandsnaam (huidige waarde "<iso:value-of select="text()"/>") 
die niet voldoet aan de bestandsnaamconventies van STRI2006. 
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



</iso:schema>