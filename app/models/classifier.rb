require "libsvm"
require "matrix"

class Classifier
  MODEL_FILE = "models/svm.model"

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
    features = examples.map {|ary| Libsvm::Node.features(ary) }
    @problem.set_examples(labels, features)
    @model = Libsvm::Model.train(@problem, @parameter)
    Rails.logger.info "Done training model"
  end

  def test(examples, expected_labels, max_datapoints)
    check_model_available?
    reset_results!

    if max_datapoints > 0
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
      found = @model.predict(Libsvm::Node.features(*example)).to_i

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
