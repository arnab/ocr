class ClassifierController < ApplicationController
  before_filter :load_model, :only => [:show]

  def show
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
