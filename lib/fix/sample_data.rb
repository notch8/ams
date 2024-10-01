# first shell into a running container with bash, then run pry.
# load the app
require_relative '../../config/environment'

# Set some variables
class SampleData
  attr_reader :asset_sample_size, :log

  def initialize(asset_sample_size: 100)
    @asset_sample_size = asset_sample_size
    @log = Logger.new(STDOUT)
  end

  def solr
    @solr ||= Blacklight.default_index.connection
  end

  def a_docs
    @a_docs ||= solr.get('select', params: {q: 'has_model_ssim:Asset', rows: asset_sample_size, start: rand_start})['response']['docs']
  end

  def rand_start
    @rand_start ||= rand(0..(total_assets - asset_sample_size - 1))
  end

  def total_assets
    solr.get('select', params: {q: 'has_model_ssim:Asset', rows: 0})['response']['numFound']
  end

  def ars(refresh: false)
    # Rest instance variables if refresh is true
    @ars = @ars_with_pis = @ars_with_pis_in_fedora = nil if refresh
    @ars ||= a_docs.map{|doc| AssetResource.find(doc['id'])}
  end

  def ars_with_pis(media_type: nil)
    @ars_with_pis ||= ars.select{ |ar| ar.physical_instantiation_resources.present? }
    if media_type
      filter(ars: @ars_with_pis, media_type: media_type)
    else
      @ars_with_pis
    end
  end

  def ars_with_pis_in_fedora(media_type: nil)
    @ars_with_pis_in_fedora ||= ars_with_pis.select do |ar|
      ar.physical_instantiation_resources.any? do |pi|
        begin
          pi = PhysicalInstantiation.find(pi.id)
        rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone => e
          log.error("#{e.class}: #{e.message}")
          false
        end
      end
    end

    if media_type
      filter(ars: @ars_with_pis_in_fedora, media_type: media_type)
    else
      @ars_with_pis_in_fedora
    end
  end

  def save_assets_to_pg
    ars.each do |ar|
      Hyrax.persister.save(resource: ar)
    end
    ars(refresh: true)
  end

  # Class method for filtering a set of AssetResources
  def self.filter(ars: [], media_type: nil)
    filtered = ars
    if media_type
      filtered = filtered.select do |ar|
        ar.physical_instantiation_resources.any? do |pi|
          pi.media_type.to_s.strip.downcase == media_type.to_s.strip.downcase
        end
      end
    end
    filtered
  end

  # Delegated instance method
  def filter(*args, **kwargs); self.class.filter(*args, **kwargs); end

end
