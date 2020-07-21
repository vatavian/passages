require "application_system_test_case"

class PassagesTest < ApplicationSystemTestCase
  setup do
    @passage = passages(:one)
  end

  test "visiting the index" do
    visit passages_url
    assert_selector "h1", text: "Passages"
  end

  test "creating a Passage" do
    visit passages_url
    click_on "New Passage"

    fill_in "Title", with: @passage.title
    click_on "Create Passage"

    assert_text "Passage was successfully created"
    click_on "Back"
  end

  test "updating a Passage" do
    visit passages_url
    click_on "Edit", match: :first

    fill_in "Title", with: @passage.title
    click_on "Update Passage"

    assert_text "Passage was successfully updated"
    click_on "Back"
  end

  test "destroying a Passage" do
    visit passages_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Passage was successfully destroyed"
  end
end
