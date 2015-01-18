# -*- coding: utf-8 -*-

require "./lib/GooglePlayScraper" 
require "./lib/GoogleSearchScraper" 
require "./lib/ImageHandler"
require 'levenshtein' #編集距離を計算してくれる

class AppsController < ApplicationController
  
  def index

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

    #ウェブページの状態（0：初期　1：エラー　2：成功）
    @status = 0

    #チェックされている特徴量
    @checked = Array.new
    #チェックされている特徴量を抽出
    if params[:appchar] 
      params[:appchar].to_hash.keep_if do |k, v|        
        @checked.push(k) if v == "1"
      end 
    end
    @checked.push("title") if @checked.empty?

    #入力されたアプリ名(なんでparams[:name]は配列なの・・・）
    @appname = params[:name].to_s

    #あるアプリに対する入力アプリとの距離
    @similarity = Hash.new

    unless @appname.blank?

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

        @titleInDB = Hash.new

        #チェックされた特徴量でループ
        @checked.each do |char|

          activeChar = calcCharacteristics(char, @app)
          
          #DB中の全アプリでループ
          AndroidApp.all.each do |target|

            packageId = target["packageid"]    
            
            @titleInDB[packageId] = target["title"]
            
            if @similarity[packageId].blank?
              @similarity[packageId] = Array.new
            end   

            passiveChar = calcCharacteristics(char, target)

            @similarity[packageId]
              .push(calcSimilarity(char, activeChar, passiveChar))

          end
        end

        #類似度を距離でソート(三平方の定理で距離を計算）
        @similarity = @similarity.sort do |(k1, v1), (k2, v2)|
          a = Math.sqrt(v1.inject(0.0) {|m, v| m += v*v })
          b = Math.sqrt(v2.inject(0.0) {|m, v| m += v*v })
          b <=> a
        end
        
        @status = 2
        
      rescue OpenURI::HTTPError => ex.message
        @errMessage = ex.message
        @status = 1
      rescue NoUrlError => ex
        @errMessage = ex.message
        @status = 1
      rescue NoKeywordError => ex
        @errMessage = ex.message      
        @status = 1
        # rescue => ex
        #   @errMessage = ex.message
        #   @status = 1
      end
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
      max = 30      #magic number
      ashikiri = [Levenshtein.distance(active, passive), max]
      (max - ashikiri.min).to_f / max
    when "icongeo"
      max = 8 * 8      #magic number
      (max - Levenshtein.distance(active, passive)).to_f / max
    end

  end
end
