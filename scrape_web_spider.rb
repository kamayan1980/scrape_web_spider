Encoding.default_external = 'UTF-8'
require 'open-uri'
require 'nokogiri'
require "csv"
require 'anemone'
require 'time'

def extraction_html(doc)

  web_title = doc.title
  web_desc = doc.xpath('/html/head/meta[@name="description"]/@content').to_s
  web_h1 = doc.css("h1").inner_text

  if web_h1.empty?
    doc.search("h1 a img").each do |image|
      web_h1 = image.attribute("alt").value
    end
  end
  web_h1 = web_h1.gsub(/\r\n|\r|\n|\s|\t/, "")

  return web_title, web_desc, web_h1      # 複数の値を返す
end

ARGV.each do |uri|

  scrape_csv_txt = []
  scrape_csv_head = ["URL" ,"Title", "Description", "H1"]
  charset = nil

  opts = {
    # :depth_limit => 1,
    :user_agent => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.10240",
    :delay => 2,
    :skip_query_strings => true,
  }
  
  Anemone.crawl(uri, opts) do |anemone|
    anemone.on_every_page do |page|
      if page.doc.nil?
        next
      end
      puts page.url
      web_title, web_desc, web_h1 = extraction_html(page.doc)      
      scrape_csv_txt << [page.url, web_title, web_desc, web_h1]
    end
  end

  fname = uri 
  fname = fname.gsub(/:|\//, '_')
  t = Time.new


  fname += t.strftime("%Y%m%d_%H%M%S") + ".csv"
  
  CSV.open(fname, "w") do |csv|
    csv << scrape_csv_head
    scrape_csv_txt.each do |row|
      csv << row
    end
  end

end
