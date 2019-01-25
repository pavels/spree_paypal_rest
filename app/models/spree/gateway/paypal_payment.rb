module Spree
  module Gateway::PaypalPayment

    def payment(order, web_profile_id, return_url, cancel_url)
      payment_options = payment_payload(order, web_profile_id, return_url, cancel_url)
      @payment = PayPal::SDK::REST::DataTypes::Payment.new(payment_options)
      return @payment
    end

    def payment_payload(order, web_profile_id, return_url, cancel_url)
      
      #paypal don't like it if the subtotal don't add up
      #If we have Promo we have to change sub_total
      #TODO: Update for TaxRate, Shipment 
      sub_total = 0
      order.all_adjustments.eligible.each do |adj|
          if (adj.source_type.eql?('Spree::PromotionAction'))
           sub_total = sub_total + adj.amount
          end
      end
      sub_total = sub_total + order.item_total
      
      
      
      payload = {
        intent: 'sale',
        experience_profile_id: web_profile_id,
        payer:{
          payment_method: 'paypal',
          payer_info:{
            first_name: order.billing_address.first_name,
            last_name: order.billing_address.last_name,
            email: order.email,
            billing_address: billing_address(order)
          }
        },
        redirect_urls: {
          return_url: return_url,
          cancel_url: cancel_url,
        },
        transactions:[{
          item_list:{
            items: order_line_items(order)
          },
          amount: {
            total: '%.2f' % order.total,
            currency: order.currency,
            details:{
              shipping: '%.2f' % order.shipments.map(&:discounted_cost).sum,
              subtotal: '%.2f' % order.item_total,
              tax: '%.2f' % order.additional_tax_total
            }
          },
          description: 'This is the sale description',
        }]
      }
    end

    def order_line_items(order)
      items = []

      order.line_items.map do |item|
        items << {
          name: item.product.name,
          sku: item.product.sku,
          price: '%.2f' % item.price,
          currency: item.order.currency,
          quantity: item.quantity
        }
      end

      order.all_adjustments.eligible.each do |adj|
        next if adj.amount.zero?
        next if adj.source_type.eql?('Spree::TaxRate')
        next if adj.source_type.eql?('Spree::Shipment')
        next if adj.source_type.eql?('Spree::PromotionAction')
        items << {
          name: adj.label,
          price: '%.2f' % adj.amount,
          currency: order.currency,
          quantity: 1
        }
      end
      items
    end

    def billing_address(order)
      {
        recipient_name: order.billing_address.full_name,
        line1: order.billing_address.address1 + ' ' + order.billing_address.address2,
        city: order.billing_address.city,
        country_code: order.billing_address.country.iso,
        postal_code: order.billing_address.zipcode,
        phone: order.billing_address.phone,
        state: order.billing_address.state ? order.billing_address.state.name : ''
      }
    end

  end
end