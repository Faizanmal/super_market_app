"""
Payment Gateway Integration
Handles mobile payments, BNPL, and split bills
"""

import uuid
import hashlib
import hmac
from decimal import Decimal
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any
from enum import Enum
import json


class PaymentMethod(Enum):
    """Supported payment methods"""
    CREDIT_CARD = 'credit_card'
    DEBIT_CARD = 'debit_card'
    GOOGLE_PAY = 'google_pay'
    APPLE_PAY = 'apple_pay'
    SAMSUNG_PAY = 'samsung_pay'
    PAYPAL = 'paypal'
    BNPL_AFTERPAY = 'afterpay'
    BNPL_KLARNA = 'klarna'
    BNPL_AFFIRM = 'affirm'
    STORE_CREDIT = 'store_credit'
    LOYALTY_POINTS = 'loyalty_points'
    CASH = 'cash'
    CRYPTO = 'crypto'


class PaymentStatus(Enum):
    """Payment status types"""
    PENDING = 'pending'
    PROCESSING = 'processing'
    AUTHORIZED = 'authorized'
    CAPTURED = 'captured'
    COMPLETED = 'completed'
    FAILED = 'failed'
    CANCELLED = 'cancelled'
    REFUNDED = 'refunded'
    PARTIALLY_REFUNDED = 'partially_refunded'
    DISPUTED = 'disputed'


