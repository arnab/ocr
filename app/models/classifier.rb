require "libsvm"
require "matrix"

class Classifier
  MODEL_FILE = "models/svm.model"
  # Out of the 28x28 attributes, these were selected as the important ones by PCA.
  # See models/reduce_dimensions.log
  SELECTED_ATTRIBUTES = [101,102,128,129,150,151,153,154,155,156,157,158,180,182,183,184,185,189,191,
                         211,212,214,221,232,238,240,242,243,249,262,263,264,265,267,268,270,271,272,
                         273,284,291,292,296,298,299,300,301,318,319,320,323,324,327,328,330,346,347,
                         348,349,350,351,352,354,355,373,374,375,376,377,378,379,380,381,382,383,401,
                         402,403,404,405,406,407,408,409,410,411,414,428,430,431,432,433,434,435,436,
                         437,438,439,442,456,457,458,460,461,462,463,465,466,483,486,487,488,489,490,
                         491,492,493,494,496,498,514,515,516,517,518,524,539,540,541,542,543,544,545,
                         551,567,568,569,570,572,573,578,594,596,597,598,626,627,655,656,657,658,659]

  attr_reader :problem, :parameter, :model, :results

  def initialize(cache_size: 100, eps: 0.001, c: 1)
    @problem = Libsvm::Problem.new
    @parameter = Libsvm::SvmParameter.new
    @parameter.cache_size = cache_size # in megabytes
    @parameter.eps = eps
    @parameter.c = c
    @model = nil
    reset_results!
  end

  def train(examples, labels)
    labels.map! {|str| DataAccessor.word_to_num str}
    Rails.logger.info "Training LibSVM model with #{examples.size} examples"
    Rails.logger.debug "Number of attributes before reducing: #{examples.first.size}"
    examples.map! do |e|
      e = SELECTED_ATTRIBUTES.map {|i| e[i] }
    end
    Rails.logger.debug "Number of attributes after reducing: #{examples.first.size}"
    features = examples.map {|ary| Libsvm::Node.features(ary) }
    @problem.set_examples(labels, features)
    @model = Libsvm::Model.train(@problem, @parameter)
    Rails.logger.info "Done training model"
  end

  def test(examples, expected_labels, max_datapoints=nil)
    check_model_available?
    reset_results!

    if max_datapoints.present? && max_datapoints > 0
      indices = max_datapoints.times.map{ Random.rand(examples.size) }
      examples = indices.map{ |i| examples[i] }
      expected_labels = indices.map{ |i| expected_labels[i] }
    end

    expected_labels.map! {|str| DataAccessor.word_to_num str}
    Rails.logger.info "Running tests on #{examples.size} examples"
    failure_count = 0
    reporting_step_size = examples.size / 20

    examples.each_with_index do |example, i|
      expected = expected_labels[i].to_i
      reduced_example = SELECTED_ATTRIBUTES.map {|i| example[i]}
      found = @model.predict(Libsvm::Node.features(*reduced_example)).to_i

      @results[:confusion_matrix][found, expected] << i
      failure_count += 1 unless found == expected

      if (i+1) % reporting_step_size == 0
        log_accuracy(failure_count, examples.size, i+1)
      end
    end
    log_accuracy(failure_count, examples.size)
    @results[:accuracy] = 100 - failure_count.to_f / examples.size * 100
    @results_ready = true
  end

  def load_model
    @model = Libsvm::Model.load(MODEL_FILE)
  end

  def save_model
    check_model_available?
    @model.save(MODEL_FILE)
    Rails.logger.info "Saved model to #{MODEL_FILE}"
  end

  def check_model_available?
    raise "model not trained yet" if @model.nil?
  end

  def reset_results!
    @results_ready = false
    @results = {
      :accuracy => nil,
      # 10 labels to classify. So 10x10 matrix
      :confusion_matrix => Matrix.build(10, 10) { [] }
    }
  end

  def results_ready?
    @results_ready
  end

  def log_accuracy(failure_count, total_count, milepost=nil)
    total = milepost || total_count
    accuracy = 100 - failure_count.to_f / total * 100
    fmt = "%.2f"
    if milepost.present?
      Rails.logger.debug "Accuracy at #{total}/#{total_count}: #{fmt % accuracy}"
    else
      Rails.logger.info "Accuracy: #{fmt % accuracy.to_f}"
    end
  end
end
