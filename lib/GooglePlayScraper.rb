# -*- coding: utf-8 -*-
require "open-uri"
require "nokogiri"
require "pp"

class GooglePlayScraper

  @document #スクレイプするhtml

  #スクレイピングしたアプリ情報を格納するハッシュ
  @app
  attr_reader :app

  #コンストラクタ
  def initialize(source)

    @app = Hash.new
  
    url, @app["packageid"] = convert(source)

    charset = ""
    begin 
      html = open(url) do |data|
        charset = data.charset # 文字コードを取得（XML変換の引数に必要）
        data.read               #読み込み結果を返却
      end

      # htmlをXMLに変換
      @document = Nokogiri::HTML.parse(html, nil, charset)

    rescue OpenURI::HTTPError
      #URLの読み込み失敗
      raise 
    end

    #***** スクレイピング *****#
    @app["title"] = getAppTitle
    @app["iconurl"] = getAppIconUrl
    @app["description"] = getAppDesc
    @app["rateaverage"] = getAppRateAve
    @app["ratecount"] = getAppRateCnt
    @app["simapps"] = getSimApps
    @app["category"] = getAppCategory
    @app["developer"] = getAppDeveloper
  end
  
  #以降の定義はprivate
  private 

  ### 変数sourceはurlかパッケージIDのどちらか。
  ### それぞれの場合においてurlとpackageIdを設定する
  def convert(source)   
    #source=urlな場合
    if source.match(/http(s)?:\/\/.*$/)

      parsed = URI.parse(source) #urlを分解

      #クエリに対してhl=jaを追加
      if md = parsed.query.match(/hl=(.*)/)
        #設定値を強制的にjaに
        #"abcde"["cd"] = "hoge" =>"abhogee"
        parsed.query[md[1]] = "ja"
      else 
        parsed.query += "&hl=ja"       
      end

      #部品でurlを再構築
      url = parsed.to_s

      #クエリからパッケージIDを抜き出す(.*?で最短マッチングを使用）
      md = parsed.query.match(/id=(.*?)[$&]/)
      pp md[0] + " " + md[1]
      packageid = md[1]
      
      #source=packageidな場合
    else
      url = 
        "https://play.google.com/store/apps/details?id=#{source}&hl=ja"
      packageid = source
    end

    return url, packageid
  end
    
  #アプリのタイトルを取得
  def getAppTitle
    return @document
      .xpath("//div[@class='document-title']")
      .children
      .inner_text
  end
  
  #アプリのアイコンのURLを取得
  def getAppIconUrl
    return @document
      .xpath("//img[@alt='Cover art']")
      .first
      .attribute("src")
      .value

  end

  #アプリの説明文を取得
  def getAppDesc
    #1行1ノードの説明文ノードセット
    nodeset = 
      @document
      .xpath("//div[@class='id-app-orig-desc']")
      .children

    desc = ""
    nodeset.each do |line|
      desc = desc + line + "\n"
    end

    return desc
  end

  #アプリの平均レートを取得
  def getAppRateAve
    return @document
      .xpath("//meta[@itemprop='ratingValue']")
      .attribute("content")
      .value
      .to_f
  end

  #アプリのレート数を取得
  def getAppRateCnt
    return @document
      .xpath("//meta[@itemprop='ratingCount']")
      .attribute("content")
      .value
      .to_i
  end

  #類似のアプリ一覧を取得
  #戻り値：文字列(パッケージID)の配列
  def getSimApps
    similarAppsRep = "類似のアイテム"

    #「類似のアプリ」と「このデベロッパーの他のアプリ」からなる長さ2のノードセット
    @document.search(".rec-cluster").each do |cluster|
      if cluster.search("h1").inner_text.include?(similarAppsRep)
        simapps = cluster.search(".card").collect do |card|
          card.attribute("data-docid").value
        end   
        return simapps
      end
    end
  end
  
  #アプリのカテゴリを取得
  #戻り値：文字列
  def getAppCategory    
    category = @document
      .xpath("//span[@itemprop='genre']")
      .children
      .inner_text
  end

  #アプリの開発者を取得
  def getAppDeveloper
    developer= @document
      .xpath("//span[@itemprop='name']")
      .children
      .inner_text
  end
end

