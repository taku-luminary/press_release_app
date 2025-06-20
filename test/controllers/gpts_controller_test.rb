require "test_helper"

class GptsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get gpts_index_url
    assert_response :success
  end

  test "should get new" do
    get gpts_new_url
    assert_response :success
  end

  test "should get create" do
    get gpts_create_url
    assert_response :success
  end
end
