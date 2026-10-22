require "minitest/autorun"
require "date"
require "time"

# Load the module under test
require_relative "../../scripts/pull_events"

class DateParserTest < Minitest::Test
  # Standard format: "Mon 2nd Mar, 5:30pm"
  def test_weekday_ordinal_month_time
    result = SheetDateParser.parse("Mon 2nd Mar, 5:30pm", 2026, 3)
    assert_equal Date.new(2026, 3, 2), result[:start_date]
    assert_equal "17:30", result[:start_time]
    assert_nil result[:end_date]
  end

  # Time with am: "Tue 3rd Mar, 10am"
  def test_weekday_ordinal_month_am_time
    result = SheetDateParser.parse("Tue 3rd Mar, 10am", 2026, 3)
    assert_equal Date.new(2026, 3, 3), result[:start_date]
    assert_equal "10:00", result[:start_time]
  end

  # Date range: "9-11 March"
  def test_date_range
    result = SheetDateParser.parse("9-11 March", 2026, 3)
    assert_equal Date.new(2026, 3, 9), result[:start_date]
    assert_equal Date.new(2026, 3, 11), result[:end_date]
    assert_nil result[:start_time]
  end

  # Day only with full month: "Wed 11th March"
  def test_weekday_ordinal_full_month_no_time
    result = SheetDateParser.parse("Wed 11th March", 2026, 3)
    assert_equal Date.new(2026, 3, 11), result[:start_date]
    assert_nil result[:start_time]
  end

  # No weekday, ordinal + abbreviated month + time: "18th Mar, 12pm"
  def test_ordinal_month_time_no_weekday
    result = SheetDateParser.parse("18th Mar, 12pm", 2026, 3)
    assert_equal Date.new(2026, 3, 18), result[:start_date]
    assert_equal "12:00", result[:start_time]
  end

  # Date range abbreviated: "11-12 Mar"
  def test_date_range_abbreviated_month
    result = SheetDateParser.parse("11-12 Mar", 2026, 3)
    assert_equal Date.new(2026, 3, 11), result[:start_date]
    assert_equal Date.new(2026, 3, 12), result[:end_date]
  end

  # 12pm should be 12:00 not 00:00
  def test_12pm_is_noon
    result = SheetDateParser.parse("Fri 13th Mar, 12pm", 2026, 3)
    assert_equal "12:00", result[:start_time]
  end

  # 12am should be 00:00
  def test_12am_is_midnight
    result = SheetDateParser.parse("Fri 13th Mar, 12am", 2026, 3)
    assert_equal "00:00", result[:start_time]
  end

  # Time with minutes: "5:30pm"
  def test_time_with_minutes
    result = SheetDateParser.parse("Mon 2nd Mar, 5:30pm", 2026, 3)
    assert_equal "17:30", result[:start_time]
  end

  # Full month name in April tab
  def test_april_date
    result = SheetDateParser.parse("Mon 6th Apr, 5:30pm", 2026, 4)
    assert_equal Date.new(2026, 4, 6), result[:start_date]
    assert_equal "17:30", result[:start_time]
  end

  # Graceful handling of unparseable dates
  def test_unparseable_returns_nil_date
    result = SheetDateParser.parse("TBD", 2026, 3)
    assert_nil result[:start_date]
  end

  # Blank input
  def test_blank_returns_nil
    result = SheetDateParser.parse("", 2026, 3)
    assert_nil result[:start_date]
  end

  # Cross-month range: "31 Jul - 2 Aug"
  def test_cross_month_date_range
    result = SheetDateParser.parse("31 Jul - 2 Aug", 2026, 7)
    assert_equal Date.new(2026, 7, 31), result[:start_date]
    assert_equal Date.new(2026, 8, 2), result[:end_date]
    assert_nil result[:start_time]
  end

  # "18th March" - no weekday, full month, no time
  def test_ordinal_full_month_no_time
    result = SheetDateParser.parse("18th March", 2026, 3)
    assert_equal Date.new(2026, 3, 18), result[:start_date]
    assert_nil result[:start_time]
  end

# Year tab (no tab month): month must come from the cell text
def test_year_tab_takes_month_from_text
  result = SheetDateParser.parse("7th May", 2027, nil)
  assert_equal Date.new(2027, 5, 7), result[:start_date]
end

def test_year_tab_range_takes_month_from_text
  result = SheetDateParser.parse("16-17 Mar", 2027, nil)
  assert_equal Date.new(2027, 3, 16), result[:start_date]
  assert_equal Date.new(2027, 3, 17), result[:end_date]
end

def test_year_tab_without_month_returns_nil_date
  assert_nil SheetDateParser.parse("15th, 6pm", 2027, nil)[:start_date]
  assert_nil SheetDateParser.parse("16-17", 2027, nil)[:start_date]
  assert_nil SheetDateParser.parse("TBC", 2027, nil)[:start_date]