class PaymentGatewayBase:
    """Base class for payment gateway integrations"""
    
    def __init__(self, api_key: str, secret_key: str, sandbox: bool = True):
        self.api_key = api_key
        self.secret_key = secret_key
        self.sandbox = sandbox
        self.base_url = self._get_base_url()
    
    def _get_base_url(self) -> str:
        raise NotImplementedError
    
    def create_payment_intent(self, amount: Decimal, currency: str, **kwargs) -> Dict:
        raise NotImplementedError
    
    def capture_payment(self, payment_id: str) -> Dict:
        raise NotImplementedError
    
    def refund_payment(self, payment_id: str, amount: Optional[Decimal] = None) -> Dict:
        raise NotImplementedError
    
    def _generate_signature(self, payload: str) -> str:
        return hmac.new(
            self.secret_key.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()


class StripeGateway(PaymentGatewayBase):
    """Stripe payment gateway integration"""
    
    def _get_base_url(self) -> str:
        return 'https://api.stripe.com/v1'
    
    def create_payment_intent(
        self,
        amount: Decimal,
        currency: str = 'usd',
        customer_id: Optional[str] = None,
        metadata: Optional[Dict] = None,
        **kwargs
    ) -> Dict:
        """Create a Stripe PaymentIntent"""
        # In production, use stripe library:
        # import stripe
        # stripe.api_key = self.api_key
        # intent = stripe.PaymentIntent.create(...)
        
        return {
            'id': f'pi_{uuid.uuid4().hex[:24]}',
            'client_secret': f'pi_{uuid.uuid4().hex}',
            'amount': int(amount * 100),  # Stripe uses cents
            'currency': currency,
            'status': 'requires_payment_method',
            'created': int(datetime.now().timestamp()),
        }
    
    def capture_payment(self, payment_id: str) -> Dict:
        """Capture an authorized payment"""
        return {
            'id': payment_id,
            'status': 'succeeded',
            'captured': True,
        }
    
    def refund_payment(self, payment_id: str, amount: Optional[Decimal] = None) -> Dict:
        """Refund a payment"""
        return {
            'id': f'rf_{uuid.uuid4().hex[:24]}',
            'payment_id': payment_id,
            'amount': int(amount * 100) if amount else None,
            'status': 'succeeded',
        }
    
    def create_customer(self, email: str, name: str, **kwargs) -> Dict:
        """Create a Stripe customer"""
        return {
            'id': f'cus_{uuid.uuid4().hex[:14]}',
            'email': email,
            'name': name,
            'created': int(datetime.now().timestamp()),
        }
    
    def attach_payment_method(self, customer_id: str, payment_method_token: str) -> Dict:
        """Attach a payment method to customer"""
        return {
            'id': f'pm_{uuid.uuid4().hex[:24]}',
            'customer': customer_id,
            'type': 'card',
        }


class MobileWalletHandler:
    """Handle mobile wallet payments (Google Pay, Apple Pay, Samsung Pay)"""
    
    def __init__(self, stripe_gateway: StripeGateway):
        self.stripe = stripe_gateway
        self.supported_networks = ['visa', 'mastercard', 'amex', 'discover']
    
    def get_payment_configuration(self, wallet_type: str) -> Dict:
        """Get wallet-specific payment configuration"""
        base_config = {
            'merchant_id': 'merchant.com.supermart',
            'merchant_name': 'SuperMart Pro',
            'supported_networks': self.supported_networks,
            'merchant_capabilities': ['supports3DS', 'supportsCredit', 'supportsDebit'],
        }
        
        if wallet_type == 'google_pay':
            return {
                **base_config,
                'environment': 'TEST' if self.stripe.sandbox else 'PRODUCTION',
                'api_version': 2,
                'api_version_minor': 0,
                'allowed_payment_methods': [{
                    'type': 'CARD',
                    'parameters': {
                        'allowedAuthMethods': ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
                        'allowedCardNetworks': ['VISA', 'MASTERCARD', 'AMEX'],
                    },
                    'tokenizationSpecification': {
                        'type': 'PAYMENT_GATEWAY',
                        'parameters': {
                            'gateway': 'stripe',
                            'stripe:version': '2022-11-15',
                            'stripe:publishableKey': self.stripe.api_key,
                        }
                    }
                }]
            }
        
        elif wallet_type == 'apple_pay':
            return {
                **base_config,
                'country_code': 'US',
                'currency_code': 'USD',
                'supported_features': [
                    'supports_instant_funds_out',
                    'supports_credit',
                    'supports_debit',
                ],
            }
        
        return base_config
    
    def process_wallet_payment(
        self,
        wallet_type: str,
        payment_token: str,
        amount: Decimal,
        currency: str = 'usd',
        **kwargs
    ) -> Dict:
        """Process a mobile wallet payment"""
        # Validate token and create payment
        intent = self.stripe.create_payment_intent(
            amount=amount,
            currency=currency,
            metadata={'wallet_type': wallet_type},
            **kwargs
        )
        
        return {
            'success': True,
            'payment_id': intent['id'],
            'wallet_type': wallet_type,
            'amount': float(amount),
            'currency': currency,
            'status': 'completed',
        }


class BNPLProvider:
    """Buy Now Pay Later provider integration"""
    
    def __init__(self, provider: str, api_key: str, sandbox: bool = True):
        self.provider = provider
        self.api_key = api_key
        self.sandbox = sandbox
    
    def check_eligibility(self, customer_id: str, amount: Decimal) -> Dict:
        """Check if customer is eligible for BNPL"""
        # Simulated eligibility check
        min_amount = Decimal('35.00')
        max_amount = Decimal('2000.00')
        
        eligible = min_amount <= amount <= max_amount
        
        return {
            'eligible': eligible,
            'provider': self.provider,
            'amount': float(amount),
            'payment_options': self._get_payment_options(amount) if eligible else [],
            'reason': None if eligible else 'Amount outside eligible range',
        }
    
    def _get_payment_options(self, amount: Decimal) -> List[Dict]:
        """Get available BNPL payment options"""
        if self.provider == 'afterpay':
            return [
                {
                    'plan': 'pay_in_4',
                    'installments': 4,
                    'frequency': 'biweekly',
                    'amount_per_installment': float(amount / 4),
                    'interest': 0,
                    'fees': 0,
                }
            ]
        
        elif self.provider == 'klarna':
            return [
                {
                    'plan': 'pay_in_4',
                    'installments': 4,
                    'frequency': 'biweekly',
                    'amount_per_installment': float(amount / 4),
                    'interest': 0,
                    'fees': 0,
                },
                {
                    'plan': 'pay_in_30',
                    'installments': 1,
                    'frequency': 'once',
                    'amount_per_installment': float(amount),
                    'interest': 0,
                    'fees': 0,
                    'due_date': (datetime.now() + timedelta(days=30)).isoformat(),
                },
                {
                    'plan': 'financing',
                    'installments': 12,
                    'frequency': 'monthly',
                    'amount_per_installment': float((amount * Decimal('1.15')) / 12),  # 15% APR example
                    'interest': 15.0,
                    'fees': 0,
                }
            ]
        
        elif self.provider == 'affirm':
            return [
                {
                    'plan': '3_month',
                    'installments': 3,
                    'frequency': 'monthly',
                    'amount_per_installment': float(amount / 3),
                    'interest': 0,
                    'fees': 0,
                },
                {
                    'plan': '6_month',
                    'installments': 6,
                    'frequency': 'monthly',
                    'amount_per_installment': float((amount * Decimal('1.10')) / 6),
                    'interest': 10.0,
                    'fees': 0,
                },
            ]
        
        return []
    
    def create_checkout(self, customer_id: str, order_id: str, amount: Decimal, plan: str) -> Dict:
        """Create BNPL checkout session"""
        return {
            'checkout_id': f'bnpl_{uuid.uuid4().hex[:16]}',
            'provider': self.provider,
            'order_id': order_id,
            'amount': float(amount),
            'plan': plan,
            'checkout_url': f'https://{self.provider}.example.com/checkout/{uuid.uuid4().hex}',
            'expires_at': (datetime.now() + timedelta(hours=1)).isoformat(),
        }
    
    def capture_payment(self, checkout_id: str) -> Dict:
        """Capture BNPL payment after checkout completion"""
        return {
            'success': True,
            'checkout_id': checkout_id,
            'status': 'captured',
            'captured_at': datetime.now().isoformat(),
        }


class SplitPaymentHandler:
    """Handle split bills and group payments"""
    
    def __init__(self, stripe_gateway: StripeGateway):
        self.stripe = stripe_gateway
        self.splits = {}  # split_id -> split details
    
    def create_split(
        self,
        order_id: str,
        total_amount: Decimal,
        participants: List[Dict],  # [{user_id, email, amount, ...}]
        split_type: str = 'equal',  # equal, custom, percentage
    ) -> Dict:
        """Create a split payment session"""
        split_id = f'split_{uuid.uuid4().hex[:16]}'
        
        if split_type == 'equal':
            amount_per_person = total_amount / len(participants)
            for p in participants:
                p['amount'] = float(amount_per_person)
        
        split = {
            'id': split_id,
            'order_id': order_id,
            'total_amount': float(total_amount),
            'split_type': split_type,
            'participants': participants,
            'status': 'pending',
            'payments_received': [],
            'created_at': datetime.now().isoformat(),
            'expires_at': (datetime.now() + timedelta(hours=24)).isoformat(),
        }
        
        self.splits[split_id] = split
        
        return split
    
    def get_participant_payment_link(self, split_id: str, participant_id: str) -> Dict:
        """Get payment link for a participant"""
        if split_id not in self.splits:
            return {'error': 'Split not found'}
        
        split = self.splits[split_id]
        participant = next((p for p in split['participants'] if p['user_id'] == participant_id), None)
        
        if not participant:
            return {'error': 'Participant not found'}
        
        return {
            'payment_url': f'https://pay.supermart.example.com/split/{split_id}/{participant_id}',
            'amount': participant['amount'],
            'expires_at': split['expires_at'],
        }
    
    def record_payment(self, split_id: str, participant_id: str, payment_id: str) -> Dict:
        """Record a participant's payment"""
        if split_id not in self.splits:
            return {'error': 'Split not found'}
        
        split = self.splits[split_id]
        participant = next((p for p in split['participants'] if p['user_id'] == participant_id), None)
        
        if not participant:
            return {'error': 'Participant not found'}
        
        # Record the payment
        split['payments_received'].append({
            'participant_id': participant_id,
            'payment_id': payment_id,
            'amount': participant['amount'],
            'paid_at': datetime.now().isoformat(),
        })
        
        # Check if all payments received
        all_paid = len(split['payments_received']) == len(split['participants'])
        if all_paid:
            split['status'] = 'completed'
        else:
            split['status'] = 'partial'
        
        return {
            'success': True,
            'split_status': split['status'],
            'payments_pending': len(split['participants']) - len(split['payments_received']),
        }
    
    def get_split_status(self, split_id: str) -> Dict:
        """Get status of a split payment"""
        if split_id not in self.splits:
            return {'error': 'Split not found'}
        
        split = self.splits[split_id]
        
        paid_participants = [p['participant_id'] for p in split['payments_received']]
        pending_participants = [
            p['user_id'] for p in split['participants']
            if p['user_id'] not in paid_participants
        ]
        
        return {
            'id': split_id,
            'status': split['status'],
            'total_amount': split['total_amount'],
            'amount_received': sum(p['amount'] for p in split['payments_received']),
            'paid_participants': paid_participants,
            'pending_participants': pending_participants,
        }


class StoreCreditManager:
    """Manage store credit and gift cards"""
    
    def __init__(self):
        self.credits = {}  # user_id -> credit balance
        self.gift_cards = {}  # card_number -> gift card info
    
    def get_balance(self, user_id: str) -> Decimal:
        """Get store credit balance"""
        return self.credits.get(user_id, Decimal('0'))
    
    def add_credit(self, user_id: str, amount: Decimal, reason: str) -> Dict:
        """Add store credit"""
        current = self.credits.get(user_id, Decimal('0'))
        self.credits[user_id] = current + amount
        
        return {
            'user_id': user_id,
            'amount_added': float(amount),
            'new_balance': float(self.credits[user_id]),
            'reason': reason,
        }
    
    def use_credit(self, user_id: str, amount: Decimal) -> Dict:
        """Use store credit for payment"""
        current = self.credits.get(user_id, Decimal('0'))
        
        if amount > current:
            return {'error': 'Insufficient store credit'}
        
        self.credits[user_id] = current - amount
        
        return {
            'success': True,
            'amount_used': float(amount),
            'remaining_balance': float(self.credits[user_id]),
        }
    
    def create_gift_card(self, amount: Decimal, purchaser_id: str) -> Dict:
        """Create a new gift card"""
        card_number = f'GM{uuid.uuid4().hex[:14].upper()}'
        pin = str(uuid.uuid4().int)[:4]
        
        self.gift_cards[card_number] = {
            'card_number': card_number,
            'pin': pin,
            'amount': amount,
            'balance': amount,
            'purchaser_id': purchaser_id,
            'redeemed_by': None,
            'created_at': datetime.now().isoformat(),
            'expires_at': (datetime.now() + timedelta(days=365)).isoformat(),
            'is_active': True,
        }
        
        return {
            'card_number': card_number,
            'pin': pin,
            'amount': float(amount),
        }
    
    def redeem_gift_card(self, card_number: str, pin: str, user_id: str) -> Dict:
        """Redeem gift card to store credit"""
        if card_number not in self.gift_cards:
            return {'error': 'Invalid gift card'}
        
        card = self.gift_cards[card_number]
        
        if card['pin'] != pin:
            return {'error': 'Invalid PIN'}
        
        if not card['is_active']:
            return {'error': 'Gift card is no longer active'}
        
        if card['balance'] <= 0:
            return {'error': 'Gift card has no balance'}
        
        # Transfer balance to store credit
        amount = card['balance']
        card['balance'] = Decimal('0')
        card['redeemed_by'] = user_id
        card['is_active'] = False
        
        self.add_credit(user_id, amount, f'Gift card redemption: {card_number}')
        
        return {
            'success': True,
            'amount_redeemed': float(amount),
            'store_credit_balance': float(self.credits[user_id]),
        }


class PaymentService:
    """Main payment service orchestrating all payment methods"""
    
    def __init__(self, stripe_api_key: str, stripe_secret: str, sandbox: bool = True):
        self.stripe = StripeGateway(stripe_api_key, stripe_secret, sandbox)
        self.wallet_handler = MobileWalletHandler(self.stripe)
        self.split_handler = SplitPaymentHandler(self.stripe)
        self.store_credit = StoreCreditManager()
        
        # BNPL providers
        self.bnpl_providers = {
            'afterpay': BNPLProvider('afterpay', 'afterpay_key', sandbox),
            'klarna': BNPLProvider('klarna', 'klarna_key', sandbox),
            'affirm': BNPLProvider('affirm', 'affirm_key', sandbox),
        }
    
    def process_payment(
        self,
        order_id: str,
        amount: Decimal,
        payment_method: PaymentMethod,
        customer_id: str,
        **kwargs
    ) -> Dict:
        """Process payment with specified method"""
        
        if payment_method in [PaymentMethod.CREDIT_CARD, PaymentMethod.DEBIT_CARD]:
            return self._process_card_payment(order_id, amount, customer_id, **kwargs)
        
        elif payment_method in [PaymentMethod.GOOGLE_PAY, PaymentMethod.APPLE_PAY, PaymentMethod.SAMSUNG_PAY]:
            return self.wallet_handler.process_wallet_payment(
                payment_method.value, kwargs.get('payment_token', ''), amount, **kwargs
            )
        
        elif payment_method in [PaymentMethod.BNPL_AFTERPAY, PaymentMethod.BNPL_KLARNA, PaymentMethod.BNPL_AFFIRM]:
            provider_name = payment_method.value.replace('bnpl_', '')
            return self._process_bnpl(order_id, amount, customer_id, provider_name, **kwargs)
        
        elif payment_method == PaymentMethod.STORE_CREDIT:
            return self.store_credit.use_credit(customer_id, amount)
        
        elif payment_method == PaymentMethod.LOYALTY_POINTS:
            return self._process_loyalty_payment(customer_id, amount, **kwargs)
        
        else:
            return {'error': f'Unsupported payment method: {payment_method.value}'}
    
    def _process_card_payment(self, order_id: str, amount: Decimal, customer_id: str, **kwargs) -> Dict:
        """Process card payment"""
        intent = self.stripe.create_payment_intent(
            amount=amount,
            metadata={'order_id': order_id, 'customer_id': customer_id}
        )
        
        return {
            'success': True,
            'payment_id': intent['id'],
            'client_secret': intent['client_secret'],
            'status': intent['status'],
        }
    
    def _process_bnpl(self, order_id: str, amount: Decimal, customer_id: str, provider: str, **kwargs) -> Dict:
        """Process BNPL payment"""
        if provider not in self.bnpl_providers:
            return {'error': f'Unknown BNPL provider: {provider}'}
        
        bnpl = self.bnpl_providers[provider]
        
        # Check eligibility
        eligibility = bnpl.check_eligibility(customer_id, amount)
        if not eligibility['eligible']:
            return {'error': eligibility['reason']}
        
        # Create checkout
        plan = kwargs.get('plan', eligibility['payment_options'][0]['plan'])
        checkout = bnpl.create_checkout(customer_id, order_id, amount, plan)
        
        return {
            'success': True,
            'checkout_url': checkout['checkout_url'],
            'checkout_id': checkout['checkout_id'],
            'plan': plan,
        }
    
    def _process_loyalty_payment(self, customer_id: str, amount: Decimal, **kwargs) -> Dict:
        """Process payment using loyalty points"""
        from .customer_app_models import LoyaltyCard
        
        try:
            card = LoyaltyCard.objects.get(customer__user_id=customer_id)
            points_needed = int(amount / card.program.redemption_rate)
            
            if card.points_balance >= points_needed:
                discount = card.redeem_points(points_needed)
                return {
                    'success': True,
                    'points_redeemed': points_needed,
                    'discount_amount': float(discount),
                    'remaining_points': card.points_balance,
                }
            else:
                return {
                    'error': 'Insufficient loyalty points',
                    'points_available': card.points_balance,
                    'points_needed': points_needed,
                }
        except Exception as e:
            return {'error': str(e)}
    
    def get_available_methods(self, amount: Decimal, customer_id: str) -> List[Dict]:
        """Get available payment methods for customer"""
        methods = [
            {'method': 'credit_card', 'name': 'Credit Card', 'icon': '💳', 'available': True},
            {'method': 'debit_card', 'name': 'Debit Card', 'icon': '💳', 'available': True},
            {'method': 'google_pay', 'name': 'Google Pay', 'icon': '📱', 'available': True},
            {'method': 'apple_pay', 'name': 'Apple Pay', 'icon': '🍎', 'available': True},
            {'method': 'paypal', 'name': 'PayPal', 'icon': '🅿️', 'available': True},
        ]
        
        # Add BNPL if eligible
        for provider_name, provider in self.bnpl_providers.items():
            eligibility = provider.check_eligibility(customer_id, amount)
            methods.append({
                'method': f'bnpl_{provider_name}',
                'name': provider_name.title(),
                'icon': '🔄',
                'available': eligibility['eligible'],
                'payment_options': eligibility.get('payment_options', []),
            })
        
        # Add store credit if available
        credit_balance = self.store_credit.get_balance(customer_id)
        methods.append({
            'method': 'store_credit',
            'name': 'Store Credit',
            'icon': '🏪',
            'available': credit_balance > 0,
            'balance': float(credit_balance),
        })
        
        return methods


# Global payment service instance
# In production, load API keys from environment
payment_service = PaymentService(
    stripe_api_key='pk_test_xxx',
    stripe_secret='sk_test_xxx',
    sandbox=True
)
