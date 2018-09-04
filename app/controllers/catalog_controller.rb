class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  configure_blacklight do |config|
    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    config.search_builder_class = AMS::SearchBuilder

    # Show gallery view
    config.view.gallery.partials = [:index_header, :index]
    config.view.slideshow.partials = [:index]

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: "title_tesim description_tesim creator_tesim keyword_tesim"
    }

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name("asset_types", :facetable), label: "Asset Type", limit: 5, collapse: true
    config.add_facet_field solr_name("topics", :facetable), label: "Topic", limit: 5, collapse: true
    config.add_facet_field solr_name("genre", :facetable), label: "Genre", limit: 5, collapse: true
    config.add_facet_field solr_name("producing_organization", :facetable), label: "Producing Organization", limit: 5, collapse: true
    config.add_facet_field "media_type_ssim", label: "Media Type", limit: 5, collapse: false
    config.add_facet_field "format_ssim", label: "Physical Format", limit: 5, collapse: true
    config.add_facet_field "holding_organization_ssim", label: "Holding Organization", limit: 5, collapse: true
    config.add_facet_field "language_ssim", label: "Language", limit: 5, collapse: true
    config.add_facet_field "level_of_user_access_ssim", label: "Level of user access", limit: 5, collapse: true
    config.add_facet_field "transcript_status_ssim", label: "Transcript Status", limit: 5, collapse: true

    config.add_facet_field 'minimally_cataloged_ssim', query: {
        yes: { label: 'Yes', fq: 'minimally_cataloged_ssim:Yes' },
    no: { label: 'No', fq: '-minimally_cataloged_ssim:No' }
    }, label:"Minimally Cataloged", collapse: true

    config.add_facet_field 'outside_url_ssim', query: {
        yes: { label: 'Yes', fq: 'outside_url_ssim:[* TO *]' },
        no: { label: 'No', fq: '-outside_url_ssim:[* TO *]' }
    }, label:"Outside URL", collapse: true

    config.add_facet_field 'sonyci_id_ssim', query: {
        yes: { label: 'Yes', fq: 'sonyci_id_ssim:[* TO *]' },
        no: { label: 'No', fq: '-sonyci_id_ssim:[* TO *]' }
    }, label:"Digitized Copy in AAPB", collapse: true

    # The generic_type isn't displayed on the facet list
    # It's used to give a label to the filter that comes from the user profile
    config.add_facet_field solr_name("generic_type", :facetable), if: false


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name', if: false

    config.add_index_field solr_name('admin_set'), label: 'Admin Set'
    config.add_index_field solr_name("created_date", :stored_searchable), label: 'Created Date', itemprop: 'created_date', helper_method: :iconify_auto_link
    config.add_index_field solr_name("copyright_date", :stored_searchable), itemprop: 'copyright_date', helper_method: :iconify_auto_link
    config.add_index_field solr_name("broadcast_date", :stored_searchable), label: 'Broadcast Date', itemprop: 'broadcast_date', helper_method: :iconify_auto_link
    config.add_index_field 'id', label: 'GUID'

    # Uses a Blacklight model accessor for description decision logic
    config.add_index_field "description", accessor: "display_description"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name("title", :stored_searchable)

    config.add_show_field solr_name("broadcast", :stored_searchable)
    config.add_show_field solr_name("asset_types", :stored_searchable)
    config.add_show_field solr_name("created", :stored_searchable)
    config.add_show_field solr_name("date", :stored_searchable), label: "Date"
    config.add_show_field solr_name("copyright_date", :stored_searchable)

    config.add_show_field solr_name("keyword", :stored_searchable)
    config.add_show_field solr_name("subject", :stored_searchable)
    config.add_show_field solr_name("creator", :stored_searchable)
    config.add_show_field solr_name("contributor", :stored_searchable)
    config.add_show_field solr_name("publisher", :stored_searchable)
    config.add_show_field solr_name("based_near_label", :stored_searchable)
    config.add_show_field solr_name("language", :stored_searchable)
    config.add_show_field solr_name("date_uploaded", :stored_searchable)
    config.add_show_field solr_name("date_modified", :stored_searchable)
    config.add_show_field solr_name("date_created", :stored_searchable)
    config.add_show_field solr_name("rights_statement", :stored_searchable)
    config.add_show_field solr_name("license", :stored_searchable)
    config.add_show_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_show_field solr_name("format", :stored_searchable)
    config.add_show_field solr_name("identifier", :stored_searchable)

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields') do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("contributor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = solr_name("title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      solr_name = solr_name("description", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      solr_name = solr_name("subject", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      solr_name = solr_name("resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      solr_name = solr_name("format", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      solr_name = solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      solr_name = solr_name("based_near_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      solr_name = solr_name("keyword", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name("depositor", :symbol)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = solr_name("license", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end
    config.add_search_field('broadcast') do |field|
      solr_name = solr_name("broadcast", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end
    config.add_search_field('created') do |field|
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end
    config.add_search_field('date') do |field|
      solr_name = solr_name("date", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end
    config.add_search_field('copyright_date') do |field|
      solr_name = solr_name("copyright_date", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{solr_name('system_create', :stored_sortable, type: :date)} desc", label: "relevance"
    config.add_sort_field "#{solr_name('system_create', :stored_sortable, type: :date)} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{solr_name('system_create', :stored_sortable, type: :date)} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{solr_name('system_modified', :stored_sortable, type: :date)} desc", label: "date modified \u25BC"
    config.add_sort_field "#{solr_name('system_modified', :stored_sortable, type: :date)} asc", label: "date modified \u25B2"
    config.add_sort_field "#{solr_name('broadcast', :stored_sortable)} dsc", label: "broadcast \u25BC"
    config.add_sort_field "#{solr_name('broadcast', :stored_sortable)} asc", label: "broadcast \u25B2"
    config.add_sort_field "#{solr_name('created', :stored_sortable, type: :date)} dsc", label: "created  \u25BC"
    config.add_sort_field "#{solr_name('created', :stored_sortable, type: :date)} asc", label: "created  \u25B2"
    config.add_sort_field "#{solr_name('copyright_date', :stored_sortable, type: :date)} dsc", label: "copyright date  \u25BC"
    config.add_sort_field "#{solr_name('copyright_date', :stored_sortable, type: :date)} asc", label: "copyright date  \u25B2"
    config.add_sort_field "#{solr_name('date', :stored_sortable, type: :date)} dsc", label: "date  \u25BC"
    config.add_sort_field "#{solr_name('date', :stored_sortable, type: :date)} asc", label: "date  \u25B2"
    config.add_sort_field "#{solr_name('title', :stored_sortable)} dsc", label: "title  \u25BC"
    config.add_sort_field "#{solr_name('title', :stored_sortable)} asc", label: "title  \u25B2"
    config.add_sort_field "#{solr_name('episode_number', :stored_sortable)} dsc", label: "Episode Number  \u25BC"
    config.add_sort_field "#{solr_name('episode_number', :stored_sortable)} asc", label: "Episode Number  \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
