classifier = Classifier.new(cache_size: 1000)

training_file = DataAccessor::FILES[:raw_csv][:train]
labels, examples = DataAccessor.labels_and_examples_from(training_file)
classifier.train(examples, labels)
classifier.save_model

training_file = DataAccessor::FILES[:raw_csv][:test]
labels, examples = DataAccessor.labels_and_examples_from(training_file)
classifier.test(examples, labels)
