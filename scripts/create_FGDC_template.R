library(magrittr)
library(xml2)

#' @param file.out the file to write the template to
create_FGDC_template <- function(file.out){
  tempxml <- tempfile(fileext = '.xml')
  
  d <- xml_new_document()
  mt <-  xml_add_child(d, "metadata")
  m <- xml_add_child(mt, "idinfo")
  
  # <---Bibliodata--->
  m %>%  xml_add_child("citation") %>%
    xml_add_child("citeinfo") %>%
    xml_add_child("origin-template") %>%
    xml_add_sibling('pubdate', "{{pubdate}}") %>%
    xml_add_sibling('title', "{{title}}") %>%
    xml_add_sibling('geoform', "text files") %>%
    xml_add_sibling('onlink', "{{doi}}") %>% 
    xml_add_sibling('lworkcit-template')
  
  m %>%
    xml_add_child('descript') %>%
    xml_add_child("abstract",'{{abstract}}') %>%
    xml_add_sibling("purpose", '{{purpose}}')
  
  m %>%
    xml_add_child('timeperd') %>%
    xml_add_child("timeinfo") %>%
    xml_add_child("rngdates") %>%
    xml_add_child('begdate','{{start-date}}') %>%
    xml_add_sibling('enddate','{{end-date}}')
  m %>%
    xml_add_child('status') %>%
    xml_add_child("progress", "Complete") %>% 
    xml_add_sibling('update','{{update}}') 
  # </---Bibliodata--->
  
  # <---Spatial--->
  m %>% 
    xml_add_child('spdom') %>% 
    xml_add_child('bounding') %>% 
    xml_add_child('westbc', "{{wbbox}}") %>% 
    xml_add_sibling('eastbc', "{{ebbox}}") %>% 
    xml_add_sibling('northbc', "{{nbbox}}") %>% 
    xml_add_sibling('southbc', "{{sbbox}}")
  # </---Spatial--->
  
  # <---Keywords--->
  k <- xml_add_child(m, 'keywords') 
  
  k %>% 
    xml_add_child('theme', "
                  <themekt>none</themekt>
                  {{#themekeywords}}
                  <themekey>{{.}}</themekey>
                  {{/themekeywords}}")
  
  k %>% 
    xml_add_child('theme') %>% 
    xml_add_child('themekt','ISO 19115 Topic Category') %>% 
    xml_add_sibling('themekey','environment') %>% 
    xml_add_sibling('themekey','inlandWaters') %>% 
    xml_add_sibling('themekey','007') %>% 
    xml_add_sibling('themekey','012') 
  
  k %>% 
    xml_add_child('place') %>% 
    xml_add_child('placekt','Department of Commerce, 1995, Countries, Dependencies, Areas of Special Sovereignty, and 
                  Their Principal Administrative Divisions,  Federal Information Processing Standard (FIPS) 10-4, 
                  Washington, D.C., National Institute of Standards and Technology') %>% 
    xml_add_sibling('placekey','United States') %>% 
    xml_add_sibling('placekey','US')
  k %>% 
    xml_add_child('place-template')
  
  k %>% 
    xml_add_child('state-template')
  # </---Keywords--->  
  
  # <---Contact people --->
  p <- xml_add_child(m, 'accconst','none')
  
  pt <-  xml_add_child(m,'ptcontac') 
  
  pt %>% 
    xml_add_child('cntinfo') %>% 
    xml_add_child('cntperp') %>% 
    xml_add_child('cntper','{{contact-person}}') %>% 
    xml_add_sibling('cntorg','U.S. Geological Survey')
  
  p %>% 
    xml_add_sibling('useconst','{{usage-rules}}')
  
  pt %>% xml_add_child('cntaddr') %>% 
    xml_add_child('addrtype','Mailing and Physical') %>% 
    xml_add_sibling('address', '8551 Research Way') %>% 
    xml_add_sibling('city','Middleton') %>% 
    xml_add_sibling('state','WI') %>% 
    xml_add_sibling('postal','53562') %>% 
    xml_add_sibling('country','U.S.A.')
  
  pt %>%  xml_add_child('cntvoice','{{contact-phone}}') %>% 
    xml_add_sibling('cntemail','{{contact-email}}')
  # </---Contact people --->
  
  # <---Credit and external bibliodata--->
  m %>% 
    xml_add_child('datacred','{{funding-credits}}') %>% 
    xml_add_sibling('native','{{build-environment}}') %>% 
    xml_add_sibling('crossref') %>% 
    xml_add_child('citeinfo') %>% 
    xml_add_child('origin','{{cite-authors}}') %>% 
    xml_add_sibling('pubdate','{{cite-date}}') %>% 
    xml_add_sibling('title','{{cite-title}}') %>% 
    xml_add_sibling('geoform','{{paper}}') %>% 
    xml_add_sibling('pubinfo') %>% 
    xml_add_child('pubplace',"{{publisher}}") %>% 
    xml_add_sibling('publish','{{journal}}')
  # </---Credit and external bibliodata--->
  
  # <---Data quality--->
  q <- xml_add_child(mt, 'dataqual')
  
  q %>% xml_add_child('attracc') %>% 
    xml_add_child('attraccr','No formal attribute accuracy tests were conducted.')
  
  q %>% xml_add_child('logic','not applicable') %>% 
    xml_add_sibling('complete','not applicable')
  
  p <- xml_add_child(mt, 'posacc') 
  p %>% xml_add_child('horizpa') %>% 
    xml_add_child('horizpar','A formal accuracy assessment of the horizontal positional information in the data set has not been conducted.')
  
  p %>% 
    xml_add_child('vertacc') %>% 
    xml_add_child('vertaccr','A formal accuracy assessment of the vertical positional information in the data set has either not been conducted, or is not applicable.')
  
  xml_add_sibling(p, 'spdoinfo') %>% 
    xml_add_child('indspref','{{indirect-spatial}}') %>% 
    xml_add_sibling('direct','Point') %>% 
    xml_add_sibling('ptvctinf') %>% 
    xml_add_child('sdtsterm') %>% 
    xml_add_child('sdtstype','Point') %>% 
    xml_add_sibling('ptvctcnt','{{point-count}}')
  # </---Data quality--->
  
  # <---Processing steps--->
  p %>% xml_add_sibling('lineage') %>% 
    xml_add_child('procstep') %>% 
    xml_add_child('procdesc','{{process-description}}') %>% 
    xml_add_sibling('procdate','{{process-date}}')
  
  s <- xml_add_child(mt, 'spref')
  h <- xml_add_child(s, 'horizsys') 
  h %>% 
    xml_add_child('geograph') %>% 
    xml_add_child('latres','{{latitude-res}}') %>% 
    xml_add_sibling('longres','{{longitude-res}}') %>% 
    xml_add_sibling('geogunit','Decimal degrees')
  
  h %>% xml_add_child('geodetic') %>% 
    xml_add_child('horizdn','North American Datum of 1983') %>% 
    xml_add_sibling('ellips','Geodetic Reference System 80') %>% 
    xml_add_sibling('semiaxis','6378137.0') %>% 
    xml_add_sibling('denflat','298.257')
  
  dt <- xml_add_child(mt, 'eainfo') %>% 
    xml_add_child('detailed')
  dt %>% 
    xml_add_child('enttyp') %>% 
    xml_add_child('enttypl','{{data-name}}') %>% 
    xml_add_sibling('enttypd','{{data-description}}') %>% 
    xml_add_sibling('enttypds','Producer Defined')
  # </---Processing steps--->
  
  # <---Dataset details--->
  dt %>% xml_add_child('attr-template')
  # </---Dataset details--->
  
  # <---Distribution--->
  ds <- xml_add_child(mt, 'distinfo')
  db <- xml_add_child(ds, 'distrib')
  ci <-  xml_add_child(db, 'cntinfo')
  ci %>% 
    xml_add_child('cntperp') %>% 
    xml_add_child('cntper','{{distro-person}}') %>% 
    xml_add_sibling('cntorg','U.S. Geological Survey - ScienceBase')
  
  ci %>% xml_add_child('cntaddr') %>% 
    xml_add_child('addrtype','Mailing and Physical') %>% 
    xml_add_sibling('address','Denver Federal Center, Building 810, Mail Stop 302') %>% 
    xml_add_sibling('city','Denver') %>% 
    xml_add_sibling('state','CO') %>% 
    xml_add_sibling('postal','80255') %>% 
    xml_add_sibling('country','U.S.A.')
  ci %>% xml_add_child('cntvoice','1-888-275-8747') %>% 
    xml_add_sibling('cntemail','sciencebase@usgs.gov')
  
  ds %>% xml_add_child('distliab','{{liability-statement}}')
  so <- xml_add_child(ds, 'stdorder')
  # </---Distribution--->
  
  # <---Files--->
  df <-  xml_add_child(so, 'digform')
  df %>% 
    xml_add_child('digtinfo') %>% 
    xml_add_child('formname','{{file-format}}') %>% 
    xml_add_sibling('formvern','none')
  
  df %>% 
    xml_add_child('digtopt') %>% 
    xml_add_child('onlinopt') %>% 
    xml_add_child('computer') %>% 
    xml_add_child('networka') %>% 
    xml_add_child('networkr','{{doi}}')
  # </---Files--->
  
  xml_add_child(so,'fees','None')
  
  # <---Metadata creator--->
  mi <- xml_add_child(mt, 'metainfo')
  mi %>% 
    xml_add_child('metd','{{metadata-date}}') %>% 
    xml_add_sibling('metc')
  cni <- xml_add_child(mi,'cntinfo')
  cni %>% 
    xml_add_child('cntperp') %>% 
    xml_add_child('cntper','{{metadata-person}}') %>% 
    xml_add_sibling('cntorg','U.S. Geological Survey')
  cni %>% 
    xml_add_child('cntpos','Data Chief') %>% 
    xml_add_sibling('cntaddr') %>%
    xml_add_child('addrtype','Mailing and Physical') %>% 
    xml_add_sibling('address','8551 Research Way #120') %>% 
    xml_add_sibling('city','Middleton') %>% 
    xml_add_sibling('state','WI') %>% 
    xml_add_sibling('postal','53562') %>% 
    xml_add_sibling('country','U.S.A.')
  cni %>% 
    xml_add_child('cntvoice','{{metadata-phone}}') %>% 
    xml_add_sibling('cntfax','608 821-3817') %>% 
    xml_add_sibling('cntemail','{{metadata-email}}')
  mi %>% 
    xml_add_child('metstdn','FGDC Biological Data Profile of the Content Standard for Digital Geospatial Metadata') %>% 
    xml_add_sibling('metstdv','FGDC-STD-001.1-1999')
  # </---Metadata creator--->
  
  write_xml(d, file = tempxml)
  
  place.template = "{{#states}}
    <place>\n\t\t\t<placekt>U.S. Department of Commerce, 1987, Codes for the identification of the States, the District of Columbia and the outlying areas of the United States, and associated areas (Federal Information Processing Standard 5-2): Washington, D. C., NIST</placekt>
      <placekey>{{state-name}}</placekey>
      <placekey>{{state-abbr}}</placekey>
    </place>
    {{/states}}"
  
  state.template = "{{#states}}<place>
      <placekt>none</placekt>
      <placekey>{{state-name}}</placekey>
    </place>
    {{/states}}"
  
  origin.template = "{{#authors}}
      <origin>{{.}}</origin>
      {{/authors}}"
  attr.template = "{{#attributes}}<attr>
          <attrlabl>{{attr-label}}</attrlabl>
          <attrdef>{{attr-def}}</attrdef>
          <attrdefs>{{attr-defs}}</attrdefs>
          <attrdomv>
            <rdom>
              <rdommin>{{data-min}}</rdommin>
              <rdommax>{{data-max}}</rdommax>
              <attrunit>{{data-units}}</attrunit>
            </rdom>
          </attrdomv>
        </attr>\n{{/attributes}}"
  
  lworkcit.template = "{{#larger-cites}}<lworkcit>
          <citeinfo>
  {{#authors}}
      <origin>{{.}}</origin>
  {{/authors}} 
      <pubdate>{{pubdate}}</pubdate>
      <title>{{title}}</title>
  {{#link}}
      <onlink>{{.}}</onlink>
  {{/link}} 
  </citeinfo>
  </lworkcit>\n{{/larger-cites}}"
  
  suppressWarnings(readLines(tempxml)) %>% 
    gsub(pattern = '&gt;',replacement = '>',.) %>% 
    gsub(pattern = '&lt;',replacement = '<',.) %>% 
    gsub(pattern = '<place-template/>', replacement = place.template) %>% 
    gsub(pattern = '<state-template/>', replacement = state.template) %>% 
    sub(pattern = '<origin-template/>', replacement = origin.template) %>% 
    gsub(pattern = '<attr-template/>', replacement = attr.template) %>% 
    gsub(pattern = '<lworkcit-template/>', replacement = lworkcit.template) %>% 
    cat(file = file.out, sep = '\n')
  return(file.out)
}

