require "libsvm"

class Classifier
  MODEL_FILE = "models/svm.model"

  attr_reader :problem, :parameter, :model

  def initialize(cache_size: 100, eps: 0.001, c: 1)
    @problem = Libsvm::Problem.new
    @parameter = Libsvm::SvmParameter.new
    @parameter.cache_size = cache_size # in megabytes
    @parameter.eps = eps
    @parameter.c = c
    @model = nil
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

    if max_datapoints > 0
      indices = max_datapoints.times.map{ Random.rand(examples.size) }
      examples = indices.map{ |i| examples[i] }
      expected_labels = indices.map{ |i| expected_labels[i] }
    end

    expected_labels.map! {|str| DataAccessor.word_to_num str}
    Rails.logger.info "Running tests on #{examples.size} examples"
    failures = []
    examples.each_with_index do |example, i|
      expected_label = expected_labels[i]
      found_label = @model.predict(Libsvm::Node.features(*example))
      failures << i unless found_label.to_i == expected_label.to_i

      if (i+1) % 1000 == 0
        log_accuracy(failures.size, examples.size, i+1)
      end
    end
    log_accuracy(failures.size, examples.size)
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
