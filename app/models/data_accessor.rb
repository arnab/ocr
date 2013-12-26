require "csv"

class DataAccessor
  IMAGE_DIMENSIONS = {
    height: 28,
    width: 28
  }

  DATA_DIR = "data"
  FILES = {
    mnist_binary: {
      # http://yann.lecun.com/exdb/mnist/
      train: {
        examples: "mnist/train-images-idx3-ubyte",
        labels: "mnist/train-labels-idx1-ubyte"
      },
      test: {
        examples: "mnist/t10k-images-idx3-ubyte",
        labels: "mnist/t10k-labels-idx1-ubyte"
      }
    },
    raw_csv: {
      train: 'training_data.csv',
      test: 'test_data.csv'
    },
  }

  def self.mnist_data(type)
    accepted_types = FILES[:mnist_binary].keys
    unless accepted_types.include? type
      raise ArgumentError, "unknown type of data requestsed: #{type.inspect}. " +
        "Please specify one of #{accepted_types.inspect}"
    end

    labels_file = FILES[:mnist_binary][type][:labels]
    examples_file = FILES[:mnist_binary][type][:examples]
    labels_and_examples_from_mnist_data(labels_file, examples_file)
  end

  def self.labels_and_examples_from_mnist_data(labels_file, examples_file)
    labels = read_binary_data(labels_file, 8)
    examples = group_images(read_binary_data(examples_file, 16))
    [labels, examples]
  end

  def self.labels_and_examples_from(dataset)
    Rails.logger.info "Reading #{dataset}"
    data = CSV.read(File.join(DATA_DIR, dataset)).drop(1)
    labels = data.map {|d| d.pop }
    [labels, data]
  end

  def self.read_binary_data(filename, offset)
    filename = File.join(DATA_DIR, filename)

    # Skip the first offset bytes - mnsit data organization
    IO.binread(filename, nil, offset).bytes.to_a
  end

  def self.group_images(pixels_ary)
    # Single-array of all the pixels: break them into arrays,
    # where each elem represents one image, of size height*width of the image
    pixels_ary.each_slice(IMAGE_DIMENSIONS[:height] * IMAGE_DIMENSIONS[:width]).to_a
  end

  NUM_AND_WORDS = {
    0 => 'zero',
    1 => 'one',
    2 => 'two',
    3 => 'three',
    4 => 'four',
    5 => 'five',
    6 => 'six',
    7 => 'seven',
    8 => 'eight',
    9 => 'nine',
  }

  def self.num_to_word(num)
    NUM_AND_WORDS.fetch num
  end

  def self.word_to_num(str)
    NUM_AND_WORDS.invert.fetch str
  end
end
