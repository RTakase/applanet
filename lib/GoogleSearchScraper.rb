# -*- coding: utf-8 -*-
require "open-uri"
require "nokogiri"
require "pp"
require "cgi"

class NoKeywordError < StandardError
end
class NoUrlError < StandardError
end

class GoogleSearchScraper

  @url
  attr_reader :url

  #コンストラクタ
  def initialize(query)

    if (query.empty?)
      raise NoKeywordError
        .new("キーワードを入力してください・・・");
    end

    @url = extractFirstUrl(query)
  end

  #以降の定義はprivate
  private

  #与えられた検索ワードでURLを整形
  def makeUrl(keywords)

    url = "http://www.google.com/" +
      "search?num=100&ie=UTF-8&oe=UTF-8&hl=ja&q="    
    #検索キーワードを"+"で連結
    loop do
      url += CGI.escape(keywords.shift)
      break if keywords.empty?
      url += "+"
    end 
    return url

  end

  #検索結果の中で最も上位に現れたtargetのURLを返却
  def extractFirstUrl(query, target="play.google.com/store/apps/details") 

    url = "http://www.google.com/search?num=100&ie=UTF-8&oe=UTF-8&hl=ja&q=%s" % CGI.escape(query)

    begin 
      charset = ""
      html = open(url) do |data|
        charset = data.charset # 文字コードを取得（XML変換の引数に必要）
        data.read               #読み込み結果を返却
      end

    rescue OpenURI::HTTPError
      #URLの読み込み失敗
      raise OpenURI::TTPError 
    end

    # htmlをXMLに変換
    document = Nokogiri::HTML.parse(html, nil, charset)

    #検索結果の一覧
    records = document
      .xpath("//li[@class='g']")

    begin
      #各結果からURL部分を抽出
      records.each do |record|

        #a要素の属(URL)性を取り出す
        link = record
          .xpath(".//a")
          .attribute("href")
          .value
          .slice(/http.*$/) #先頭についている不要な部分を除去

        #ウェブサイト以外（"http"が含まれれていない）ならばスルー
        next unless link

        #おしりにもついてる不要な文字を除去
        link = link.split("&")[0]    

        #目的のドメイン名がURL中に含まれていればこれがお目当ての物
        if link.include?(target) 
         return CGI.unescape(link)
        end
      end
    end      
    
    #ループの途中でreturnしなかったということは
    #検索結果に抽出対象のURLがなかったことを意味する
    raise NoUrlError
      .new("検索したいアプリを見つけられませんでした・・・")
  end

end
