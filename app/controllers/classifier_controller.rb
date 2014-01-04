class ClassifierController < ApplicationController
  before_filter :load_model, :only => [:show, :test, :test_image]

  def show
    classifier.reset_results!
  end

  def test
    max_datapoints = params[:data_points].to_i
    test_data_file = DataAccessor::FILES[:raw_csv][:test]
    logger.info "Reading tests data from #{test_data_file}"
    labels, examples = DataAccessor.labels_and_examples_from(test_data_file)
    logger.info "Testsing classifier with #{labels.size} data-points"
    classifier.test(examples, labels, max_datapoints)
    render 'show'
  end

  def try
  end

  def test_image
    uploaded_io = params[:image]
    filename = Rails.root.join('public', 'uploads', uploaded_io.original_filename)
    File.open(filename, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    i = Magick::Image.read(filename)[0]
    data = i.export_pixels(0, 0, i.columns, i.rows, "I")
    @found_class = classifier.predict(data).to_i
    render 'try'
  end

  helper_method :classifier
  def classifier
    @@classifier
  end

  def load_model
    @@classifier ||= Classifier.new(cache_size: 1000).tap do |c|
      logger.info "Loading saved model into classifier"
      c.load_model
    end
  end
end
