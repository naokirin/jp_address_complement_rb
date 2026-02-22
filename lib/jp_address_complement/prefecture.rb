# frozen_string_literal: true
# rbs_inline: enabled

module JpAddressComplement
  # JIS X 0401 都道府県コード（01–47）⇔都道府県名の変換
  module Prefecture
    # JIS X 0401 都道府県コード → 都道府県名（正式名称）
    CODE_TO_NAME = {
      '01' => '北海道',
      '02' => '青森県',
      '03' => '岩手県',
      '04' => '宮城県',
      '05' => '秋田県',
      '06' => '山形県',
      '07' => '福島県',
      '08' => '茨城県',
      '09' => '栃木県',
      '10' => '群馬県',
      '11' => '埼玉県',
      '12' => '千葉県',
      '13' => '東京都',
      '14' => '神奈川県',
      '15' => '新潟県',
      '16' => '富山県',
      '17' => '石川県',
      '18' => '福井県',
      '19' => '山梨県',
      '20' => '長野県',
      '21' => '岐阜県',
      '22' => '静岡県',
      '23' => '愛知県',
      '24' => '三重県',
      '25' => '滋賀県',
      '26' => '京都府',
      '27' => '大阪府',
      '28' => '兵庫県',
      '29' => '奈良県',
      '30' => '和歌山県',
      '31' => '鳥取県',
      '32' => '島根県',
      '33' => '岡山県',
      '34' => '広島県',
      '35' => '山口県',
      '36' => '徳島県',
      '37' => '香川県',
      '38' => '愛媛県',
      '39' => '高知県',
      '40' => '福岡県',
      '41' => '佐賀県',
      '42' => '長崎県',
      '43' => '熊本県',
      '44' => '大分県',
      '45' => '宮崎県',
      '46' => '鹿児島県',
      '47' => '沖縄県'
    }.freeze

    NAME_TO_CODE = CODE_TO_NAME.invert.freeze

    # 都道府県コードから都道府県名を返す
    # @rbs (String | Integer | nil) -> String?
    # @param code [String, Integer, nil] 都道府県コード（01–47）。数値またはゼロパディング文字列
    # @return [String, nil] 都道府県名。該当なし・不正入力時は nil
    def self.name_from_code(code)
      return nil if code.nil?
      return nil if code.is_a?(String) && code.strip.empty?

      key = normalize_code(code)
      return nil unless key
      return nil if key.to_i < 1 || key.to_i > 47

      CODE_TO_NAME[key]
    end

    # 都道府県名（正式名称）から都道府県コードを2桁文字列で返す
    # @rbs (String?) -> String?
    # @param name [String, nil] 都道府県の正式名称
    # @return [String, nil] 2桁のコード（例: "13"）。該当なし時は nil
    def self.code_from_name(name)
      return nil if name.nil?
      return nil if name.is_a?(String) && name.strip.empty?

      NAME_TO_CODE[name]
    end

    def self.normalize_code(code)
      case code
      when Integer
        (1..47).cover?(code) ? format('%02d', code) : nil
      when String
        normalize_code_string(code.strip)
      end
    end
    private_class_method :normalize_code

    def self.normalize_code_string(stripped)
      return nil if stripped.empty?
      return nil unless stripped.match?(/\A\d{1,2}\z/)

      n = stripped.to_i
      (1..47).cover?(n) ? format('%02d', n) : nil
    end
    private_class_method :normalize_code_string
  end
end