end
end

class RegionMapperTest < Minitest::Test
  def test_auckland
    assert_equal "auckland", SheetRegionMapper.map("Tāmaki Makaurau/Auckland")
  end

  def test_wellington
    assert_equal "wellington", SheetRegionMapper.map("Te Whanganui-a-Tara/Wellington")
  end

  def test_christchurch_maps_to_canterbury
    assert_equal "canterbury", SheetRegionMapper.map("Otautahi/Christchurch")
  end

  def test_aotearoa_maps_to_online
    assert_equal "online", SheetRegionMapper.map("Aotearoa New Zealand")
  end

  def test_tauranga_maps_to_bay_of_plenty
    assert_equal "bay_of_plenty", SheetRegionMapper.map("Tauranga")
  end

  def test_kapiti_maps_to_wellington
    assert_equal "wellington", SheetRegionMapper.map("Kapiti")
  end

  def test_waikato
    assert_equal "waikato", SheetRegionMapper.map("Waikato/Hamilton")
  end

  def test_queenstown_maps_to_otago
    assert_equal "otago", SheetRegionMapper.map("Tāhuna/Queenstown")
  end

  def test_taupo_maps_to_waikato
    assert_equal "waikato", SheetRegionMapper.map("Taupō")
  end

  def test_invercargill_maps_to_southland
    assert_equal "southland", SheetRegionMapper.map("Waihōpai/Invercargill")
  end

  def test_blank_returns_nil
    assert_nil SheetRegionMapper.map("")
  end

  def test_nil_returns_nil
    assert_nil SheetRegionMapper.map(nil)
  end

  def test_unknown_region_returns_nil
    assert_nil SheetRegionMapper.map("Mars")
  end
end

class CsvManagerTest < Minitest::Test
  def test_dedup_key_matches_same_event
    key1 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    key2 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    assert_equal key1, key2
  end

  def test_dedup_key_case_insensitive_title
    key1 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    key2 = CsvManager.dedup_key("march ai meetup", "2026-03-02")
    assert_equal key1, key2
  end

  def test_dedup_key_different_date_no_match
    key1 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    key2 = CsvManager.dedup_key("March AI Meetup", "2026-04-06")
    refute_equal key1, key2
  end

  def test_dedup_key_nil_title_returns_nil
    assert_nil CsvManager.dedup_key(nil, "2026-03-02")
  end

  def test_dedup_key_blank_date_returns_nil
    assert_nil CsvManager.dedup_key("Some Event", "")
  end

  def test_dedup_keys_from_events
    events = [
      { "title" => "Event A", "start_date" => "2026-03-01" },
      { "title" => "Event B", "start_date" => "2026-03-02" }
    ]
    keys = CsvManager.dedup_keys(events)
    assert_includes keys, "event a||2026-03-01"
    assert_includes keys, "event b||2026-03-02"
    assert_equal 2, keys.size
  end
end

class SheetFetcherTabsTest < Minitest::Test
  def test_monthly_tabs_are_consecutive_months
    months = SheetFetcher::TABS.select { |t| t[:month] }.map { |t| Date.new(t[:year], t[:month], 1) }
    months.each_cons(2) { |a, b| assert_equal a >> 1, b }
  end

  def test_tab_gids_are_unique
    gids = SheetFetcher::TABS.map { |t| t[:gid] }
    assert_equal gids.uniq, gids
  end

def test_tab_names_match_year_and_month
  SheetFetcher::TABS.each do |t|
    expected = t[:month] ? Date.new(t[:year], t[:month], 1).strftime("%b %Y") : t[:year].to_s
    assert_equal expected, t[:name]
  end
end

def test_tabs_cover_through_end_of_2027
  covered = SheetFetcher::TABS.any? { |t| t[:year] == 2027 && t[:month].nil? } ||
    SheetFetcher::TABS.any? { |t| t[:year] == 2027 && t[:month] == 12 }
  assert covered, "expected a 2027 year tab or a Dec 2027 tab"
end

def test_tabs_to_fetch_includes_current_month_onward_and_year_tab
  names = SheetFetcher.tabs_to_fetch(Date.new(2026, 10, 22)).map { |t| t[:name] }
  assert_includes names, "Oct 2026"
  assert_includes names, "2027"
  refute_includes names, "Sep 2026"
end

def test_tabs_to_fetch_drops_year_tab_after_that_year
  names = SheetFetcher.tabs_to_fetch(Date.new(2028, 1, 5)).map { |t| t[:name] }
  refute_includes names, "2027"
end

def test_year_tab_predicate
  assert SheetFetcher.year_tab?({ name: "2027", year: 2027, month: nil })
  refute SheetFetcher.year_tab?({ name: "Jan 2027", year: 2027, month: 1 })
end
end
