# frozen_string_literal: true
unless App.rails_5_1?
  
  # Generated via
  #  `rails generate hyrax:work_resource EssenceTrackResource`
  require 'rails_helper'
  require 'hyrax/specs/shared_specs/indexers'
  
  RSpec.describe EssenceTrackResourceIndexer do
    let(:indexer_class) { described_class }
    let(:resource) { EssenceTrackResource.new }
  
    it_behaves_like 'a Hyrax::Resource indexer'
  end
end
