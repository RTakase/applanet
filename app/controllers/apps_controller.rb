# -*- coding: utf-8 -*-

require "./lib/GooglePlayScraper" 
require "./lib/GoogleSearchScraper" 
require "./lib/ImageHandler"
require 'levenshtein' #編集距離を計算してくれる

class AppsController < ApplicationController
  
  def initialize

    #特徴量の識別子とその日本語表現
    @charInfo = Hash.new
    @charInfo["title"] = "タイトル"
    @charInfo["icongeo"] = "アイコン（形ベース）"
    @charInfo["iconcolor"] = "アイコン（色ベース）"
    @charInfo["description"] = "説明文"
    @charInfo["ratecount"] = "レビュー数"
    @charInfo["rateaverage"] = "星の数"
    @charInfo["simapps"] = "類似のアプリ"

    #未実装の特徴量
    @showOnly = 
      ["iconcolor", "description", "ratecount", "rateaverage", "simapps"]

    @checked = Array.new
    @checked.push("title")

    super
  end
  
  def load

    #チェックされている特徴量を抽出
    @checked = Array.new
    if params[:appchar] 
      params[:appchar].to_hash.keep_if do |k, v|        
        @checked.push(k) if v == "1"
      end 
    end
    @checked.push("title") if @checked.empty?

    #入力されたアプリ名(なんでparams[:name]は配列なの・・・）
    @appname = params[:name].to_s

    #DBから取り出すアプリ
    @simapps = Array.new

    begin 
      #半角空白で区切って配列に
      query = @appname.split(" ")
      
      #入力されたアプリのGoogle Play url
      url = GoogleSearchScraper.new(query).url

      #スクレイピング結果
      @app = GooglePlayScraper.new(url).app    

      #avehashを計算して追加
      ih = ImageHandler.new(@app["iconurl"])
      @app["avehash"] = ih.calcAverageHash

      #入力アプリのチェックされた特徴量を予め計算
      activeChar = Hash.new
      @checked.each do |char|
        activeChar[char] = calcCharacteristics(char, @app)
      end

      #DB中の全アプリでループ
      AndroidApp.all.each do |target|
        
        #viewで使うようのデータ
        viewData = Hash.new
        
        viewData["title"] = target["title"]
        viewData["packageid"] = target["packageid"]
        viewData["similarity"] = Array.new

        #チェックされた特徴量で類似度を算出
        @checked.each do |char|
          passiveChar = calcCharacteristics(char, target)
          sim = calcSimilarity(char, activeChar[char], passiveChar)
          viewData["similarity"].push(sim)
        end

        viewData["distance"] = Math.sqrt(
          viewData["similarity"].inject(0.0) {|m, v| m += v*v }
        )
        @simapps.push(viewData)
      end

      #類似度を距離でソート(三平方の定理で距離を計算）
      @simapps = @simapps.sort do |e1, e2|
        a = Math.sqrt(e1["similarity"]
            .inject(0.0){|m, v| m += v*v })
        b = Math.sqrt(e2["similarity"]
            .inject(0.0) {|m, v| m += v*v })
        b <=> a
      end

      #magic number
      #上位x件を抜き出し
      @simapps = @simapps.values_at(0..100)


    rescue OpenURI::HTTPError => ex.message
      @message = ex.message
    rescue NoUrlError => ex
      @message = ex.message
    rescue NoKeywordError => ex
      @message = ex.message      
      # rescue => ex
      #   @message = ex.message
      #   @status = 1
    end
  end

  def calcCharacteristics(char, target)

    case char
    when "title"
      target["title"]
    when "icongeo"
      target["avehash"]
    end

  end

  def calcSimilarity(char, active, passive)

    case char
    when "title"
      dis = Levenshtein.distance(active, passive)
      max = [active.length, passive.length].max
      (max - dis.to_f) / max
    when "icongeo"
      max = 8 * 8      #magic number
      (max - Levenshtein.distance(active, passive)).to_f / max
    end

  end
end
