# Beschikbaarheid gemeentelijke subsidieregisters — mei 2025

Inventarisatie van welke gemeenten een openbaar subsidieregister publiceren,
in welk formaat, en of cultuursubsidies eruit te filteren zijn. Doel: bepalen
voor welke gemeenten we geautomatiseerd subsidieontvanger en -bedrag kunnen
koppelen aan de Iv3-uitgavencijfers.

## Samenvatting

Van de 30 onderzochte gemeenten (top 20 cultuurbesteders + 10 aanvullende)
publiceert **21 een subsidieregister** in enige vorm. Echter, slechts **7**
bieden machineleesbare data (API, CSV of Excel). De rest publiceert
uitsluitend als PDF of HTML.

| Categorie | Aantal | Gemeenten |
|---|---:|---|
| REST API / JSON | 1 | Amsterdam |
| CSV op data.overheid.nl | 2 | Zaanstad, Den Haag |
| Excel download | 4 | Utrecht, Groningen, Arnhem, Delft (via dashboard) |
| PDF | 8 | Tilburg, Amersfoort, Breda, Maastricht, Dordrecht, Deventer, Eindhoven, Haarlem |
| HTML-tabellen | 4 | Almere, Bergen op Zoom, Venlo, Hilversum |
| Power BI dashboard | 1 | Leiden |
| Niets gevonden | 9 | Rotterdam, Nijmegen, 's-Hertogenbosch, Enschede, Apeldoorn, Hoorn, Tiel, Leeuwarden, Zwolle |

## Tier 1 — Machineleesbaar, direct inzetbaar

### Amsterdam — REST API

- **URL:** `api.data.amsterdam.nl/v1/subsidies/openbaar_subsidieregister/`
- **Formaat:** JSON (ook CSV via `?_format=csv`)
- **Velden:** aanvrager, bedragVerleend, bedragVastgesteld, bedragAangevraagd,
  beleidsterrein, organisatieonderdeel, projectnaam, regelingnaam, subsidiejaar
- **Cultuurfilter:** `beleidsterrein=Cultuur`
- **Dekking:** Alle subsidieaanvragen sinds 2012, wekelijks bijgewerkt
- **Licentie:** Open data
- **Aanpak:** HTTP client, JSON parsing, filteren op beleidsterrein en jaar.
  Paginering via `_pageSize` en `_page`. Eenvoudigste van alle bronnen.

### Den Haag — Webapplicatie + CSV/Excel

- **URL:** `subsidieregister.denhaag.nl`
- **Formaat:** CSV en Excel download, interactieve webinterface
- **Velden:** ontvanger, bedrag, programma/beleidsterrein, jaar
- **Cultuurfilter:** Ja, filter op programma
- **Dekking:** Vanaf 2012, per kwartaal bijgewerkt
- **Licentie:** CC-0
- **Aanpak:** CSV download URL achterhalen. Mogelijk via
  `ckan.dataplatform.nl/dataset/subsidie-register-den-haag-2017` of directe
  downloadlinks uit de webapplicatie.

### Utrecht — Excel

- **URL:** `open.utrecht.nl/dataset/subsidieregister-utrecht`
- **Formaat:** Excel (.xlsx)
- **Velden:** datum verlening, aanvrager, subsidiedoelstelling, regelingnaam,
  verleend bedrag, aanvraagnummer, boekjaar
- **Cultuurfilter:** Via regelingnaam (bijv. "Cultuurnota 2025-2028")
- **Dekking:** 2023–2026, maandelijks bijgewerkt
- **Licentie:** CC-0
- **Aanpak:** Excel downloaden, parsen met een library, filteren op
  regelingnaam. URL-patroon:
  `data.utrecht.nl/sites/default/files/open-data/subsidieregister-{jaar}.xlsx`

### Groningen — Excel

