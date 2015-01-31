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
        "simapps" => proc{|app| app["simapps"]}
      }

      #それぞれの基準における距離
      diffCalculator = {
        "title" => method(:calcEditDistance),
        "icongeo" => method(:calcEditDistance),
        "simapps" => method(:calcSetDifference)
      }

      #それぞれの基準における距離の最大値
      diffMax = {
        "title" => proc {|*args|
          args.max {|a,b| a.length <=> b.length}.length
        },#method(:getTitleMaxLength),
        "icongeo" => proc{|*args| 64 },
        "simapps" => proc{|*args| 
          args.inject([]) {|m,v| m|v}.length
          }
      }

      #スクレイピング結果からチェックされた特徴量を計算しておく
      act = Hash.new
      @checked.each do |char|
        act[char] = charCalculator[char].call(@app)
      end

      #DB中の全アプリでループ
      @simapps = AndroidApp.take(5000).collect do |target|
      #@simapps = AndroidApp.all.collect do |target|
 
        #上で計算しておいた特徴量とtargetの特徴量で類似度を計算
        sim = @checked.collect do |char|
          pssChar = charCalculator[char].call(target)
          diff = diffCalculator[char].call(act[char], pssChar)
          max = diffMax[char].call(act[char], pssChar)
          (max - diff).to_f / max
        end
        
        #三平方の定理よりキーアプリとの距離を算出
        dis = Math.sqrt(sim.inject(0) {|m, v| m += v*v })

        #viewで使うようのデータを返却
        viewData = {
          "title" => target["title"],
          "packageid" => target["packageid"],
          "similarity" => sim,
          "distance" => dis
        }
      end

      #距離でソート
      @simapps.sort! {|a,b| b["distance"] <=> a["distance"]}

      #上位x件を抜き出し      #magic number
      @simapps = @simapps.values_at(0..100)

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
    if app["avehash"].blank?
      ImageHandler.new(app["iconurl"]).calcAverageHash
    else
      app["avehash"]
    end
  end

  def calcEditDistance(actChar, pssChar)
     Levenshtein.distance(actChar, pssChar)
  end

  def calcSetDifference(actChar, pssChar)
    ((actChar|pssChar) - (actChar&pssChar)).length
  end
end
