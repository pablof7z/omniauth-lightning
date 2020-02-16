require 'omniauth-oauth'
require 'json'

module OmniAuth
  module Strategies
    class Lightning
      include OmniAuth::Strategy

      option :title, 'Lightning Network Verification'
      option :sats_amount, 10
      option :validating_text, 'invoice-for-auth'
      option :invoice_max_age_in_seconds, 1800
      option :lnpay_key, 'pak_O0iUMxk8kK_qUzkT4YKFvp1ZsUtp'
      option :fields, [:pubkey]

      uid { @pubkey }

      info do
        {
          pubkey: @pubkey,
          description: @description
        }
      end

      def request_phase
        if options[:on_login]
          options[:on_login].call(self.env)
        else
          OmniAuth::Form.build(
            title: (options[:title]),
            url: callback_path
          ) do |f|
            f.html """
                <p>
                  Create an invoice for #{options[:invoice_sats_amount]}
                  satoshis that starts with \"#{options[:validating_text]}\".
                </p>
              """
            f.text_field 'Invoice', 'invoice'
          end.to_response
        end
      end

      def callback_phase
        r = validate_invoice!(request['invoice'])

        if r == :ok
          super
        else
          return fail!(*r)
        end
      end

      private

      def invalid_invoice(data)
        !data || data['error']
      end

      def invoice_without_required_amount(data)
        data['num_satoshis'].to_i != options[:sats_amount]
      end

      def invoice_without_required_text(data)
        !data['description'].downcase.include?(options[:validating_text].downcase)
      end

      def invoice_too_old(data)
        Time.at(data['timestamp'].to_i) < Time.now - options[:invoice_max_age_in_seconds].to_i
      end

      def invoice_from_custodial_wallet(data)
        CUSTODIAL_PUBKEYS.include?(data['destination'])
      end

      def validate_invoice!(invoice)
        data = decode_invoice(invoice)

        case
        when invalid_invoice(data)
          return :invalid_invoice, ((data && data['error']) ? Exception.new(data['error']) : nil)
        when invoice_without_required_amount(data)
          return :invoice_without_required_amount,
                 Exception.new("Invoice amount is #{data['num_satoshis']}; " \
                  "should have been #{options[:sats_amount]}")
        when invoice_without_required_text(data)
          return :invoice_without_required_text,
                 Exception.new("Invoice's description is '#{data['description']}'; " \
                 "should have text '#{options[:validating_text]}'")
        when invoice_too_old(data)
          return :old_invoice
        when invoice_from_custodial_wallet(data)
          return :custodial_wallet
        end

        @pubkey = data['destination']
        @description = data['description']

        return :ok
      end

      def decode_invoice(invoice)
        response = RestClient.get("https://#{options[:lnpay_key]}@lnpay.co/v1/node/default/payments/decodeinvoice", params: { payment_request: invoice })

        JSON.parse(response.body)
      end
    end
  end
end

CUSTODIAL_PUBKEYS = [
  '03021c5f5f57322740e4ee6936452add19dc7ea7ccf90635f95119ab82a62ae268', # bluewallet
  '02004c625d622245606a1ea2c1c69cfb4516b703b47945a3647713c05fe4aaeb1c', # WalletOfSatoshi.com
  '03c2abfa93eacec04721c019644584424aab2ba4dff3ac9bdab4e9c97007491dda', # tippin.me
  '031015a7839468a3c266d662d5bb21ea4cea24226936e2864a7ca4f2c3939836e0', # Breez
  '02a59dd887d4396178325ffb3f54b7fcb9ada9dd0d615caea2f2306d92a3692f6e', # dropbit.app
].freeze
