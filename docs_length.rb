require "crack/xml"
require "pry"

def get_docs_length
  doc_count = 0
  docs_length = Hash.new(756)
  total = 0
  File.open("model/file-list", "r") do |file|
    while(line = file.gets)
      doc_count += 1
      begin
        doc_length = 0
        target = File.open(line.chop, "r").read
        target.gsub!(/<a.*<\/a>/m, "")
        result = Crack::XML.parse(target)

        begin
          doc_length += result["xml"]["doc"]["title"].length
        rescue
        end
        begin
          doc_length += result["xml"]["doc"]["text"]["p"].join("").tr("\n", "").length
        rescue
        end

        doc_id = (doc_count - 1).to_s
        docs_length[doc_id] = doc_length
        total += doc_length
      rescue Exception => e
        docs_length[doc_id] = 756
        next
      end
    end
  end
  docs_length
end

def create_yml_file
  doc_lengths = get_docs_length
  File.open("doc_lengths.yml", "w") do |file|
    doc_lengths.each do |docl|
      file.write("doc_#{docl[0]}:\n")
      file.write("  - #{docl[1]}\n")
    end
  end
end

create_yml_file
