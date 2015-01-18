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
    @charInfo["icon"] = "アイコン"
    @charInfo["description"] = "説明文"
    @charInfo["ratecount"] = "レビュー数"
    @charInfo["rateaverage"] = "星の数"
    @charInfo["simapps"] = "類似のアプリ"

    #未実装の特徴量
    @showOnly = 
      ["description", "ratecount", "rateaverage", "simapps"]

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
    @similarity = Hash.new if @similarity.blank?

    unless @appname.blank?

      begin 
        @errMessage = ""

        #半角空白で区切って配列に
        query = @appname.split(" ")
        
        #入力されたアプリのGoogle Play url
        url = GoogleSearchScraper.new(query).url

        #スクレイピング結果
        @app = GooglePlayScraper.new(url).app    

        ih = ImageHandler.new(@app["iconurl"])
        @app["avehash"] = ih.calcAverageHash

        #チェックされた特徴量でループ
        @checked.each do |char|
          
          activeChar = calcCharacteristics(char, @app)
          
          #DB中の全アプリでループ
          AndroidApp.all.each do |target|

            packageId = target["packageid"]           

            if @similarity[packageId].blank?
              @similarity[packageId] = Hash.new
            end   

            next unless @similarity[packageId][char].blank?

            passiveChar = calcCharacteristics(char, target)

            @similarity[packageId][char] =
              calcSimilarity(char, activeChar, passiveChar)
          end
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
    when "icon"
      target["avehash"]
    end

  end

  def calcSimilarity(char, active, passive)

    case char
    when "title"
      #magic number
      max = 20
      ashikiri = [Levenshtein.distance(active, passive), max]
      (max - ashikiri.min).to_f / max
    when "icon"
      #magic number
      max = 8 * 8
      (max - Levenshtein.distance(active, passive)).to_f / max
    end

  end
end
