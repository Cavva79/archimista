xml.control :repositoryencoding => "iso15511",
  :countryencoding => "iso3166-1",
  :dateencoding => "iso8601",
  :scriptencoding => "iso15924",
  :langencoding => "iso639-2b",
  :relatedencoding => "ISAD(G)" do
  xml.recordid fond.name, {:instanceurl => "#{FONDS_URL}/#{fond.id}"}
  xml.filedesc do
    xml.titlestmt do
      xml.titleproper fond.name, {:encodinganalog => "title"}
    end
  end
  xml.maintenancestatus :value => "new" 
  xml.maintenanceagency do
    xml.agencyname "#{PROVIDER}"
  end
  xml.languagedeclaration do
    xml.language :langcode => "ita"
    xml.script :scriptcode => "Italian"
  end
  xml.conventiondeclaration do
    xml.citation "SAN"
  end
  xml.maintenancehistory do
    xml.maintenanceevent do
      xml.eventtype :value => "created"
      xml.eventdatetime ""
      xml.agenttype :value => "human"
      xml.agent ""
    end
  end
  
  # Estensione 2018
  # Modifica
  # E' il contenuto dei vecchi tag ead..relations.relation
  # Eliminati i document_forms
  # Relazioni con una scheda o citazione bibliografica (fonti - sources)
  #   scheda bibliografica (source_type_code = 1)
  #   fonte a corredo (source_type_code = 2)
  #   fonte archivistica (source_type_code = 3)
  #   fonte normativa (source_type_code = 4)
  fond_sources = fond.sources
  if fond_sources.present?
    xml.sources do
      fond_sources.each do |fond_source|
        sr_id_str = sprintf '%08d', fond_source.id
        xml.source :id => "SR-#{sr_id_str}", :href => "#{SOURCES_URL}/#{fond_source.id}", :linkrole => "URL" do
          xml.sourceentry fond_source.title
        end
      end
    end
  end
end

fond_first_levels = {
  "archivio" => "fonds",
  "fondo" => "fonds",
  "complesso di fondi" => "recordgrp",
  "iperfondo" => "recordgrp",
  "subfondo" => "subfonds",
  "sezione" => "subfonds",
  "partizione" => "subfonds",
  "sottopartizione" => "subfonds",
  "parte" => "subfonds",
  "serie" => "series",
  "sottoserie" => "subseries",
  "sottosottoserie" => "subseries",
  "sottosezione" => "otherlevel",
  "categoria" => "otherlevel",
  "classe" => "otherlevel",
  "sottoclasse" => "otherlevel",
  "rubrica" => "otherlevel",
  "voce" => "otherlevel",
  "sottovoce" => "otherlevel",
  "titolo" => "otherlevel",
  "sottotitolo" => "otherlevel",
  "articolo" => "otherlevel"
}
fond_second_levels = {"fascicolo" => "file", "unità" => "item"}

ca_id_str = sprintf '%08d', fond.id
if !fond.fond_type.present?
  tags = {:level => "fonds", :id => "CA-#{ca_id_str}"}
else
  level = fond.fond_type
  if (fond_first_levels[level] == "otherlevel")
    tags = {:level => "otherlevel", :otherlevel => level, :id => "CA-#{ca_id_str}"}
  else
    tags = {:level => fond_first_levels[level], :id => "CA-#{ca_id_str}"}
  end
end

