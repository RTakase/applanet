# -*- coding: utf-8 -*-
require "rmagick"
require "open-uri"
require "pp"
#いちいち Magick:: を書くのが面倒なため親クラス？に指定
include Magick

class ImageHandler

  @image
  
  def initialize(url)
    
    #Magick::Image.read の戻り値は配列　中身は1要素1レイヤー
    @image = open(url) do |f|
      Image.read(f.path).first
      #f.delete
    end

  end

  #http://www.toyamaguchi.com/blog/archives/20120731_average_hash/
  def calcAverageHash(size=8)

    #画像をリサイズし、量子レベルを設定（都合よくグレースケール化ができそうだったので）
    image = 
      @image.resize(size, size)
      .quantize(256, GRAYColorspace)

    #色の平均値を計算（グレースケールなのでR要素のみで）
    total = 0
    count = 0
    image.each_pixel do |pixel, i, j|
      total += pixel.red
      count += 1
    end
    
    average = total/count

    #average hash を計算
    aveHash = ""
    image.each_pixel do |pixel, i, j|
      aveHash += pixel.red > average ? "1" : "0"
    end    

    return aveHash
  end
end

