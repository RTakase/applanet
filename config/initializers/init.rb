# -*- coding: utf-8 -*-

#特徴量の識別子とその日本語表現
@charInfo = Hash.new
@charInfo["title"] = "タイトル"
@charInfo["icongeo"] = "アイコン（形ベース）"
@charInfo["iconcolor"] = "アイコン（色ベース）"
@charInfo["description"] = "説明文"
@charInfo["ratecount"] = "レビュー数"
@charInfo["rateaverage"] = "星の数"
@charInfo["simapps"] = "類似のアプリ"

#未実装な部分
@showOnly = Array.new
@showOnly = ["iconcolor", "description", "ratecount", "rateaverage", "simapps"]