- **URL:** `gemeente.groningen.nl/openbaar-subsidieregister`
- **Formaat:** Excel en PDF
- **Velden:** instelling, deelprogramma, subsidiebedrag
- **Cultuurfilter:** Ja, via deelprogramma
- **Dekking:** 2015–2025, jaarlijks
- **Aanpak:** Excel downloaden en parsen. URL-patroon:
  `gemeente.groningen.nl/file/subsidieregister-{jaar}-excel`

### Arnhem — Excel

- **URL:** `open.arnhem.nl/data/open/Subsidieregister_Arnhem_{jaar}.xlsx`
- **Formaat:** Excel (.xlsx), twee werkbladen: "Dump" (data) + "Toelichting"
- **Velden:** Gedetailleerde specificatie van de subsidieparagraaf
- **Cultuurfilter:** Waarschijnlijk ja, via programmacategorieën
- **Dekking:** 2020–2024
- **Licentie:** Via data.overheid.nl
- **Aanpak:** Excel downloaden, structuur verifiëren, parsen.

### Zaanstad — CSV

- **URL:** `data.overheid.nl/dataset/subsidies-zaanstad-2023-organisaties`
- **Formaat:** CSV (op data.overheid.nl)
- **Velden:** regeling, ontvanger, bedrag
- **Cultuurfilter:** Ja, expliciet onder "Programma 5. Economie, kunst en
  cultuur"
- **Dekking:** 2016, 2023 op data.overheid.nl; 2024–2025 op website (HTML)
- **Licentie:** CC-0
- **Aanpak:** CSV downloaden. Directe URL:
  `ckan.dataplatform.nl/dataset/.../cv_dataset_subsidies_bedr_2023.csv`

### Delft — Dashboard met CSV-export

- **URL:** `delft.incijfers.nl/mosaic/dashboard-kerncijfers/subsidieregister`
- **Formaat:** Dashboard met export naar CSV, Excel en PDF
- **Velden:** instelling, bedrag, dimensie/categorie, tijdsperiode
- **Cultuurfilter:** Waarschijnlijk via dimensie-/categoriefilter
- **Aanpak:** Export-URL achterhalen of API van incijfers.nl-platform
  onderzoeken.

## Tier 2 — Gestructureerd maar niet machineleesbaar

### Venlo — HTML met cultuurcategorie

- **URL:** `venlo.nl/subsidieregister-{jaar}`
- **Formaat:** HTML-tabellen (2024–2025), PDF (2021–2022)
- **Velden:** subsidieaanvrager, bedrag
- **Cultuurfilter:** Ja, expliciet beleidsveld "cultuur" met subcategorieën:
  amateurkunst/volkscultuur, instellingen cultuur, meerjarenvoorzieningen
  cultuur, overige cultuur
- **Dekking:** 2021–2025
- **Aanpak:** HTML scrapen. Venlo heeft de meest gedetailleerde
  cultuurcategorisering van alle onderzochte gemeenten.

### Leiden — Power BI

- **URL:** Power BI dashboard (Microsoft-hosted)
- **Formaat:** Interactief dashboard, mogelijk met exportfunctie
- **Velden:** ontvanger, bedrag, beleidsterrein, jaar
- **Cultuurfilter:** Ja, via "Programma 8: Cultuur, Sport en Recreatie"
- **Aanpak:** Power BI export-API onderzoeken, of terugvallen op de
  begrotingsdocumentatie op `programmabegroting.leiden.nl` die ook
  subsidiedetails per instelling bevat (>EUR 100.000).

### Almere — HTML

- **URL:** `almere.nl/subsidies/subsidieregister/subsidieregister-{jaar}`
- **Formaat:** HTML-tabellen
- **Velden:** aanvrager, project, status, verleend bedrag, vastgesteld bedrag
- **Cultuurfilter:** Nee, geen beleidsterreinkolom
- **Dekking:** 2020–2024, maandelijks bijgewerkt
- **Aanpak:** HTML scrapen. Culturele instellingen handmatig of via
  naamherkenning identificeren.

### Hilversum — HTML (jaarstukken)

