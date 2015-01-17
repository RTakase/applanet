# -*- coding: utf-8 -*-

require "./lib/GooglePlayScraper" 
require "./lib/GoogleSearchScraper" 
require 'levenshtein' #編集距離を計算してくれる

class AppsController < ApplicationController

  def index

    @status = 0

    unless params[:appname].blank?

      begin 
        @errMessage = ""
        @appDetails = Hash.new

        #チェックされている特徴量を抽出
        char = params[:chars].keep_if { value = "1" }

        #半角空白で区切って配列に
        query = params[:appname].split(" ")
        
        #入力されたアプリのGoogle Play url
        url = GoogleSearchScraper.new(query).url

        #スクレイピング結果
        @app = GooglePlayScraper.new(url).app 

        #あるアプリに対する入力アプリとの距離
        @similarity = Hash.new

        #入力されたアプリとDB中の全アプリとの間で距離を計算
        AndroidApp.all.each do |target|
                      
          @similarity[target["packageid"]] = 
            calcDistance(char.keys, @app, target)
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
      end
    end
  end

  def calcDistance(keys, input, target)

    keys.collect do |key|
      case key
      when "title"
        calcEditDistance(input, target)
      when "icon"
        0
      end
    end

  end

  def calcEditDistance(input, target)

    Levenshtein.distance(@app["title"], target["title"])

  end
end
