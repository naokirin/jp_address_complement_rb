# frozen_string_literal: true
# rbs_inline: enabled

module JpAddressComplement
  # UTF-8 版 KEN_ALL（utf_ken_all.csv）のフォーマット定数
  #
  # CSV の各列インデックスを定義する。include することでクラス内から直接参照できる。
  #
  # 参考: https://www.post.japanpost.jp/zipcode/dl/readme.html
  module KenAll
    # 列インデックス（KEN_ALL.CSV 形式）
    COL_PREF_CODE = 0 #: Integer
    COL_POSTAL_CODE = 2 #: Integer
    COL_KANA_PREF = 3 #: Integer
    COL_KANA_CITY = 4 #: Integer
    COL_KANA_TOWN = 5 #: Integer
    COL_PREF = 6 #: Integer
    COL_CITY = 7 #: Integer
    COL_TOWN = 8 #: Integer
    COL_IS_PARTIAL = 9 #: Integer
    COL_HAS_ALIAS = 12 #: Integer
    COL_IS_LARGE_OFFICE = 13 #: Integer
  end
end