- **URL:** `open.hilversum.nl/pages/subsidieregister`
- **Formaat:** HTML-tabellen in jaarstukken, ook ArcGIS-portal
- **Velden:** instelling, gerealiseerde subsidieverstrekkingen (2 jaar)
- **Cultuurfilter:** Via instellingsnaam (bijv. Podium De Vorstin, Filmtheater)
- **Aanpak:** HTML scrapen of ArcGIS-data onderzoeken.

### Bergen op Zoom — HTML

- **URL:** `bergenopzoom.nl/subsidieregisters`
- **Formaat:** HTML-tabellen
- **Velden:** organisatie, bedrag
- **Cultuurfilter:** Nee
- **Dekking:** 2023–2025
- **Aanpak:** HTML scrapen. Zeer beperkte data (alleen naam + bedrag).

## Tier 3 — Alleen PDF

### Tilburg
- **URL:** `tilburg.nl/inwoners/subsidies/` → "Verleende subsidies"
- Georganiseerd per instelling EN per programma; 2018–2025
- Cultuurfilter: ja via programmaverdeling

### Maastricht
- **URL:** `subsidies.gemeentemaastricht.nl/subsidieregister`
- Per kwartaal, sinds Q3 2024
- Velden: organisatie, bedrag, subsidieregeling, projectnaam
- Cultuurfilter: via subsidieregeling

### Amersfoort
- **URL:** `amersfoort.nl/subsidieregister`
- Jaarlijks PDF; 2022–2024

### Breda
- **URL:** `breda.nl/subsidies` → PDF per kwartaal
- Open data op data.breda.nl maar alleen 2017-versie
- PDF Q3 2024 beschikbaar

### Dordrecht
- **URL:** `cms.dordrecht.nl/.../Openbaar_subsidieregister`
- Halfjaarlijks PDF; 2018–2024

### Deventer
- **URL:** `deventer.nl/subsidieregister`
- Jaarlijks PDF; 2022–2024

### Eindhoven
- Alleen jaarlijkse PDF-rapporten "Subsidies in Eindhoven"
- Stichting Cultuur Eindhoven publiceert toegekende cultuursubsidies op
  cultuureindhoven.nl maar **zonder bedragen**

### Haarlem
- Alleen een PDF uit 2018 gevonden. Geen actueel register.

## Tier 4 — Niets gevonden

| Gemeente | Opmerking |
|---|---|
| Rotterdam | Ondanks grote open-data-portal geen subsidieregister. Data zit in jaarstukken. |
| Nijmegen | 660+ datasets op opendata.nijmegen.nl, maar geen subsidieregister |
| 's-Hertogenbosch | Alleen subsidie*regelingen*, geen register van verleende subsidies |
| Enschede | Niets gevonden op website of data.overheid.nl |
| Apeldoorn | Data-portaal aanwezig, maar geen subsidiedata |
| Hoorn | Niets gevonden |
| Tiel | Niets gevonden |
| Leeuwarden | Subsidieportaal vereist inlog; niets openbaar |
| Zwolle | Pagina bestaat maar retourneert 403; niet verifieerbaar |

## Landelijke initiatieven

### DUS-I (Dienst Uitvoering Subsidies aan Instellingen)
- **URL:** `dus-i.nl/subsidieregister`
- **Status:** Nieuw register, gelanceerd januari 2025
- **Dekking:** Rijkssubsidies van VWS en OCW (incl. cultuur)
- **Formaat:** Webzoekinterface, geen bevestigde download
- **Relevantie:** Complementair — dekt rijkscultuursubsidies (Rijksmuseum,
  nationale orkesten etc.), niet gemeentelijk

### data.overheid.nl — Subsidiecommunity
- **Status:** Actief maar nauwelijks gebruikt
- **Deelnemende gemeenten:** 2 (Amsterdam en Meppel)
- **Beoordeling:** Na 10 jaar is adoptie vrijwel nihil

