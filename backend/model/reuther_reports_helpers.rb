class ReutherReportsHelpers

  def self.format_date_condition(from, to, date_column)
    "(#{date_column} >= #{from} and #{date_column} <= #{to})"
  end

  def self.format_date(date)
    date.split(' ')[0].gsub('-', '')
  end

  def self.parse_date_params(params)
    if ASUtils.present?(params["from"])
      from = params["from"]
    else
      from = Time.new(1800, 01, 01).to_s
    end

    if ASUtils.present?(params["to"])
      to = params["to"]
    else
      to = Time.now.to_s
    end

    from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")
    [from, to]
  end

end