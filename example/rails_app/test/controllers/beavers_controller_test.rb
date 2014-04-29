require 'test_helper'

class BeaversControllerTest < ActionController::TestCase
  setup do
    @beaver = beavers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:beavers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create beaver" do
    assert_difference('Beaver.count') do
      post :create, beaver: { name: @beaver.name }
    end

    assert_redirected_to beaver_path(assigns(:beaver))
  end

  test "should show beaver" do
    get :show, id: @beaver
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @beaver
    assert_response :success
  end

  test "should update beaver" do
    patch :update, id: @beaver, beaver: { name: @beaver.name }
    assert_redirected_to beaver_path(assigns(:beaver))
  end

  test "should destroy beaver" do
    assert_difference('Beaver.count', -1) do
      delete :destroy, id: @beaver
    end

    assert_redirected_to beavers_path
  end
end
