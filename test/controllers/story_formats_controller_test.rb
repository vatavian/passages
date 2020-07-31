require 'test_helper'

class StoryFormatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @story_format = story_formats(:one)
  end

  test "should get index" do
    get story_formats_url
    assert_response :success
  end

  test "should get new" do
    get new_story_format_url
    assert_response :success
  end

  test "should create story_format" do
    assert_difference('StoryFormat.count') do
      post story_formats_url, params: { story_format: { author: @story_format.author, footer: @story_format.footer, header: @story_format.header, name: @story_format.name } }
    end

    assert_redirected_to story_format_url(StoryFormat.last)
  end

  test "should show story_format" do
    get story_format_url(@story_format)
    assert_response :success
  end

  test "should get edit" do
    get edit_story_format_url(@story_format)
    assert_response :success
  end

  test "should update story_format" do
    patch story_format_url(@story_format), params: { story_format: { author: @story_format.author, footer: @story_format.footer, header: @story_format.header, name: @story_format.name } }
    assert_redirected_to story_format_url(@story_format)
  end

  test "should destroy story_format" do
    assert_difference('StoryFormat.count', -1) do
      delete story_format_url(@story_format)
    end

    assert_redirected_to story_formats_url
  end
end
