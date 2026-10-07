require "minitest/autorun"
require "csv"
require "tmpdir"

require_relative "../../scripts/dump_techevents"

class DumpTechEventsTest < Minitest::Test
  def api_event(id, title, region: "auckland")
    {
      "id" => id,
      "title" => title,
      "start_date" => "2026-11-01",
      "registration_url" => "https://example.com/#{id}",
      "locations" => [ { "region" => region, "city" => "Auckland CBD" } ],
      "approved" => true
    }
  end

  def test_writes_every_event_with_techevents_headers
    Dir.mktmpdir do |dir|
      path = File.join(dir, "techevents_all.csv")
      count = TechEventsDump.write([ api_event(1, "First"), api_event(2, "Second", region: "online") ], path)

      rows = CSV.read(path, headers: true)
      assert_equal 2, count
      assert_equal TECHEVENTS_HEADERS, rows.headers
      assert_equal %w[1 2], rows.map { |r| r["id"] }
      assert_equal "https://example.com/2", rows[1]["registration_url"]
      assert_equal "online", rows[1]["regions"]
    end
  end

  def test_keeps_events_already_matched_in_events_csv
    # Unlike pull_techevents.rb, the dump must not filter out events whose id
    # appears in data/events.csv: dedupe checks need the whole live site.
    Dir.mktmpdir do |dir|
      path = File.join(dir, "techevents_all.csv")
      TechEventsDump.write([ api_event(7, "Matched to the sheet") ], path)

      assert_equal [ "7" ], CSV.read(path, headers: true).map { |r| r["id"] }
    end
  end
end
