class ReutherAccessionsReport < AbstractReport

  register_report({
    :params => [["unprocessed", "Boolean", "Include only unprocessed accessions"],
                ["from", Date, "The start of report range"],
                ["to", Date, "The end of report range"],
                ["Classification", "classification", "The accession classification"]]
  })

  def initialize(params, job, db)
    super

    from, to = ReutherReportsHelpers.parse_date_params(params)
    @from = ReutherReportsHelpers.format_date(from)
    @to = ReutherReportsHelpers.format_date(to)

    @unprocessed_only = params["unprocessed"]

    if ASUtils.present?(params['classification'])
      @classification = params["classification"]
    else
      @classification = false
    end

  end

  def query
    results = db.fetch(query_string)
    if @classification
      info[:classification] = @classification
    end
    if @unprocessed_only
      info[:processing_status] = "Unprocessed"
    else
      info[:processing_status] = "Processed and unprocessed"
    end
    info[:total_count] = "#{results.count} accessions"
    accession_ids = results.map{|result| result[:id]}
    extent_totals = db[:extent].select_group(:extent_type_id).select_append{sum(number).as(totalExtent)}.where(:accession_id=>accession_ids)
    extents = []
    extent_totals.each do |extent_total|
      ReportUtils.fix_decimal_format(extent_total, [:totalExtent])
      extent_number = extent_total[:totalExtent]
      extent_type = db[:enumeration_value][:id => extent_total[:extent_type_id]][:value]
      extents.push("#{extent_number} #{extent_type}")
    end
    info[:total_extent] = extents.join(", ")

    results
  end

  def parse_accession_identifier(row)
    identifier_json = ASUtils.json_parse(row[:identifier])
    identifier_json.each_with_index do |id_part, id_index|
      row["id_#{id_index}".to_sym] = id_part
    end
  end

  def fix_row(row)
    parse_accession_identifier(row)
    row[:accession_num] = row[:id_0]
    row[:accession_num_date] = row[:id_1]
    row[:accession_num_part] = row[:id_2]
    row[:processing_status] = row[:processing_status] ? row[:processing_status] : "UNKNOWN"
    row.delete(:identifier)
    row.delete(:id_0)
    row.delete(:id_1)
    row.delete(:id_2)
    row.delete(:id_3)
  end

  def query_string
    date_condition = ReutherReportsHelpers.format_date_condition(db.literal(@from), db.literal(@to), 'accession.accession_date')

    processing_status_condition = if @unprocessed_only
                                    "(processing_status IS NULL or processing_status not in ('processed', 'deaccession'))"
                                  else
                                    "1=1"
                                  end

    classification_condition =  if @classification
                                  "(classification_1=#{db.literal(@classification)} or classification_2=#{db.literal(@classification)})"
                                else
                                  "1=1"
                                end

    "select
      id,
      accession.identifier,
      '' as accession_num,
      '' as accession_num_date,
      '' as accession_num_part,
      classification_1,
      classification_2,
      title,
      accession_date,
      extent_number_type,
      processing_status,
      coll_mgmt_processing_status,
      processing_priority,
      location
    from accession
      natural left outer join
      (select
        accession_id as id,
        GROUP_CONCAT(DISTINCT(enumeration_value.value) SEPARATOR '; ') as processing_status
      from event_link_rlshp, event, enumeration_value
      where event_link_rlshp.event_id = event.id
        and event.event_type_id = enumeration_value.id
        and enumeration_value.value in ('processed', 'processing_started', 'processing_new', 'processing_in_progress', 'processing_partial', 'deaccession', 'processing_queue', 'processing_started')
      group by accession_id) as processing_status
      
      natural left outer join
      (select
        accession_id as id,
        GROUP_CONCAT(CONCAT(number, ' ', enumeration_value.value) SEPARATOR '; ') as extent_number_type
      from extent
      join enumeration_value on enumeration_value.id=extent.extent_type_id
      group by accession_id) as extent_cnt
      
      natural left outer join
      (select
        accession_id as id,
        enumval_processing_status.value as coll_mgmt_processing_status,
        enumval_processing_priority.value as processing_priority
      from collection_management
        left outer join enumeration_value as enumval_processing_status on enumval_processing_status.id=collection_management.processing_status_id
        left outer join enumeration_value as enumval_processing_priority on enumval_processing_priority.id=collection_management.processing_priority_id
        group by accession_id, coll_mgmt_processing_status, processing_priority) as collection_management
      
      natural left outer join
      (select
        accession_id as id,
        enumval_enum_1.value as classification_1,
        enumval_enum_2.value as classification_2,
        CONCAT_WS('; ', text_1, text_2, text_3, text_4, string_1, string_2, string_3, string_4) as location
      from user_defined
        left outer join enumeration_value as enumval_enum_1 on enumval_enum_1.id=user_defined.enum_1_id
        left outer join enumeration_value as enumval_enum_2 on enumval_enum_2.id=user_defined.enum_2_id) as user_defined
      
    where repo_id = #{db.literal(@repo_id)} and #{date_condition} and #{processing_status_condition} and #{classification_condition}
    order by accession_date desc"
  end

  def page_break
    false
  end
  
end