### Subsidietrekker.nl (Open State Foundation)
- **Status:** Effectief dood (502-fout). Laatste updates uit 2016.
- **Historische scope:** 162.179 subsidies van 206 overheidsorganisaties
- **Beoordeling:** Het meest ambitieuze eerdere initiatief, maar gestrand op
  gebrek aan gestandaardiseerde data

## Aanbevolen aanpak

### Fase 1 — Machineleesbare bronnen (7 gemeenten, ~EUR 500 mln cultuuruitgaven)

Importers bouwen voor de tier-1-bronnen:

| Gemeente | Type importer | Complexiteit |
|---|---|---|
| Amsterdam | HTTP/JSON API client | Laag |
| Den Haag | CSV download + parse | Laag |
| Utrecht | Excel download + parse | Laag |
| Groningen | Excel download + parse | Laag |
| Arnhem | Excel download + parse | Laag–middel |
| Zaanstad | CSV download + parse | Laag |
| Delft | Dashboard CSV export | Middel |

### Fase 2 — HTML scraping (5 gemeenten)

| Gemeente | Aanpak | Complexiteit |
|---|---|---|
| Venlo | HTML scrapen, cultuurcategorie direct beschikbaar | Middel |
| Leiden | Power BI export of begrotingsdocumentatie scrapen | Hoog |
| Almere | HTML scrapen, cultuurfilter handmatig | Middel |
| Hilversum | HTML/ArcGIS scrapen | Middel |
| Bergen op Zoom | HTML scrapen, zeer beperkte data | Laag |

### Fase 3 — PDF extractie (8 gemeenten)

PDF-parsing is foutgevoelig en breekbaar. Alleen zinvol als de
bovenstaande fasen niet voldoende dekking opleveren.

### Niet haalbaar (9 gemeenten)

Rotterdam, Nijmegen, 's-Hertogenbosch, Enschede, Apeldoorn, Hoorn, Tiel,
Leeuwarden, Zwolle — geen openbare data beschikbaar. Mogelijke routes:
Wob/Woo-verzoek, of wachten tot deze gemeenten vrijwillig publiceren.

## Dekking culturele uitgaven

Met de tier-1-bronnen (fase 1) dekken we:

| Gemeente | Cultuuruitgaven (Iv3) | Subsidieregister |
|---|---:|---|
| Amsterdam | 305,8 mln | API |
| Den Haag | 162,6 mln | CSV |
| Utrecht | 91,1 mln | Excel |
| Groningen | 82,6 mln | Excel |
| Arnhem | 53,5 mln | Excel |
| Zaanstad | ~15 mln (schatting) | CSV |
| Delft | 23,7 mln | Dashboard CSV |
| **Subtotaal** | **~735 mln** | |

Dit is circa **26%** van de totale gemeentelijke cultuuruitgaven (EUR 2.829
mln). Met de tier-2-bronnen erbij (Venlo, Leiden, Almere, Hilversum, Bergen
op Zoom) komen we op circa **30%**.

De ontbrekende **EUR 760 mln** van het totaal betreft voornamelijk Rotterdam
(EUR 200 mln, geen register) en de vele kleinere gemeenten die niets
publiceren.

## Databronnen

- [data.overheid.nl — Subsidies community](https://data.overheid.nl/community/group/subsidies-gemeenten)
- [Amsterdam Subsidies API](https://api.data.amsterdam.nl/v1/docs/datasets/subsidies.html)
- [Den Haag Subsidieregister](https://subsidieregister.denhaag.nl/)
- [Utrecht Subsidieregister](https://open.utrecht.nl/dataset/subsidieregister-utrecht)
- [Groningen Subsidieregister](https://gemeente.groningen.nl/openbaar-subsidieregister)
- [Arnhem Subsidieregister](https://opendata.arnhem.nl/)
- [Zaanstad Subsidieregister](https://data.overheid.nl/dataset/subsidies-zaanstad-2023-organisaties)
- [DUS-I Subsidieregister](https://www.dus-i.nl/subsidieregister)
- [Open State Foundation — Subsidietrekker](https://openstate.eu/en/projects-tools-data/finances/subsidietrekker/)
