# frozen_string_literal: true

require 'test_helper'

class HelperTestController < ApplicationController
  def test
    render plain: nil
  end
end

class TestHelperTest < ActionView::TestCase
  include RouteTranslator::ConfigurationHelper
  include RouteTranslator::RoutesHelper

  def setup
    setup_config

    @routes = ActionDispatch::Routing::RouteSet.new

    draw_routes do
      localized do
        get :helper_test, to: 'helper_test#test'
      end

      locale :vi do
        get :helper2_kiem_tra, to: 'helper2_test#test', as: 'helper2_test'
      end

      locale :en do
        get :helper2_test, to: 'helper2_test#test', as: 'helper2_test'
      end
    end
  end

  def teardown
    teardown_config
  end

  def test_no_private_method_call
    assert_nothing_raised { helper_test_path }

    assert_nothing_raised { helper2_test_vi_path }
    assert_equal '/helper2_kiem_tra', helper2_test_vi_path
    assert_nothing_raised { helper2_test_en_path }
    assert_equal '/helper2_test', helper2_test_en_path
    assert_nothing_raised { helper2_test_path }
    assert_equal '/helper2_test', helper2_test_path
  end
end
