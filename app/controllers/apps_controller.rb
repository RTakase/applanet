# -*- coding: utf-8 -*-

require "./lib/GooglePlayScraper" 
require "./lib/GoogleSearchScraper" 
require "./lib/ImageHandler"
require "levenshtein" #編集距離を計算してくれる
require "statsample"

class NoCharError < StandardError
end

class AppsController < ApplicationController

  def covariance_matrix
  end

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
      @simapps = AndroidApp.take(10000).collect do |target|
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
      @simapps = @simapps.values_at(0..10)

      #主成分分析
      #https://github.com/clbustos/statsample
      if @simapps[0]["similarity"].length >= 3
        
        cov = covariance_matrix(@simapps)
        
        pca = Statsample::Factor::PCA.new(cov)

        #中身を随時減らしていくために別途用意
        _evec = pca.eigenvectors
        _eval = pca.eigenvalues

        eval = Array.new
        evec = Array.new

        #最大の固有値に対応する固有ベクトルを2個選ぶ
        #固有値の配列の並びと固有ベクトルの配列の並びは対応付いてると信じてる
        (0..1).each do |i|
          eval[i] = _eval.max
          index = _eval.index(eval[i])
          evec[i] = _evec[index]
          _evec.delete(evec[i])
          _eval.delete(eval[i])
        end

        #類似度を次元削減
        (0..@simapps.length-1).each do |i|
          vec = Vector.elements(@simapps[i]["similarity"])         
          @simapps[i]["similarity"] = evec.collect do |evec|     
            evec.inner_product(vec)
          end          
        end
      end

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

  #Statsampleがベクトル間の共分散行列しかなさそうだったので要素間のものを定義
  def covariance_matrix(simapps)
    row = simapps[0]["similarity"].length 
    col = simapps.length
    mean = Array.new(row,0.0)
    cov = Matrix.zero(row)

    #平均値を算出
    (0..col-1).each do |i| 
      data = simapps[i]["similarity"]

      (0..row-1).each do |j|
        mean[j] += data[j]
      end
    end
    mean.collect! {|v| v / col }

    #共分散行列を算出
    (0..col-1).each do |i|
      data = simapps[i]["similarity"]

      (0..row-1).each do |j|
        (0..row-1).each do |k|
          cov[j,k] += (data[j] - mean[j]) * (data[k] - mean[k])
        end
      end
    end
    cov.collect {|v| v / col }
  end
end
