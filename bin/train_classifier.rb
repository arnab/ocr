def train_model(examples, labels)
  problem = Libsvm::Problem.new
  parameter = Libsvm::SvmParameter.new
  parameter.cache_size = 1000 # in megabytes
  parameter.eps = 0.001
  parameter.c = 1

  puts "Training model with #{labels.size} examples"

  examples.map! {|ary| Libsvm::Node.features(ary) }
  problem.set_examples(labels, examples)
  model = Libsvm::Model.train(problem, parameter)
  model_file = "/var/tmp/svm-model.model"
  model.save(model_file)
  puts "Saved model to #{model_file}"
  model
end

def test_model(model, examples, labels)
  puts "Running tests on #{examples.size} examples\n  "
  failures = []
  examples.each_with_index do |example, i|
    expected_label = labels[i]
    found_label = model.predict(Libsvm::Node.features(*example))
    failures << i unless found_label.to_i == expected_label.to_i

    if (i+1) % 1000 == 0
    # if (i+1) == examples.size
      puts "  Accuracy at #{(i+1)}/#{examples.size}: #{100 - failures.size.to_f / (i+1) * 100 }"
    end
  end
  puts "Accuracy: #{100 - failures.size.to_f / examples.size * 100 }"
end

classifier = Classifier.new(cache_size: 1000)

training_file = DataAccessor::FILES[:raw_csv][:train]
labels, examples = DataAccessor.labels_and_examples_from(training_file)
classifier.train(examples, labels)
classifier.save_model

training_file = DataAccessor::FILES[:raw_csv][:test]
labels, examples = DataAccessor.labels_and_examples_from(training_file)
classifier.test(examples, labels)
