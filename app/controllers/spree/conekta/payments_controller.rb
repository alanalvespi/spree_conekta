module Spree::Conekta
  class PaymentsController < Spree::StoreController
    ssl_required

    def show
      @order = Spree::Order.find_by_number(params[:id])
      @order_details = @order.last_payment_details.params
    end

    def create
      PaymentNotificationHandler.new(params).perform_action if params['type'] == 'charge.paid'
      render nothing: true
    end

  # POST /charges
  # POST /charges.json
  def create
    product = Product.find(charge_params["charge"]["product_id"])
    if product.is_subscription?
      # Create Plan
      plan = Conekta::Plan.create({
        id: "#{product.name}-#{rand(999999)}",
        name: product.description,
        amount: product.price,
          currency: "MXN",
          interval: "month"
      })
      # Create Customer
      customer = Conekta::Customer.create({
        name: "Juan #{rand(999)}",
        email: "lews.therin@gmail.com",
        phone: "55-5555-5555",
        cards: [charge_params["charge"]["token"]]
      })
      subscription = customer.create_subscription({
        "plan_id" => plan.id
      })
      respond_to do |format|
        if subscription
          format.html { redirect_to products_path, notice: 'Subscription was successfully created.' }
        else
          format.html { render action: 'new' }
        end
      end
    else
      begin
        charge = Conekta::Charge.create({
          amount: product.price.to_i,
          currency: 'MXN',
          description: product.description,
          card: charge_params["charge"]["token"],
          reference_id: "ANYIDCAN-be-ref"
        })
      rescue Conekta::Error => e
        flash[:error] = e.message
        raise e.message
        return
      end
      @charge = Charge.new
      @charge.add(charge)
      respond_to do |format|
        if @charge.save
          format.html { redirect_to @charge, notice: 'Charge was successfully created.' }
          format.json { render action: 'show', status: :created, location: @charge }
        else
          format.html { render action: 'new' }
          format.json { render json: @charge.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  #ToDo destroy and update
  end
end
