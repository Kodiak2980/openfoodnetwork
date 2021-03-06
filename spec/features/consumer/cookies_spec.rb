require 'spec_helper'

feature "Cookies", js: true do
  describe "banner" do
    
    # keeps banner toggle config unchanged
    around do |example|
      original_banner_toggle = Spree::Config[:cookies_consent_banner_toggle]
      example.run
      Spree::Config[:cookies_consent_banner_toggle] = original_banner_toggle
    end

    describe "in the homepage" do
      before do
        Spree::Config[:cookies_consent_banner_toggle] = true
        visit_root_path_and_wait
      end

      scenario "does not show after cookies are accepted" do
        accept_cookies_and_wait
        expect_not_visible_cookies_banner

        visit_root_path_and_wait
        expect_not_visible_cookies_banner
      end

      scenario "banner contains cookies policy link that opens coookies policy page and closes banner" do
        click_banner_cookies_policy_link_and_wait
        expect_visible_cookies_policy_page
        expect_not_visible_cookies_banner

        close_cookies_policy_page_and_wait
        expect_visible_cookies_banner
      end

      scenario "does not show after cookies are accepted, and policy page is opened through the footer, and closed again (bug #2599)" do
        accept_cookies_and_wait
        expect_not_visible_cookies_banner
        
        click_footer_cookies_policy_link_and_wait
        expect_visible_cookies_policy_page
        expect_not_visible_cookies_banner

        close_cookies_policy_page_and_wait
        expect_not_visible_cookies_banner
      end
    end

    describe "in product listing page" do
      before do
        Spree::Config[:cookies_consent_banner_toggle] = true
      end

      scenario "it is showing" do
        visit "/shops"
        expect_visible_cookies_banner
      end
    end

    describe "disabled in the settings" do
      scenario "it is not showing" do
        Spree::Config[:cookies_consent_banner_toggle] = false
        visit root_path
        expect(page).to have_no_content I18n.t('legal.cookies_banner.cookies_usage')
      end
    end
  end

  describe "policy page" do

    # keeps config unchanged
    around do |example|
      original_config_value = Spree::Config[:cookies_policy_matomo_section]
      example.run
      Spree::Config[:cookies_policy_matomo_section] = original_config_value
    end

    scenario "showing session_id cookies description with correct instance domain" do
      visit '/#/policies/cookies'
      expect(page).to have_content('_session_id')
        .and have_content('127.0.0.1')
    end

    describe "with Matomo section configured" do
      scenario "shows Matomo cookies details" do
        Spree::Config[:cookies_policy_matomo_section] = true
        visit '/#/policies/cookies'
        expect(page).to have_content matomo_description_text
      end
    end

    describe "without Matomo section configured" do
      scenario "does not show Matomo cookies details" do
        Spree::Config[:cookies_policy_matomo_section] = false
        visit '/#/policies/cookies'
        expect(page).to have_no_content matomo_description_text
      end
    end
  end

  def matomo_description_text
    I18n.t('legal.cookies_policy.cookie_matomo_basics_desc')
  end

  def expect_visible_cookies_policy_page
    expect(page).to have_content I18n.t('legal.cookies_policy.header')
  end

  def expect_visible_cookies_banner
    expect(page).to have_css("button", :text => accept_cookies_button_text, :visible => true)
  end

  def expect_not_visible_cookies_banner
    expect(page).to have_no_css("button", :text => accept_cookies_button_text, :visible => true)
  end

  def accept_cookies_button_text
    I18n.t('legal.cookies_banner.cookies_accept_button')
  end

  def visit_root_path_and_wait
    visit root_path
    sleep 1
  end

  def accept_cookies_and_wait
    click_button accept_cookies_button_text
    sleep 2
  end

  def click_banner_cookies_policy_link_and_wait
    find("p.ng-binding > a", :text => "cookies policy").click
    sleep 2
  end

  def click_footer_cookies_policy_link_and_wait
    find("div > a", :text => "cookies policy").click
    sleep 2
  end

  def close_cookies_policy_page_and_wait
    find("a.close-reveal-modal").click
    sleep 2
  end
end
