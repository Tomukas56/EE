import Stripe from 'stripe';
export declare class PaymentService {
    createPaymentIntent(amount: number, currency?: string, customerId?: string): Promise<{
        clientSecret: string | null;
        paymentIntentId: string;
    }>;
    createCustomer(email: string, name?: string): Promise<Stripe.Response<Stripe.Customer>>;
    getCustomerByEmail(email: string): Promise<Stripe.Customer | null>;
    attachPaymentMethod(paymentMethodId: string, customerId: string): Promise<Stripe.Response<Stripe.PaymentMethod>>;
    listPaymentMethods(customerId: string): Promise<Stripe.PaymentMethod[]>;
    chargeSession(customerId: string, amount: number, description: string): Promise<Stripe.Response<Stripe.PaymentIntent>>;
}
//# sourceMappingURL=PaymentService.d.ts.map