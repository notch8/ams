# frozen_string_literal: true
unless App.rails_5_1?
  
  # Generated via
  #  `rails generate hyrax:work_resource PhysicalInstantiationResource`
  #
  # @see https://github.com/samvera/hyrax/wiki/Hyrax-Valkyrie-Usage-Guide#forms
  # @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
  class PhysicalInstantiationResourceForm < Hyrax::Forms::ResourceForm(PhysicalInstantiationResource)
    include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields(:physical_instantiation_resource)
  
    # Define custom form fields using the Valkyrie::ChangeSet interface
    #
    # property :my_custom_form_field
  
    # if you want a field in the form, but it doesn't have a directly corresponding
    # model attribute, make it virtual
    #
    # property :user_input_not_destined_for_the_model, virtual: true
  end
end