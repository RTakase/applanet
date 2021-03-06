# -*- coding: utf-8 -*-
#使い方(引数に半角空白混じりのアプリ名を入れる場合は、必ずダブルクォーテーションで区切ること
#rake db_manager:update[angry]

namespace :dbmanage do

  require "GoogleSearchScraper"
  require "GooglePlayScraper"
  require "ImageHandler"


  desc "adjust database size"
  task :adjust => :environment do 
    
    AndroidApp.all.each_with_index do |app, i|
      if i.modulo(2) == 0
        app.destroy
        app.save
      end
    end
  end


  desc "check emply value in androidapp database and rewrite"
  task :check => :environment do |x, args|
    # ログの出力を切る
    ActiveRecord::Base.logger = false    

    #テーブルの属性を取り出す（idとavehashはチェックしないので除外）
    attrs = AndroidApp.attribute_names - ["id"]

    AndroidApp.all.each do |app|
      begin
        emptyAttrs = attrs.select {|attr| app[attr].blank? }        
        print "."
        
        unless emptyAttrs.empty?
          newone = GooglePlayScraper.new(app["packageid"]).app

          emptyAttrs.each do |attr|
            app[attr] = newone[attr]
          end

          if emptyAttrs.include?("avehash")
            ih = ImageHandler.new(app["iconurl"])
            app["avehash"] = ih.calcAverageHash
          end

          app.save
          puts ""
          puts "#{emptyAttrs} in #{app["packageid"]} was made filled!"
        end         
        rescue => ex
        app.destroy
        app.save
        puts "was destroyed. reasons are here."
        puts ex.message
      end
    end
  end

  desc "update trigger"
  task :update => :environment do
    keywords = [
      # "エディタ android アプリ",
      # "ばんごはん android アプリ",
      # "カカオトーク android アプリ",
      # "白猫 android アプリ",
      # "jam android app",
      # "onepiece android app",
      # "naruto android app",
      # "timer android app",
      # "light android app",
      # "memory android app",
      # "歯医者マニア android app",
      # "Broken Screen android app",
      # "ラーメン android app",
      # "star android app",
      # "ファッション android app",
      # "crazy android app",
      # "Dumplings to the Moon android app"
      "angry bird android",
      "ソニック",
      "ミッキー",
      "life bear",
      "万歩計 android",
      "サンタクロース android",
      "コンセント android",
      "smart news android",
      "コロニー android",
      "ビックリマン android",
      "イオン android",
      "政治 android アプリ",
      "パソコン　android アプリ",
      "車　android アプリ",
      "ローソン　アンドロイド　アプリ",
      "bigmama android アプリ",
      "ブラウザ android アプリ"
    ]

    apps = keywords.collect do |keyword|
      begin 
        GoogleSearchScraper.new(keyword).url
      rescue => ex
        puts ex.message
        ""
      end
    end    
    
    apps.delete("")
    
    apps.each do |app|      
      #与えたい引数をrakeのtaskの引数形式に変換
      args = Rake::TaskArguments.new([:targetId], [app])
      Rake::Task["dbmanage:update:loop"].execute(args)
    end
  end

  namespace :update do
    desc "update androidapp database"
    task :loop,
    [:targetId, :callerIds] do |x, args|

      begin
        # ログの出力を切る
        ActiveRecord::Base.logger = false    
        
        #タスク実行時の引数を取得（なにもない場合はアングリーバード）
        packageid = args.targetId
        packageid = "com.nhncorp.lineweather" if packageid.blank?

        callerIds = args.callerIds
        callerIds = [] if callerIds.blank?

        print callerIds.length
        print ":" + packageid

        #********************************#
        # AndroidApp.all.each do |app|
        #   app.destroy
        # end
        #********************************#

        res = AndroidApp.find_by(:packageid => packageid)

        if res
          #すでに登録されていれば登録はしない
          puts "...is already exists."

          # sum = res["simapps"] | app["simapps"]

          # puts app["simapps"]

          # if sum.length > res["simapps"].length
          #   res["simapps"] = sum
          #   res.save
          #   print " only simapps were updated."
          # end

          # puts ""
          sims = res["simapps"]
        else
          #未登録であればスクレイピングを行って登録
          app = GooglePlayScraper.new(packageid).app

          begin
            #average hash を計算して追加
            ih = ImageHandler.new(app["iconurl"])
            app["avehash"] = ih.calcAverageHash
          rescue => ex
            print "without avehash, "
          end

          #登録
          newone = AndroidApp.new(app)
          newone.save
          puts "...was created."

          sims = app["simapps"]
        end     

        #2つのアプリがお互いの類似のアプリの1つ目である場合無限ループが起こる　これを回避
        sims = sims.drop_while do |item| 
          callerIds.include?(item)
        end

        callerIds.push(packageid)

        #呼び出しの階層が深くなり過ぎたらやめよう
        if callerIds.length < 5

          #類似のアプリに対して繰り返し
          sims.each do |sim|         
            #与えたい引数をrakeのtaskの引数形式に変換
            args = Rake::TaskArguments.new(
              [:targetId, :callerIds], [sim, callerIds])
            Rake::Task["dbmanage:update:loop"].execute(args)
          end

        end

        callerIds = callerIds.pop
        
      rescue => ex
        puts "...was NOT created. reason is here."
        puts ex.message
      end    
    end
  end
end
