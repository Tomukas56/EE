import Stripe from 'stripe';
function getStripe() {
    const apiKey = process.env.STRIPE_SECRET_KEY;
    if (!apiKey) {
        throw new Error('STRIPE_SECRET_KEY is not configured');
    }
    return new Stripe(apiKey, {
        apiVersion: '2025-11-17.clover',
    });
}
export class PaymentService {
    async createPaymentIntent(amount, currency = 'eur', customerId) {
        try {
            const params = {
                amount: Math.round(amount * 100),
                currency,
                automatic_payment_methods: { enabled: true },
            };
            if (customerId)
                params.customer = customerId;
            const paymentIntent = await getStripe().paymentIntents.create(params);
            return {
                clientSecret: paymentIntent.client_secret,
                paymentIntentId: paymentIntent.id,
            };
        }
        catch (error) {
            console.error('Error creating payment intent:', error);
            throw error;
        }
    }
    async createCustomer(email, name) {
        try {
            const params = { email };
            if (name)
                params.name = name;
            return await getStripe().customers.create(params);
        }
        catch (error) {
            console.error('Error creating customer:', error);
            throw error;
        }
    }
    async getCustomerByEmail(email) {
        try {
            const customers = await getStripe().customers.list({ email, limit: 1 });
            return customers.data[0] || null;
        }
        catch (error) {
            console.error('Error getting customer:', error);
            throw error;
        }
    }
    async attachPaymentMethod(paymentMethodId, customerId) {
        try {
            const stripe = getStripe();
            const paymentMethod = await stripe.paymentMethods.attach(paymentMethodId, { customer: customerId });
            await stripe.customers.update(customerId, {
                invoice_settings: { default_payment_method: paymentMethodId },
            });
            return paymentMethod;
        }
        catch (error) {
            console.error('Error attaching payment method:', error);
            throw error;
        }
    }
    async listPaymentMethods(customerId) {
        try {
            const paymentMethods = await getStripe().paymentMethods.list({ customer: customerId, type: 'card' });
            return paymentMethods.data;
        }
        catch (error) {
            console.error('Error listing payment methods:', error);
            throw error;
        }
    }
    async chargeSession(customerId, amount, description) {
        try {
            return await getStripe().paymentIntents.create({
                amount: Math.round(amount * 100),
                currency: 'eur',
                customer: customerId,
                description,
                confirm: true,
                automatic_payment_methods: { enabled: true, allow_redirects: 'never' },
            });
        }
        catch (error) {
            console.error('Error charging session:', error);
            throw error;
        }
    }
}
//# sourceMappingURL=PaymentService.js.map