xml.archdesc tags do
  xml.did do
    xml.physdescstructured :physdescstructuredtype => "spaceoccupied", :coverage => "whole" do
      xml.quantity fond.length.blank? ? "" : fond.length
      xml.unittype fond.length.blank? ? "" : "ml"
      if !fond.extent.blank?
        xml.descriptivenote do
          xml.p fond.extent 
        end
      end
    end
    
    fond_custodians = fond.custodians
    if fond_custodians.count > 0
      xml.repository do
        fond_custodians.each do |custodian|
          id = custodian.custodian_identifiers.first
          if id.nil?
            sc_id_str = sprintf '%08d', custodian.id
            xml.corpname :id => "SC-#{sc_id_str}" do 
              xml.part custodian.preferred_name.name
            end
          else
            xml.corpname :identifier => id.identifier do 
              xml.part custodian.preferred_name.name
            end
          end
          building = custodian.custodian_buildings.first
          if !building.address.blank?
            xml.address do
              xml.addressline building.address + ", " +  building.postcode + ", " +  building.city
            end
          end
        end
      end
    end
    
    fond_creators = fond.creators
    if fond_creators.count > 0
      xml.origination do
        fond_creators.each do |creator|
          id = creator.creator_identifiers.first
		  sp_id_str = sprintf '%08d', creator.id
          case creator.creator_type
          when 'C'
            if id.nil?
              xml.corpname :identifier => "SP-#{sp_id_str}" do
                xml.part creator.preferred_name.name
              end
            else
              xml.corpname :identifier => id.identifier do
                xml.part creator.preferred_name.name
              end
            end
          when 'P'
            if id.nil?
              xml.persname :identifier => "SP-#{sp_id_str}" do
                xml.part creator.preferred_name.name
              end
            else
              xml.persname :identifier => id.identifier do
                xml.part creator.preferred_name.name
              end
            end            
          when 'F'
            if id.nil?
              xml.famname :identifier => "SP-#{sp_id_str}" do
                xml.part creator.preferred_name.name
              end
            else
              xml.famname :identifier => id.identifier do
                xml.part creator.preferred_name.name
              end
            end            
          end
        end
      end
    end
    
    fond.fond_identifiers.each do |id|
      xml.unitid "CA-#{ca_id_str}", { :localtype => "#{fond.fond_type}", :repositorycode => "#{id.identifier}" }
    end

    # Estensione 2018
    # Modifica
    xml.unittitle fond.name, {:localtype => "Denominazione"}
    other_names = fond.other_names
    other_names.each do |on|
      xml.unittitle on.name, {:localtype => "altreDenominazioni"}
    end

    # Estensione 2018
    # Modifica
    # Gestione delle date
    if fond.preferred_event.present? && fond.preferred_event.valid?
      xml.unitdatestructured do
        xml.dateset do
          #datesingle
          if fond.preferred_event.start_date_from == fond.preferred_event.end_date_from && fond.preferred_event.start_date_to == fond.preferred_event.end_date_to            
            if fond.preferred_event.start_date_from == fond.preferred_event.start_date_to
              xml.datesingle fond.preferred_event.start_date_display, { :standarddate => fond.preferred_event.start_date_from }.reject{ |k,v| v.nil? }
            else 
              xml.datesingle fond.preferred_event.start_date_display, { :notbefore => fond.preferred_event.start_date_from, :notafter => fond.preferred_event.start_date_to }.reject{ |k,v| v.nil? }
            end
          #daterange
          else
            xml.daterange do
              xml.fromdate fond.preferred_event.start_date_display, { :standarddate => fond.preferred_event.start_date_from }.reject{ |k,v| v.nil? }
              xml.todate fond.preferred_event.end_date_display, { :standarddate => fond.preferred_event.end_date_to }.reject{ |k,v| v.nil? }
            end
          end
          
          xml.datesingle fond.preferred_event.note, {:localtype => "noteAllaData"}
        end
      end      
    end    
  end
  if fond.history.present?
    xml.custodhist do
      xml.p fond.history
    end
  end
  if fond.description.present?
    xml.scopecontent do
      xml.p fond.description
    end
  end
  if fond.access_condition.present?
    xml.accessrestrict do
      xml.p fond.access_condition_note
    end
  end

  # Estensione 2018
  # Modifica
  xml.processinfo do
    xml.p "Pubblicata"    
  end

  # Estensione 2018
  # Aggiunta
  # Compilatore della singola entità (compilatori - fond_editors)
  fond_editors = fond.fond_editors
  if (fond_editors.present?)
    fond_editors_event_type = {"aggiornamento scheda" => "updated", "inserimento dati" => "created",
      "integrazione successiva" => "updated", "prima redazione" => "created",
      "revisione" => "revised", "rielaborazione" => "revised", "schedatura" => "created"}
    xml.processinfo :localtype => "compilatori" do
      fond_editors.each do |fe|
        xml.processinfo :localtype => "compilatore" do
          xml.p do
            xml.persname do
              xml.part fe.name, {:localtype => "compilatore"}
              xml.part fe.qualifier, {:localtype => "qualifica"}
              xml.part fond_editors_event_type[fe.editing_type], {:localtype => "tipoIntervento"}
            end
            xml.date fe.edited_at, {:localtype => "dataIntervento"}
          end
        end
      end
    end
  end

  # Estensione 2018
  # Aggiunta
  # Relazione con Tipologia Documentaria (profili documentari - document_forms)
  fond_document_forms = fond.document_forms
  if (fond_document_forms.present?)
    xml.controlaccess do
      fond_document_forms.each do |fdf|        
        xml.genreform do
          xml.part fdf.name, { :localtype => "denominazione" }
          xml.part fdf.description, { :localtype => "descrizione" }
          xml.part fdf.note, { :localtype => "note" }
        end        
      end
    end
  end
  
  xml.dsc do
    if fond.has_children?
      xml << render(:partial => "ead_fonds.xml", :locals => { :fonds => fond.children.where("id != #{fond.id} AND trashed = 0").order(:sequence_number) } )
    end
  end
end
