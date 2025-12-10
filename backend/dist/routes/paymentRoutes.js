import { Router } from 'express';
import { PaymentService } from '../services/PaymentService.js';
const router = Router();
const paymentService = new PaymentService();
// Create payment intent
router.post('/create-intent', async (req, res) => {
    try {
        const { amount, customerId } = req.body;
        if (!amount || amount <= 0) {
            return res.status(400).json({ error: 'Invalid amount' });
        }
        const result = await paymentService.createPaymentIntent(amount, 'eur', customerId);
        res.json(result);
    }
    catch (error) {
        console.error('Error creating payment intent:', error);
        res.status(500).json({ error: 'Failed to create payment intent' });
    }
});
// Create customer
router.post('/customers', async (req, res) => {
    try {
        const { email, name } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email is required' });
        }
        // Check if customer exists
        const existingCustomer = await paymentService.getCustomerByEmail(email);
        if (existingCustomer) {
            return res.json(existingCustomer);
        }
        const customer = await paymentService.createCustomer(email, name);
        res.json(customer);
    }
    catch (error) {
        console.error('Error creating customer:', error);
        res.status(500).json({ error: 'Failed to create customer' });
    }
});
// Attach payment method
router.post('/payment-methods/attach', async (req, res) => {
    try {
        const { paymentMethodId, customerId } = req.body;
        if (!paymentMethodId || !customerId) {
            return res.status(400).json({ error: 'Payment method ID and customer ID are required' });
        }
        const paymentMethod = await paymentService.attachPaymentMethod(paymentMethodId, customerId);
        res.json(paymentMethod);
    }
    catch (error) {
        console.error('Error attaching payment method:', error);
        res.status(500).json({ error: 'Failed to attach payment method' });
    }
});
// List payment methods
router.get('/payment-methods/:customerId', async (req, res) => {
    try {
        const customerId = req.params.customerId;
        const paymentMethods = await paymentService.listPaymentMethods(customerId);
        res.json(paymentMethods);
    }
    catch (error) {
        console.error('Error listing payment methods:', error);
        res.status(500).json({ error: 'Failed to list payment methods' });
    }
});
export default router;
//# sourceMappingURL=paymentRoutes.js.map