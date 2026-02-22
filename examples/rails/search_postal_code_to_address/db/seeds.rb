# frozen_string_literal: true

# サンプル用の郵便番号データ（本番では KEN_ALL.CSV を rake jp_address_complement:import で投入）
# 東京都千代田区など数件を登録し、動作確認できるようにする
JpAddressComplement::PostalCode.find_or_create_by!(
  postal_code: '1000001', pref_code: '13', pref: '東京都', city: '千代田区', town: '千代田',
  kana_pref: 'トウキョウト', kana_city: 'チヨダク', kana_town: 'チヨダ',
  has_alias: false, is_partial: false, is_large_office: false
)
JpAddressComplement::PostalCode.find_or_create_by!(
  postal_code: '1000001', pref_code: '13', pref: '東京都', city: '千代田区', town: '丸の内（１丁目）',
  kana_pref: 'トウキョウト', kana_city: 'チヨダク', kana_town: 'マルノウチ（１チョウメ）',
  has_alias: false, is_partial: false, is_large_office: false
)
JpAddressComplement::PostalCode.find_or_create_by!(
  postal_code: '0600000', pref_code: '01', pref: '北海道', city: '札幌市中央区', town: nil,
  kana_pref: 'ホッカイドウ', kana_city: 'サッポロシチュウオウク', kana_town: nil,
  has_alias: false, is_partial: false, is_large_office: false
)
JpAddressComplement::PostalCode.find_or_create_by!(
  postal_code: '1500002', pref_code: '13', pref: '東京都', city: '渋谷区', town: '渋谷',
  kana_pref: 'トウキョウト', kana_city: 'シブヤク', kana_town: 'シブヤ',
  has_alias: false, is_partial: false, is_large_office: false
)
