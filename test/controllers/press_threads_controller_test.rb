require "test_helper"

class PressThreadsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get press_threads_index_url
    assert_response :success
  end

  test "should get show" do
    get press_threads_show_url
    assert_response :success
  end

  test "should get new" do
    get press_threads_new_url
    assert_response :success
  end

  test "should get create" do
    get press_threads_create_url
    assert_response :success
  end
end
