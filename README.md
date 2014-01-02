OCR
===

Showcase Classification (Machine Learning) using libsvm in Ruby. Built to be demo-ed in my [Machine Learning with Ruby talk](http://gardencityruby2014.busyconf.com/schedule#activity_5252638a3101f6000f00003a). Slides for the talk can be found [here](https://slid.es/arnab_deka/ml-with-ruby/).

Steps to try it out
======
+ `bundle install`
+ Download the training and test data from the [mnist website](http://yann.lecun.com/exdb/mnist/)
+ Put these files in `data/mnist`
+ Prepare CSV data from this raw data: `rails r bin/prep_data.rb <MAX-NUMBER-OF-EXAMPLES>`
  + The smaller data you have, the faster the training step will be. Recommend about 5000 if you are just playing around.
+ Train the classifier: `rails r bin/train_classifier.rb`
  + This will create and save the model in `models/svm.model`
+ Start the rails server `rails s`
+ Visit the classifier at [localhost:3000/classifier/show](http://localhost:3000/classifier/show)
