# -*- coding: utf-8 -*-
require "open-uri"
require "nokogiri"
require "pp"

class GooglePlayScraper

  @lang
  @similarAppsRep　#「類似のアプリ」の表現
  @webPage #スクレイプするhtml

  #スクレイピングしたアプリ情報を格納するハッシュ
  @app
  attr_reader :app

  #コンストラクタ
  def initialize(source, lang="ja")

    #***** 初期設定 *****#
    @lang = lang

    @app = Hash.new

    case @lang
    when "ja"
      @similarAppsRep = "類似のアイテム"
    else 
      @similarAppsRep = nil
    end
    
    #変数sourceはurlかパッケージIDのどちらか。
    #それぞれの場合においてurlとpackageIdを設定する
    if source.include?("http") 
      url = source
      #urlからクエリ部分を抜き出し、パッケージIDを見つける
      URI.parse(source).query.split("&").each do |q|
        #キーとバリューのセット
        tuple = q.split("=")
        #キーがidなら、その値をパッケージIDにセット
        if (tuple[0] == "id") 
          @app["packageid"] = tuple[1]
          end
      end
    else
      url = 
        "https://play.google.com/store/apps/details?id=%s&hl=%s" % [source, @lang]
      @app["packageid"] = source
    end
    
    #***** URLを読み込んでhtmlを返却 *****#
    charset = ""
    begin 
      html = open(url) do |data|
        charset = data.charset # 文字コードを取得（XML変換の引数に必要）
        data.read               #読み込み結果を返却
      end

      # htmlをXMLに変換
      @webPage = Nokogiri::HTML.parse(html, nil, charset)

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

  #アプリのタイトルを取得
  #戻り値：文字列
  def getAppTitle
    
    #タイトルをスクレイピング
    title = @webPage
      .xpath("//div[@class='document-title']")
      .children
      .inner_text

  end
  
  #アプリのアイコンのURLを取得
  #戻り値：文字列
  def getAppIconUrl

    #アイコン画像のURLをスクレイピング
    imageUrl = @webPage
      .xpath("//img[@alt='Cover art']")
      .first
      .attribute("src")
      .value

  end

  #アプリの説明文を取得
  #戻り値：文字列
  def getAppDesc

    #1行1ノードの説明文ノードセット
    nodeset = 
      @webPage
      .xpath("//div[@class='id-app-orig-desc']")
      .children

    desc = ""
    nodeset.each do |line|
      desc = desc + line + "\n"
    end

    return desc

  end

  #アプリの平均レートを取得
  #戻り値：少数
  def getAppRateAve

    rateAve = @webPage
      .xpath("//meta[@itemprop='ratingValue']")
      .attribute("content")
      .value
      .to_f

  end

  #アプリのレート数を取得
  #戻り値：整数
  def getAppRateCnt

    rateCount = @webPage
      .xpath("//meta[@itemprop='ratingCount']")
      .attribute("content")
      .value
      .to_i

  end

  #類似のアプリ一覧を取得
  #戻り値：文字列(パッケージID)の配列
  def getSimApps

    tmp = nil

    #「類似のアプリ」と「このデベロッパーの他のアプリ」からなる長さ2のノードセット
    nodeset = @webPage
      .xpath("//div[@class='rec-cluster']")

    #divの日本語のタイトルでどちらが「類似のアプリ」であるかを判断
    nodeset.each do |node|
      if (node.xpath("h1").inner_text == @similarAppsRep)
        tmp = node
        break;
      end
    end
    
    packageIds = []

    #1類似のアプリのパッケージID1ノードなリノードセット
    nodeset = tmp
      .xpath("div[@class='cards expandable']")
      .children
      .xpath("@data-docid")

    nodeset.each do |node|      
      packageIds.push(node.value)
    end

    return packageIds

  end

  #アプリのカテゴリを取得
  #戻り値：文字列
  def getAppCategory
    
    category = @webPage
      .xpath("//span[@itemprop='genre']")
      .children
      .inner_text

  end

  #アプリの開発者を取得
  def getAppDeveloper

    developer= @webPage
      .xpath("//span[@itemprop='name']")
      .children
      .inner_text

  end
end
#******************************************************#

