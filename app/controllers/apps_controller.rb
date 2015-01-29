# -*- coding: utf-8 -*-

require "./lib/GooglePlayScraper" 
require "./lib/GoogleSearchScraper" 
require "./lib/ImageHandler"
require 'levenshtein' #編集距離を計算してくれる

class NoCharError < StandardError
end

class AppsController < ApplicationController

  def error
  end

  def load
    begin 
      if params[:char].blank?
        raise NoCharError.new("基準はひとつ以上選んでください・・・");
      else
        #チェックされている特徴量を抽出
        @checked = params[:char].split(",");       
      end

      #入力されたアプリのGoogle Play url
      url = GoogleSearchScraper.new(params[:name]).url

      #スクレイピング結果
      @app = GooglePlayScraper.new(url).app   

      #それぞれの基準における特徴量
      charCalculator = {
        "title" => proc{|app| app["title"] },
        "icongeo" => method(:calcAverageHash),
        "simapps" => proc{|app| app["simapps"] }
      } 

      #それぞれの基準における距離
      diffCalculator = {
        "title" => method(:calcEditDistance),
        "icongeo" => method(:calcEditDistance),
        "simapps" => method(:calcSetDifference)
      }

      #それぞれの基準における距離の最大値
      diffMax = {
        "title" => method(:getTitleMaxLength),
        "icongeo" => proc{|*args| 64 },
        "simapps" => proc{|*args| 0 }
      }
      
      #与えられたactとpssに対して、charが示す特徴量での類似度を算出するproc
      #特徴量　→　距離　→　類似度
      calcSimilarity = proc do |act, pss, char|
        actChar = charCalculator[char].call(act)
        pssChar = charCalculator[char].call(pss)
        diff = diffCalculator[char].call(actChar, pssChar)
        max = diffMax[char].call(actChar, pssChar)
        (max - diff).to_f / max
      end

      #キーアプリの類似度は予め計算しておく（procのcurryを利用）
      calcSimilarity.curry.(@app)

      #DB中の全アプリでループ
      #@simapps = AndroidApp.take(31).collect do |target|
      @simapps = AndroidApp.all.collect do |target|
        
        #viewで使うようのデータ
        viewData = {
          "title" => target["title"],
          "packageid" => target["packageid"],
          "similarity" => Array.new
        }

        #チェックされた特徴量で類似度を算出
        viewData["similarity"] = @checked.collect do |char|
          calcSimilarity.call(@app, target, char)
        end

        #三平方の定理よりキーアプリとの距離を算出
        viewData["distance"] = 
          Math.sqrt(viewData["similarity"].inject {|m, v| m += v*v })

        viewData
      end

      #距離でソート
      @simapps.sort! {|a,b| b["distance"] <=> a["distance"]}

      #上位x件を抜き出し      #magic number
      @simapps = @simapps.values_at(0..30)

    rescue OpenURI::HTTPError => ex.message
      @message = ex.message
      render action: :error
    rescue NoUrlError => ex
      @message = ex.message
      render action: :error
    rescue NoKeywordError => ex
      @message = ex.message
      render action: :error     
    rescue NoCharError => ex
      @message = ex.message
      render action: :error   
    # rescue => ex
    #   #@message = "すみません何かがおかしいようです・・・"
    #   @message = ex.message
    #   render action: :error
    end
  end

  def getTitleMaxLength(*args)
    str = args.max do |a,b|
      a.length <=> b.length
    end
    return str.length
  end

  def calcAverageHash(app)
    if app["averagehash"].blank?
      ImageHandler.new(app["iconurl"]).calcAverageHash
    else 
      app["averagehash"]
    end
  end

  def calcEditDistance(actChar, pssChar)
     Levenshtein.distance(actChar, pssChar)
  end

  def calcSetDifference(actChar, pssChar)
    return 0
  end
end
