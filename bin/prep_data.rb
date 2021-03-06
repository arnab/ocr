# 1. read binary input data
# 2. Normalize
# 3. PCA -a attribute selection
# 4. Write massaged data

require "csv"

def write_to_csv(labels, data, out_file)
  if ARGV.first.present?
    max_lines = ARGV.first.to_i
    indices = max_lines.times.map{ Random.rand(labels.size) }.uniq
    labels = indices.map {|i| labels[i]}
    data = indices.map {|i| data[i]}
  end
  puts "Writing #{labels.size} items to #{out_file}"

  headers = []
  DataAccessor::IMAGE_DIMENSIONS[:width].times do |x|
    DataAccessor::IMAGE_DIMENSIONS[:height].times {|y| headers << "pixel-#{x+1}-#{y+1}" }
  end
  headers << "label"
  CSV.open(out_file, "wb", write_headers: true, headers: headers) do |csv|
    data.each_with_index do |example, i|
      label = I18n.with_locale(:en) { DataAccessor.num_to_word labels[i] }
      csv << [example, label].flatten
      puts "Done with #{i+1} lines" if (i+1) % 5000 == 0
    end
  end
end

# Silence I18n warning. Noop coz we use that in num-to-words
I18n.enforce_available_locales = false

[:train, :test].each do |type|
  labels, examples = DataAccessor.mnist_data(type)
  out_file = File.join(DataAccessor::DATA_DIR, DataAccessor::FILES[:raw_csv][type])
  write_to_csv(labels, examples, out_file)
end
