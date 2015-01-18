# -*- coding: utf-8 -*-
#使い方(引数に半角空白混じりのアプリ名を入れる場合は、必ずダブルクォーテーションで区切ること
#rake db_manager:update[angry]

namespace :dbmanage do

  # descの記述は必須
  desc "androidApp database manager"
  
  task :update, 
    [:callerIds, :targetId] => :environment do |x, args|

      begin
        # ログの出力を切る
        ActiveRecord::Base.logger = false    

        require "GoogleSearchScraper"
        require "GooglePlayScraper"
        require "ImageHandler"
        
        #タスク実行時の引数を取得（なにもない場合はアングリーバード）
        packageId = args.targetId
        #packageId = "com.rovio.angrybirds" if packageId.blank?
        packageId = "jp.gungho.pad" if packageId.blank?

        callerIds = args.callerIds
        callerIds = [] if callerIds.blank?

        print callerIds.length
        print ":" + packageId

        #********************************#
        # AndroidApp.all.each do |app|
        #   app.destroy
        # end
        #********************************#

        res = AndroidApp.find_by(:packageid => packageId)

        if (res)
          #すでに登録されていれば登録はせず、類似のアプリ配列を取得
          puts "...is already exists."
          sims = res.simapps
        else
          #未登録であればスクレイピングし、登録類似のアプリに対して本タスクを繰り返す

          #スクレイピング
          app = GooglePlayScraper.new(packageId).app

          #average hash を計算して追加
          ih = ImageHandler.new(app["iconurl"])
          app["avehash"] = ih.calcAverageHash

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

        callerIds.push(packageId)

        #呼び出しの階層が深くなり過ぎたらやめよう
        if callerIds.length < 10

          #類似のアプリに対して繰り返し
          sims.each do |sim|         
            #与えたい引数をrakeのtaskの引数形式に変換
            args = Rake::TaskArguments.new(
              [:callerIds, :targetId], [callerIds, sim])
            Rake::Task["dbmanage:update"].execute(args)
          end

        end

        callerIds = callerIds.pop
        
      rescue => ex
        puts "...was NOT created. reason is here."
        puts ex.message
      end    
    end
  end
