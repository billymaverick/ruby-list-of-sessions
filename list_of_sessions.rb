require 'csv'
require 'date'
require 'duration' # gem

TEST_FILE = 'C:/Users/Isaac/Desktop/test_export.csv'

SPANISH = [""]

class Report

  attr_accessor :rows

  def initialize(rows)
    @rows = rows # This can be either a CSV::Table or just an array of rows
  end

  def filter (field, value)
    Report.new( @rows.select { |row| row[field] == value } )
  end

  def split_rows_by_unique_value(field)
    result = {}
    @rows.each do |row|
      value = row[field]
      if result.has_key? value
        result[value] << row
      else
        result[value] = [row]
      end
    end
    result.each do |key, table|
      result[key] = Report.new table
    end
    result
  end

  def duration
    durations = []
    rows.each do |row|
      durations << row[:duration]
    end
    durations.inject(&:+)
  end

  def duration_by_stage
    {transcribing: get_rows(:is_finished, 'No').duration,
     ready_for_qa: get_rows(:is_finished, 'Yes').get_rows(:qa, nil).duration,
     qa_in_progress: get_rows(:qa_status, 'Expires').duration,
     ready_for_review: get_rows(:qa_status, 'Submitted').get_rows(:status, 'In Progress').duration,
     review_in_progress: get_rows(:review_status, 'Expires').duration,
     complete: get_rows(:status, 'Completed').duration
    }
  end

  # Generate EOD report by segment
  def generate_report
    spanish = @rows.select
  end

  def yield_per_qa
    files_qa = get_rows(:qa_status, 'Submitted').split_rows_by_unique_value(:qa)
    result = {}
    files_qa.each do |key, report|
      result[key] = report.duration
    end
  end

  def self.create(filename)

    table = CSV.table(filename)

    # Format the CSV
    table.each do |row|

      # Convert duration string to a duration object
      hms = row[:duration].split(':').map(&:to_i)
      row[:duration] = Duration.new({:hours => hms[0], :minutes => hms[1], :seconds => hms[2]})

      # Edit QA field. TODO: QA session duration
      if row[:qa]
        qa, qstart, qstatus = row[:qa].split("\n")
        row[:qa] = qa
        row[:qa_status] = qstatus.split(':')[0]
      end

      # Edit review field TODO: Review session duration
      if row[:review]
        reviewer, start, rstatus = row[:review].split("\n")
        row[:review] = reviewer
        row[:review_status] = rstatus.split
      end
    end
    Report.new table
  end

  # Fix malformed csv due to commas in recording name
  def self.fix_csv (filename, new_filename)

    rows = CSV.read(filename)

    rows.each do |row|
      if row.length > 12
        offset = row.length - 8
        rec_name = row.slice!(4..offset).join
        row.insert(4, rec_name)
      end
    end

    CSV.open(new_filename, 'wb') do |csv|
      rows.each do |row|
        csv << row
      end
    end

    true

  end

end
