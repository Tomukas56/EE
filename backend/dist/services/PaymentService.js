import Stripe from 'stripe';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
    apiVersion: '2025-11-17.clover',
});
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
            const paymentIntent = await stripe.paymentIntents.create(params);
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
            return await stripe.customers.create(params);
        }
        catch (error) {
            console.error('Error creating customer:', error);
            throw error;
        }
    }
    async getCustomerByEmail(email) {
        try {
            const customers = await stripe.customers.list({ email, limit: 1 });
            return customers.data[0] || null;
        }
        catch (error) {
            console.error('Error getting customer:', error);
            throw error;
        }
    }
    async attachPaymentMethod(paymentMethodId, customerId) {
        try {
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
            const paymentMethods = await stripe.paymentMethods.list({ customer: customerId, type: 'card' });
            return paymentMethods.data;
        }
        catch (error) {
            console.error('Error listing payment methods:', error);
            throw error;
        }
    }
    async chargeSession(customerId, amount, description) {
        try {
            return await stripe.paymentIntents.create({
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