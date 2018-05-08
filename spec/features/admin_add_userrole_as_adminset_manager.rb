require 'rails_helper'

include Warden::Test::Helpers

RSpec.feature 'AdminAddUserroleAsAdminserManager.', js: true do

  context 'As Admin add a UserRole as Adminset Manager' do
    let(:admin_user) { create :admin_user }
    let!(:user) { create :user }
    let!(:user_with_role) { create :user_with_role }
    let!(:admin_set) { create :admin_set, title: ["Test Admin Set"] }

    before do
      login_as(admin_user)
    end

    scenario 'Assign set of user (role) as Manager to AdminSet' do

      # Check AdminSet exist
      visit '/admin/admin_sets'
      expect(page).to have_content admin_set.title[0]

      # Open AdminSet and edit
      find('td a', text: "Test Admin Set").click
      click_on('Edit')
      expect(page).to have_content 'Edit Administrative Set'

      # Add participants
      click_on('Participants')
      fill_in('permission_template_access_grants_attributes_0_agent_id', with: 'user')
      find("#group-participants-form select option[value='manage']").select_option
      find('#group-participants-form .btn').click
      expect(page).to have_content  'participant rights have been updated'

      # Login manager role user to check permissions
      visit destroy_user_session_path
      login_as(user_with_role)

      # Check AdminSet permissions exist
      visit '/admin/admin_sets'
      expect(page).to have_content admin_set.title[0]

      # Open AdminSet and edit
      find('td a', text: "Test Admin Set").click
      click_on('Edit')
      expect(page).to have_content 'Edit Administrative Set'

      # Login other user to check permissions
      visit destroy_user_session_path
      login_as(user)

      # Check other user AdminSet permissions exist
      visit '/admin/admin_sets'
      expect(page).to have_content 'You are not authorized to access this page.'

      exit
    end
  end

end