require "crack/xml"
require 'pry'
# k [1.2..2]
OKAPI_K = 2.0
# b [0, 1]
OKAPI_B = 0.5
AVG_DOC_LENGTH = 755.68
DOC_LENGTHS = YAML.load_file("doc_lengths.yml")
# arguments: ruby tfidf.rb 1 query_file outfile_name model_dir ntcir_dir
FEEDBACK_FLAG = (ARGV[0] == "1" ? true : false)
QUERY_FILE_PATH = ARGV[1]
OUTPUT_FILENAME = ARGV[2]
MODEL_DIR_PATH = ARGV[3]
NTCIR_DIR_PATH = ARGV[4]

def okapi_tf(x, doc_id)
  tf = ((OKAPI_K + 1) * x) / (x + OKAPI_K)
  docl = DOC_LENGTHS["doc_#{doc_id}"]&.first || AVG_DOC_LENGTH
  normalizer = 1 - OKAPI_B + OKAPI_B * docl / AVG_DOC_LENGTH
  tf / normalizer
end

def query_tf(x)
  tf = ((OKAPI_K + 1) * x) / (x + OKAPI_K)
end

def count_em(string, substring)
  string.scan(/(?=#{substring})/).count
end

def uni_bigrams(concepts)
  unigrams = []
  bigrams = []
  concepts.each do |concept|
    concept.each_char.with_index do |c, i|
      # unigrams << c
      if i != (concept.length - 1)
        bigrams << concept[i..(i+1)]
      end
    end
  end
  unigrams + bigrams
end

startee = Time.now

terms = {}
vocab_all = IO.readlines("#{MODEL_DIR_PATH}/vocab.all")
file_list = IO.readlines("#{MODEL_DIR_PATH}/file-list")
answer = IO.readlines("queries/ans_train.csv")
File.open("model/inverted-file", "r") do |file|
  while (line = file.gets)
    infos = line.split(" ")
    vocab = if infos[1].to_i == -1
              vocab_all[infos[0].to_i]
            elsif vocab_all[infos[1].to_i][0] =~ /[A-Za-z]/
              vocab_all[infos[0].to_i] + " " + vocab_all[infos[1].to_i]
            else
              vocab_all[infos[0].to_i] + vocab_all[infos[1].to_i]
            end.tr("\n", "")
    idf = Math.log10(46972.0 / infos[2].to_f)

    term_value = Hash.new(0)
    term_value[:idf] = idf
    (1..infos[2].to_i).each do |n|
      line = file.gets
      term_doc = line.split(" ")
      term_tf = okapi_tf(term_doc[1].to_i, term_doc[0])
      term_value[term_doc[0]] = term_tf
    end
    terms[vocab] = term_value
  end
end

aps = []

target = File.open("#{QUERY_FILE_PATH}", "r").read
queries = Crack::XML.parse(target)
File.open("#{OUTPUT_FILENAME}", "a") do |file|
  file.write("query_id,retrieved_docs\n")
  queries["xml"]["topic"].each_with_index do |query, i|
    desc = [query["title"], query["narrative"], query["question"]].join("")
    concepts = query["concepts"].tr("。 \n", "").split("、")
    candidate_docs = Hash.new(0)

    concepts = uni_bigrams(concepts)

    concepts.each do |concept|
      factor = 1
      factor += count_em(desc, concept)
      factor = query_tf(factor)
      
      words = concept

      cur_idf = terms[words][:idf]
      terms[words].reject { |k| k == :idf }.each do |doc|
        candidate_docs[doc[0]] += doc[1] * cur_idf * cur_idf * factor
      end
    end

    sort_candidates = Hash[candidate_docs.sort_by { |k, v| -v }[0..99]]

    cur_answers = answer[i+1].split(",")[-1].split(" ")
    precisions = []
    hit_count = 0
    sort_candidates.each_with_index do |can, i|
      if cur_answers.include? file_list[can[0].to_i].split("/")[-1].strip.downcase
        hit_count += 1
        precisions << hit_count.to_f / (i + 1)
      end
    end

    ap = precisions.inject(:+) / precisions.count
    aps << ap

    file.write("#{query["number"][-3..-1]},")
    sort_candidates.each_with_index do |can, i|
      break if i > 100
      file.write(file_list[can[0].to_i].split("/")[-1].strip.downcase)
      file.write(" ")
    end
    file.write("\n")
  end
end
finishee = Time.now
map = aps.inject(:+) / aps.count
binding.pry
puts "done"
