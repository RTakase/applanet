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

        #半角空白で区切って配列に
        query = params[:appname].split(" ")
        
        #入力されたアプリのGoogle Play url
        url = GoogleSearchScraper.new(query).url

        #スクレイピング結果
        @app = GooglePlayScraper.new(url).app 

        @dis = Hash.new
        #入力されたアプリとDB中の全アプリとの間でタイトルの編集距離を計算
        AndroidApp.all.each do |other|
          @dis[other["title"]] = 
            Levenshtein.distance(@app["title"], other["title"])
        end

        @dis = @dis.sort_by do |key, value|
          value
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
end
