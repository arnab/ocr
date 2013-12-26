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
        examples: "train-images-idx3-ubyte",
        labels: "train-labels-idx1-ubyte"
      },
      test: {
        examples: "t10k-images-idx3-ubyte",
        labels: "t10k-labels-idx1-ubyte"
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
    labels = read_data(labels_file, 8)
    examples = group_images(read_data(examples_file, 16))
    [labels, examples]
  end

  def self.read_data(filename, offset)
    filename = File.join(DATA_DIR, filename)

    # Skip the first offset bytes - mnsit data organization
    IO.binread(filename, nil, offset).bytes.to_a
  end

  def self.group_images(pixels_ary)
    # Single-array of all the pixels: break them into arrays,
    # where each elem represents one image, of size height*width of the image
    pixels_ary.each_slice(IMAGE_DIMENSIONS[:height] * IMAGE_DIMENSIONS[:width]).to_a
  end
end
