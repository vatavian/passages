require "application_system_test_case"

class StoryFormatsTest < ApplicationSystemTestCase
  setup do
    @story_format = story_formats(:one)
  end

  test "visiting the index" do
    visit story_formats_url
    assert_selector "h1", text: "Story Formats"
  end

  test "creating a Story format" do
    visit story_formats_url
    click_on "New Story Format"

    fill_in "Author", with: @story_format.author
    fill_in "Footer", with: @story_format.footer
    fill_in "Header", with: @story_format.header
    fill_in "Name", with: @story_format.name
    click_on "Create Story format"

    assert_text "Story format was successfully created"
    click_on "Back"
  end

  test "updating a Story format" do
    visit story_formats_url
    click_on "Edit", match: :first

    fill_in "Author", with: @story_format.author
    fill_in "Footer", with: @story_format.footer
    fill_in "Header", with: @story_format.header
    fill_in "Name", with: @story_format.name
    click_on "Update Story format"

    assert_text "Story format was successfully updated"
    click_on "Back"
  end

  test "destroying a Story format" do
    visit story_formats_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Story format was successfully destroyed"
  end
end
